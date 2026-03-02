#!/usr/bin/env bash
# check-operational-depth-parity.sh — enforce memory-level operational parity
#
# Tiers are defined in docs/operational-depth-parity.md.
# Default is strict: Tier A + Tier B + Tier C for every enabled sister.
#
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
source "$(dirname "$0")/lib/load-sisters.sh"

ERRORS=0
REQUIRED_TIERS="${REQUIRED_TIERS:-A,B,C}"

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

has_tier() {
  local tier="$1"
  [[ ",${REQUIRED_TIERS}," == *",${tier},"* ]]
}

extract_tools_strict() {
  local src="$1"

  {
    # ToolDefinition list style: name: "tool_name".to_string(),
    grep -E 'name:\s*"[a-z_]+".to_string\(\)' "$src" 2>/dev/null \
      | grep -oE '"[a-z_]+"' \
      | tr -d '"' \
      || true

    # Dispatch match arms from common implementations.
    grep -E '"[a-z_]+" =>.*(validation::|Self::handle|::execute|self\.tool_)' "$src" 2>/dev/null \
      | grep -oE '"[a-z_]+"' \
      | tr -d '"' \
      || true

    grep -E 'tool_name == "[a-z_]+"' "$src" 2>/dev/null \
      | grep -oE '"[a-z_]+"' \
      | tr -d '"' \
      || true

    grep -E '^[[:space:]]{1,10}"[a-z_]+" => \{' "$src" 2>/dev/null \
      | grep -oE '"[a-z_]+"' \
      | tr -d '"' \
      || true
  } | sort -u
}

tools_has() {
  local pattern="$1"
  local tools="$2"
  echo "$tools" | grep -Eq "$pattern"
}

compact_group_for_capability() {
  local key="$1"
  local capability="$2"

  case "${key}:${capability}" in
    memory:ground|memory:evidence|memory:suggest) echo "memory_grounding" ;;
    vision:ground|vision:evidence|vision:suggest) echo "vision_grounding" ;;
    codebase:ground|codebase:evidence|codebase:suggest) echo "codebase_grounding" ;;
    identity:ground|identity:evidence|identity:suggest) echo "identity_grounding" ;;
    time:ground|time:evidence|time:suggest) echo "time_core" ;;
    contract:ground|contract:evidence|contract:suggest) echo "contract_main" ;;
    comm:ground|comm:evidence|comm:suggest) echo "comm_store" ;;

    memory:workspace_create|memory:workspace_add|memory:workspace_list|memory:workspace_query|memory:workspace_compare|memory:workspace_xref) echo "memory_workspace" ;;
    vision:workspace_create|vision:workspace_add|vision:workspace_list|vision:workspace_query|vision:workspace_compare|vision:workspace_xref) echo "vision_workspace" ;;
    codebase:workspace_create|codebase:workspace_add|codebase:workspace_list|codebase:workspace_query|codebase:workspace_compare|codebase:workspace_xref) echo "codebase_workspace" ;;
    identity:workspace_create|identity:workspace_add|identity:workspace_list|identity:workspace_query|identity:workspace_compare|identity:workspace_xref) echo "identity_workspace" ;;
    time:workspace_create|time:workspace_add|time:workspace_list|time:workspace_query|time:workspace_compare|time:workspace_xref) echo "time_workspace" ;;
    contract:workspace_create|contract:workspace_add|contract:workspace_list|contract:workspace_query|contract:workspace_compare|contract:workspace_xref) echo "contract_workspace" ;;
    comm:workspace_create|comm:workspace_add|comm:workspace_list|comm:workspace_query|comm:workspace_compare|comm:workspace_xref) echo "comm_workspace" ;;

    memory:session_start|memory:session_end|memory:session_resume) echo "memory_session" ;;
    vision:session_start|vision:session_end|vision:session_resume) echo "vision_session" ;;
    codebase:session_start|codebase:session_end|codebase:session_resume) echo "codebase_session" ;;
    identity:session_start|identity:session_end|identity:session_resume) echo "identity_actions" ;;
    time:session_start|time:session_end|time:session_resume) echo "time_workspace" ;;
    contract:session_start|contract:session_end|contract:session_resume) echo "contract_workspace" ;;
    comm:session_start|comm:session_end|comm:session_resume) echo "comm_session" ;;
    *)
      echo ""
      ;;
  esac
}

