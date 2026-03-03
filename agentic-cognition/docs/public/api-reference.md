---
status: stable
---

# API Reference

AgenticCognition exposes its functionality through three primary surfaces: the Rust library API, the CLI, and the MCP server.

## Rust Library

The core library (`agentic-cognition` crate) provides:

- `WriteEngine` -- model creation, belief management, heartbeat, connections
- `QueryEngine` -- belief queries, graph traversal, soul reflection, predictions
- `CognitionStore` -- storage abstraction for `.acog` file persistence
- `format::AcogFile` -- direct file I/O with BLAKE3 integrity verification

## MCP Tools (14)

All 14 MCP tools are accessible through `agentic-cognition-mcp` over JSON-RPC 2.0 stdio transport. See the MCP Tools documentation for full parameter tables.

## CLI Commands (40+)

The `acog` binary provides 40+ commands organized into groups: model, belief, self, pattern, shadow, bias, drift, and predict. See the CLI Reference for complete usage.

## FFI Bindings

The `agentic-cognition-ffi` crate exposes a C-compatible FFI surface. Python bindings are available via `pip install agentic-cognition` and npm/WASM bindings through the `npm/wasm` package.
