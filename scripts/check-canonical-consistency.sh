#!/usr/bin/env bash
# check-canonical-consistency.sh
#
# Cross-sister canonical consistency guardrail.
# Uses agentic-memory as the reference sister and verifies that
# all other sisters have equivalent structural files.
#
# Usage:
#   ./scripts/check-canonical-consistency.sh           # check all sisters
#   ./scripts/check-canonical-consistency.sh identity   # check one sister
#   ./scripts/check-canonical-consistency.sh --fix      # show fix suggestions
#
# Exit codes:
#   0  All checks pass
#   1  One or more checks failed

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ─── Configuration ───────────────────────────────────────────────────────────

REFERENCE="agentic-memory"
SISTERS=("agentic-vision" "agentic-codebase" "agentic-identity")

# Filter to specific sister if argument provided
if [[ "${1:-}" != "" && "${1:-}" != "--fix" ]]; then
    SISTERS=("agentic-${1/agentic-/}")
fi

SHOW_FIX=false
if [[ "${1:-}" == "--fix" || "${2:-}" == "--fix" ]]; then
    SHOW_FIX=true
fi

FAIL_COUNT=0
WARN_COUNT=0
PASS_COUNT=0
SKIP_COUNT=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Helpers ─────────────────────────────────────────────────────────────────

pass() {
    ((PASS_COUNT++))
    printf "  ${GREEN}PASS${NC}  %s — %s\n" "$1" "$2"
}

fail() {
    ((FAIL_COUNT++))
    printf "  ${RED}FAIL${NC}  %s — %s\n" "$1" "$2"
    if [[ "$SHOW_FIX" == true && -n "${3:-}" ]]; then
        printf "        ${CYAN}fix:${NC} %s\n" "$3"
    fi
}

warn() {
    ((WARN_COUNT++))
    printf "  ${YELLOW}WARN${NC}  %s — %s\n" "$1" "$2"
}

skip() {
    ((SKIP_COUNT++))
}

section() {
    printf "\n${BOLD}── %s ──${NC}\n" "$1"
}

# ─── Check: Root-Level Files ────────────────────────────────────────────────

check_root_files() {
    local sister="$1"
    local ref_dir="$ROOT_DIR/$REFERENCE"
    local sis_dir="$ROOT_DIR/$sister"

    local files=(
        README.md
        LICENSE
        CONTRIBUTING.md
        INSTALL.md
        Cargo.toml
        Cargo.lock
        .gitignore
    )

    for f in "${files[@]}"; do
        if [[ -f "$ref_dir/$f" ]]; then
            if [[ -f "$sis_dir/$f" ]]; then
                # Check non-empty
                if [[ -s "$sis_dir/$f" ]]; then
                    pass "$sister" "root/$f exists and non-empty"
                else
                    fail "$sister" "root/$f is empty" "Populate $sister/$f"
                fi
            else
                fail "$sister" "root/$f missing" "cp $REFERENCE/$f $sister/$f (adapt content)"
            fi
        fi
    done
}

# ─── Check: docs/ Directory ─────────────────────────────────────────────────

check_docs() {
    local sister="$1"
    local ref_dir="$ROOT_DIR/$REFERENCE/docs"
    local sis_dir="$ROOT_DIR/$sister/docs"

    # Canonical docs files (from reference sister, excluding sister-specific ones)
    local docs=(
        api-reference.md
        benchmarks.md
        command-surface.md
        concepts.md
        faq.md
        file-format.md
        integration-guide.md
        quickstart.md
        runtime-install-sync.md
    )

    for f in "${docs[@]}"; do
        if [[ -f "$ref_dir/$f" ]]; then
            if [[ -f "$sis_dir/$f" ]]; then
                local lines
                lines=$(wc -l < "$sis_dir/$f" | tr -d ' ')
                if (( lines > 5 )); then
                    pass "$sister" "docs/$f exists ($lines lines)"
                else
                    warn "$sister" "docs/$f is very short ($lines lines)"
                fi
            else
                fail "$sister" "docs/$f missing" "Create $sister/docs/$f"
            fi
        fi
    done

    # Check REPO_HYGIENE.md (canonical across all sisters)
    if [[ -f "$sis_dir/REPO_HYGIENE.md" ]]; then
        pass "$sister" "docs/REPO_HYGIENE.md exists"
    else
        fail "$sister" "docs/REPO_HYGIENE.md missing" "Create $sister/docs/REPO_HYGIENE.md"
    fi
}

