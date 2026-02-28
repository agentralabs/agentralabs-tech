#!/usr/bin/env bash
# check-canonical-consistency.sh — Cross-sister consistency validator
#
# Run from the agentralabs-tech workspace root. Validates that ALL sisters
# are structurally identical where they must be. If anything drifts, it fails.
#
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"

# Load sister data from single-source registry
source "$(dirname "$0")/lib/load-sisters.sh"

ERRORS=0

fail() {
  echo "FAIL: $*" >&2
  ERRORS=$((ERRORS + 1))
}

pass() {
  echo "  ok: $*"
}

section() {
  echo ""
  echo "── $* ──"
}

# ── 0. Cross-validate SISTERS array against web navigation contract ────────

section "Cross-validate SISTERS against navigation-contract.json"

NAV_CONTRACT_FILE="${WORKSPACE}/agentralabs-tech-web/docs/ecosystem/navigation-contract.json"
if [ -f "$NAV_CONTRACT_FILE" ] && command -v python3 >/dev/null 2>&1; then
  CONTRACT_KEYS="$(python3 -c "
import json, sys
data = json.load(open('${NAV_CONTRACT_FILE}'))
keys = sorted('agentic-' + s['key'] for s in data.get('sisters',[]) if s.get('enabled', True))
print(' '.join(keys))
")"
  SCRIPT_KEYS="$(printf '%s\n' "${SISTERS[@]}" | sort | tr '\n' ' ' | sed 's/ $//')"
  if [ "$CONTRACT_KEYS" = "$SCRIPT_KEYS" ]; then
    pass "SISTERS array matches navigation-contract.json enabled sisters"
  else
    fail "SISTERS array does not match navigation-contract.json. Script: [${SCRIPT_KEYS}] Contract: [${CONTRACT_KEYS}]. A new sister may have been added to the web contract but not to this script."
  fi
else
  pass "Skipping navigation-contract cross-check (file or python3 not available)"
fi

# ── 1. CANONICAL_SISTER_KIT.md byte-identity ────────────────────────────────

section "CANONICAL_SISTER_KIT.md byte-identity"

REFERENCE="${WORKSPACE}/agentic-memory/docs/ecosystem/CANONICAL_SISTER_KIT.md"
if [ ! -f "$REFERENCE" ]; then
  fail "Reference file missing: ${REFERENCE}"
else
  for sister in "${SISTERS[@]}"; do
    target="${WORKSPACE}/${sister}/docs/ecosystem/CANONICAL_SISTER_KIT.md"
    if [ ! -f "$target" ]; then
      fail "${sister}: missing docs/ecosystem/CANONICAL_SISTER_KIT.md"
    elif ! diff -q "$REFERENCE" "$target" >/dev/null 2>&1; then
      fail "${sister}: docs/ecosystem/CANONICAL_SISTER_KIT.md differs from memory's"
      diff --brief "$REFERENCE" "$target" 2>&1 | head -3
    else
      pass "${sister}: canonical kit matches"
    fi
  done
fi

# ── 2. Check script body-identity ───────────────────────────────────────────

section "Check script body-identity (assertion body must match)"

extract_body() {
  # Strip everything before "# ── Shared helpers" and the header vars section
  sed -n '/^# ── Shared helpers/,$p' "$1"
}

REFERENCE_BODY="$(extract_body "${WORKSPACE}/agentic-memory/scripts/check-canonical-sister.sh")"
for sister in "${SISTERS[@]}"; do
  target="${WORKSPACE}/${sister}/scripts/check-canonical-sister.sh"
  if [ ! -f "$target" ]; then
    fail "${sister}: missing scripts/check-canonical-sister.sh"
  else
    body="$(extract_body "$target")"
    if [ "$REFERENCE_BODY" != "$body" ]; then
      fail "${sister}: check script assertion body differs from memory's"
    else
      pass "${sister}: check script body matches"
    fi
  fi
done

# ── 3. Sister manifest presence and structure ───────────────────────────────

section "Sister manifest validation"

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  key="${EXPECTED_KEYS[$i]}"
  name="${EXPECTED_NAMES[$i]}"
  manifest="${WORKSPACE}/${sister}/docs/public/sister.manifest.json"

  if [ ! -f "$manifest" ]; then
    fail "${sister}: missing docs/public/sister.manifest.json"
    continue
  fi

  if ! grep -qF "\"key\": \"${key}\"" "$manifest"; then
    fail "${sister}: manifest missing key \"${key}\""
  else
    pass "${sister}: manifest key=${key}"
  fi

  if ! grep -qF "\"name\": \"${name}\"" "$manifest"; then
    fail "${sister}: manifest missing name \"${name}\""
  else
    pass "${sister}: manifest name=${name}"
  fi

  if ! grep -qF '"page_ids": [' "$manifest"; then
    fail "${sister}: manifest missing page_ids array"
  else
    pass "${sister}: manifest has page_ids"
  fi
done

# ── 4. Install script canonical strings ─────────────────────────────────────

section "Install script canonical output strings"

CANONICAL_STRINGS=(
  "MCP client summary:"
  "Universal MCP entry (works in any MCP client):"
  "Quick terminal check:"
  'echo "  args: ${SERVER_ARGS_TEXT}"'
  "After restart, confirm"
  "Optional feedback:"
  "AGENTIC_TOKEN"
)

for sister in "${SISTERS[@]}"; do
  script="${WORKSPACE}/${sister}/scripts/install.sh"
  if [ ! -f "$script" ]; then
    fail "${sister}: missing scripts/install.sh"
    continue
  fi
  missing=0
  for str in "${CANONICAL_STRINGS[@]}"; do
    if ! grep -qF "$str" "$script"; then
      fail "${sister}: install.sh missing canonical string: ${str}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: install.sh has all canonical strings"
  fi
done

# ── 5. README section consistency ───────────────────────────────────────────

section "README canonical sections"

README_SECTIONS=(
  '## Install'
  '## Quickstart'
  '## How It Works'
  '<img src="assets/github-hero-pane.svg"'
  '<img src="assets/github-terminal-pane.svg"'
)

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    fail "${sister}: missing README.md"
    continue
  fi
  missing=0
  for sec in "${README_SECTIONS[@]}"; do
    if ! grep -qF "$sec" "$readme"; then
      fail "${sister}: README.md missing: ${sec}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: README has all canonical sections"
  fi
done

# ── 6. CI workflow presence ─────────────────────────────────────────────────

section "CI workflow presence"

REQUIRED_WORKFLOWS=(
  ci.yml
  release.yml
  canonical-sister-guardrails.yml
  install-command-guardrails.yml
)

for sister in "${SISTERS[@]}"; do
  missing=0
  for wf in "${REQUIRED_WORKFLOWS[@]}"; do
    if [ ! -f "${WORKSPACE}/${sister}/.github/workflows/${wf}" ]; then
      fail "${sister}: missing .github/workflows/${wf}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: all required workflows present"
  fi
done

# ── 7. Release workflow publish parity ───────────────────────────────────────

section "Release workflow publish parity (core + ffi + mcp + cli)"

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  release_wf="${WORKSPACE}/${sister}/.github/workflows/release.yml"

  if [ ! -f "$release_wf" ]; then
    fail "${sister}: missing .github/workflows/release.yml"
    continue
  fi

  missing=0
  for pkg in "${CORE_CRATES[$i]}" "${FFI_CRATES[$i]}" "${MCP_CRATES[$i]}" "${CLI_CRATES[$i]}"; do
    if ! grep -qF "$pkg" "$release_wf"; then
      fail "${sister}: release workflow missing publish target ${pkg}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: release workflow references core+ffi+mcp+cli crates"
  fi

  if grep -Eq 'cargo publish[^#\n]*\|\|[[:space:]]*true' "$release_wf"; then
    fail "${sister}: release workflow has non-blocking cargo publish (|| true)"
  fi
  if grep -qF 'continue-on-error: true' "$release_wf"; then
    fail "${sister}: release workflow has continue-on-error: true (publish must fail fast)"
  fi
