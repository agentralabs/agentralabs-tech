# agentra-cli

`agentra` is the top-level UX/orchestration CLI for the Agentra sister ecosystem.

It does **not** replace sister CLIs/MCPs. It detects and coordinates them.

## Commands

```bash
agentra ui
agentra status
agentra status --session
agentra doctor
agentra doctor --fix
agentra backup run
agentra backup list
agentra backup verify
agentra server preflight
agentra control off
agentra control on
agentra toggle codebase off
agentra toggle memory off
agentra toggle vision off
```

Or via workspace:

```bash
cargo run --bin agentra -- ui
cargo run --bin agentra -- status
cargo run --bin agentra -- status --session
cargo run --bin agentra -- doctor --fix
cargo run --bin agentra -- backup run
cargo run --bin agentra -- server preflight
cargo run --bin agentra -- toggle codebase off
```

## Behavior

- Detects binaries from `PATH` first.
- Falls back to local release binaries under sister directories when present.
- Persists sister enable/disable toggles to `agentra-config.json` at workspace root.
- `agentra doctor` checks MCP wiring and binary health across detected clients.
- `agentra doctor --fix` repairs stale/missing MCP entries (non-destructive merge/backup behavior).
- Runtime artifact resync: when full control is on, `.acb` / `.amem` / `.avis` artifacts auto-enable matching sisters.
- In server runtime (`AGENTRA_RUNTIME_MODE=server` or `AGENTRA_PROFILE=server`), takeover requires auth (`AGENTIC_TOKEN` or `AGENTIC_TOKEN_FILE`).
- Server runtime can scan extra artifact locations via `AGENTRA_ARTIFACT_DIRS=/path/a:/path/b`.
- `agentra server preflight` is advisory by default; add `--strict` to make failures non-zero in CI.
- Generate server token with `openssl rand -hex 32`.
- Cloud runtimes cannot read laptop artifacts directly; sync first (for example with `./sync_artifacts.sh --target=<server-path-or-rsync-target>` from workspace root).
- `agentra control off` disables auto-takeover/resync; `agentra control on` enables it.
- Reports status per tool:
  - `OK`
  - `DISABLED`
  - `MISSING`

## UI Controls

- `r` refresh
- `h` start hints
- `q` quit

## Scope

This crate is intentionally small and focused on UX. It should avoid coupling sister internals.
