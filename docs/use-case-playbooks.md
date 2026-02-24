---
status: stable
---

# Use-Case Playbooks

Step-based operational playbooks for common user goals.

## Playbook 1: Local desktop setup (all sisters)

1. Install workspace dependencies.
2. Run `./install_all.sh`.
3. Validate with `agentra status` and `agentra doctor`.
4. Open your MCP client and confirm all sister tools appear.

## Playbook 2: Server deployment with auth and artifact sync

1. Set `AGENTRA_RUNTIME_MODE=server` and `AGENTIC_TOKEN`.
2. Sync `.amem/.acb/.avis` to server storage.
3. Run `agentra server preflight --strict`.
4. Start MCP servers on host.
5. Validate first MCP tool call from client.

## Playbook 3: Incident recovery

1. Run `agentra backup list` and select snapshot.
2. Run `agentra backup verify`.
3. Restore with scope (`--memory`, `--mcp`, `--artifacts`).
4. Re-run `agentra doctor` and verify MCP tools.

## Playbook 4: Controlled takeover release

1. Disable one sister with `agentra toggle <sister> off` if needed.
2. Release full control with `agentra control off`.
3. Re-enable when ready with `agentra control on`.
