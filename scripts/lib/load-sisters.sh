#!/usr/bin/env bash
# load-sisters.sh — Load sister data from docs/sisters-registry.json
#
# Source this file from any script in the agentralabs-tech workspace.
# It populates parallel arrays that replace all hardcoded sister lists.
#
# Usage:
#   source "$(dirname "$0")/lib/load-sisters.sh"
#
# Requires: jq

set -euo pipefail

# Resolve registry path relative to workspace root
REGISTRY="${WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}/docs/sisters-registry.json"

if [ ! -f "$REGISTRY" ]; then
  echo "FATAL: sisters-registry.json not found at $REGISTRY" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "FATAL: jq is required but not installed" >&2
  exit 1
fi

# ── Core arrays ───────────────────────────────────────────────────────────
SISTERS=($(jq -r '.sisters[].repo' "$REGISTRY"))
SISTER_KEYS=($(jq -r '.sisters[].key' "$REGISTRY"))
SISTER_NAMES=($(jq -r '.sisters[].name' "$REGISTRY"))
SISTER_SHORT_NAMES=($(jq -r '.sisters[].shortName' "$REGISTRY"))
SISTER_FILE_EXTS=($(jq -r '.sisters[].fileExtension' "$REGISTRY"))

# ── Package arrays ────────────────────────────────────────────────────────
NPM_PACKAGES=($(jq -r '.sisters[].packages.npm' "$REGISTRY"))
CORE_CRATES=($(jq -r '.sisters[].packages.coreCrate' "$REGISTRY"))
FFI_CRATES=($(jq -r '.sisters[].packages.ffiCrate' "$REGISTRY"))
MCP_CRATES=($(jq -r '.sisters[].packages.mcpCrate' "$REGISTRY"))
CLI_CRATES=($(jq -r '.sisters[].packages.cliCrate' "$REGISTRY"))

# ── Path arrays ───────────────────────────────────────────────────────────
MCP_TOOL_SOURCES=($(jq -r '.sisters[].paths.mcpToolSource' "$REGISTRY"))

# ── Aliases for backward compatibility ────────────────────────────────────
EXPECTED_KEYS=("${SISTER_KEYS[@]}")
EXPECTED_NAMES=("${SISTER_NAMES[@]}")
SISTER_DISPLAY_NAMES=("${SISTER_NAMES[@]}")
FILE_FORMATS=("${SISTER_FILE_EXTS[@]}")
