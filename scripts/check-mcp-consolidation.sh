#!/usr/bin/env bash
# check-mcp-consolidation.sh — Enforce canonical MCP tool consolidation contract
#
# Verifies each enabled sister adheres to docs/mcp-consolidation-contract.json:
# - Compact facade list is canonical
# - Facade tool names are documented
# - Facade tools exist in Rust MCP source
# - Operation-based routing is present
# - Compact surface env toggle is present (except declared exceptions)
#
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
source "$(dirname "$0")/lib/load-sisters.sh"

CONTRACT_FILE="${WORKSPACE}/docs/mcp-consolidation-contract.json"
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

if ! command -v jq >/dev/null 2>&1; then
  echo "FATAL: jq is required but not installed" >&2
  exit 1
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "FATAL: rg (ripgrep) is required but not installed" >&2
  exit 1
fi

if [ ! -f "$CONTRACT_FILE" ]; then
  echo "FATAL: contract file missing: ${CONTRACT_FILE}" >&2
  exit 1
fi

get_contract_field() {
  local repo="$1"
  local field="$2"
  jq -r --arg repo "$repo" --arg field "$field" '
    (.sisters[] | select(.repo == $repo) | .[$field]) // empty
  ' "$CONTRACT_FILE"
}

section "MCP Consolidation Contract"

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  key="${SISTER_KEYS[$i]}"
  sister_dir="${WORKSPACE}/${sister}"
  command_surface="${sister_dir}/docs/public/command-surface.md"

  section "${sister}"

  if [ ! -d "$sister_dir" ]; then
    fail "${sister}: repository directory not found"
    continue
  fi

  if [ ! -f "$command_surface" ]; then
    fail "${sister}: missing docs/public/command-surface.md"
    continue
  fi

  if ! jq -e --arg repo "$sister" '.sisters[] | select(.repo == $repo)' "$CONTRACT_FILE" >/dev/null; then
    fail "${sister}: missing contract entry in docs/mcp-consolidation-contract.json"
    continue
  fi

  prefix="$(get_contract_field "$sister" "prefix")"
  if [ -z "$prefix" ] || [ "$prefix" = "null" ]; then
    fail "${sister}: missing required contract field 'prefix'"
    continue
  fi

  max_tools="$(jq -r --arg repo "$sister" '
    (.sisters[] | select(.repo == $repo) | .maxFacadeTools)
    // .default.maxFacadeTools
    // 12
  ' "$CONTRACT_FILE")"

  require_doc_section="$(jq -r --arg repo "$sister" '
    if (.sisters[] | select(.repo == $repo) | has("requireCompactDocSection")) then
      (.sisters[] | select(.repo == $repo) | .requireCompactDocSection)
    else
      (.default.requireCompactDocSection // true)
    end
  ' "$CONTRACT_FILE")"

  require_env_toggle="$(jq -r --arg repo "$sister" '
    if (.sisters[] | select(.repo == $repo) | has("requireCompactEnvToggle")) then
      (.sisters[] | select(.repo == $repo) | .requireCompactEnvToggle)
    else
      (.default.requireCompactEnvToggle // true)
    end
  ' "$CONTRACT_FILE")"

  compact_tools=()
  while IFS= read -r tool; do
    compact_tools+=("$tool")
  done < <(
    jq -r --arg repo "$sister" '
      .sisters[] | select(.repo == $repo) | .compactTools[]?
    ' "$CONTRACT_FILE"
  )

  tool_count="${#compact_tools[@]}"
  if [ "$tool_count" -eq 0 ]; then
    fail "${sister}: no compactTools declared in contract"
    continue
  fi

  if [ "$tool_count" -gt "$max_tools" ]; then
    fail "${sister}: compact tool count ${tool_count} exceeds maxFacadeTools ${max_tools}"
  else
    pass "${sister}: compact tool count ${tool_count}/${max_tools}"
  fi

  if [ "$require_doc_section" = "true" ]; then
    if rg -q "Compact Facade Tools|consolidated" "$command_surface"; then
      pass "${sister}: compact section present in command-surface.md"
    else
      fail "${sister}: command-surface.md missing compact section"
    fi
  fi

  if rg -q '`operation`|operation' "$command_surface"; then
    pass "${sister}: docs mention operation-based routing"
  else
    fail "${sister}: command-surface.md must mention operation-based routing"
  fi

  for tool in "${compact_tools[@]}"; do
    if [[ "$tool" != ${prefix}* ]]; then
      fail "${sister}: contract tool '${tool}' must start with prefix '${prefix}'"
    fi

    if grep -qF "$tool" "$command_surface"; then
      :
    else
      fail "${sister}: command-surface.md missing compact tool '${tool}'"
    fi

    if rg -q --fixed-strings "\"${tool}\"" "$sister_dir" \
      -g '*.rs' \
      -g '!**/target/**' \
      -g '!**/tests/**'; then
      :
    else
      fail "${sister}: compact tool '${tool}' not found in Rust MCP source"
    fi
  done

  if rg -q 'get\("operation"\)|operation.*Unknown|Unknown .* operation|"operation"' "$sister_dir" \
    -g '*.rs' \
    -g '!**/target/**' \
    -g '!**/tests/**'; then
    pass "${sister}: operation-based dispatch detected in source"
  else
    fail "${sister}: no operation-based dispatch pattern detected in source"
  fi

  if rg -q 'test_.*compact|compact_.*test|MCP_TOOL_SURFACE' "$sister_dir" \
    -g '*.rs' \
    -g '!**/target/**'; then
    pass "${sister}: compact guard tests/signals present"
  else
    fail "${sister}: missing compact-surface test coverage/signals"
  fi

  if [ "$require_env_toggle" = "true" ]; then
    env_vars=()
    while IFS= read -r env_var; do
      env_vars+=("$env_var")
    done < <(
      jq -r --arg repo "$sister" '
        .sisters[] | select(.repo == $repo) | .compactEnvVars[]?
      ' "$CONTRACT_FILE"
    )

    if [ "${#env_vars[@]}" -eq 0 ]; then
      fail "${sister}: requireCompactEnvToggle=true but compactEnvVars is empty"
    else
      for env_var in "${env_vars[@]}"; do
        if rg -q --fixed-strings "$env_var" "$sister_dir" -g '*.rs' -g '!**/target/**'; then
          :
        else
          fail "${sister}: missing compact env toggle reference '${env_var}'"
        fi
      done
      pass "${sister}: compact env toggles declared and detected"
    fi
  fi

  if rg -q --fixed-strings "tools/list" "$sister_dir" -g '*.rs' -g '!**/target/**'; then
    pass "${sister}: tools/list handling present"
  else
    fail "${sister}: tools/list handler not detected"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: ${ERRORS} MCP consolidation error(s) found"
  exit 1
else
  echo "MCP consolidation checks passed."
fi
