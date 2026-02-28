#!/usr/bin/env bash
# capture-to-memory.sh — Claude Code hook that auto-captures conversation
# context into agentic-memory (.amem file).
#
# Called by Claude Code hooks on: UserPromptSubmit, PostToolUse, Stop
# Receives JSON on stdin with session_id, hook_event_name, and event-specific fields.
#
# Installed by: scripts/install-mcp-servers.sh → ~/.claude/hooks/capture-to-memory.sh
# To disable: remove the hooks section from ~/.claude/settings.json

set -euo pipefail

AMEM="${HOME}/.cargo/bin/amem"
BRAIN="${AMEM_BRAIN:-${HOME}/.brain.amem}"
MAX_CONTENT=1500

# Bail if amem binary or brain file doesn't exist
[ -x "$AMEM" ] || exit 0
[ -f "$BRAIN" ] || exit 0

# Read hook input from stdin
INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "0"')

# Use a consistent numeric session for amem (hash the string session ID)
AMEM_SESSION=$(echo "$SESSION_ID" | cksum | awk '{print $1 % 99999}')

truncate_text() {
  local text="$1"
  if [ ${#text} -gt $MAX_CONTENT ]; then
    echo "${text:0:$MAX_CONTENT}...[truncated]"
  else
    echo "$text"
  fi
}

case "$EVENT" in
  UserPromptSubmit)
    PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')
    [ -z "$PROMPT" ] && exit 0
    CONTENT=$(truncate_text "[user] $PROMPT")
    "$AMEM" add "$BRAIN" episode "$CONTENT" --session "$AMEM_SESSION" --confidence 0.90 2>/dev/null || true
    ;;

  PostToolUse)
    TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
    # Skip capturing memory's own tool calls (already captured by MCP auto-capture)
    case "$TOOL" in
      mcp__agentic-memory__*) exit 0 ;;
    esac
    TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null | head -c 500)
    CONTENT=$(truncate_text "[tool] $TOOL | input: $TOOL_INPUT")
    "$AMEM" add "$BRAIN" inference "$CONTENT" --session "$AMEM_SESSION" --confidence 0.82 2>/dev/null || true
    ;;

  Stop)
    CONTENT="[turn-end] Assistant finished responding"
    "$AMEM" add "$BRAIN" episode "$CONTENT" --session "$AMEM_SESSION" --confidence 0.75 2>/dev/null || true
    ;;
esac

exit 0
