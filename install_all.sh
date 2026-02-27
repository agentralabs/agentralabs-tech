#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TEST_MODE=0

# Read sisters from single-source registry
REGISTRY="${ROOT_DIR}/docs/sisters-registry.json"
if [ ! -f "$REGISTRY" ]; then
  echo "Error: sisters-registry.json not found at $REGISTRY" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed" >&2
  exit 1
fi

usage() {
  cat <<'EOF'
Usage: ./install_all.sh [--test-mode] [--profile=desktop|terminal|server] [--help]

Installs all sister CLI + MCP tools from local paths.
Sisters are read from docs/sisters-registry.json.

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

# Build install targets dynamically from registry
INSTALL_TARGETS=()
SISTER_COUNT=$(jq '.sisters | length' "$REGISTRY")
for i in $(seq 0 $((SISTER_COUNT - 1))); do
  repo=$(jq -r ".sisters[$i].repo" "$REGISTRY")
  cli_crate=$(jq -r ".sisters[$i].packages.cliCrate" "$REGISTRY")
  mcp_crate=$(jq -r ".sisters[$i].packages.mcpCrate" "$REGISTRY")
  mcp_crate_path=$(jq -r ".sisters[$i].mcp.cratePath" "$REGISTRY")

  # CLI crate — standard path convention: <repo>/crates/<cli-crate>
  cli_path="$ROOT_DIR/$repo/crates/$cli_crate"
  if [ -d "$cli_path" ]; then
    INSTALL_TARGETS+=("${cli_crate}|${cli_path}")
  fi

  # MCP crate — uses cratePath from registry
  mcp_path="$ROOT_DIR/$repo/$mcp_crate_path"
  if [ -d "$mcp_path" ]; then
    INSTALL_TARGETS+=("${mcp_crate}|${mcp_path}")
  fi
done

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
  local label="$1"
  local path="$2"

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

total="${#INSTALL_TARGETS[@]}"
completed=0

echo "Installing all sisters from: $ROOT_DIR"
[[ "$TEST_MODE" -eq 1 ]] && echo "Running in test mode (no installs will be executed)."
echo "Profile: $PROFILE"

for target in "${INSTALL_TARGETS[@]}"; do
  IFS='|' read -r label path <<< "$target"
  completed=$((completed + 1))
  draw_progress "$completed" "$total" "Installing $label"
  run_install "$label" "$path"
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
