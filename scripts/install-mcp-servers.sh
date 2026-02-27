#!/usr/bin/env bash
# install-mcp-servers.sh — Build and install all agentic sister MCP servers
# and configure ~/.claude/mcp.json to use the stable cargo-installed paths.
#
# Usage: bash scripts/install-mcp-servers.sh
#
# Sister definitions are read from docs/sisters-registry.json (single source
# of truth). To add a new sister, edit the registry — not this file.
#
# This script is idempotent — safe to re-run after code changes.

set -euo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CARGO_BIN="${CARGO_HOME:-$HOME/.cargo}/bin"
CLAUDE_MCP_CONFIG="$HOME/.claude/mcp.json"
REGISTRY="${WORKSPACE_ROOT}/docs/sisters-registry.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[info]${NC}  $*"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $*"; }
fail()  { echo -e "${RED}[fail]${NC}  $*"; exit 1; }

if [ ! -f "$REGISTRY" ]; then
  fail "sisters-registry.json not found at $REGISTRY"
fi

if ! command -v jq >/dev/null 2>&1; then
  fail "jq is required but not installed"
fi

SISTER_COUNT=$(jq '.sisters | length' "$REGISTRY")

# ── Step 1: Build and install all MCP binaries ─────────────────────
info "Building and installing MCP server binaries..."
FAILED=0

for i in $(seq 0 $((SISTER_COUNT - 1))); do
  sister=$(jq -r ".sisters[$i].repo" "$REGISTRY")
  bin_name=$(jq -r ".sisters[$i].mcp.binary" "$REGISTRY")
  crate_rel=$(jq -r ".sisters[$i].mcp.cratePath" "$REGISTRY")
  crate_path="${WORKSPACE_ROOT}/${sister}/${crate_rel}"

  if [ ! -d "$crate_path" ]; then
    warn "Skipping $sister — crate path not found: $crate_path"
    FAILED=$((FAILED + 1))
    continue
  fi

  info "Installing $bin_name from $crate_path ..."
  if cargo install --path "$crate_path" --force --quiet 2>/dev/null; then
    installed_path="$CARGO_BIN/$bin_name"
    if [ -x "$installed_path" ]; then
      version=$("$installed_path" --version 2>/dev/null || echo "unknown")
      ok "$bin_name $version → $installed_path"
    else
      warn "$bin_name built but not found at $installed_path"
      FAILED=$((FAILED + 1))
    fi
  else
    warn "$bin_name build failed"
    FAILED=$((FAILED + 1))
  fi
done

if [ "$FAILED" -gt 0 ]; then
  warn "$FAILED sister(s) failed to install"
fi

# ── Step 2: Generate ~/.claude/mcp.json ────────────────────────────
info "Updating $CLAUDE_MCP_CONFIG ..."

mkdir -p "$(dirname "$CLAUDE_MCP_CONFIG")"

# Build MCP config dynamically from registry
jq -n --arg cargo_bin "$CARGO_BIN" --slurpfile reg "$REGISTRY" '
  {
    mcpServers: (
      $reg[0].sisters | map({
        key: .repo,
        value: {
          command: ($cargo_bin + "/" + .mcp.binary),
          args: .mcp.args
        }
      }) | from_entries
    )
  }
' > "$CLAUDE_MCP_CONFIG"

ok "MCP config written to $CLAUDE_MCP_CONFIG"

# ── Step 3: Verify all binaries are reachable ──────────────────────
info "Verifying installed binaries..."
ALL_OK=true

for i in $(seq 0 $((SISTER_COUNT - 1))); do
  bin_name=$(jq -r ".sisters[$i].mcp.binary" "$REGISTRY")
  bin_path="$CARGO_BIN/$bin_name"
  if [ -x "$bin_path" ]; then
    ok "$bin_name ✓"
  else
    warn "$bin_name not found at $bin_path"
    ALL_OK=false
  fi
done

if $ALL_OK; then
  echo ""
  ok "All $SISTER_COUNT sister MCP servers installed and configured."
  info "Restart Claude Code to pick up the new binaries."
else
  echo ""
  warn "Some servers missing — check build output above."
fi
