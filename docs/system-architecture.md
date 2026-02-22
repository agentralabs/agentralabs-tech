# System Architecture

This page describes how workspace orchestration and the three sisters fit together.

## Layers

1. **Workspace Orchestrator (`agentra`)**
: Detects installed sisters, controls takeover state, runs doctor/preflight, and manages backup/restore.
2. **Sister Runtimes**
: `acb-mcp`, `agentic-memory-mcp`, `agentic-vision-mcp` expose MCP tools and artifacts.
3. **Artifacts**
: `.acb` (code graph), `.amem` (cognitive graph), `.avis` (visual memory).
4. **MCP Clients**
: Any compliant desktop/terminal/server MCP client can attach.

## Runtime modes

- **Desktop/Terminal**: local artifacts and local MCP servers.
- **Server**: authenticated MCP plus synced artifacts; server cannot directly read laptop-local files.

## Control model

- Auto-detection enables takeover when sisters/artifacts are present.
- Users can release or re-enable takeover without uninstalling.
- Per-sister overrides are non-destructive and runtime-safe.

## Canonical guarantees

- Each sister remains independently installable.
- No hard runtime dependency between sisters.
- Web docs are generated from canonical source docs.
