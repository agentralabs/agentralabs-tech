---
status: stable
---

# Agentra Workspace How-To

## 1. Install all sisters locally

From your workspace root (`<agentra-workspace>`):

```bash
./install_all.sh
```

Dry run only:

```bash
./install_all.sh --test-mode
```

Install individual sisters via cargo:

```bash
cargo install agentic-cognition-cli
cargo install agentic-reality-cli
```

## 2. Verify detection and MCP wiring

```bash
cargo run --bin agentra -- status
cargo run --bin agentra -- status --session
cargo run --bin agentra -- doctor
```

Auto-repair MCP wiring:

```bash
cargo run --bin agentra -- doctor --fix
```

Expected tool states are `OK`, `DISABLED`, or `MISSING` with hints.

## 3. Toggle sisters and full control

Disable individual sisters:

```bash
cargo run --bin agentra -- toggle codebase off
cargo run --bin agentra -- toggle memory off
cargo run --bin agentra -- toggle vision off
cargo run --bin agentra -- toggle identity off
cargo run --bin agentra -- toggle time off
cargo run --bin agentra -- toggle contract off
cargo run --bin agentra -- toggle comm off
cargo run --bin agentra -- toggle planning off
cargo run --bin agentra -- toggle cognition off
cargo run --bin agentra -- toggle reality off
```

Re-enable:

```bash
cargo run --bin agentra -- toggle codebase on
cargo run --bin agentra -- toggle memory on
cargo run --bin agentra -- toggle vision on
cargo run --bin agentra -- toggle identity on
cargo run --bin agentra -- toggle time on
cargo run --bin agentra -- toggle contract on
cargo run --bin agentra -- toggle comm on
cargo run --bin agentra -- toggle planning on
cargo run --bin agentra -- toggle cognition on
cargo run --bin agentra -- toggle reality on
```

Release/re-enable full control:

```bash
cargo run --bin agentra -- control off
cargo run --bin agentra -- control on
```

Settings persist in `./agentra-config.json` at workspace root.

## 4. Start the dashboard

```bash
cargo run --bin agentra -- ui
```

Controls:

- `r` refresh
- `h` hints
- `q` quit

## 5. Operations backup and restore

Create snapshot:

```bash
cargo run --bin agentra -- backup run --workspace "$PWD"
```

List snapshots:

```bash
cargo run --bin agentra -- backup list
```

Verify latest snapshot:

```bash
cargo run --bin agentra -- backup verify
```

Restore examples:

```bash
cargo run --bin agentra -- backup restore <snapshot-name> --memory
cargo run --bin agentra -- backup restore <snapshot-name> --mcp
cargo run --bin agentra -- backup restore <snapshot-name> --artifacts
```

Retention:

```bash
cargo run --bin agentra -- backup prune --keep 20 --dry-run
cargo run --bin agentra -- backup prune --keep 20
```

## 6. Server runtime (auth + artifact sync)

Hosted/cloud runtimes cannot directly read files on your laptop.
Sync artifacts to server-accessible paths and configure auth first.

Required environment:

```bash
export AGENTRA_RUNTIME_MODE=server
export AGENTIC_TOKEN="$(openssl rand -hex 32)"
export AGENTRA_ARTIFACT_DIRS="/srv/agentra:/data/brains"
# optional token file:
# export AGENTIC_TOKEN_FILE="/etc/agentra/token"
```

Sync artifacts:

```bash
./sync_artifacts.sh --target=<server-path-or-rsync-target>
```

Run strict preflight:

```bash
cargo run --bin agentra -- server preflight --strict
```

Start MCP runtimes on the server host:

```bash
agentic-memory-mcp serve
agentic-vision-mcp serve
acb-mcp serve
acog-mcp serve
agentic-reality-mcp serve
```

Client-side validation (any MCP client):

```bash
which agentic-memory-mcp
which agentic-vision-mcp
which acb-mcp
which acog-mcp
which agentic-reality-mcp
```

Protocol parity:

- Desktop and server use the same MCP contract.
- Server mode only adds explicit auth and artifact-sync requirements.

### Troubleshooting Matrix

| Symptom | Likely cause | Check | Fix |
|:--|:--|:--|:--|
| Sister shows `MISSING` in status | Binary not installed or not in `PATH` | `which acb-mcp`, `which agentic-memory-mcp`, `which agentic-vision-mcp`, `which acog-mcp`, `which agentic-reality-mcp` | Reinstall sister, reopen shell, rerun `agentra doctor --fix` |
| MCP client does not show sister tools | Client config not reloaded | Inspect MCP config and process state | Restart MCP client after install/repair |
| Server preflight fails token check | Missing `AGENTIC_TOKEN` or token file | `echo $AGENTIC_TOKEN`, inspect token file path | Set token env or `AGENTIC_TOKEN_FILE`, rerun preflight |
| Server preflight fails artifact check | Artifacts not synced to server dirs | Inspect `AGENTRA_ARTIFACT_DIRS` and target directory contents | Run `./sync_artifacts.sh --target=...`, rerun preflight |
| Takeover does not activate | Sisters disabled or control off | `agentra status`, check toggle state | `agentra toggle <sister> on`, `agentra control on`, then `agentra doctor` |
| Backup verify fails | Snapshot corruption or partial copy | `agentra backup verify` output | Restore previous valid snapshot, rerun backup |
| Doc command mismatch suspected | Old docs cache | Compare against `--help` output of current binaries | Use the command surface pages and regenerate docs sync |
| Cognition `.acog` artifact not found | AgenticCognition not installed or artifact path misconfigured | `which acog-mcp`, `ls *.acog` | `cargo install agentic-cognition-cli`, rerun `agentra doctor --fix` |
| Reality `.areal` artifact not found | AgenticReality not installed or artifact path misconfigured | `which agentic-reality-mcp`, `ls *.areal` | `cargo install agentic-reality-cli`, rerun `agentra doctor --fix` |

## 7. OpenClaw TUI command namespace

Primary runtime control namespace is `agentra`:

```text
/agentra <status|where|on|off|resync|disable|enable>
/agentra-status
/agentra-where
```

Legacy aliases remain valid:

```text
/sisters ...
/sisters-status
/sisters-where
```

## 8. Run local AI smoke test

```bash
./local_ai_test.sh
```

Requirements:

- `ollama` in `PATH`
- local model `llama3`

## 9. Build and package

```bash
cargo build --release -p agentra-cli
cargo package -p agentra-cli
```
