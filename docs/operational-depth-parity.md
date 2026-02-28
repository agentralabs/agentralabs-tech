---
status: stable
---

# Operational Depth Parity Contract

This contract defines what "100% sister parity" means beyond structural parity.
Canonical parity remains mandatory. Operational parity is an additional hard
gate and is enforced by guardrails.

## Policy

All enabled sisters in `docs/sisters-registry.json` must pass:

1. Canonical parity guardrails
2. Operational depth parity guardrails

No waiver path exists on `main`.

## Tier Model

### Tier A (Baseline Runtime Capability) — Required for every sister

CLI command surface must include these capabilities:

1. `init`
2. `info`
3. `query`
4. `export`
5. `ground`
6. `evidence`
7. `suggest`
8. `workspace create`
9. `workspace add`
10. `workspace list`
11. `workspace query`
12. `workspace compare`
13. `workspace xref`

MCP tool surface must include these capabilities:

1. `*ground`
2. `*evidence`
3. `*suggest`
4. `*workspace_create`
5. `*workspace_add`
6. `*workspace_list`
7. `*workspace_query`
8. `*workspace_compare`
9. `*workspace_xref`

### Tier B (Session Lifecycle) — Required for every sister

MCP tool surface must include:

1. `session_start`
2. `session_end`
3. `*_session_resume` (or equivalent explicit session resume tool)

### Tier C (Memory-Depth Runtime Controls) — Required for every sister

Each sister must implement and document:

1. Runtime sync workflow (`runtime-sync` / `runtime_sync`)
2. Auto-capture controls:
   1. `AUTO_CAPTURE_MODE`
   2. `AUTO_CAPTURE_REDACT`
   3. `AUTO_CAPTURE_MAX_CHARS`
3. Storage budget controls:
   1. `STORAGE_BUDGET_MODE`
   2. `STORAGE_BUDGET_BYTES`
   3. `STORAGE_BUDGET_HORIZON_YEARS`
   4. `STORAGE_BUDGET_TARGET_FRACTION`

## Guardrail

Use:

```bash
./scripts/check-operational-depth-parity.sh
```

This script fails when any enabled sister is missing any required Tier A, B, or
C capability.

It is also called by:

```bash
./scripts/check-canonical-consistency.sh
```

## Release Rule

A release is blocked if either canonical or operational parity fails.