mcp_has_capability() {
  local key="$1"
  local capability="$2"
  local tools="$3"
  local compact_group

  case "$capability" in
    ground)
      tools_has '(^|.*_)ground$' "$tools" && return 0
      ;;
    evidence)
      tools_has '(^|.*_)evidence$' "$tools" && return 0
      ;;
    suggest)
      tools_has '(^|.*_)suggest$' "$tools" && return 0
      ;;
    workspace_create)
      tools_has '(^|.*_)workspace_create$' "$tools" && return 0
      ;;
    workspace_add)
      tools_has '(^|.*_)workspace_add$' "$tools" && return 0
      ;;
    workspace_list)
      tools_has '(^|.*_)workspace_list$' "$tools" && return 0
      ;;
    workspace_query)
      tools_has '(^|.*_)workspace_query$' "$tools" && return 0
      ;;
    workspace_compare)
      tools_has '(^|.*_)workspace_compare$' "$tools" && return 0
      ;;
    workspace_xref)
      tools_has '(^|.*_)workspace_xref$' "$tools" && return 0
      ;;
    session_start)
      tools_has '^session_start$' "$tools" && return 0
      ;;
    session_end)
      tools_has '^session_end$' "$tools" && return 0
      ;;
    session_resume)
      tools_has '(^|.*_)session_resume$' "$tools" && return 0
      ;;
  esac

  compact_group="$(compact_group_for_capability "$key" "$capability")"
  if [ -n "$compact_group" ] && tools_has "^${compact_group}$" "$tools"; then
    return 0
  fi

  return 1
}

cli_has() {
  local pattern="$1"
  local sister_dir="$2"
  local cli_crate="$3"

  local candidates=(
    "${sister_dir}/crates/${cli_crate}/src"
    "${sister_dir}/src/cli"
    "${sister_dir}/src/bin"
    "${sister_dir}/src"
  )

  for c in "${candidates[@]}"; do
    if [ -d "$c" ] && grep -rqiE "$pattern" "$c" --include='*.rs'; then
      return 0
    fi
  done

  return 1
}

