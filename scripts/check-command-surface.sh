#!/usr/bin/env bash
# check-command-surface.sh — Verify MCP command surface docs are canonical
#
# Canonical behavior:
# - If docs/mcp-consolidation-contract.json has a sister entry, enforce that
#   all contract compactTools are documented in docs/public/command-surface.md
# - Otherwise, fall back to legacy extraction from Rust dispatch and enforce
#   full tool-name documentation coverage
#
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
CONTRACT_FILE="${WORKSPACE}/docs/mcp-consolidation-contract.json"

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

contract_has_sister() {
  local sister="$1"
  [ -f "$CONTRACT_FILE" ] || return 1
  jq -e --arg repo "$sister" '.sisters[] | select(.repo == $repo)' "$CONTRACT_FILE" >/dev/null 2>&1
}

read_contract_tools() {
  local sister="$1"
  [ -f "$CONTRACT_FILE" ] || return 0
  jq -r --arg repo "$sister" '.sisters[] | select(.repo == $repo) | .compactTools[]?' "$CONTRACT_FILE"
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

  if contract_has_sister "$sister"; then
    # In consolidated mode, docs are canonicalized to compact facade tools.
    compact_tools="$(read_contract_tools "$sister")"
    compact_count="$(echo "$compact_tools" | sed '/^$/d' | wc -l | tr -d ' ')"
    if [ -z "$compact_tools" ] || [ "$compact_count" -eq 0 ]; then
      fail "${sister}: contract entry exists but compactTools is empty"
      continue
    fi

    missing=0
    missing_names=""
    while IFS= read -r tool; do
      [ -z "$tool" ] && continue
      if ! grep -qF "$tool" "$doc"; then
        fail "${sister}: compact MCP tool '${tool}' missing from command-surface.md"
        missing=$((missing + 1))
        missing_names="${missing_names} ${tool}"
      fi
    done <<< "$compact_tools"

    if [ "$missing" -eq 0 ]; then
      pass "${sister}: all ${compact_count} compact MCP tools documented in command-surface.md"
    else
      echo "  HINT: Add the following compact tools to ${sister}/docs/public/command-surface.md:"
      echo "       ${missing_names}"
    fi
  else
    # Legacy fallback: enforce full extracted tool documentation.
    tools="$(extract_tools_strict "$src")"
    tool_count="$(echo "$tools" | wc -l | tr -d ' ')"

    if [ -z "$tools" ] || [ "$tool_count" -eq 0 ]; then
      fail "${sister}: no MCP tools extracted from source (extraction bug?)"
      continue
    fi

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
