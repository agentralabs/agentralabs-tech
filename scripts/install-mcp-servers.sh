#!/usr/bin/env bash
# install-mcp-servers.sh — Build and install all agentic sister MCP servers
# and configure ~/.claude/mcp.json to use the stable cargo-installed paths.
#
# Usage: bash scripts/install-mcp-servers.sh
#        bash scripts/install-mcp-servers.sh --no-capture   # skip auto-capture hooks
#
# Sister definitions are read from docs/sisters-registry.json (single source
# of truth). To add a new sister, edit the registry — not this file.
#
# By default, this installer enables auto-capture: every conversation with
# Claude Code is recorded into ~/.brain.amem via hooks. To disable auto-capture
# after installation, remove the hooks section from ~/.claude/settings.json.
#
# This script is idempotent — safe to re-run after code changes.

set -euo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CARGO_BIN="${CARGO_HOME:-$HOME/.cargo}/bin"
CLAUDE_MCP_CONFIG="$HOME/.claude/mcp.json"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CLAUDE_HOOKS_DIR="$HOME/.claude/hooks"
REGISTRY="${WORKSPACE_ROOT}/docs/sisters-registry.json"
HOOK_SOURCE="${WORKSPACE_ROOT}/scripts/hooks/capture-to-memory.sh"

# Parse flags
ENABLE_CAPTURE=true
for arg in "$@"; do
  case "$arg" in
    --no-capture) ENABLE_CAPTURE=false ;;
  esac
done

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

# Build MCP config dynamically from registry.
# agentic-memory gets extra env vars for auto-capture + storage budget.
# All other sisters get command + args only.
jq -n --arg cargo_bin "$CARGO_BIN" --slurpfile reg "$REGISTRY" '
  {
    mcpServers: (
      $reg[0].sisters | map(
        if .key == "memory" then
          {
            key: .repo,
            value: {
              command: ($cargo_bin + "/" + .mcp.binary),
              args: (.mcp.args + ["--mode", "full"]),
              env: {
                "AMEM_AUTO_CAPTURE_MODE": "full",
                "AMEM_AUTO_CAPTURE_REDACT": "true",
                "AMEM_AUTO_CAPTURE_MAX_CHARS": "768",
                "AMEM_STORAGE_BUDGET_MODE": "auto-rollup",
                "AMEM_STORAGE_BUDGET_BYTES": "536870912",
                "AMEM_STORAGE_BUDGET_HORIZON_YEARS": "5",
                "AMEM_STORAGE_BUDGET_TARGET_FRACTION": "0.85"
              }
            }
          }
        else
          {
            key: .repo,
            value: {
              command: ($cargo_bin + "/" + .mcp.binary),
              args: .mcp.args
            }
          }
        end
      ) | from_entries
    )
  }
' > "$CLAUDE_MCP_CONFIG"

ok "MCP config written to $CLAUDE_MCP_CONFIG"

# ── Step 3: Install auto-capture hooks ─────────────────────────────
if $ENABLE_CAPTURE; then
  info "Installing auto-capture hooks (default ON) ..."

  # 3a: Install the hook script
  mkdir -p "$CLAUDE_HOOKS_DIR"
  if [ -f "$HOOK_SOURCE" ]; then
    cp "$HOOK_SOURCE" "$CLAUDE_HOOKS_DIR/capture-to-memory.sh"
    chmod +x "$CLAUDE_HOOKS_DIR/capture-to-memory.sh"
    ok "Hook script installed → $CLAUDE_HOOKS_DIR/capture-to-memory.sh"
  else
    warn "Hook source not found at $HOOK_SOURCE — skipping hook install"
  fi

  # 3b: Initialize brain file if it doesn't exist
  BRAIN_FILE="${AMEM_BRAIN:-$HOME/.brain.amem}"
  if [ ! -f "$BRAIN_FILE" ]; then
    AMEM_BIN="$CARGO_BIN/amem"
    if [ -x "$AMEM_BIN" ]; then
      "$AMEM_BIN" add "$BRAIN_FILE" fact "Brain file initialized by install-mcp-servers.sh" --confidence 0.50 2>/dev/null || true
      ok "Brain file initialized → $BRAIN_FILE"
    else
      warn "amem CLI not found — brain file not initialized (hooks will create it on first capture)"
    fi
  else
    ok "Brain file already exists → $BRAIN_FILE"
  fi

  # 3c: Generate or merge ~/.claude/settings.json with hooks config
  # Use absolute path (resolved at install time) so hooks work from any directory
  HOOK_CMD="$CLAUDE_HOOKS_DIR/capture-to-memory.sh"

  HOOKS_CONFIG=$(jq -n --arg cmd "$HOOK_CMD" '{
    hooks: {
      UserPromptSubmit: [
        { matcher: "", hooks: [{ type: "command", command: $cmd, timeout: 5 }] }
      ],
      PostToolUse: [
        { matcher: "", hooks: [{ type: "command", command: $cmd, timeout: 5 }] }
      ],
      Stop: [
        { matcher: "", hooks: [{ type: "command", command: $cmd, timeout: 5 }] }
      ]
    }
  }')

  if [ -f "$CLAUDE_SETTINGS" ]; then
    # Merge: preserve existing settings, add/overwrite hooks
    EXISTING=$(cat "$CLAUDE_SETTINGS")
    echo "$EXISTING" | jq --argjson hooks "$(echo "$HOOKS_CONFIG" | jq '.hooks')" \
      '. + {hooks: $hooks}' > "$CLAUDE_SETTINGS"
    ok "Hooks merged into existing $CLAUDE_SETTINGS"
  else
    echo "$HOOKS_CONFIG" > "$CLAUDE_SETTINGS"
    ok "Settings written to $CLAUDE_SETTINGS"
  fi
else
  info "Auto-capture hooks skipped (--no-capture flag)"
fi

# ── Step 4: Verify all binaries are reachable ──────────────────────
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
  if $ENABLE_CAPTURE; then
    info "Auto-capture is ON — conversations will be saved to ~/.brain.amem"
    info "To disable: edit ~/.claude/settings.json or re-run with --no-capture"
  fi
  info "Restart Claude Code to pick up the new binaries."
else
  echo ""
  warn "Some servers missing — check build output above."
fi
