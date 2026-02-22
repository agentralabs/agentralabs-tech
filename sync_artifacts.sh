#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$ROOT_DIR"
TARGET=""
DRY_RUN=0
INCLUDE_HOME_BRAIN=1

usage() {
  cat <<'EOF'
Usage: ./sync_artifacts.sh --target=<path-or-rsync-target> [options]

Syncs sister artifacts (.acb, .amem, .avis) to a local or remote target.

Options:
  --target=<value>          Required. Example local path: /srv/agentra/artifacts
                            Example remote path: user@host:/srv/agentra/artifacts
  --source=<dir>            Source directory to scan (default: workspace root)
  --no-home-brain           Do not include ~/.brain.amem
  --dry-run                 Preview what will sync
  --help                    Show this help

Examples:
  ./sync_artifacts.sh --target=/srv/agentra/artifacts
  ./sync_artifacts.sh --target=ubuntu@10.0.0.8:/srv/agentra/artifacts
EOF
}

while (($#)); do
  case "$1" in
    --target=*)
      TARGET="${1#*=}"
      shift
      ;;
    --source=*)
      SOURCE_DIR="${1#*=}"
      shift
      ;;
    --no-home-brain)
      INCLUDE_HOME_BRAIN=0
      shift
      ;;
    --dry-run)
      DRY_RUN=1
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

if [[ -z "$TARGET" ]]; then
  echo "Error: --target is required." >&2
  usage >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: source directory not found: $SOURCE_DIR" >&2
  exit 1
fi

RSYNC_ARGS=(-av)

if [[ "$DRY_RUN" -eq 1 ]]; then
  RSYNC_ARGS+=(--dry-run)
fi

echo "Syncing sister artifacts..."
echo "  source: $SOURCE_DIR"
echo "  target: $TARGET"
echo "  include ~/.brain.amem: $([[ "$INCLUDE_HOME_BRAIN" -eq 1 ]] && echo yes || echo no)"

manifest_file="$(mktemp)"
cleanup() {
  rm -f "$manifest_file"
}
trap cleanup EXIT

while IFS= read -r abs_path; do
  rel_path="${abs_path#$SOURCE_DIR/}"
  printf '%s\n' "$rel_path" >>"$manifest_file"
done < <(
  find "$SOURCE_DIR" \
    \( -path '*/.git/*' -o -path '*/target/*' -o -path '*/node_modules/*' -o -path '*/tests/fixtures/*' \) -prune \
    -o -type f \( -name '*.acb' -o -name '*.amem' -o -name '*.avis' \) -print
)

artifact_count="$(wc -l <"$manifest_file" | tr -d '[:space:]')"
if [[ "$artifact_count" == "0" ]]; then
  echo "No artifacts found under source directory."
else
  echo "Artifacts found: $artifact_count"
  rsync "${RSYNC_ARGS[@]}" --files-from="$manifest_file" "$SOURCE_DIR"/ "$TARGET"/
fi

if [[ "$INCLUDE_HOME_BRAIN" -eq 1 && -f "$HOME/.brain.amem" ]]; then
  BRAIN_ARGS=(-av)
  if [[ "$DRY_RUN" -eq 1 ]]; then
    BRAIN_ARGS+=(--dry-run)
  fi
  rsync "${BRAIN_ARGS[@]}" "$HOME/.brain.amem" "${TARGET%/}/.brain.amem"
fi

echo ""
echo "Sync complete."
echo "On the server, set:"
echo "  export AGENTRA_RUNTIME_MODE=server"
echo "  export AGENTIC_TOKEN=\"\$(openssl rand -hex 32)\""
echo "  export AGENTRA_ARTIFACT_DIRS=\"<server-path-containing-synced-artifacts>\""
echo ""
echo "Then run preflight:"
echo "  agentra server preflight --strict"
echo ""
echo "[next] Restart MCP host/client"
echo "[tip] Optional feedback: https://agentralabs.tech/docs/feedback"
