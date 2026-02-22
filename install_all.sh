#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$ROOT_DIR/agentic-codebase"
cargo install --path .

cd "$ROOT_DIR/agentic-memory"
cargo install --path .

cd "$ROOT_DIR/agentic-vision"
cargo install --path .
