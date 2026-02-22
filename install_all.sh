#!/usr/bin/env bash
set -euo pipefail

cd agentic-codebase
cargo install --path .

cd ../agentic-memory
cargo install --path .

cd ../agentic-vision
cargo install --path .
