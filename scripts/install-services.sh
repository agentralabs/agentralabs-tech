#!/usr/bin/env bash
#
# Install systemd/launchd service files for Agentra MCP servers.
#
# Usage:
#   bash scripts/install-services.sh [sister...]
#
# Examples:
#   bash scripts/install-services.sh              # Install all enabled sisters
#   bash scripts/install-services.sh memory planning  # Install specific sisters
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY="$REPO_ROOT/docs/sisters-registry.json"

if [[ ! -f "$REGISTRY" ]]; then
    echo "error: sisters-registry.json not found at $REGISTRY" >&2
    exit 1
fi

# Determine which sisters to install.
if [[ $# -gt 0 ]]; then
    SISTERS=("$@")
else
    # All enabled sisters from registry.
    mapfile -t SISTERS < <(
        python3 -c "
import json, sys
reg = json.load(open('$REGISTRY'))
for s in reg['sisters']:
    if s.get('enabled', False):
        print(s['key'])
" 2>/dev/null || jq -r '.sisters[] | select(.enabled == true) | .key' "$REGISTRY"
    )
fi

install_macos() {
    local sister="$1"
    local home="$HOME"
    local plist_dir="$home/Library/LaunchAgents"
    local template="$SCRIPT_DIR/services/com.agentra.mcp.plist.template"
    local target="$plist_dir/com.agentra.mcp.${sister}.plist"

    if [[ ! -f "$template" ]]; then
        echo "  skip: plist template not found" >&2
        return 1
    fi

    mkdir -p "$plist_dir"
    mkdir -p "$home/Library/Logs"

    # Unload if already loaded.
    launchctl unload "$target" 2>/dev/null || true

    # Substitute placeholders.
    sed -e "s|__SISTER__|${sister}|g" \
        -e "s|__HOME__|${home}|g" \
        "$template" > "$target"

    echo "  installed: $target"
    echo "  load with: launchctl load $target"
}

install_linux() {
    local sister="$1"
    local service_src="$SCRIPT_DIR/services/agentic-mcp@.service"
    local target="/etc/systemd/system/agentic-mcp@.service"

    if [[ ! -f "$service_src" ]]; then
        echo "  skip: systemd template not found" >&2
        return 1
    fi

    # Only install the template once (it's parameterized via %i).
    if [[ ! -f "$target" ]]; then
        if command -v sudo >/dev/null 2>&1; then
            sudo cp "$service_src" "$target"
            sudo systemctl daemon-reload
            echo "  installed template: $target"
        else
            echo "  skip: sudo not available; manually copy $service_src to $target" >&2
            return 1
        fi
    fi

    echo "  enable with: sudo systemctl enable --now agentic-mcp@${sister}"
}

OS="$(uname -s)"
echo "Installing Agentra MCP service files..."
echo "Platform: $OS"
echo "Sisters: ${SISTERS[*]}"
echo ""

for sister in "${SISTERS[@]}"; do
    echo "[$sister]"
    case "$OS" in
        Darwin)
            install_macos "$sister"
            ;;
        Linux)
            install_linux "$sister"
            ;;
        *)
            echo "  skip: unsupported platform $OS" >&2
            ;;
    esac
    echo ""
done

echo "Done."
