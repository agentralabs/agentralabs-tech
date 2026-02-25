---
status: stable
---

# System Architecture

This page shows how Agentra orchestration and the four sisters operate together across local and server runtime environments.

## Architecture overview flowchart

![Agentra Ecosystem Architecture Overview](/images/docs/architecture/architecture-overview.svg)

The overview flow is:

1. MCP client requests go through `agentra`.
2. `agentra` coordinates sister runtimes (`acb-mcp`, `agentic-memory-mcp`, `agentic-vision-mcp`, `agentic-identity-mcp`).
3. Sister runtimes produce and consume artifacts (`.acb`, `.amem`, `.avis`, `.aid`).
4. Runtime targets (desktop, terminal, server) execute under one contract.

## Local runtime flowchart (desktop and terminal)

![Local Runtime Flow (Desktop and Terminal)](/images/docs/architecture/local-runtime-flow.svg)

Local runtime sequence:

1. Install one or more sisters.
2. Restart the MCP client so it reloads config.
3. `agentra` detects binaries and artifact availability.
4. Takeover policy applies (auto/prompt/manual or explicit control toggles).

## Server handoff flowchart (auth + artifact sync)

![Server Handoff Flow (Authentication and Artifact Sync)](/images/docs/architecture/server-handoff-flow.svg)

Server mode adds two non-optional requirements:

1. Explicit authentication (`AGENTIC_TOKEN` or `AGENTIC_TOKEN_FILE`).
2. Artifact sync from local machine to server-accessible directories.

## Layer model

1. **Workspace orchestrator (`agentra`)**: detection, takeover state, doctor/preflight, backup and restore.
2. **Sister runtimes**: `acb-mcp`, `agentic-memory-mcp`, `agentic-vision-mcp`, and `agentic-identity-mcp` expose MCP tools.
3. **Artifacts**: `.acb` (code graph), `.amem` (memory graph), `.avis` (visual memory), `.aid` (identity anchor).
4. **MCP clients**: any compliant desktop, terminal, or server MCP client.

## Runtime modes

- **Desktop and terminal**: local artifacts with local MCP servers.
- **Server**: authenticated MCP with synced artifacts. Server runtimes cannot directly read laptop-local files.

## Control model

- Auto-detection can activate takeover when sisters or artifacts are present.
- Users can release and re-enable control without uninstalling sisters.
- Per-sister enable/disable remains non-destructive and runtime-safe.

## Canonical guarantees

- Each sister remains independently installable.
- No hard runtime dependency between sisters.
- Documentation pages are generated from canonical source docs.
