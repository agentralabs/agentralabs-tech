#!/usr/bin/env bash
# check-command-surface.sh — Verify every MCP tool in Rust source is documented
#
# Generic guardrail: extracts MCP tool names from each sister's Rust dispatch
# code and verifies they appear in docs/public/command-surface.md. Fails if
# any published tool is undocumented.
#
# This ensures that when a developer adds a new MCP tool to a sister, the
# command-surface doc must be updated before the check passes.
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

# ── Tool extraction ────────────────────────────────────────────────────────
#
# Extracts MCP tool names from Rust dispatch code. Four patterns are matched:
#   A. Match arms:     "tool_name" => ...::execute
#   B. Monolithic:     "tool_name" => self.tool_*(...)
#   C. If-guarded:     tool_name == "tool_name"
#   D. Block-match:    "tool_name" => {  (standalone match arms)
#
# This filters out MCP protocol names and enum variant matches automatically.

extract_tools_strict() {
  local src="$1"

  {
    # Pattern A: Modular registry dispatch — "tool" => module::execute(...)
    grep -E '"[a-z_]+" =>.*::execute' "$src" 2>/dev/null \
      | grep -oE '"[a-z_]+"' \
      | tr -d '"' \
      || true

    # Pattern B: Monolithic server dispatch — "tool" => self.tool_*(...)
    #   Also handles: "tool" => return self.tool_*(...)
    grep -E '"[a-z_]+" =>.*self\.tool_' "$src" 2>/dev/null \
      | grep -oE '"[a-z_]+"' \
      | tr -d '"' \
      || true

    # Pattern C: If-guarded tools — if tool_name == "action_context" { return self.tool_...
    grep -E 'tool_name == "[a-z_]+"' "$src" 2>/dev/null \
      | grep -oE '"[a-z_]+"' \
      | tr -d '"' \
      || true

    # Pattern D: Block-match dispatch — "tool_name" => { (e.g., agentic-time tools.rs)
    #   Restricted to ≤10 leading spaces to avoid inner match arms (e.g.,
    #   decay_type match at 16+ spaces inside a tool handler).
    grep -E '^[[:space:]]{1,10}"[a-z_]+" => \{' "$src" 2>/dev/null \
      | grep -oE '"[a-z_]+"' \
      | tr -d '"' \
      || true
  } | sort -u
}

# ── Sister configuration ──────────────────────────────────────────────────
#
# SISTERS and MCP_TOOL_SOURCES are loaded from docs/sisters-registry.json
# via load-sisters.sh. To add a new sister, edit the registry — not this file.

TOOL_SRCS=()
DOC_PATHS=()
for i in "${!SISTERS[@]}"; do
  TOOL_SRCS+=("${WORKSPACE}/${SISTERS[$i]}/${MCP_TOOL_SOURCES[$i]}")
  DOC_PATHS+=("${WORKSPACE}/${SISTERS[$i]}/docs/public/command-surface.md")
done

# ── Main check loop ───────────────────────────────────────────────────────

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  src="${TOOL_SRCS[$i]}"
  doc="${DOC_PATHS[$i]}"

  section "Command surface: ${sister}"

  if [ ! -f "$src" ]; then
    fail "${sister}: tool source not found: ${src}"
    continue
  fi
  if [ ! -f "$doc" ]; then
    fail "${sister}: command-surface.md not found: ${doc}"
    continue
  fi

  # Extract tool names from Rust dispatch code
  tools="$(extract_tools_strict "$src")"
  tool_count="$(echo "$tools" | wc -l | tr -d ' ')"

  if [ -z "$tools" ] || [ "$tool_count" -eq 0 ]; then
    fail "${sister}: no MCP tools extracted from source (extraction bug?)"
    continue
  fi

  # Check each tool is documented
  missing=0
  missing_names=""
  while IFS= read -r tool; do
    if ! grep -qF "$tool" "$doc"; then
      fail "${sister}: MCP tool '${tool}' missing from command-surface.md"
      missing=$((missing + 1))
      missing_names="${missing_names} ${tool}"
    fi
  done <<< "$tools"

  if [ "$missing" -eq 0 ]; then
    pass "${sister}: all ${tool_count} MCP tools documented in command-surface.md"
  else
    echo "  HINT: Add the following tools to ${sister}/docs/public/command-surface.md:"
    echo "       ${missing_names}"
  fi
done

# ── Summary ────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: ${ERRORS} command-surface error(s) found"
  echo ""
  echo "To fix: update each sister's docs/public/command-surface.md to include"
  echo "all MCP tools registered in the Rust source dispatch code."
  exit 1
else
  echo "Command-surface checks passed. All MCP tools are documented."
fi