# ─── Check: docs/public/ Directory ──────────────────────────────────────────

check_docs_public() {
    local sister="$1"
    local sis_dir="$ROOT_DIR/$sister/docs/public"

    local public_files=(
        sister.manifest.json
        installation.md
        command-surface.md
    )

    for f in "${public_files[@]}"; do
        if [[ -f "$sis_dir/$f" ]]; then
            pass "$sister" "docs/public/$f exists"
        else
            fail "$sister" "docs/public/$f missing" "Create $sister/docs/public/$f"
        fi
    done
}

# ─── Check: .github/ Templates and Workflows ───────────────────────────────

check_github() {
    local sister="$1"
    local sis_dir="$ROOT_DIR/$sister/.github"

    local templates=(
        ISSUE_TEMPLATE/bug_report.md
        ISSUE_TEMPLATE/feature_request.md
        PULL_REQUEST_TEMPLATE.md
        FUNDING.yml
    )

    for f in "${templates[@]}"; do
        if [[ -f "$sis_dir/$f" ]]; then
            pass "$sister" ".github/$f exists"
        else
            fail "$sister" ".github/$f missing" "Create $sister/.github/$f"
        fi
    done

    # Check for at least one CI workflow
    local workflow_count
    workflow_count=$(find "$sis_dir/workflows" -name "*.yml" 2>/dev/null | wc -l | tr -d ' ')
    if (( workflow_count > 0 )); then
        pass "$sister" ".github/workflows/ has $workflow_count workflow(s)"
    else
        fail "$sister" ".github/workflows/ has no CI workflows" "Add CI workflow YAML files"
    fi
}

# ─── Check: scripts/ Directory ──────────────────────────────────────────────

