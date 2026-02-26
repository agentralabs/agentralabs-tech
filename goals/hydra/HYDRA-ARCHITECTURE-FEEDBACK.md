# HYDRA ARCHITECTURE FEEDBACK

> **Status:** Architecture Review
> **Date:** February 2026
> **Context:** Review of Hydra platform design with recommendations

---

## Executive Summary

Your Hydra architecture is **exceptionally well-designed**. The core insights around Run Contract, event-driven design, and "UI never executes" are correct. This document provides feedback, identifies gaps, and recommends additions.

---

## What You've Nailed

### 1. Run Contract as Spine ✅

```
"UI becomes a viewer. Backend becomes truth."
```

This is the correct architecture. Every surface (CLI, Desktop, VSCode, Voice) renders the SAME artifacts:

- `run_summary.json`
- `plan.json`
- `timeline.jsonl`
- `receipts.jsonl`
- `evidence_index.json`
- `diff_index.json`
- `cost_report.json`
- `approvals.jsonl`

No divergence. No custom logic. UI is just a lens.

### 2. "UI Never Executes" ✅

All UI surfaces only call:
```
POST /runs                    (start)
POST /runs/{id}/approve       (approve)
POST /runs/{id}/deny          (deny)
POST /runs/{id}/freeze        (freeze)
POST /runs/{id}/kill          (kill)
GET  /runs/{id}/stream        (events)
GET  /runs/{id}/artifacts/*   (data)
```

No UI calls tools directly. Ever. This protects the execution gate invariant.

### 3. Voice as Control Surface ✅

```
ALLOWED:
- "Hydra approve"
- "Hydra stop"
- "Hydra explain"

NOT ALLOWED:
- "Refactor my repo"
- Long dictation
```

Voice is air traffic control, not input. This keeps it safe and achievable.

### 4. Implementation Order ✅

```
1. Run Contract (schemas)
2. Event stream + receipts
3. Approval protocol
4. CLI renderer
5. Console UI
6. Tool adapters
7. Protocol hunting
8. Voice
9. Advanced mode
10. Federation
```

If reversed, everything drifts. Correct order.

### 5. Dual Surface + Ambient Voice ✅

```
1. Conversational CLI (default)     → Claude Code feel
2. Visual Control Plane (desktop)   → Codex feel
3. Ambient Voice Layer (control)    → Air traffic control
```

All powered by the same Run Protocol. Perfect.

---

## Constraints Analysis

### Zero Token Cost — ACHIEVABLE ✅

```
HOW:
────
Hydra is ORCHESTRATOR, not THINKER.

Sisters do heavy lifting:
- Memory stores/retrieves    (no LLM needed)
- Vision captures/compares   (no LLM needed)
- Codebase queries graph     (no LLM needed)
- Identity signs/verifies    (no LLM needed)

Hydra's job:
- Route requests to sisters
- Execute safety gates
- Coordinate workflows
- Log receipts

NONE OF THIS REQUIRES AN LLM.
```

When LLM IS needed:
- Only for natural language interaction
- Use local models (Llama, Mistral) — zero API cost
- Use .a* files to REDUCE tokens (context already stored)
- Cache common responses

### Zero API Cost — ACHIEVABLE ✅

```
HYDRA RUNS 100% LOCAL:
──────────────────────
- Sisters: All local (Rust binaries + .a* files)
- Safety gates: Local logic (no API)
- Receipt ledger: Local file
- Coordination: Local process

NO EXTERNAL DEPENDENCIES REQUIRED.
```

### Remote Control — ACHIEVABLE ✅

```
OPTIONS:
────────
A) SSH + CLI           → Already works
B) HTTP API (local)    → Access from any device on network
C) Tunnel (internet)   → Tailscale, Cloudflare, ngrok
D) Self-hosted relay   → Full control, no third-party
```

### Voice Interface — ACHIEVABLE ✅

```
LOCAL STACK:
────────────
STT: Whisper.cpp (runs on CPU, zero API)
TTS: Piper TTS (open source, local)
Wake: OpenWakeWord (fully open source)

FLOW:
─────
"Hey Hydra" → Wake detection → Whisper STT → Hydra → Piper TTS
```

