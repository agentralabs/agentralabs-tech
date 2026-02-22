# agentra-cli

`agentra` is the top-level UX/orchestration CLI for the Agentra sister ecosystem.

It does **not** replace sister CLIs/MCPs. It detects and coordinates them.

## Commands

```bash
agentra ui
agentra status
agentra status --session
agentra toggle codebase off
agentra toggle memory off
agentra toggle vision off
```

Or via workspace:

```bash
cargo run --bin agentra ui
cargo run --bin agentra status
cargo run --bin agentra -- status --session
cargo run --bin agentra -- toggle codebase off
```

## Behavior

- Detects binaries from `PATH` first.
- Falls back to local release binaries under sister directories when present.
- Persists sister enable/disable toggles to `agentra-config.json` at workspace root.
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