check_scripts() {
    local sister="$1"
    local sis_dir="$ROOT_DIR/$sister/scripts"

    if [[ -d "$sis_dir" ]]; then
        if [[ -f "$sis_dir/install.sh" ]]; then
            pass "$sister" "scripts/install.sh exists"
        else
            fail "$sister" "scripts/install.sh missing" "Create $sister/scripts/install.sh"
        fi

        local script_count
        script_count=$(find "$sis_dir" -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
        if (( script_count > 0 )); then
            pass "$sister" "scripts/ has $script_count script(s)"
        else
            warn "$sister" "scripts/ directory is empty"
        fi
    else
        fail "$sister" "scripts/ directory missing" "mkdir -p $sister/scripts"
    fi
}

# ─── Check: planning-docs/ ──────────────────────────────────────────────────

check_planning_docs() {
    local sister="$1"
    local sis_dir="$ROOT_DIR/$sister/planning-docs"

    if [[ -d "$sis_dir" ]]; then
        pass "$sister" "planning-docs/ directory exists"

        if [[ -f "$sis_dir/CANONICAL_SISTER_KIT.md" ]]; then
            pass "$sister" "planning-docs/CANONICAL_SISTER_KIT.md exists"
        else
            fail "$sister" "planning-docs/CANONICAL_SISTER_KIT.md missing" "Copy from $REFERENCE"
        fi

        # Check for ECOSYSTEM-CONVENTIONS (canonical reference doc)
        if [[ -f "$sis_dir/ECOSYSTEM-CONVENTIONS.md" ]]; then
            pass "$sister" "planning-docs/ECOSYSTEM-CONVENTIONS.md exists"
        else
            warn "$sister" "planning-docs/ECOSYSTEM-CONVENTIONS.md missing (recommended)"
        fi

        # Check for implementation delta
        local delta_count
        delta_count=$(find "$sis_dir" -name "IMPLEMENTATION-DELTA*" 2>/dev/null | wc -l | tr -d ' ')
        if (( delta_count > 0 )); then
            pass "$sister" "planning-docs/ has $delta_count implementation delta(s)"
        else
            warn "$sister" "planning-docs/ has no IMPLEMENTATION-DELTA file"
        fi
    else
        fail "$sister" "planning-docs/ directory missing" "mkdir -p $sister/planning-docs"
    fi
}

# ─── Check: assets/ Directory ───────────────────────────────────────────────

check_assets() {
    local sister="$1"
    local sis_dir="$ROOT_DIR/$sister/assets"

    if [[ -d "$sis_dir" ]]; then
        local svg_count
        svg_count=$(find "$sis_dir" -name "*.svg" 2>/dev/null | wc -l | tr -d ' ')
        if (( svg_count > 0 )); then
            pass "$sister" "assets/ has $svg_count SVG(s)"
        else
            warn "$sister" "assets/ exists but has no SVG files (hero/terminal pane needed)"
        fi
    else
        fail "$sister" "assets/ directory missing" "mkdir -p $sister/assets"
    fi
}

# ─── Check: examples/ Directory ─────────────────────────────────────────────

check_examples() {
    local sister="$1"
    local sis_dir="$ROOT_DIR/$sister/examples"

    if [[ -d "$sis_dir" ]]; then
        pass "$sister" "examples/ directory exists"
        if [[ -f "$sis_dir/README.md" ]]; then
            pass "$sister" "examples/README.md exists"
        else
            warn "$sister" "examples/README.md missing"
        fi
    else
        warn "$sister" "examples/ directory missing"
    fi
}

# ─── Check: docs/ecosystem/ ─────────────────────────────────────────────────

check_ecosystem_docs() {
    local sister="$1"
    local sis_dir="$ROOT_DIR/$sister/docs/ecosystem"

    local ecosystem_files=(
        CANONICAL_SISTER_KIT.md
    )

    for f in "${ecosystem_files[@]}"; do
        if [[ -f "$sis_dir/$f" ]]; then
            pass "$sister" "docs/ecosystem/$f exists"
        else
            warn "$sister" "docs/ecosystem/$f missing"
        fi
    done
}

# ─── Check: Python Bindings ─────────────────────────────────────────────────

check_python() {
    local sister="$1"
    local sis_dir="$ROOT_DIR/$sister/python"

    if [[ -d "$sis_dir" ]]; then
        pass "$sister" "python/ directory exists"
        if [[ -f "$sis_dir/pyproject.toml" ]]; then
            pass "$sister" "python/pyproject.toml exists"
        else
            fail "$sister" "python/pyproject.toml missing" "Create Python package config"
        fi
    else
        warn "$sister" "python/ directory missing (Python bindings not available)"
    fi
}

# ─── Check: npm/WASM Bindings ───────────────────────────────────────────────

check_npm() {
    local sister="$1"
    local sis_dir="$ROOT_DIR/$sister/npm/wasm"

    if [[ -d "$sis_dir" ]]; then
        pass "$sister" "npm/wasm/ directory exists"
        if [[ -f "$sis_dir/Cargo.toml" ]]; then
            pass "$sister" "npm/wasm/Cargo.toml exists"
        else
            fail "$sister" "npm/wasm/Cargo.toml missing"
        fi
    else
        warn "$sister" "npm/wasm/ directory missing (WASM bindings not available)"
    fi
}

# ─── Check: Paper/Research ───────────────────────────────────────────────────

check_paper() {
    local sister="$1"
    local sis_dir="$ROOT_DIR/$sister"

    # Check for paper/ or publication/ directory
    local paper_dirs=()
    [[ -d "$sis_dir/paper" ]] && paper_dirs+=("$sis_dir/paper")
    [[ -d "$sis_dir/publication" ]] && paper_dirs+=("$sis_dir/publication")

    if (( ${#paper_dirs[@]} > 0 )); then
        local pdf_count=0
        pdf_count=$(find "${paper_dirs[@]}" -name "*.pdf" 2>/dev/null | wc -l | tr -d ' ') || true
        if (( pdf_count > 0 )); then
            pass "$sister" "Research paper(s) found ($pdf_count PDF(s))"
        else
            warn "$sister" "paper/ directory exists but no PDFs found"
        fi
    else
        warn "$sister" "No paper/ or publication/ directory"
    fi
}

# ─── Check: README Quality ──────────────────────────────────────────────────

check_readme_sections() {
    local sister="$1"
    local readme="$ROOT_DIR/$sister/README.md"

    if [[ ! -f "$readme" ]]; then
        fail "$sister" "README.md missing entirely"
        return
    fi

    # Check for canonical sections that every sister should have
    local sections=(
        "Problems Solved"
        "Install"
        "Benchmarks"
        "MCP Server"
        "Privacy and Security"
    )

    for section in "${sections[@]}"; do
        if grep -qi "$section" "$readme" >/dev/null 2>&1; then
            pass "$sister" "README has '$section' section"
        else
            fail "$sister" "README missing '$section' section" "Add ## $section to README.md"
        fi
    done

    # Check for footer
    if grep -q "Agentra Labs" "$readme" >/dev/null 2>&1; then
        pass "$sister" "README has Agentra Labs footer"
    else
        warn "$sister" "README missing Agentra Labs footer"
    fi

    # Check for badge row
    if grep -q "img.shields.io" "$readme" >/dev/null 2>&1; then
        pass "$sister" "README has badge row"
    else
        fail "$sister" "README missing badge row"
    fi
}

# ─── Main ────────────────────────────────────────────────────────────────────

printf "${BOLD}Cross-Sister Canonical Consistency Check${NC}\n"
printf "Reference: ${CYAN}%s${NC}\n" "$REFERENCE"
printf "Checking:  %s\n" "${SISTERS[*]}"
printf "Date:      %s\n" "$(date +%Y-%m-%d)"

for sister in "${SISTERS[@]}"; do
    if [[ ! -d "$ROOT_DIR/$sister" ]]; then
        printf "\n${RED}ERROR: $sister directory not found at $ROOT_DIR/$sister${NC}\n"
        ((FAIL_COUNT++))
        continue
    fi

    section "$sister"

    check_root_files "$sister"
    check_docs "$sister"
    check_docs_public "$sister"
    check_github "$sister"
    check_scripts "$sister"
    check_planning_docs "$sister"
    check_assets "$sister"
    check_examples "$sister"
    check_ecosystem_docs "$sister"
    check_python "$sister"
    check_npm "$sister"
    check_paper "$sister"
    check_readme_sections "$sister"
done

# ─── Summary ─────────────────────────────────────────────────────────────────

printf "\n${BOLD}── Summary ──${NC}\n"
printf "  ${GREEN}PASS${NC}: %d\n" "$PASS_COUNT"
printf "  ${RED}FAIL${NC}: %d\n" "$FAIL_COUNT"
printf "  ${YELLOW}WARN${NC}: %d\n" "$WARN_COUNT"

if (( FAIL_COUNT > 0 )); then
    printf "\n${RED}${BOLD}FAILED${NC} — %d check(s) failed. Run with --fix for suggestions.\n" "$FAIL_COUNT"
    exit 1
else
    if (( WARN_COUNT > 0 )); then
        printf "\n${GREEN}${BOLD}PASSED${NC} with %d warning(s).\n" "$WARN_COUNT"
    else
        printf "\n${GREEN}${BOLD}PASSED${NC} — all checks green.\n"
    fi
    exit 0
fi
