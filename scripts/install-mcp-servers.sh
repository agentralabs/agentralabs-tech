#!/usr/bin/env bash
# install-mcp-servers.sh — Build and install all 5 agentic sister MCP servers
# and configure ~/.claude/mcp.json to use the stable cargo-installed paths.
#
# Usage: bash scripts/install-mcp-servers.sh
#
# This script is idempotent — safe to re-run after code changes.

set -euo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CARGO_BIN="${CARGO_HOME:-$HOME/.cargo}/bin"
CLAUDE_MCP_CONFIG="$HOME/.claude/mcp.json"

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

# ── Sister definitions ─────────────────────────────────────────────
declare -a SISTERS=(
  "agentic-memory"
  "agentic-vision"
  "agentic-codebase"
  "agentic-identity"
  "agentic-time"
)

declare -A MCP_CRATE_PATH=(
  [agentic-memory]="agentic-memory/crates/agentic-memory-mcp"
  [agentic-vision]="agentic-vision/crates/agentic-vision-mcp"
  [agentic-codebase]="agentic-codebase/crates/agentic-codebase-mcp"
  [agentic-identity]="agentic-identity/crates/agentic-identity-mcp"
  [agentic-time]="agentic-time/crates/agentic-time-mcp"
)

declare -A MCP_BIN_NAME=(
  [agentic-memory]="agentic-memory-mcp"
  [agentic-vision]="agentic-vision-mcp"
  [agentic-codebase]="agentic-codebase-mcp"
  [agentic-identity]="agentic-identity-mcp"
  [agentic-time]="agentic-time-mcp"
)

declare -A MCP_ARGS=(
  [agentic-memory]='["serve"]'
  [agentic-vision]='["--log-level", "error", "serve"]'
  [agentic-codebase]='[]'
  [agentic-identity]='[]'
  [agentic-time]='[]'
)

# ── Step 1: Build and install all MCP binaries ─────────────────────
info "Building and installing MCP server binaries..."
FAILED=0

for sister in "${SISTERS[@]}"; do
  crate_path="${WORKSPACE_ROOT}/${MCP_CRATE_PATH[$sister]}"
  bin_name="${MCP_BIN_NAME[$sister]}"

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

# Build JSON manually to avoid jq dependency
cat > "$CLAUDE_MCP_CONFIG" << MCPJSON
{
  "mcpServers": {
    "agentic-memory": {
      "command": "$CARGO_BIN/agentic-memory-mcp",
      "args": ["serve"]
    },
    "agentic-vision": {
      "command": "$CARGO_BIN/agentic-vision-mcp",
      "args": ["--log-level", "error", "serve"]
    },
    "agentic-codebase": {
      "command": "$CARGO_BIN/agentic-codebase-mcp",
      "args": []
    },
    "agentic-identity": {
      "command": "$CARGO_BIN/agentic-identity-mcp",
      "args": [],
      "env": {}
    },
    "agentic-time": {
      "command": "$CARGO_BIN/agentic-time-mcp",
      "args": []
    }
  }
}
MCPJSON

ok "MCP config written to $CLAUDE_MCP_CONFIG"

# ── Step 3: Verify all binaries are reachable ──────────────────────
info "Verifying installed binaries..."
ALL_OK=true

for sister in "${SISTERS[@]}"; do
  bin_name="${MCP_BIN_NAME[$sister]}"
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
  ok "All 5 sister MCP servers installed and configured."
  info "Restart Claude Code to pick up the new binaries."
else
  echo ""
  warn "Some servers missing — check build output above."
fi
