#!/usr/bin/env bash
#
# Release gate automation for Agentra sisters.
#
# Runs pre-publish checks and optionally publishes crates to crates.io.
#
# Usage:
#   bash scripts/release.sh check              # Dry-run: run all gates
#   bash scripts/release.sh check memory        # Check a single sister
#   bash scripts/release.sh publish memory       # Publish memory crates
#   bash scripts/release.sh publish-all          # Publish all sisters (order-aware)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY="$REPO_ROOT/docs/sisters-registry.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}PASS${NC} $1"; }
fail() { echo -e "  ${RED}FAIL${NC} $1"; FAILURES=$((FAILURES + 1)); }
warn() { echo -e "  ${YELLOW}WARN${NC} $1"; }

FAILURES=0

# ── Helpers ──────────────────────────────────────────────────────────

get_sisters() {
    python3 -c "
import json
reg = json.load(open('$REGISTRY'))
for s in sorted(reg['sisters'], key=lambda x: x.get('order', 99)):
    if s.get('enabled', False):
        print(s['key'])
" 2>/dev/null || jq -r '.sisters | sort_by(.order) | .[] | select(.enabled == true) | .key' "$REGISTRY"
}

get_repo() {
    local key="$1"
    python3 -c "
import json
reg = json.load(open('$REGISTRY'))
for s in reg['sisters']:
    if s['key'] == '$key':
        print(s['repo'])
        break
" 2>/dev/null || jq -r ".sisters[] | select(.key == \"$key\") | .repo" "$REGISTRY"
}

# ── Gate checks ──────────────────────────────────────────────────────

check_sister() {
    local key="$1"
    local repo
    repo="$(get_repo "$key")"
    local sister_dir="$REPO_ROOT/$repo"

    echo ""
    echo "══════════════════════════════════════════════════"
    echo " Release gates: $key ($repo)"
    echo "══════════════════════════════════════════════════"

    # Gate 1: Directory exists
    if [[ -d "$sister_dir" ]]; then
        pass "directory exists"
    else
        fail "directory $sister_dir not found"
        return
    fi

    # Gate 2: CHANGELOG.md exists
    if [[ -f "$sister_dir/CHANGELOG.md" ]]; then
        pass "CHANGELOG.md present"
    else
        fail "CHANGELOG.md missing"
    fi

    # Gate 3: Cargo.toml exists and has version
    local cargo_toml="$sister_dir/Cargo.toml"
    if [[ -f "$cargo_toml" ]]; then
        local version
        version=$(grep -m1 '^version' "$cargo_toml" | sed 's/.*= *"\(.*\)"/\1/' || echo "")
        if [[ -n "$version" ]]; then
            pass "version: $version"
        else
            fail "no version in Cargo.toml"
        fi
    else
        fail "Cargo.toml missing"
    fi

    # Gate 4: cargo check passes
    if (cd "$sister_dir" && cargo check --quiet 2>/dev/null); then
        pass "cargo check"
    else
        fail "cargo check failed"
    fi

    # Gate 5: cargo test passes
    if (cd "$sister_dir" && cargo test --quiet 2>/dev/null); then
        pass "cargo test"
    else
        fail "cargo test failed"
    fi

    # Gate 6: MCP binary builds
    local mcp_binary="agentic-${key}-mcp"
    if (cd "$sister_dir" && cargo build --release --bin "$mcp_binary" --quiet 2>/dev/null); then
        pass "MCP binary builds ($mcp_binary)"
    else
        warn "MCP binary build skipped or failed ($mcp_binary)"
    fi

    # Gate 7: No uncommitted changes in sister dir
    if (cd "$sister_dir" && git diff --quiet HEAD -- . 2>/dev/null); then
        pass "clean working tree"
    else
        warn "uncommitted changes in $repo"
    fi
}

publish_sister() {
    local key="$1"
    local repo
    repo="$(get_repo "$key")"
    local sister_dir="$REPO_ROOT/$repo"

    echo ""
    echo "Publishing $key..."

    # Run gates first.
    check_sister "$key"
    if [[ $FAILURES -gt 0 ]]; then
        echo -e "${RED}Aborting publish: $FAILURES gate(s) failed${NC}"
        return 1
    fi

    # Publish core crate first, then MCP crate.
    echo "  Publishing crates (dry-run)..."
    (cd "$sister_dir" && cargo publish --dry-run 2>&1 | tail -5) || true

    echo ""
    echo -e "${YELLOW}To actually publish, run:${NC}"
    echo "  cd $sister_dir && cargo publish"
    echo ""
    echo "  For workspace members, publish in dependency order:"
    echo "    cargo publish -p agentic-${key}"
    echo "    cargo publish -p agentic-${key}-mcp"
}

# ── Main ─────────────────────────────────────────────────────────────

CMD="${1:-check}"
shift || true

case "$CMD" in
    check)
        if [[ $# -gt 0 ]]; then
            for sister in "$@"; do
                check_sister "$sister"
            done
        else
            echo "Running release gates for all enabled sisters..."
            while IFS= read -r sister; do
                check_sister "$sister"
            done < <(get_sisters)
        fi
        ;;
    publish)
        if [[ $# -eq 0 ]]; then
            echo "Usage: release.sh publish <sister>" >&2
            exit 1
        fi
        publish_sister "$1"
        ;;
    publish-all)
        echo "Publishing all sisters in dependency order..."
        while IFS= read -r sister; do
            publish_sister "$sister"
        done < <(get_sisters)
        ;;
    *)
        echo "Usage: release.sh {check|publish|publish-all} [sister...]" >&2
        exit 1
        ;;
esac

echo ""
if [[ $FAILURES -gt 0 ]]; then
    echo -e "${RED}Total failures: $FAILURES${NC}"
    exit 1
else
    echo -e "${GREEN}All gates passed.${NC}"
fi