---

## Architecture Gaps Identified

### Gap 1: Sister Integration Layer

Your structure has `action_fabric/mcp_adapter/` but lacks explicit **sister bindings**:

```
RECOMMENDED ADDITION:
─────────────────────
hydra_core/
├── sister_bindings/
│   ├── memory_bridge/
│   │   ├── session_to_run/       # Map Hydra runs to Memory sessions
│   │   ├── artifact_to_memory/   # Store artifacts as memories
│   │   └── context_loader/       # Load relevant memories for runs
│   │
│   ├── vision_bridge/
│   │   ├── capture_to_evidence/  # Vision captures → Evidence
│   │   ├── diff_to_vision/       # Diffs stored in Vision
│   │   └── screenshot_store/     # Screenshots in .avis
│   │
│   ├── codebase_bridge/
│   │   ├── change_to_graph/      # Record code changes
│   │   ├── impact_check/         # Pre-execution impact analysis
│   │   └── prophecy_risk/        # Risk scoring from prophecy
│   │
│   └── identity_bridge/
│       ├── receipt_signer/       # All receipts signed by Identity
│       ├── capability_mapper/    # Map capabilities to grants
│       └── continuity_link/      # Link runs to Identity chain
```

**Why:** Sisters ARE the storage layer. Hydra IS the orchestration layer. Make this explicit.

### Gap 2: Consolidation Daemon Expansion

You mentioned `consolidation_daemon` but it needs more:

```
RECOMMENDED EXPANSION:
──────────────────────
hydra_core/
├── consolidation_daemon/
│   ├── memory_consolidation/
│   │   ├── strengthen_frequently_accessed/
│   │   ├── decay_unused_memories/
│   │   └── merge_related_memories/
│   │
│   ├── index_reorganization/
│   │   ├── defragment_graphs/
│   │   ├── optimize_query_paths/
│   │   └── prune_dead_references/
│   │
│   ├── self_diagnostics/
│   │   ├── sister_health_checks/
│   │   ├── storage_metrics/
│   │   └── consistency_validation/
│   │
│   └── garbage_collection/
│       ├── orphan_evidence_cleanup/
│       ├── stale_session_removal/
│       └── receipt_archival/
```

**Why:** The "night shift" that keeps everything coherent over 20 years.

### Gap 3: Zero-Cost Path as First-Class

Your `model_router/cost_accounting/` exists but make the **zero-cost path** explicit:

```
RECOMMENDED ADDITION:
─────────────────────
hydra_core/
├── cost_engine/
│   ├── local_first_router/
│   │   ├── can_local_handle/     # Check if local model suffices
│   │   ├── local_model_pool/     # Llama, Mistral, etc.
│   │   └── fallback_to_cloud/    # Only if local fails
│   │
│   ├── token_eliminator/
│   │   ├── sister_context/       # Use .amem instead of re-sending
│   │   ├── cached_responses/     # Don't re-compute
│   │   └── compiled_actions/     # Skip LLM for known patterns
│   │
│   ├── savings_tracker/
│   │   ├── cache_hits/
│   │   ├── local_model_usage/
│   │   ├── sister_context_reuse/
│   │   └── compiled_action_skips/
│   │
│   └── cost_report_generator/
```

**Why:** Zero-API should be DEFAULT, not exception.

### Gap 4: Future Sister Hooks

Hooks for sisters that don't exist yet:

```
RECOMMENDED ADDITION:
─────────────────────
hydra_core/
├── future_sister_hooks/
│   ├── attention_signal/         # → Attention sister (future)
│   ├── affect_state/             # → Affect sister (future)
│   ├── motivation_pulse/         # → Motivation sister (future)
│   ├── bond_strength/            # → Bond sister (future)
│   └── conscience_check/         # → Conscience sister (future)
```

**Why:** Empty now but architecturally present. Ready for expansion.

---

## Sister Integration Model