done

# ── 8. CI workflow trigger alignment ────────────────────────────────────────

section "CI workflow trigger alignment (canonical-sister-guardrails.yml)"

for sister in "${SISTERS[@]}"; do
  wf="${WORKSPACE}/${sister}/.github/workflows/canonical-sister-guardrails.yml"
  if [ ! -f "$wf" ]; then
    continue  # already flagged above
  fi
  if ! grep -qF 'push:' "$wf"; then
    fail "${sister}: canonical-sister-guardrails.yml missing push trigger"
  elif ! grep -qF 'pull_request:' "$wf"; then
    fail "${sister}: canonical-sister-guardrails.yml missing pull_request trigger"
  else
    pass "${sister}: CI triggers aligned (push + pull_request)"
  fi
done

# ── 9. Asset directory ──────────────────────────────────────────────────────

section "Design asset presence"

for sister in "${SISTERS[@]}"; do
  hero="${WORKSPACE}/${sister}/assets/github-hero-pane.svg"
  term="${WORKSPACE}/${sister}/assets/github-terminal-pane.svg"
  if [ ! -f "$hero" ] || [ ! -f "$term" ]; then
    fail "${sister}: missing SVG assets"
  else
    pass "${sister}: SVG assets present"
  fi
done

# ── 10. Web install route registration ───────────────────────────────────────

section "Web install route registration"

ROUTE_FILE="${WORKSPACE}/agentralabs-tech-web/app/install/[target]/[profile]/route.ts"
if [ ! -f "$ROUTE_FILE" ]; then
  pass "Skipping web install route check (web repo not available)"
else
  for key in "${SISTER_KEYS[@]}"; do
    if ! grep -qF "\"${key}\"" "$ROUTE_FILE"; then
      fail "Web route missing target: ${key}"
    else
      pass "Web route has target: ${key}"
    fi
  done
fi

# ── 11. Public docs baseline parity ────────────────────────────────────────

section "Public docs baseline parity"

BASELINE_DOCS=(
  experience-with-vs-without.md
  quickstart.md
  installation.md
  command-surface.md
  runtime-install-sync.md
  integration-guide.md
  concepts.md
  api-reference.md
  benchmarks.md
  faq.md
)

for sister in "${SISTERS[@]}"; do
  missing=0
  for doc in "${BASELINE_DOCS[@]}"; do
    if [ ! -f "${WORKSPACE}/${sister}/docs/public/${doc}" ]; then
      fail "${sister}: missing docs/public/${doc}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: all baseline public docs present"
  fi
done

# ── 12. Core scripts presence ──────────────────────────────────────────────

section "Core scripts presence"

REQUIRED_SCRIPTS=(
  scripts/install.sh
  scripts/check-install-commands.sh
  scripts/check-canonical-sister.sh
  scripts/check-runtime-hardening.sh
  scripts/test-primary-problems.sh
)

for sister in "${SISTERS[@]}"; do
  missing=0
  for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -f "${WORKSPACE}/${sister}/${script}" ]; then
      fail "${sister}: missing ${script}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: all required scripts present"
  fi
done

# ── 13. Web navigation contract — all sister keys present ────────────────────

section "Web navigation contract"

NAV_CONTRACT="${WORKSPACE}/agentralabs-tech-web/docs/ecosystem/navigation-contract.json"
if [ ! -f "$NAV_CONTRACT" ]; then
  pass "Skipping navigation contract check (web repo not available)"
else
  for key in "${SISTER_KEYS[@]}"; do
    if ! grep -qF "\"key\": \"${key}\"" "$NAV_CONTRACT"; then
      fail "navigation-contract.json missing sister key: ${key}"
    else
      pass "navigation-contract.json has sister key: ${key}"
    fi
  done
fi

# ── 14. Manifest page_ids baseline ──────────────────────────────────────────

section "Manifest page_ids baseline"

BASELINE_PAGE_IDS=(
  experience-with-vs-without
  quickstart
  installation
  command-surface
  runtime-install-sync
)

for sister in "${SISTERS[@]}"; do
  manifest="${WORKSPACE}/${sister}/docs/public/sister.manifest.json"
  if [ ! -f "$manifest" ]; then
    continue  # already flagged above
  fi
  missing=0
  for pid in "${BASELINE_PAGE_IDS[@]}"; do
    if ! grep -qF "\"${pid}\"" "$manifest"; then
      fail "${sister}: manifest missing baseline page_id: ${pid}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: manifest has all baseline page_ids"
  fi
done

# ── 15. README nav bar links ────────────────────────────────────────────────

section "README nav bar links"

NAV_LINKS=(
  '#quickstart'
  '#problems-solved'
  '#how-it-works'
  '#benchmarks'
  '#install'
)
# Additional nav elements checked by text presence (not href)
NAV_TEXT_LINKS=(
  '>Papers</a>'
  '>API</a>'
)

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue  # already flagged above
  fi
  missing=0
  for link in "${NAV_LINKS[@]}"; do
    if ! grep -qF "href=\"${link}\"" "$readme"; then
      fail "${sister}: README nav bar missing link: ${link}"
      missing=1
    fi
  done
  for textlink in "${NAV_TEXT_LINKS[@]}"; do
    if ! grep -qF "$textlink" "$readme"; then
      fail "${sister}: README nav bar missing text link: ${textlink}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: README has all nav bar links"
  fi
done

# ── 16. README architecture SVG width ───────────────────────────────────────

section "README architecture SVG width"

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue  # already flagged above
  fi
  if grep -qF 'architecture-agentra.svg' "$readme"; then
    if grep 'architecture-agentra.svg' "$readme" | grep -qF 'width="980"'; then
      pass "${sister}: architecture SVG width=980"
    else
      fail "${sister}: architecture SVG not using width=\"980\""
    fi
  fi
done

# ── 17. Web scenario data files ─────────────────────────────────────────────

section "Web scenario data files"

WEB_DATA_DIR="${WORKSPACE}/agentralabs-tech-web/data"
if [ ! -d "$WEB_DATA_DIR" ]; then
  pass "Skipping web scenario data check (web repo not available)"
else
  for key in "${SISTER_KEYS[@]}"; do
    datafile="${WEB_DATA_DIR}/scenarios-${key}.ts"
    if [ ! -f "$datafile" ]; then
      fail "Web missing data/scenarios-${key}.ts"
    else
      pass "Web has data/scenarios-${key}.ts"
    fi
  done
fi

# ── 18. Workspace README sister mentions ──────────────────────────────────

section "Workspace README sister mentions"

WORKSPACE_README="${WORKSPACE}/README.md"
if [ ! -f "$WORKSPACE_README" ]; then
  fail "Workspace README.md missing"
else
  for sister in "${SISTERS[@]}"; do
    if grep -qF "$sister" "$WORKSPACE_README"; then
      pass "Workspace README mentions ${sister}"
    else
      fail "Workspace README missing mention of ${sister}"
    fi
  done
fi

# ── 19. README npm install rows ──────────────────────────────────────────────

section "README npm install rows"

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  pkg="${NPM_PACKAGES[$i]}"
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue  # already flagged above
  fi
  if grep -qF "npm install ${pkg}" "$readme"; then
    pass "${sister}: README has npm install ${pkg}"
  else
    fail "${sister}: README missing npm install ${pkg}"
  fi
done

