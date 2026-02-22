# agentra-cli

`agentra` is the top-level UX/orchestration CLI for the Agentra sister ecosystem.

It does **not** replace sister CLIs/MCPs. It detects and coordinates them.

## Commands

```bash
agentra ui
agentra status
```

Or via workspace:

```bash
cargo run --bin agentra ui
cargo run --bin agentra status
```

## Behavior

- Detects binaries from `PATH` first.
- Falls back to local release binaries under sister directories when present.
- Reports status per tool:
  - `OK`
  - `MISSING`

## UI Controls

- `r` refresh
- `h` start hints
- `q` quit

## Scope

This crate is intentionally small and focused on UX. It should avoid coupling sister internals.
