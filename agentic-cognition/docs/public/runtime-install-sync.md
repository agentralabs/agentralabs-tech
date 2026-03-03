---
status: stable
---

# Runtime Install Sync

AgenticCognition ensures that the runtime behavior matches the install-time promises. This document describes the synchronization contract.

## Install-time Guarantees

The installer configures MCP server entries for detected clients, sets up the storage directory, and verifies binary availability. The completion output includes an MCP client summary, generic MCP guidance, and a quick terminal check command.

## Runtime Behavior

At runtime, the MCP server reads from the configured storage directory, enforces Content-Length framing, validates JSON-RPC 2.0 protocol compliance, and applies the 8 MiB frame size limit.

## Profile Parity

All three profiles (desktop, terminal, server) produce identical runtime behavior for the core cognition engine. The only differences are in MCP client configuration (desktop), PATH setup (terminal), and auth token generation (server).

## Update Path

Running the installer again is safe. MCP config updates are merge-only and never destructive. Existing user configuration is preserved.

## Verification

After installation, run `acog model create` to verify the binary is functional. The MCP server can be tested with any MCP-compatible client.