section "Operational Depth Parity (tiers: ${REQUIRED_TIERS})"

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  key="${SISTER_KEYS[$i]}"
  cli_crate="${CLI_CRATES[$i]}"
  sister_dir="${WORKSPACE}/${sister}"
  tool_src="${sister_dir}/${MCP_TOOL_SOURCES[$i]}"
  command_surface="${sister_dir}/docs/public/command-surface.md"

  if [ ! -d "$sister_dir" ]; then
    fail "${sister}: repository missing in workspace"
    continue
  fi

  if [ ! -f "$command_surface" ]; then
    fail "${sister}: missing docs/public/command-surface.md"
    continue
  fi

  if [ ! -f "$tool_src" ]; then
    fail "${sister}: missing MCP tool source: ${MCP_TOOL_SOURCES[$i]}"
    continue
  fi

  tools="$(extract_tools_strict "$tool_src")"
  if [ -z "$tools" ]; then
    fail "${sister}: could not extract MCP tools from ${MCP_TOOL_SOURCES[$i]}"
    continue
  fi

  section "${sister} (${key})"

  if has_tier "A"; then
    # Tier A CLI verbs.
    if cli_has '\bInit\b|"init"' "$sister_dir" "$cli_crate"; then pass "${sister}: CLI init"; else fail "${sister}: missing Tier A CLI command 'init'"; fi
    if cli_has '\bInfo\b|"info"' "$sister_dir" "$cli_crate"; then pass "${sister}: CLI info"; else fail "${sister}: missing Tier A CLI command 'info'"; fi
    if cli_has '\bQuery\b|"query"' "$sister_dir" "$cli_crate"; then pass "${sister}: CLI query"; else fail "${sister}: missing Tier A CLI command 'query'"; fi
    if cli_has '\bExport\b|"export"' "$sister_dir" "$cli_crate"; then pass "${sister}: CLI export"; else fail "${sister}: missing Tier A CLI command 'export'"; fi
    if cli_has '\bGround\b|"ground"' "$sister_dir" "$cli_crate"; then pass "${sister}: CLI ground"; else fail "${sister}: missing Tier A CLI command 'ground'"; fi
    if cli_has '\bEvidence\b|"evidence"' "$sister_dir" "$cli_crate"; then pass "${sister}: CLI evidence"; else fail "${sister}: missing Tier A CLI command 'evidence'"; fi
    if cli_has '\bSuggest\b|"suggest"' "$sister_dir" "$cli_crate"; then pass "${sister}: CLI suggest"; else fail "${sister}: missing Tier A CLI command 'suggest'"; fi

    if cli_has 'workspace.*create|Workspace.*Create|workspace_create' "$sister_dir" "$cli_crate"; then pass "${sister}: CLI workspace create"; else fail "${sister}: missing Tier A workspace command 'create'"; fi
    if cli_has 'workspace.*add|Workspace.*Add|workspace_add' "$sister_dir" "$cli_crate"; then pass "${sister}: CLI workspace add"; else fail "${sister}: missing Tier A workspace command 'add'"; fi
    if cli_has 'workspace.*list|Workspace.*List|workspace_list' "$sister_dir" "$cli_crate"; then pass "${sister}: CLI workspace list"; else fail "${sister}: missing Tier A workspace command 'list'"; fi
    if cli_has 'workspace.*query|Workspace.*Query|workspace_query' "$sister_dir" "$cli_crate"; then pass "${sister}: CLI workspace query"; else fail "${sister}: missing Tier A workspace command 'query'"; fi
    if cli_has 'workspace.*compare|Workspace.*Compare|workspace_compare' "$sister_dir" "$cli_crate"; then pass "${sister}: CLI workspace compare"; else fail "${sister}: missing Tier A workspace command 'compare'"; fi
    if cli_has 'workspace.*xref|Workspace.*Xref|workspace_xref' "$sister_dir" "$cli_crate"; then pass "${sister}: CLI workspace xref"; else fail "${sister}: missing Tier A workspace command 'xref'"; fi

    # Tier A MCP tools.
    if mcp_has_capability "$key" "ground" "$tools"; then pass "${sister}: MCP *ground"; else fail "${sister}: missing Tier A MCP tool '*ground' (or compact equivalent)"; fi
    if mcp_has_capability "$key" "evidence" "$tools"; then pass "${sister}: MCP *evidence"; else fail "${sister}: missing Tier A MCP tool '*evidence' (or compact equivalent)"; fi
    if mcp_has_capability "$key" "suggest" "$tools"; then pass "${sister}: MCP *suggest"; else fail "${sister}: missing Tier A MCP tool '*suggest' (or compact equivalent)"; fi
    if mcp_has_capability "$key" "workspace_create" "$tools"; then pass "${sister}: MCP *workspace_create"; else fail "${sister}: missing Tier A MCP tool '*workspace_create' (or compact equivalent)"; fi
    if mcp_has_capability "$key" "workspace_add" "$tools"; then pass "${sister}: MCP *workspace_add"; else fail "${sister}: missing Tier A MCP tool '*workspace_add' (or compact equivalent)"; fi
    if mcp_has_capability "$key" "workspace_list" "$tools"; then pass "${sister}: MCP *workspace_list"; else fail "${sister}: missing Tier A MCP tool '*workspace_list' (or compact equivalent)"; fi
    if mcp_has_capability "$key" "workspace_query" "$tools"; then pass "${sister}: MCP *workspace_query"; else fail "${sister}: missing Tier A MCP tool '*workspace_query' (or compact equivalent)"; fi
    if mcp_has_capability "$key" "workspace_compare" "$tools"; then pass "${sister}: MCP *workspace_compare"; else fail "${sister}: missing Tier A MCP tool '*workspace_compare' (or compact equivalent)"; fi
    if mcp_has_capability "$key" "workspace_xref" "$tools"; then pass "${sister}: MCP *workspace_xref"; else fail "${sister}: missing Tier A MCP tool '*workspace_xref' (or compact equivalent)"; fi
  fi

  if has_tier "B"; then
    if mcp_has_capability "$key" "session_start" "$tools"; then pass "${sister}: MCP session_start"; else fail "${sister}: missing Tier B MCP tool 'session_start' (or compact equivalent)"; fi
    if mcp_has_capability "$key" "session_end" "$tools"; then pass "${sister}: MCP session_end"; else fail "${sister}: missing Tier B MCP tool 'session_end' (or compact equivalent)"; fi
    if mcp_has_capability "$key" "session_resume" "$tools"; then pass "${sister}: MCP *session_resume"; else fail "${sister}: missing Tier B MCP tool '*session_resume' (or compact equivalent)"; fi
  fi

  if has_tier "C"; then
    if grep -rq -e "runtime-sync" -e "runtime_sync" "$sister_dir" --exclude-dir=target; then pass "${sister}: runtime-sync present"; else fail "${sister}: missing Tier C runtime-sync workflow"; fi
    if grep -rqF "AUTO_CAPTURE_MODE" "$sister_dir" --exclude-dir=target; then pass "${sister}: AUTO_CAPTURE_MODE"; else fail "${sister}: missing Tier C AUTO_CAPTURE_MODE"; fi
    if grep -rqF "AUTO_CAPTURE_REDACT" "$sister_dir" --exclude-dir=target; then pass "${sister}: AUTO_CAPTURE_REDACT"; else fail "${sister}: missing Tier C AUTO_CAPTURE_REDACT"; fi
    if grep -rqF "AUTO_CAPTURE_MAX_CHARS" "$sister_dir" --exclude-dir=target; then pass "${sister}: AUTO_CAPTURE_MAX_CHARS"; else fail "${sister}: missing Tier C AUTO_CAPTURE_MAX_CHARS"; fi
    if grep -rqF "STORAGE_BUDGET_MODE" "$sister_dir" --exclude-dir=target; then pass "${sister}: STORAGE_BUDGET_MODE"; else fail "${sister}: missing Tier C STORAGE_BUDGET_MODE"; fi
    if grep -rqF "STORAGE_BUDGET_BYTES" "$sister_dir" --exclude-dir=target; then pass "${sister}: STORAGE_BUDGET_BYTES"; else fail "${sister}: missing Tier C STORAGE_BUDGET_BYTES"; fi
    if grep -rqF "STORAGE_BUDGET_HORIZON_YEARS" "$sister_dir" --exclude-dir=target; then pass "${sister}: STORAGE_BUDGET_HORIZON_YEARS"; else fail "${sister}: missing Tier C STORAGE_BUDGET_HORIZON_YEARS"; fi
    if grep -rqF "STORAGE_BUDGET_TARGET_FRACTION" "$sister_dir" --exclude-dir=target; then pass "${sister}: STORAGE_BUDGET_TARGET_FRACTION"; else fail "${sister}: missing Tier C STORAGE_BUDGET_TARGET_FRACTION"; fi
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: ${ERRORS} operational parity error(s) found"
  exit 1
else
  echo "Operational depth parity checks passed."
fi
