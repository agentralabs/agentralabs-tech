---
status: stable
---

# Server Runtime Auth and Artifact Sync

How hosted agents authenticate and consume local sister artifacts safely.

## Cloud Boundary

Hosted runtimes cannot directly read files from your laptop.  
Sync artifacts to server-accessible storage, then authenticate server MCP calls.

## 1) Enable Server Mode

Required environment:

```bash
export AGENTRA_RUNTIME_MODE=server
export AGENTIC_TOKEN="$(openssl rand -hex 32)"
export AGENTRA_ARTIFACT_DIRS="/srv/agentra:/data/brains"
# optional file-based token:
# export AGENTIC_TOKEN_FILE="/etc/agentra/token"
```

Run strict preflight:

```bash
agentra server preflight --strict
```

## 2) Sync Local Artifacts to Server

Push runtime artifacts before expecting server takeover:

```bash
./sync_artifacts.sh --target=<server-path-or-rsync-target>
```

Sync includes:

- `.amem`
- `.avis`
- `.acb`
- optional `~/.brain.amem`

## 3) Start MCP Runtimes on Server Host

```bash
agentic-memory-mcp serve
agentic-vision-mcp serve
acb-mcp serve
```

Expected install + restart signal:

```text
[####################################] 100% Install complete
Install complete: <runtime>
[next] Restart MCP host/client
[tip] Optional feedback: https://agentralabs.tech/docs/feedback
```

## 4) Validate from Any MCP Client

Client-side checklist:

```bash
which agentic-memory-mcp
which agentic-vision-mcp
which acb-mcp
# then trigger first MCP tool call from your client
```

## Protocol Parity

Desktop and server follow the same MCP contract.  
Server mode only adds explicit authentication and artifact-sync requirements.

## Operational Notes

- Keep `AGENTIC_TOKEN` secret; prefer `AGENTIC_TOKEN_FILE` in production.
- Treat synced artifact directories as sensitive data stores.
- Re-run `agentra server preflight --strict` after deploys, token rotation, or path changes.
