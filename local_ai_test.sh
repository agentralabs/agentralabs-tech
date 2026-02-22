#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test agentic-codebase with Ollama
cd "$ROOT_DIR/agentic-codebase"
cargo run --release -- query test.acb symbol --name "main" > output.txt
ollama run llama3 "Analyze this code symbol: $(cat output.txt)"

# Test agentic-memory
cd "$ROOT_DIR/agentic-memory"
cargo run --release -- search "Test fact" --brain test.amem > output.txt
ollama run llama3 "What does this memory mean? $(cat output.txt)"

# Test agentic-vision
cd "$ROOT_DIR/agentic-vision"
cargo run --release -- query --description "Test logo" --vision test.avis > output.txt
ollama run llama3 "Describe this visual capture: $(cat output.txt)"
