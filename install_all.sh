#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TEST_MODE=0

usage() {
  cat <<'EOF'
Usage: ./install_all.sh [--test-mode] [--profile=desktop|terminal|server] [--help]

Installs all sister tools from local paths:
  - agentic-codebase
  - agentic-memory
  - agentic-vision
  - agentic-identity

Options:
  --test-mode   Print planned install commands without executing.
  --profile     Install profile (desktop, terminal, server). Default: desktop.
  --help        Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --test-mode)
      TEST_MODE=1
      shift
      ;;
    --profile=*)
      PROFILE="${1#*=}"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

PROFILE="${PROFILE:-desktop}"
case "$PROFILE" in
  desktop|terminal|server) ;;
  *)
    echo "Unknown profile: $PROFILE" >&2
    usage >&2
    exit 1
    ;;
esac

SISTERS=(
  "agentic-codebase"
  "agentic-memory"
  "agentic-vision"
  "agentic-identity"
)

draw_progress() {
  local done_count="$1"
  local total_count="$2"
  local label="$3"
  local width=28
  local filled=$((done_count * width / total_count))
  local empty=$((width - filled))
  printf "\r["
  printf "%${filled}s" "" | tr " " "#"
  printf "%${empty}s" "" | tr " " "-"
  printf "] %d/%d %s" "$done_count" "$total_count" "$label"
}

run_install() {
  local sister="$1"
  local path="$ROOT_DIR/$sister"

  if [[ ! -d "$path" ]]; then
    echo
    echo "ERROR: Missing directory: $path" >&2
    exit 1
  fi

  if [[ "$TEST_MODE" -eq 1 ]]; then
    echo
    echo "[test-mode] cargo install --path \"$path\""
    return
  fi

  cargo install --path "$path"
}

total="${#SISTERS[@]}"
completed=0

echo "Installing all sisters from: $ROOT_DIR"
[[ "$TEST_MODE" -eq 1 ]] && echo "Running in test mode (no installs will be executed)."
echo "Profile: $PROFILE"

for sister in "${SISTERS[@]}"; do
  completed=$((completed + 1))
  draw_progress "$completed" "$total" "Installing $sister"
  run_install "$sister"
done

echo
echo "Install flow completed."
if [[ "$PROFILE" == "server" ]]; then
  echo "Server auth gate:"
  echo "  - Generate token: openssl rand -hex 32"
  echo "  - Set AGENTIC_TOKEN or AGENTIC_TOKEN_FILE before runtime takeover."
  echo "  - MCP clients must use Authorization: Bearer <same-token>."
  echo "Artifact sync for server takeover:"
  echo "  - Cloud/server cannot read laptop artifacts directly."
  echo "  - Sync artifacts first: ./sync_artifacts.sh --target=<server-path-or-rsync-target>"
  echo "  - Set AGENTRA_ARTIFACT_DIRS to scan local artifact paths."
  echo "    Example: export AGENTRA_ARTIFACT_DIRS=\"/srv/agentra:/data/brains\""
fi