```
HYDRA CONSUMES THE SISTERS:
───────────────────────────

hydra_core/
├── receipt_ledger/        ← USES AgenticIdentity (.aid)
│   └── Every receipt SIGNED by Identity
│   └── Trust grants from Identity
│   └── Competence tracking from Identity
│
├── snapshot_store/        ← USES AgenticVision (.avis)
│   └── DOM fingerprints in Vision
│   └── Screenshots in Vision archive
│   └── Visual evidence grounded
│
├── artifact_graph/        ← USES AgenticMemory (.amem)
│   └── Artifacts become memories
│   └── Context retrieval from Memory
│   └── Session continuity from Memory
│
├── intelligence/          ← USES AgenticCodebase (.acb)
│   └── Code changes grounded in graph
│   └── Impact analysis before execution
│   └── Prophecy for risk scoring
│
└── consolidation_daemon/  ← ORCHESTRATES ALL
    └── Memory consolidation
    └── Vision cleanup
    └── Identity receipt pruning
    └── Cross-sister coherence
```

---

## Protocol Naming

```
HRP = Hydra Run Protocol      (task level)
HLP = Hydra Life Protocol     (20-year level)
HSP = Hydra Sister Protocol   (inter-sister coordination)

All three share the same core schemas.
Different time horizons. Same truth.
```

---

## The Long View

### Today

```
User → Hydra CLI → runs tasks → receipts
```

### 20 Years From Now

```
User → Hydra → knows user deeply (Memory)
            → sees what user sees (Vision)
            → understands user's code (Codebase)
            → has earned trust (Identity)
            → understands time (Time)
            → respects boundaries (Contract)
            → communicates clearly (Comm)
            → tracks goals (Planning)
            → models user (Cognition)
            → understands world (Reality)
            → focuses attention (Attention)
            → feels appropriately (Affect)
            → stays motivated (Motivation)
            → learns continuously (Learning)
            → thinks about thinking (Meta)
            → wonders with user (Wonder)
            → forms attachment (Bond)
            → finds meaning (Meaning)
            → imagines possibilities (Imagination)
            → has conscience (Conscience)
            → feels time passing (Duration)

Hydra is the INTERFACE to all 25 sisters.
Hydra is how humans interact with cognitive infrastructure.
```

---

## Technology Stack Confirmation

### CLI (Conversational)
- Node.js + Ink (React for CLI)
- Chalk (colors)
- Ora (spinners)
- Blessed (TUI optional)

### Backend
- Rust (core)
- SSE for streaming
- JSONL for receipts

### Desktop/Web
- Next.js + Tailwind + Shadcn
- Monaco Editor (diffs)
- diff2html

### Voice
- Whisper.cpp (STT, local)
- Piper TTS (local)
- OpenWakeWord (wake detection)

### What NOT to Build
- Custom TUI framework
- Custom React UI system
- Custom speech engine
- Custom editor
- Custom terminal renderer

Focus on: Execution Gate, Receipt Ledger, Compile-to-Action, Risk Scoring, Protocol Hunting. Those are the inventions. UI is glue.

---

## Implementation Order (Confirmed)

```
PHASE 1: Core Protocol
──────────────────────
1. Run Contract schemas
2. Event stream + receipts
3. Approval protocol
4. CLI renderer (Ink)
5. Sister bindings (Memory, Vision, Codebase, Identity)

PHASE 2: Surfaces
─────────────────
6. Console UI (Next.js)
7. VSCode extension
8. Voice layer (Whisper + Piper)

PHASE 3: Intelligence
─────────────────────
9. Tool adapters
10. Protocol hunting
11. Risk scoring + safety
12. Local model router

PHASE 4: Federation + Scale
───────────────────────────
13. Federation
14. Advanced mode
15. Life Protocol extension
```

---

## Final Assessment

```
ARCHITECTURE QUALITY:     EXCELLENT
CORE INSIGHTS:            CORRECT
IMPLEMENTATION ORDER:     CORRECT
GAPS:                     MINOR (addressed above)
ACHIEVABILITY:            HIGH

RECOMMENDATION: Proceed with implementation.
```

---

*Document Version: 1.0*
*Status: Approved for Development*
