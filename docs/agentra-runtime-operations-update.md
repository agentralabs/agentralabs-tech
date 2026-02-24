---
status: stable
---

# Agentra Runtime + Operations Update

**Date:** February 22, 2026  
**Scope:** OpenClaw TUI takeover behavior, universal MCP wiring, Agentra command UX, and operational backup/recovery.

## 1) Runtime Takeover and Session Resync

Implemented runtime behavior so Agentra takeover is automatic and repeatable at session start.

- `openclaw tui` now auto-detects sister presence from artifacts and binaries.
- Detection supports artifacts: `.acb`, `.amem`, `.avis`.
- Detection supports binaries: `acb`, `acb-mcp`, `amem`, `agentic-memory-mcp`, `agentic-vision-mcp`.
- Runtime resync runs continuously (periodic re-detection) so footer state updates when environment changes.
- Full-control status is derived from active sisters (not only 3/3 scenarios).
- User can always release/re-enable control without uninstalling anything.

## 2) Dynamic Per-Sister Disable/Enable Overrides

Added non-destructive per-sister control at runtime.

- Supports disabling any sister independently: `codebase`, `memory`, `vision`.
- Disable override takes precedence over artifact/binary detection.
- Backed by config file:
  - `~/.openclaw/sisters-disable.json`
- Optional env overrides:
  - `OPENCLAW_SISTERS_DISABLE_FILE`
  - `OPENCLAW_SISTERS_DISABLE` (and `OPENCLAW_DISABLE_SISTERS`)

Result: users can keep installations intact, temporarily disable a sister, and re-enable instantly.

## 3) TUI Footer and Runtime Messaging Improvements

Status output is now explicit and operationally useful.

- Footer shows:
  - connected/disconnected state
  - sister states (`On/Off`)
  - detection source tags (`PATH`, `artifact`, `artifact+PATH`, `disabled`, `none`)
  - full-control count (`N/3 enabled`)
- Added diagnostics command:
  - `/agentra where` (legacy alias supported)
- Runtime update messaging now uses Agentra wording:
  - `Agentra sisters takeover enabled: ...`
  - `Agentra sisters resynced: codebase=..., memory=..., vision=...`
  - `Agentra sisters runtime update: codebase=..., memory=..., vision=...`

## 4) Slash Command UX: Agentra as Primary Namespace

Moved command UX from `sisters` naming to `agentra` naming, with backward compatibility.

Primary commands:

- `/agentra <status|where|on|off|resync|disable|enable>`
- `/agentra-status`
- `/agentra-where`

Legacy aliases still supported:

- `/sisters ...`
- `/sisters-status`
- `/sisters-where`

Result: cleaner naming for users while preserving existing workflows.

## 5) Universal MCP Wiring (No Client Favoritism)

Standardized MCP auto-configuration behavior across discovered clients.

- Client detection and merge now target common MCP config patterns across desktop and terminal environments.
- Codex MCP registration/repair flow integrated alongside JSON-based MCP configs.
- `agentra doctor --fix` validates and repairs stale/missing sister MCP entries.
- Server profile remains the only mode requiring explicit auth hardening guidance.

## 6) New Native Operations Commands: Backup + Recovery

Implemented first-class backup operations in `agentra-cli`.

### Added command group

- `agentra backup run`
- `agentra backup list`
- `agentra backup verify`
- `agentra backup restore`
- `agentra backup prune`

### Backup behavior

`agentra backup run` creates timestamped snapshots under:

- default root: `~/.agentra-backups`
- snapshot format: `snapshot-<unix-seconds>`

Each snapshot contains:

- memory:
  - `~/.brain.amem` (when present)
- MCP configs:
  - discovered MCP client config files
- runtime artifacts:
  - `.acb`, `.amem`, `.avis` from workspace scan
- health ledger files:
  - from `ACB_HEALTH_LEDGER_DIR` / `AGENTRA_HEALTH_LEDGER_DIR` / default `~/.agentra/health-ledger`

Each snapshot writes:

- `meta/manifest.json`
- `meta/SHA256SUMS.txt`

### Verify behavior

`agentra backup verify` re-hashes all entries and checks against manifest checksums.

### Restore behavior

`agentra backup restore <snapshot>` supports selective restore:

- `--memory`
- `--mcp`
- `--artifacts`

Safety behavior:

- Existing target files are backed up as `.agentra.bak.<timestamp>` before overwrite (unless `--force`).

### Retention behavior

`agentra backup prune --keep <N>` removes older managed snapshots and keeps newest `N`.

- Optional `--dry-run` previews deletion.
- Prunes only managed snapshot directories (`snapshot-*`).

## 7) Installer Post-Install UX Update

After install completes (`100% Install complete`), users now get consistent next-step guidance.

- restart MCP client/system
- verify sister server appears
- optional feedback link

This reduces ambiguity and first-run friction.

## 8) Validation Performed

Validated through local runs and tests:

- TUI command and runtime tests passed.
- `agentra-cli` tests passed after backup/prune additions.
- Live command checks performed for:
  - `agentra backup run/list/verify/restore`
  - `agentra backup prune --dry-run` and real prune
- Global OpenClaw runtime rebuild/reinstall and gateway restart performed during TUI updates.

## 9) Quick Command Reference

```bash
# Agentra runtime controls in OpenClaw TUI
/agentra status
/agentra where
/agentra off
/agentra on
/agentra disable memory
/agentra enable memory
/agentra resync

# Backup operations (agentra-cli)
agentra backup run --workspace <path>
agentra backup list
agentra backup verify
agentra backup restore <snapshot> --memory
agentra backup prune --keep 20 --dry-run
agentra backup prune --keep 20
```

## 10) Recommended Docs Placement

This update can be split into docs pages:

- Runtime takeover + command UX
- Universal MCP behavior
- Operations: backup/verify/restore/prune
- Troubleshooting with `agentra doctor --fix`


## 11) Server Runtime Auth + Artifact Sync (Implemented)

Added executable server-runtime checks and aligned sync guidance.

- New command:
  - `agentra server preflight [--strict] [--artifact-dir <path>]...`
- Preflight validates:
  - server mode enabled (`AGENTRA_RUNTIME_MODE=server`)
  - auth token configured (`AGENTIC_TOKEN` or token file)
  - artifact dirs configured and existing
  - synced artifacts present in server dirs (`.acb/.amem/.avis`)
  - sister MCP binaries resolvable on host (`acb-mcp`, `agentic-memory-mcp`, `agentic-vision-mcp`)
- Strict mode exits non-zero on failures.

Also updated `sync_artifacts.sh` output with next-step signals:

- run `agentra server preflight --strict`
- restart MCP host/client
- optional feedback link

Docs updated:

- `docs/how-to.md` server section now uses preflight + sync + parity wording.
- New standalone doc source:
  - `SERVER_RUNTIME_AUTH_ARTIFACT_SYNC.md`
