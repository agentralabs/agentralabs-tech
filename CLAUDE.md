# Agentra Workspace — Claude Code Instructions

## Sister Registry

All sister automation reads from `docs/sisters-registry.json` (single source of truth).
To add a new sister, follow `docs/NEW-SISTER-PLAYBOOK.md`.

## Hydra Gradual Planning (IMPORTANT)

`goals/hydra/HYDRA-GRADUAL-PLANNING.md` is a living document that captures lessons from every sister for the future Hydra orchestrator. **It must grow naturally as work happens.**

When you complete any of the following types of work on a sister, update the relevant section in HYDRA-GRADUAL-PLANNING.md:

- **New pattern or architecture** — add to "Patterns Hydra Should Inherit" under that sister
- **Edge case discovered** — add to "Edge Cases Discovered" under that sister
- **Hardening or safety fix** — add to the sister's section with Hydra implications
- **Integration challenge solved** — add to "Integration Challenges" if it taught something reusable
- **New invention or capability** — note which Hydra component benefits

This is not a separate task. It's part of finishing the work. When you solve a hard problem, the last step is noting what Hydra can learn from it.

The file lives in `goals/hydra/` (gitignored, private). If it doesn't exist locally, skip silently.

## MCP Quality Standard

All MCP servers must comply with `docs/MCP-QUALITY-STANDARD.md`. Key rules:

- **Tool descriptions:** verb-first imperative, no trailing periods
- **Error handling:** tool execution errors → `isError: true`; protocol errors → JSON-RPC error
- **Unknown tool:** error code `-32803` (TOOL_NOT_FOUND), never `-32601` or `-32602`
- **Gold standard:** copy MCP types from `agentic-memory/crates/agentic-memory-mcp/src/types/`

When building or modifying any sister's MCP server, reference the standard. Guardrail Sections 42-45 catch violations automatically.

## Commit Style

- Never add "Co-Authored-By: Claude" to commits
- Use conventional commit prefixes: `feat:`, `fix:`, `chore:`, `docs:`

## Guardrails

Before pushing, run:
```bash
bash scripts/check-canonical-consistency.sh
bash scripts/check-command-surface.sh
```

The 29 pre-existing command-surface failures (undocumented MCP tools in codebase + vision) are known and not blocking.