# ── 20. Installation doc npm sections ────────────────────────────────────────

section "Installation doc npm sections"

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  pkg="${NPM_PACKAGES[$i]}"
  doc="${WORKSPACE}/${sister}/docs/public/installation.md"
  if [ ! -f "$doc" ]; then
    fail "${sister}: missing docs/public/installation.md"
    continue
  fi
  if grep -qF "npm install ${pkg}" "$doc"; then
    pass "${sister}: installation.md has npm install ${pkg}"
  else
    fail "${sister}: installation.md missing npm install ${pkg}"
  fi
done

# ── 21. Required SVG assets per sister ────────────────────────────────────────

section "Required SVG assets per sister"

REQUIRED_SVGS=(
  "assets/github-hero-pane.svg"
  "assets/github-terminal-pane.svg"
  "assets/benchmark-chart.svg"
  "assets/architecture-agentra.svg"
)

for sister in "${SISTERS[@]}"; do
  missing=0
  for svg in "${REQUIRED_SVGS[@]}"; do
    if [ ! -f "${WORKSPACE}/${sister}/${svg}" ]; then
      fail "${sister}: missing ${svg}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: all required SVGs present"
  fi
done

# ── 22. README references benchmark and architecture SVGs ────────────────────

section "README benchmark + architecture SVG references"

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue
  fi
  if ! grep -qF 'benchmark-chart.svg' "$readme"; then
    fail "${sister}: README missing benchmark-chart.svg reference"
  elif ! grep -qF 'architecture-agentra.svg' "$readme"; then
    fail "${sister}: README missing architecture-agentra.svg reference"
  else
    pass "${sister}: README references both benchmark + architecture SVGs"
  fi
done

# ── 23. MCP command-surface documentation completeness ─────────────────────

section "MCP command-surface documentation completeness"

CMD_SURFACE_SCRIPT="${WORKSPACE}/scripts/check-command-surface.sh"
if [ -f "$CMD_SURFACE_SCRIPT" ]; then
  if bash "$CMD_SURFACE_SCRIPT" >/dev/null 2>&1; then
    pass "All MCP tools documented in command-surface.md (all sisters)"
  else
    # Re-run to capture which tools are missing (|| true prevents set -e exit)
    sub_output="$(bash "$CMD_SURFACE_SCRIPT" 2>&1 || true)"
    sub_errors="$(echo "$sub_output" | grep -c '^FAIL:' || true)"
    echo "$sub_output" | grep '^FAIL:' | while IFS= read -r line; do
      echo "FAIL: $line"
    done || true
    ERRORS=$((ERRORS + sub_errors))
  fi
else
  fail "scripts/check-command-surface.sh not found"
fi

# ── 24. 4-crate structure + language bindings per sister ──────────────────────

section "4-crate structure + language bindings"

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  key="${SISTER_KEYS[$i]}"
  missing=0

  for suffix in cli mcp ffi; do
    crate_dir="${WORKSPACE}/${sister}/crates/agentic-${key}-${suffix}"
    if [ ! -d "$crate_dir" ] || [ ! -f "${crate_dir}/Cargo.toml" ]; then
      fail "${sister}: missing crate crates/agentic-${key}-${suffix}"
      missing=1
    fi
  done

  if [ ! -d "${WORKSPACE}/${sister}/python" ] || [ ! -f "${WORKSPACE}/${sister}/python/pyproject.toml" ]; then
    fail "${sister}: missing python/pyproject.toml"
    missing=1
  fi

  if [ ! -d "${WORKSPACE}/${sister}/npm/wasm" ] || [ ! -f "${WORKSPACE}/${sister}/npm/wasm/Cargo.toml" ]; then
    fail "${sister}: missing npm/wasm/Cargo.toml"
    missing=1
  fi

  if [ "$missing" -eq 0 ]; then
    pass "${sister}: 4-crate structure + python + wasm present"
  fi
done

# ── 25. MCP stdio hardening parity ──────────────────────────────────────────

section "MCP stdio hardening parity (frame limit + Content-Length + JSON-RPC)"

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  key="${SISTER_KEYS[$i]}"
  mcp_src="${WORKSPACE}/${sister}/crates/agentic-${key}-mcp/src"

  if [ ! -d "$mcp_src" ]; then
    fail "${sister}: MCP source directory missing (crates/agentic-${key}-mcp/src)"
    continue
  fi

  missing=0

  # 8 MiB frame limit constant
  if ! grep -rqF "MAX_CONTENT_LENGTH_BYTES" "$mcp_src"; then
    fail "${sister}: MCP source missing MAX_CONTENT_LENGTH_BYTES (8 MiB frame limit)"
    missing=1
  fi

  # Content-Length framing support
  if ! grep -rqiF "content-length:" "$mcp_src"; then
    fail "${sister}: MCP source missing Content-Length framing"
    missing=1
  fi

  # JSON-RPC version handling
  if ! grep -rqF "jsonrpc" "$mcp_src"; then
    fail "${sister}: MCP source missing jsonrpc version handling"
    missing=1
  fi

  if [ "$missing" -eq 0 ]; then
    pass "${sister}: MCP hardening patterns present (frame limit + framing + jsonrpc)"
  fi
done

# ── 26. Local goals/ directory structure (gitignored but must exist) ──────────
#
# WHEN YOU NEED CONTRACTS:
#   cat goals/validation/SISTER-HYDRA-INTEGRATION-CONTRACT.md
#   cat goals/validation/MCP-TOOL-STANDARDS.md
#
# WHEN BUILDING A NEW SISTER:
#   cat goals/new-sisters/SISTER-V2-PATTERNS.md
#   cp -r agentic-sdk/ ../new-sister/deps/
#
# WHEN BUILDING HYDRA:
#   ls goals/hydra/   # 13 specification documents
#

section "Local goals/ directory structure"

GOALS_DIR="${WORKSPACE}/goals"
if [ ! -d "$GOALS_DIR" ]; then
  pass "Skipping goals/ check (gitignored, local-only)"
