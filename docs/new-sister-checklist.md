---
status: stable
---

# New Sister Rollout Checklist

Use this page when a new sister is being prepared for public release. It follows the same frame and layout as existing docs. No new UI pane is required.

## 1. Define the sister contract

1. Set the sister scope in one line: what problem it solves.
2. Confirm artifact format and naming conventions.
3. Confirm MCP surface and tool names.
4. Confirm standalone behavior if other sisters are missing.

## 2. Match installer quality (required)

1. Benchmark against existing installers from AgenticMemory, AgenticVision, and AgenticCodebase.
2. Keep output short, deterministic, and user-readable.
3. Show one clear progress bar from `0%` to `100%`.
4. Print explicit post-install instructions:
   1. restart MCP client
   2. verify tool discovery
   3. optional feedback channel

## 3. Publish docs/public pages

1. Create public pages under the sister repo `docs/public/`.
2. Add `docs/public/sister.manifest.json`.
3. Include only pages intended for public navigation.
4. Keep commands in command-focused pages only.

## 4. Wire to web docs automatically

1. Ensure the sister repo name follows the `agentic-*` pattern.
2. Ensure the manifest includes:
   1. `key`
   2. `name`
   3. `page_ids`
   4. optional `slug_by_id`
3. Optional operator controls live in `docs/config/sister-overrides.json`.
4. Do not add extra tabs or panes for new sisters.

## 5. Runtime and detection checks

1. Verify local/desktop/server install profiles.
2. Verify MCP detection after client restart.
3. Verify per-project isolation (no graph or memory cross-talk).
4. Verify auth is required only for server profile.

## 6. Release gate

1. Guardrails green in sister repo.
2. Docs sync guardrails green in web repo.
3. Public docs lint and sync checks green.
4. Install + runtime smoke tests pass on macOS/Linux/Windows.

## 7. Operational depth parity gate (required for 100%)

If the sister targets full ecosystem parity, all three tiers are required:

1. Tier A baseline runtime capability:
   1. CLI parity (`init`, `info`, `query`, `export`, `ground`, `evidence`, `suggest`, workspace verbs)
   2. MCP parity (`*ground`, `*evidence`, `*suggest`, workspace tools)
2. Tier B session lifecycle parity:
   1. `session_start`
   2. `session_end`
   3. `*_session_resume`
3. Tier C memory-depth runtime controls:
   1. `runtime-sync` workflow
   2. `AUTO_CAPTURE_*` controls
   3. `STORAGE_BUDGET_*` controls

Guardrail:

```bash
./scripts/check-operational-depth-parity.sh
```