else
  GOALS_GROUPS=(validation new-sisters hydra vision)
  missing=0
  for group in "${GOALS_GROUPS[@]}"; do
    if [ ! -d "${GOALS_DIR}/${group}" ]; then
      fail "goals/${group}/ subdirectory missing"
      missing=1
    fi
  done

  # Validation group — needed NOW for sister compliance
  VALIDATION_DOCS=(
    "SISTER-HYDRA-INTEGRATION-CONTRACT.md"
    "MCP-TOOL-STANDARDS.md"
    "EDGE-CASE-HANDLERS-SPEC.md"
  )
  for doc in "${VALIDATION_DOCS[@]}"; do
    if [ ! -f "${GOALS_DIR}/validation/${doc}" ]; then
      fail "goals/validation/${doc} missing"
      missing=1
    fi
  done

  # New-sisters group — needed when building future sisters
  NEW_SISTER_DOCS=(
    "ASTRAL-MISSING-SISTERS.md"
    "SISTER-V2-PATTERNS.md"
    "SISTER-V2-PLANNED-PRE-PHILIP.md"
  )
  for doc in "${NEW_SISTER_DOCS[@]}"; do
    if [ ! -f "${GOALS_DIR}/new-sisters/${doc}" ]; then
      fail "goals/new-sisters/${doc} missing"
      missing=1
    fi
  done

  # Hydra group — needed LATER when building Hydra orchestrator
  HYDRA_DOCS=(
    "HYDRA-COMPLETE-SPEC.md"
    "HYDRA-INVENTIONS.md"
    "SKILL-FABRIC-SPEC.md"
    "RESOURCE-OPTIMIZATION-SPEC.md"
    "HYDRA-UX-SPEC.md"
    "HYDRA-ARCHITECTURE-FEEDBACK.md"
    "HYDRA-SKILL-ECOSYSTEMS.md"
    "HydraPhilosophy.md"
    "HydraMail.md"
    "HYDRA-PHONECOMM.md"
    "MOREOFHYDRA.md"
    "UIUX-minset.md"
  )
  for doc in "${HYDRA_DOCS[@]}"; do
    if [ ! -f "${GOALS_DIR}/hydra/${doc}" ]; then
      fail "goals/hydra/${doc} missing"
      missing=1
    fi
  done

  # Vision group — 20-year roadmaps
  VISION_DOCS=(
    "SISTER-VISION-20-YEAR.md"
    "VISION-AMEM-20-YEAR-ROADMAP.md"
  )
  for doc in "${VISION_DOCS[@]}"; do
    if [ ! -f "${GOALS_DIR}/vision/${doc}" ]; then
      fail "goals/vision/${doc} missing"
      missing=1
    fi
  done

  if [ "$missing" -eq 0 ]; then
    pass "goals/ has all 4 groups with all required documents"
  fi

  # Hydra gradual planning: every sister should have a section
  HYDRA_PLANNING="${GOALS_DIR}/hydra/HYDRA-GRADUAL-PLANNING.md"
  if [ -f "$HYDRA_PLANNING" ]; then
    hydra_missing=()
    for key in "${SISTER_KEYS[@]}"; do
      # Check for the sister's section header (case-insensitive)
      if ! grep -qi "From ${key}" "$HYDRA_PLANNING"; then
        hydra_missing+=("$key")
      fi
    done
    if [ ${#hydra_missing[@]} -gt 0 ]; then
      # Soft warning — does not increment ERRORS (not a CI blocker)
      echo "  WARN: HYDRA-GRADUAL-PLANNING.md missing sections for: ${hydra_missing[*]}"
      echo "        Add lessons learned from these sisters to goals/hydra/HYDRA-GRADUAL-PLANNING.md"
    else
      pass "HYDRA-GRADUAL-PLANNING.md has sections for all ${#SISTER_KEYS[@]} sisters"
    fi
  fi
fi

# ── 27. Local agentic-sdk/ crate (gitignored but must exist) ──────────
#
# Single source of truth for Rust traits all sisters implement.
# Will be published to crates.io when ready.
#
# WHEN VALIDATING A SISTER:
#   cd agentic-sdk && cargo test
#   cat docs/SISTER-COMPLIANCE-VERIFICATION.md
#
# WHEN BUILDING A NEW SISTER:
#   # Add to new sister's Cargo.toml:
#   # agentic-sdk = { path = "../agentic-sdk" }
#

section "Local agentic-sdk/ crate"

CONTRACTS_DIR="${WORKSPACE}/agentic-sdk"
if [ ! -d "$CONTRACTS_DIR" ]; then
  pass "Skipping agentic-sdk/ check (gitignored, local-only)"
else
  missing=0

  if [ ! -f "${CONTRACTS_DIR}/Cargo.toml" ]; then
    fail "agentic-sdk/Cargo.toml missing"
    missing=1
  fi

  REQUIRED_SOURCES=(
    src/lib.rs
    src/types.rs
    src/sister.rs
    src/context.rs
    src/errors.rs
    src/events.rs
    src/grounding.rs
    src/query.rs
    src/receipts.rs
    src/file_format.rs
    src/hydra.rs
  )
  for src in "${REQUIRED_SOURCES[@]}"; do
    if [ ! -f "${CONTRACTS_DIR}/${src}" ]; then
      fail "agentic-sdk/${src} missing"
      missing=1
    fi
  done

  if [ ! -f "${CONTRACTS_DIR}/docs/SISTER-COMPLIANCE-VERIFICATION.md" ]; then
    fail "agentic-sdk/docs/SISTER-COMPLIANCE-VERIFICATION.md missing"
    missing=1
  fi

  # v0.2.0: Verify key traits exist in source
  for trait_name in "SessionManagement" "WorkspaceManagement" "Grounding" "HydraBridge" "ExecutionGate" "ProtocolError"; do
    if ! grep -rq "$trait_name" "${CONTRACTS_DIR}/src/"; then
      fail "agentic-sdk missing required trait/type: $trait_name"
      missing=1
    fi
  done

  if [ "$missing" -eq 0 ]; then
    pass "agentic-sdk/ crate structure complete (11 source files + v0.2.0 traits)"
  fi
fi

# ── 28. Research paper directory parity ──────────────────────────────────────

section "Research paper directory parity"

for sister in "${SISTERS[@]}"; do
  paper_dir="${WORKSPACE}/${sister}/paper"
  if [ ! -d "$paper_dir" ]; then
    fail "${sister}: missing paper/ directory"
    continue
  fi

  paper_i="$(ls -d "${paper_dir}"/paper-i-* 2>/dev/null | head -1)"
  if [ -z "$paper_i" ]; then
    fail "${sister}: missing paper/paper-i-* subdirectory"
    continue
  fi

  if ! ls "$paper_i"/*.tex >/dev/null 2>&1; then
    fail "${sister}: missing .tex file in $(basename "$paper_i")"
  elif ! ls "$paper_i"/*.bib >/dev/null 2>&1; then
    fail "${sister}: missing .bib file in $(basename "$paper_i")"
  else
    pass "${sister}: paper/paper-i-* with .tex + .bib present"
  fi
done

# ── 29. SVG design system conformance ────────────────────────────────────────
#
# All sister SVGs MUST use the canonical Agentra design system:
#   Background: #f2f1ea (light parchment, NOT dark gradients)
#   Grid: dotted pattern with #b8b6ae or #c8c5bb or #c9c6bb dots
#   Text: #111111 primary ink
#   Accent: #ea580c orange
#   Font: JetBrains Mono (or IBM Plex Mono fallback)
#
# This prevents the exact problem that happened with agentic-time's initial
# SVGs (dark gradient theme with system-ui fonts).

section "SVG design system conformance (Agentra canonical)"

SVG_DESIGN_TOKENS=(
  "#f2f1ea"           # canonical background color
  "#111111"           # canonical ink color
  "#ea580c"           # canonical accent color
  "JetBrains Mono"    # canonical font family
)

SVG_DARK_ANTI_TOKENS=(
  "linearGradient"    # dark gradient backgrounds are NOT canonical
  "system-ui"         # system fonts are NOT canonical
)

for sister in "${SISTERS[@]}"; do
  missing=0
  for svg in "${REQUIRED_SVGS[@]}"; do
    svgfile="${WORKSPACE}/${sister}/${svg}"
    if [ ! -f "$svgfile" ]; then
      continue  # already flagged in section 21
    fi

    # Positive check: must contain design tokens
    for token in "${SVG_DESIGN_TOKENS[@]}"; do
      if ! grep -qF "$token" "$svgfile"; then
        fail "${sister}: ${svg} missing design token: ${token}"
        missing=1
      fi
    done

    # Negative check: must NOT contain anti-tokens
    for antitoken in "${SVG_DARK_ANTI_TOKENS[@]}"; do
      if grep -qF "$antitoken" "$svgfile"; then
        fail "${sister}: ${svg} has non-canonical token: ${antitoken} (use Agentra design system)"
        missing=1
      fi
    done
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: all SVGs conform to Agentra design system"
  fi
done

# ── 30. README full canonical structure ──────────────────────────────────────
#
# Beyond basic section presence (section 5), enforce the complete README
# structure that all sisters must have. This catches stripped-down READMEs
# that have Install/Quickstart but miss MCP, Benchmarks, or other sections.

section "README full canonical structure"

README_FULL_SECTIONS=(
  '## Problems Solved'
  '## MCP'                      # MCP Tools or MCP Server
  '## Benchmarks'
  '## Why'
  '## Install'
  '## Quickstart'
  '## How It Works'
  '## Common Workflows'
  '## Validation'
  '## Repository Structure'
  '## Contributing'
  '## Privacy and Security'
  'Built by'                    # footer
)

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue  # already flagged above
  fi
  missing=0
  for sec in "${README_FULL_SECTIONS[@]}"; do
    if ! grep -qF "$sec" "$readme"; then
      fail "${sister}: README missing canonical section/element: ${sec}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: README has all canonical structure elements"
  fi
done

# ── 31. README canonical badges ──────────────────────────────────────────────
#
# All sisters must have the standard badge rows: pip install, cargo install,
# MCP Server, MIT License, and format badge.

section "README canonical badges"

README_BADGES=(
  'pip_install'
  'cargo_install'
  'MCP_Server'
  'License-MIT'
  'Research-Paper_I'        # must link to paper-i
  'format-.'               # .amem, .atime, .acb, .avis, .aid
)

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue
  fi
  missing=0
  for badge in "${README_BADGES[@]}"; do
    if ! grep -qF "$badge" "$readme"; then
      fail "${sister}: README missing canonical badge: ${badge}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: README has all canonical badges"
  fi
done

# ── 32. README deployment model section ──────────────────────────────────────

section "README Deployment Model + MCP Server configuration"

README_DEPLOY_ELEMENTS=(
  '## Deployment Model'
  '## MCP Server'
  'claude_desktop_config.json'
  '.vscode/settings.json'
  'Standalone'
)

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue
  fi
  missing=0
  for elem in "${README_DEPLOY_ELEMENTS[@]}"; do
    if ! grep -qF "$elem" "$readme"; then
      fail "${sister}: README missing deployment element: ${elem}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: README has deployment model + MCP server config"
  fi
done

# ── 33. README install profiles (desktop/terminal/server) ──────────────────

section "README install profiles"

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue
  fi
  missing=0
  for profile in desktop terminal server; do
    if ! grep -qF "install/${profile}" "$readme" 2>/dev/null; then
      # Try alternate pattern with sister key
      key="${sister#agentic-}"
      if ! grep -qF "${key}/${profile}" "$readme" 2>/dev/null; then
        fail "${sister}: README missing install profile: ${profile}"
        missing=1
      fi
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: README has all 3 install profiles"
  fi
done

# ── 34. Root governance files ────────────────────────────────────────────────
#
# Every sister MUST have these root files for a professional, complete repo.

section "Root governance files"

ROOT_FILES=(
  LICENSE
  CONTRIBUTING.md
  SECURITY.md
  Makefile
  CHANGELOG.md
)

for sister in "${SISTERS[@]}"; do
  missing=0
  for rf in "${ROOT_FILES[@]}"; do
    if [ ! -f "${WORKSPACE}/${sister}/${rf}" ]; then
      fail "${sister}: missing root file ${rf}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: all root governance files present"
  fi
done

# ── 35. Web content: every sister name must appear in critical web pages ──────

section "Web sister name parity in critical pages"

WEB_ROOT="${WORKSPACE}/agentralabs-tech-web"

# These files MUST mention ALL sister display names. If a new sister is added
# and these files are not updated, the guardrail will FAIL.
WEB_CRITICAL_FILES=(
  "app/page.tsx"
  "app/layout.tsx"
  "components/footer.tsx"
  "components/pricing-section.tsx"
  "lib/site.ts"
  "app/opengraph-image.tsx"
  "app/projects/page.tsx"
  "app/projects/head.tsx"
)

if [ ! -d "$WEB_ROOT" ]; then
  pass "Skipping web sister name parity (web repo not available)"
else
  for webfile in "${WEB_CRITICAL_FILES[@]}"; do
    filepath="${WEB_ROOT}/${webfile}"
    if [ ! -f "$filepath" ]; then
      fail "Web critical file missing: ${webfile}"
      continue
    fi
    missing_names=()
    for name in "${SISTER_DISPLAY_NAMES[@]}"; do
      if ! grep -qF "$name" "$filepath"; then
        missing_names+=("$name")
      fi
    done
    if [ ${#missing_names[@]} -gt 0 ]; then
      fail "Web ${webfile} missing sister names: ${missing_names[*]}"
    else
      pass "Web ${webfile}: all 5 sister names present"
    fi
  done
fi

# ── 36. Web content: file format strings must appear on home page ─────────────

section "Web home page file format completeness"

HOME_PAGE="${WEB_ROOT}/app/page.tsx"
HERO_SECTION="${WEB_ROOT}/components/hero-section.tsx"

if [ ! -d "$WEB_ROOT" ]; then
  pass "Skipping web file format check (web repo not available)"
else
  for target in "$HOME_PAGE" "$HERO_SECTION"; do
    if [ ! -f "$target" ]; then
      continue
    fi
    basename="$(basename "$(dirname "$target")")/$(basename "$target")"
    missing_fmt=()
    for fmt in "${FILE_FORMATS[@]}"; do
      if ! grep -qF "$fmt" "$target"; then
        missing_fmt+=("$fmt")
      fi
    done
    if [ ${#missing_fmt[@]} -gt 0 ]; then
      fail "Web ${basename} missing file formats: ${missing_fmt[*]}"
    else
      pass "Web ${basename}: all 5 file formats present"
    fi
  done
fi

# ── 37. Web content: no stale "Four" count (must say "Five") ──────────────────

section "Web stale sister count detection"

# Any file saying "Four open-source" or "Four independent" or "Four file formats"
# is stale and must be updated to "Five".
STALE_COUNT_PATTERNS=(
  "Four open-source"
  "Four file format"
  "Four independent"
  "Four sisters"
)

if [ ! -d "$WEB_ROOT" ]; then
  pass "Skipping stale count detection (web repo not available)"
else
  stale_found=0
  for pattern in "${STALE_COUNT_PATTERNS[@]}"; do
    matches="$(grep -rl "$pattern" "$WEB_ROOT" --include='*.tsx' --include='*.ts' --include='*.md' 2>/dev/null || true)"
    if [ -n "$matches" ]; then
      while IFS= read -r match; do
        relative="${match#"${WEB_ROOT}/"}"
        # Skip node_modules and .next
        case "$relative" in
          node_modules/*|.next/*) continue ;;
        esac
        fail "Web ${relative} contains stale count: '${pattern}' (should be Five)"
        stale_found=1
      done <<< "$matches"
    fi
  done
  if [ "$stale_found" -eq 0 ]; then
    pass "Web: no stale 'Four' sister counts found"
  fi
fi

# ── 38. Web flyer pages: all sisters in social media OG images ────────────────

section "Web social media flyer sister parity"

WEB_FLYER_FILES=(
  "app/flyers/twitter-post/route.tsx"
  "app/flyers/linkedin-post/route.tsx"
  "app/twitter-image.tsx"
)

# These files must reference all sister short names (MEMORY, VISION, etc.)
# OR their full display names (AgenticMemory, etc.)

if [ ! -d "$WEB_ROOT" ]; then
  pass "Skipping flyer parity (web repo not available)"
else
  for flyer in "${WEB_FLYER_FILES[@]}"; do
    filepath="${WEB_ROOT}/${flyer}"
    if [ ! -f "$filepath" ]; then
      fail "Web flyer missing: ${flyer}"
      continue
    fi
    missing_short=()
    for sname in "${SISTER_SHORT_NAMES[@]}"; do
      # Check for short name OR full name (case insensitive)
      if ! grep -qi "$sname" "$filepath"; then
        missing_short+=("$sname")
      fi
    done
    if [ ${#missing_short[@]} -gt 0 ]; then
      fail "Web ${flyer} missing sisters: ${missing_short[*]}"
    else
      pass "Web ${flyer}: all 5 sisters present"
    fi
  done
fi

# ── 39. Web about section: all sisters mentioned in description ───────────────

section "Web about section sister completeness"

ABOUT_SECTION="${WEB_ROOT}/components/about-section.tsx"
if [ ! -f "$ABOUT_SECTION" ]; then
  pass "Skipping about section check (file not available)"
else
  missing_about=()
  for name in "${SISTER_DISPLAY_NAMES[@]}"; do
    if ! grep -qF "$name" "$ABOUT_SECTION"; then
      missing_about+=("$name")
    fi
  done
  if [ ${#missing_about[@]} -gt 0 ]; then
    fail "Web about-section.tsx missing sister names: ${missing_about[*]}"
  else
    pass "Web about-section.tsx: all 5 sister names present"
  fi
fi

# ── 40. Web scenario data + component: every sister has scenario integration ──

section "Web scenario integration completeness"

SCENARIO_COMPONENT="${WEB_ROOT}/components/scenario-cards-section.tsx"
SCENARIO_PAGE="${WEB_ROOT}/components/scenario-page.tsx"

if [ ! -d "$WEB_ROOT" ]; then
  pass "Skipping scenario integration check (web repo not available)"
else
  # Already checked data files in section 17, now check components reference all
  for component in "$SCENARIO_COMPONENT" "$SCENARIO_PAGE"; do
    if [ ! -f "$component" ]; then
      continue
    fi
    basename="$(basename "$component")"
    for key in "${SISTER_KEYS[@]}"; do
      if ! grep -qi "$key" "$component"; then
        fail "Web ${basename} missing scenario reference for: ${key}"
      fi
    done
    pass "Web ${basename}: all 5 sister scenarios referenced"
  done
fi

# ── 41. Sister registry integrity ────────────────────────────────────────────
#
# Validates that docs/sisters-registry.json is present and consistent with
# the SISTERS array loaded from it. Also checks that key scripts and CI
# workflows reference the registry (not hardcoded lists).

section "Sister registry integrity"

REGISTRY_FILE="${WORKSPACE}/docs/sisters-registry.json"
if [ ! -f "$REGISTRY_FILE" ]; then
  fail "docs/sisters-registry.json not found"
else
  REGISTRY_COUNT=$(jq '.sisters | length' "$REGISTRY_FILE")
  SCRIPT_COUNT=${#SISTERS[@]}
  if [ "$REGISTRY_COUNT" -ne "$SCRIPT_COUNT" ]; then
    fail "Registry has $REGISTRY_COUNT sisters but script loaded $SCRIPT_COUNT"
  else
    pass "Registry count ($REGISTRY_COUNT) matches loaded SISTERS array"
  fi

  # Validate all registry sisters have required fields
  for i in $(seq 0 $((REGISTRY_COUNT - 1))); do
    key=$(jq -r ".sisters[$i].key" "$REGISTRY_FILE")
    for field in name repo shortName fileExtension cliBinary; do
      val=$(jq -r ".sisters[$i].${field}" "$REGISTRY_FILE")
      if [ "$val" = "null" ] || [ -z "$val" ]; then
        fail "Registry sister[$i] ($key) missing required field: $field"
      fi
    done
  done
  pass "All registry sisters have required fields"

  # Verify key scripts reference the registry (not hardcoded)
  REGISTRY_CONSUMERS=(
    "scripts/check-canonical-consistency.sh"
    "scripts/check-command-surface.sh"
    "scripts/install-mcp-servers.sh"
    "install_all.sh"
    "sync_artifacts.sh"
  )
  for script in "${REGISTRY_CONSUMERS[@]}"; do
    if [ -f "${WORKSPACE}/${script}" ]; then
      if grep -qF "load-sisters.sh" "${WORKSPACE}/${script}" || grep -qF "sisters-registry.json" "${WORKSPACE}/${script}"; then
        pass "${script} reads from registry"
      else
        fail "${script} does not reference registry (may have hardcoded sister list)"
      fi
    fi
  done

  # Verify CI workflows reference the registry
  CI_CONSUMERS=(
    ".github/workflows/canonical-consistency.yml"
  )
  for wf in "${CI_CONSUMERS[@]}"; do
    if [ -f "${WORKSPACE}/${wf}" ]; then
      if grep -qF "sisters-registry.json" "${WORKSPACE}/${wf}"; then
        pass "${wf} references sisters-registry.json"
      else
        fail "${wf} does not reference sisters-registry.json (may have hardcoded sister list)"
      fi
    fi
  done
fi

# ── Section 42: MCP Tool Description Quality ─────────────────────────────────

section "MCP Tool Description Quality (no trailing periods)"

for key in "${SISTER_KEYS[@]}"; do
  repo=$(jq -r ".sisters[] | select(.key==\"$key\") | .repo" "$REGISTRY_FILE")
  sister_dir="${WORKSPACE}/${repo}"

  if [ ! -d "$sister_dir" ]; then
    continue
  fi

  # Find the main MCP source file where tool descriptions live
  desc_file=""
  case "$key" in
    identity)
      desc_file="${sister_dir}/crates/agentic-identity-mcp/src/main.rs"
      ;;
    codebase)
      desc_file="${sister_dir}/src/mcp/server.rs"
      ;;
    memory)
      # Memory descriptions are in the tools/ directory via ToolDefinition structs
      desc_file="${sister_dir}/crates/agentic-memory-mcp/src/tools/registry.rs"
      ;;
    vision)
      desc_file="${sister_dir}/crates/agentic-vision-mcp/src/tools/registry.rs"
      ;;
    *)
      # For future sisters, try common locations
      for candidate in \
        "${sister_dir}/crates/agentic-${key}-mcp/src/main.rs" \
        "${sister_dir}/crates/agentic-${key}-mcp/src/tools/registry.rs" \
        "${sister_dir}/src/mcp/server.rs"; do
        if [ -f "$candidate" ]; then
          desc_file="$candidate"
          break
        fi
      done
      ;;
  esac

  if [ -n "$desc_file" ] && [ -f "$desc_file" ]; then
    # Count tool-level descriptions with trailing periods (.",)
    trailing=$(grep -c '"description":.*\."' "$desc_file" 2>/dev/null) || trailing=0
    if [ "$trailing" -gt 0 ]; then
      fail "${key}: ${trailing} tool description(s) have trailing periods (see goals/MCP-QUALITY-STANDARD.md)"
    else
      pass "${key}: no trailing periods in tool descriptions"
    fi
  fi
done

# ── Section 43: MCP Unknown Tool Error Code (-32803) ─────────────────────────

section "MCP Unknown Tool Error Code (-32803)"

for key in "${SISTER_KEYS[@]}"; do
  repo=$(jq -r ".sisters[] | select(.key==\"$key\") | .repo" "$REGISTRY_FILE")
  sister_dir="${WORKSPACE}/${repo}"

  if [ ! -d "$sister_dir" ]; then
    continue
  fi

  # Check for wrong error codes used for unknown/not-found tools
  # -32602 (INVALID_PARAMS) should NOT be used for unknown tools
  # -32601 (METHOD_NOT_FOUND) should NOT be used for unknown tools
  # Correct: -32803 (TOOL_NOT_FOUND)
  wrong_code=false

  # Search all Rust source files for unknown tool error patterns
  if grep -rn "unknown tool.*-32602\|unknown tool.*32602\|-32602.*unknown tool" "$sister_dir/src" "$sister_dir/crates" 2>/dev/null | grep -qi "tool"; then
    wrong_code=true
  fi
  if grep -rn 'method_not_found.*"Unknown tool\|method_not_found.*"Tool not found' "$sister_dir/src" "$sister_dir/crates" 2>/dev/null | grep -qi "tool"; then
    wrong_code=true
  fi

  if [ "$wrong_code" = true ]; then
    fail "${key}: uses wrong error code for unknown tools (should be -32803 TOOL_NOT_FOUND)"
  else
    pass "${key}: correct error code for unknown tools"
  fi
done

# ── Section 44: Invention Edge Case Test Parity ─────────────────────────────

section "Invention Edge Case Test Parity (edge_cases_inventions.rs)"

for key in "${SISTER_KEYS[@]}"; do
  repo=$(jq -r ".sisters[] | select(.key==\"$key\") | .repo" "$REGISTRY_FILE")
  test_path=$(jq -r ".sisters[] | select(.key==\"$key\") | .paths.edgeCaseInventionsTest // empty" "$REGISTRY_FILE")
  sister_dir="${WORKSPACE}/${repo}"

  if [ ! -d "$sister_dir" ]; then
    continue
  fi

  if [ -z "$test_path" ]; then
    fail "${key}: missing paths.edgeCaseInventionsTest in sisters-registry.json"
    continue
  fi

  full_path="${sister_dir}/${test_path}"
  if [ -f "$full_path" ]; then
    # Verify file has at least one test function
    test_count=$(grep -c '#\[tokio::test\]\|#\[test\]' "$full_path" 2>/dev/null || echo 0)
    if [ "$test_count" -gt 0 ]; then
      pass "${key}: edge_cases_inventions.rs present with ${test_count} tests"
    else
      fail "${key}: edge_cases_inventions.rs exists but contains 0 test functions"
    fi
  else
    fail "${key}: missing ${test_path}"
  fi
done

# ── Section 45: MCP Two-Tier Error Handling (is_protocol_error) ──────────────

section "MCP Two-Tier Error Handling (is_protocol_error)"

for key in "${SISTER_KEYS[@]}"; do
  repo=$(jq -r ".sisters[] | select(.key==\"$key\") | .repo" "$REGISTRY_FILE")
  sister_dir="${WORKSPACE}/${repo}"

  if [ ! -d "$sister_dir" ]; then
    continue
  fi

  # Check if the sister has an MCP crate with error handling
  has_mcp=false
  for candidate in \
    "${sister_dir}/crates/agentic-${key}-mcp/src/types/error.rs" \
    "${sister_dir}/crates/agentic-${key}-mcp/src/main.rs" \
    "${sister_dir}/src/mcp/protocol.rs"; do
    if [ -f "$candidate" ]; then
      has_mcp=true
      break
    fi
  done

  if [ "$has_mcp" = false ]; then
    continue
  fi

  # Check for is_protocol_error method or equivalent two-tier pattern
  has_two_tier=false

  # Pattern 1: Explicit is_protocol_error() method (memory, vision)
  if grep -rq "is_protocol_error" "$sister_dir/crates" "$sister_dir/src" 2>/dev/null; then
    has_two_tier=true
  fi

  # Pattern 2: isError / ToolCallResult::error pattern in handler
  if grep -rq "ToolCallResult::error\|is_error.*Some(true)\|isError.*true" "$sister_dir/crates" "$sister_dir/src" 2>/dev/null; then
    has_two_tier=true
  fi

  if [ "$has_two_tier" = true ]; then
    pass "${key}: has two-tier error handling (isError:true for tool errors)"
  else
    fail "${key}: missing two-tier error handling — tool errors must use isError:true, not JSON-RPC errors (see goals/MCP-QUALITY-STANDARD.md)"
  fi
done

# ── Section 46: agentic-sdk cargo test ──────────────────────────────────

section "agentic-sdk cargo test"

CONTRACTS_DIR="${WORKSPACE}/agentic-sdk"
if [ -d "$CONTRACTS_DIR" ] && [ -f "${CONTRACTS_DIR}/Cargo.toml" ]; then
  # Run cargo test in the contracts crate and capture output
  test_output=$(cd "$CONTRACTS_DIR" && cargo test 2>&1)
  if echo "$test_output" | grep -q "test result: ok"; then
    # Sum all "N passed" lines (unit tests + integration tests + doc tests)
    test_count=$(echo "$test_output" | grep -o '[0-9]* passed' | grep -o '[0-9]*' | awk '{s+=$1} END {print s}')
    test_count=${test_count:-0}
    pass "agentic-sdk: cargo test passes (${test_count} tests)"
  else
    fail "agentic-sdk: cargo test FAILED — contracts are broken"
  fi

  # Verify version is >= 0.2.0
  contracts_version=$(grep '^version' "${CONTRACTS_DIR}/Cargo.toml" | head -1 | grep -o '"[^"]*"' | tr -d '"')
  case "$contracts_version" in
    0.1.*)
      fail "agentic-sdk version ${contracts_version} is pre-validation — must be >= 0.2.0"
      ;;
    *)
      pass "agentic-sdk version ${contracts_version}"
      ;;
  esac
else
  pass "Skipping agentic-sdk cargo test (local-only, gitignored)"
fi

# ── Section 47: Standard Reference Doc Pages ─────────────────────────────────
#
# Every sister MUST have 8 standard reference doc pages in docs/public/.
# These pages provide consistent documentation coverage across the ecosystem.
# See CANONICAL_SISTER_KIT.md Section 10 for details.

section "Standard Reference Doc Pages (docs/public/)"

STANDARD_DOC_PAGES=(
  "architecture.md"
  "cli-reference.md"
  "configuration.md"
  "ffi-reference.md"
  "mcp-tools.md"
  "mcp-resources.md"
  "mcp-prompts.md"
  "troubleshooting.md"
)

for sister in "${SISTERS[@]}"; do
  docs_dir="${WORKSPACE}/${sister}/docs/public"
  if [ ! -d "$docs_dir" ]; then
    fail "${sister}: docs/public/ directory missing"
    continue
  fi
  missing=0
  missing_pages=()
  for page in "${STANDARD_DOC_PAGES[@]}"; do
    if [ ! -f "${docs_dir}/${page}" ]; then
      missing_pages+=("$page")
      missing=1
    fi
  done
  if [ "$missing" -eq 1 ]; then
    fail "${sister}: missing standard doc pages: ${missing_pages[*]}"
  else
    pass "${sister}: all 8 standard reference doc pages present"
  fi
done

# ── Section 48: agentic-sdk Trait Implementations ───────────────────────
#
# Every sister MUST implement agentic-sdk v0.2.0 traits.
# Checks: contracts.rs exists, module declared in lib.rs, dep in Cargo.toml.

section "agentic-sdk Trait Implementations"

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  core_crate="${CORE_CRATES[$i]}"
  sister_dir="${WORKSPACE}/${sister}"

  if [ ! -d "$sister_dir" ]; then
    pass "Skipping ${sister} (not cloned locally)"
    continue
  fi

  # Resolve the core crate source directory
  # Codebase uses flat structure (src/), others use crates/<core>/src/
  if [ -d "${sister_dir}/crates/${core_crate}/src" ]; then
    src_dir="${sister_dir}/crates/${core_crate}/src"
    cargo_toml="${sister_dir}/crates/${core_crate}/Cargo.toml"
  elif [ -d "${sister_dir}/src" ]; then
    src_dir="${sister_dir}/src"
    cargo_toml="${sister_dir}/Cargo.toml"
  else
    fail "${sister}: cannot locate core crate source directory"
    continue
  fi

  # 1. contracts.rs exists
  if [ -f "${src_dir}/contracts.rs" ]; then
    pass "${sister}: contracts.rs exists"
  else
    fail "${sister}: contracts.rs missing in ${src_dir}"
  fi

  # 2. contracts module declared in lib.rs
  if [ -f "${src_dir}/lib.rs" ]; then
    if grep -qE '(pub\s+)?mod\s+contracts' "${src_dir}/lib.rs"; then
      pass "${sister}: contracts module declared in lib.rs"
    else
      fail "${sister}: contracts module NOT declared in lib.rs"
    fi
  else
    fail "${sister}: lib.rs not found in ${src_dir}"
  fi

  # 3. agentic-sdk dependency in Cargo.toml
  if [ -f "$cargo_toml" ]; then
    if grep -q 'agentic.sdk' "$cargo_toml"; then
      pass "${sister}: agentic-sdk dependency present"
    else
      fail "${sister}: agentic-sdk dependency MISSING in ${cargo_toml}"
    fi
  else
    fail "${sister}: Cargo.toml not found at ${cargo_toml}"
  fi
done

# ── Section 49: Content Depth Validation ─────────────────────────────────────
#
# Validates that documentation files have real content, not stubs.
# Minimum thresholds are set at 40% of agentic-memory's line counts.
# This prevents sisters from passing guardrails with placeholder files.

section "Content Depth Validation (docs, paper, scripts)"

# Doc depth thresholds: "filename:minimum_lines" pairs
# Derived from agentic-memory at 40% floor — below this is a stub
DOC_DEPTH_RULES="
architecture.md:50
concepts.md:100
benchmarks.md:100
api-reference.md:100
file-format.md:90
installation.md:45
integration-guide.md:70
mcp-tools.md:65
mcp-resources.md:35
mcp-prompts.md:50
quickstart.md:40
cli-reference.md:100
troubleshooting.md:80
faq.md:55
configuration.md:50
command-surface.md:75
experience-with-vs-without.md:30
primary-problem-coverage.md:25
initial-problem-coverage.md:25
playbooks-agent-integration.md:60
runtime-install-sync.md:50
"

# Paper depth: each paper-i-* .tex must be at least 300 lines (real paper, not outline)
PAPER_MIN_LINES=300

# README depth: minimum 400 lines
README_MIN_LINES=400

for sister in "${SISTERS[@]}"; do
  sister_dir="${WORKSPACE}/${sister}"
  if [ ! -d "$sister_dir" ]; then
    continue
  fi

  # Check doc depth
  doc_failures=0
  while IFS=: read -r doc_name min_lines; do
    [ -z "$doc_name" ] && continue
    doc_file="${sister_dir}/docs/public/${doc_name}"
    if [ -f "$doc_file" ]; then
      actual_lines="$(wc -l < "$doc_file")"
      if [ "$actual_lines" -lt "$min_lines" ]; then
        fail "${sister}: docs/public/${doc_name} has ${actual_lines} lines (minimum: ${min_lines}). Content is too thin — expand to canonical depth."
        doc_failures=$((doc_failures + 1))
      fi
    fi
  done <<< "$DOC_DEPTH_RULES"
  if [ "$doc_failures" -eq 0 ]; then
    pass "${sister}: all docs meet minimum content depth thresholds"
  fi

  # Check paper depth
  paper_dir="${sister_dir}/paper"
  if [ -d "$paper_dir" ]; then
    paper_failures=0
    for paper_subdir in "${paper_dir}"/paper-i-*; do
      if [ ! -d "$paper_subdir" ]; then
        continue
      fi
      paper_name="$(basename "$paper_subdir")"
      tex_file="$(find "$paper_subdir" -name "*.tex" -maxdepth 1 2>/dev/null | head -1)"
      if [ -n "$tex_file" ] && [ -f "$tex_file" ]; then
        actual_lines="$(wc -l < "$tex_file")"
        if [ "$actual_lines" -lt "$PAPER_MIN_LINES" ]; then
          fail "${sister}: ${paper_name}/$(basename "$tex_file") has ${actual_lines} lines (minimum: ${PAPER_MIN_LINES}). Paper must be based on real benchmarks and test data, not an outline."
          paper_failures=$((paper_failures + 1))
        fi
      fi
    done
    if [ "$paper_failures" -eq 0 ]; then
      pass "${sister}: research papers meet minimum depth threshold (${PAPER_MIN_LINES}+ lines)"
    fi
  fi

  # Check README depth
  readme_file="${sister_dir}/README.md"
  if [ -f "$readme_file" ]; then
    actual_lines="$(wc -l < "$readme_file")"
    if [ "$actual_lines" -lt "$README_MIN_LINES" ]; then
      fail "${sister}: README.md has ${actual_lines} lines (minimum: ${README_MIN_LINES}). README must have canonical depth."
    else
      pass "${sister}: README.md meets minimum depth threshold (${actual_lines} lines)"
    fi
  fi
done

# ── 50. Paper Compilation Verification (PDF must exist alongside .tex) ────

section "Paper Compilation Verification (PDF must exist alongside .tex)"

for sister in "${SISTERS[@]}"; do
  sister_dir="${WORKSPACE}/${sister}"
  [ -d "$sister_dir" ] || continue

  paper_dirs="$(find "$sister_dir/paper" -maxdepth 1 -type d -name 'paper-*' 2>/dev/null || true)"
  if [ -z "$paper_dirs" ]; then
    continue
  fi

  while IFS= read -r pdir; do
    [ -z "$pdir" ] && continue
    tex_files="$(find "$pdir" -maxdepth 1 -name '*.tex' 2>/dev/null || true)"
    if [ -z "$tex_files" ]; then
      continue
    fi

    pdf_files="$(find "$pdir" -maxdepth 1 -name '*.pdf' 2>/dev/null || true)"
    if [ -z "$pdf_files" ]; then
      fail "${sister}: $(basename "$pdir") has .tex source but no compiled .pdf — run pdflatex"
    else
      # Check .aux exists (produced by every pdflatex run)
      aux_files="$(find "$pdir" -maxdepth 1 -name '*.aux' 2>/dev/null || true)"
      if [ -z "$aux_files" ]; then
        fail "${sister}: $(basename "$pdir") has .pdf but missing .aux — recompile with pdflatex"
      else
        # Only require .bbl if a .bib file exists (external bibliography)
        bib_files="$(find "$pdir" -maxdepth 1 -name '*.bib' 2>/dev/null || true)"
        if [ -n "$bib_files" ]; then
          bbl_files="$(find "$pdir" -maxdepth 1 -name '*.bbl' 2>/dev/null || true)"
          if [ -z "$bbl_files" ]; then
            fail "${sister}: $(basename "$pdir") has .bib but no .bbl — run bibtex"
          else
            pass "${sister}: $(basename "$pdir") paper fully compiled (PDF + bib artifacts present)"
          fi
        else
          pass "${sister}: $(basename "$pdir") paper compiled (PDF + aux present, no external bibliography)"
        fi
      fi
    fi
  done <<< "$paper_dirs"
done

# ── 51. Operational Depth Parity (Tier A/B/C) ──────────────────────────────

section "Operational Depth Parity (Tier A/B/C)"

if "${WORKSPACE}/scripts/check-operational-depth-parity.sh"; then
  pass "Operational depth parity guardrail passed"
else
  fail "Operational depth parity guardrail failed (see output above)"
fi

# ── 52. MCP Consolidation Guardrail ─────────────────────────────────────────

section "MCP Consolidation Guardrail"

if "${WORKSPACE}/scripts/check-mcp-consolidation.sh"; then
  pass "MCP consolidation guardrail passed"
else
  fail "MCP consolidation guardrail failed (see output above)"
fi

# ── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: ${ERRORS} consistency error(s) found"
  exit 1
else
  echo "Cross-sister consistency checks passed."
fi
