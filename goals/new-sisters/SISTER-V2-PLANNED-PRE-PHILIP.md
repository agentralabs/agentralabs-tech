# SISTER-V2-PLANNED-PRE-PHILIP.md

# Planned Implementations — Before User Feedback

> **Status:** Documented before 11philip22's use case. These remain valid and should be implemented alongside the new V2 patterns.

---

## 1. Runtime Hardening (All Sisters)

> **Origin:** Stress-tested across Memory, Vision, Codebase during production hardening.

### Mandatory for All Sisters

```
HARDENING REQUIREMENT                    STATUS
─────────────────────────────────────────────────
Strict MCP input validation              ✅ Memory, Vision, Codebase
  (no silent fallback behavior)          ⬜ Identity needs audit

Deterministic per-project identity       ✅ Memory, Vision, Codebase
  (canonical-path hashing)               ⬜ Identity needs audit

Zero cross-project contamination         ✅ All current sisters

Safe graph/artifact resolution           ✅ Codebase
  (never bind to unrelated cache)        ⬜ Apply pattern to others

Concurrent startup locking               ✅ Memory, Codebase
  (with stale-lock recovery)             ⬜ Vision, Identity need it

Merge-only MCP config updates            ✅ All current sisters
  (never destructive overwrite)

Profile-based universal installer        ✅ All current sisters
  (desktop|terminal|server)

Post-install restart guidance            ✅ All current sisters

Optional feedback prompt                 ✅ All current sisters

Token-based server auth gates            ⬜ Needs implementation
```

### Spec Files Needed

```
SPEC-INSTALLER-UNIVERSAL.md    — Universal installer patterns
SPEC-RUNTIME-HARDENING.md      — Hardening requirements
SPEC-RELEASE-PUBLISH.md        — Release gate checklist
SPEC-DOCS-PUBLIC-SYNC.md       — Documentation sync process
SPEC-CI-GUARDRAILS.md          — CI checks that block bad releases
```

---

## 2. 20-Year Infrastructure (All Sisters)

> **Origin:** SISTER-VISION-20-YEAR.md constitution

### Phase 2: SQLite Migration

```
CURRENT:  JSON/binary graph files
TARGET:   SQLite backing store (single file, scales to TB)

WHY:
- JSON breaks at ~50MB
- SQLite handles concurrent access natively
- Indexes for fast queries
- ACID compliant
- Still single portable file

MIGRATION PATH:
- Keep .amem/.avis/.acb/.aid extensions
- SQLite is the backing store under the hood
- Auto-migrate on first load of old format
- Backwards compatible forever
```

**Effort:** ~1-2 weeks per sister

---

### Phase 3: Hierarchical Retention

```
LAYER 0: Raw capture (hot, recent)
         → Kept for days/weeks
         
LAYER 1: Session/episode level (warm)
         → Compressed after 30 days
         
LAYER 2: Digest level (monthly)
         → Auto-summarized
         
LAYER 3: Core knowledge (permanent)
         → Never expires, never compressed

IMPLEMENTATION:
- Background daemon compresses old data
- Importance scoring determines retention
- User can pin anything to Layer 3
- Configurable retention policies
```

**Effort:** ~1 week per sister

---

### Phase 4: Semantic Search (Vector Embeddings)

```
CURRENT:  Keyword/type-based queries
TARGET:   Semantic similarity search

IMPLEMENTATION:
- Store embeddings in SQLite (via sqlite-vec or similar)
- Generate embeddings on insert
- query_similar() uses vector search
- Hybrid: keyword + semantic ranking

EMBEDDING OPTIONS:
- Local: all-MiniLM-L6-v2 (~80MB model)
- API: OpenAI/Anthropic embeddings
- Configurable per deployment
```

**Effort:** ~1 week per sister

---

### Phase 5: Encryption at Rest

```
CURRENT:  Plain files
TARGET:   AES-256 encryption, user-controlled key

IMPLEMENTATION:
- Transparent encrypt on save
- Transparent decrypt on load
- Key derived from user passphrase
- Optional hardware key support (YubiKey)
- File is meaningless without key

CRITICAL FOR:
- 20 years of personal data
- Business/professional use
- Compliance requirements
```

**Effort:** ~3-5 days per sister

---

### Phase 6: Cross-Sister Integration

```
CURRENT:  Sisters operate independently
TARGET:   Sisters share context via Memory links

EXAMPLES:
- Vision capture links to Memory session
- Codebase analysis links to Memory decision
- Identity action links to Memory task
- All sisters can query Memory for context

IMPLEMENTATION:
- Common session_id across sisters
- Memory as central context store
- Cross-sister MCP queries
- Unified timeline view
```

**Effort:** ~1-2 weeks total

---

## 3. Identity Roadmap

> **Origin:** Identity invention planning

### v0.2: Contextual Identity

```
CAPABILITY:
Agent presents different identity facets in different contexts.
"Work mode" vs "Personal mode" vs "Public mode"

IMPLEMENTATION:
- Identity contexts (work, personal, public, custom)
- Context-specific trust grants
- Automatic context detection
- Context switching without new identity
```

---

### v0.3: Social Recovery

```
CAPABILITY:
Recover identity through trusted network if keys are lost.

IMPLEMENTATION:
- Designate recovery trustees (humans or agents)
- M-of-N threshold recovery
- Time-locked recovery (prevent instant theft)
- Recovery audit trail
```

---

### v0.4: Reputation Accumulation

```
CAPABILITY:
Build verifiable reputation over time.

IMPLEMENTATION:
- Aggregate competence proofs into reputation score
- Domain-specific reputation (coding, writing, research)
- Reputation attestations from others
- Reputation portability across platforms
```

---

## 4. Hydra Additions

> **Origin:** Hydra planning docs

### Consolidation Daemon

```
PURPOSE:
Background process that maintains system health.

COMPONENTS:
├── Memory Consolidation
│   ├── Strengthen frequently accessed memories
│   ├── Decay unused memories
│   └── Merge duplicate/similar memories
│
├── Index Reorganization  
│   ├── Optimize query indexes
│   ├── Rebuild fragmented indexes
│   └── Update statistics
│
├── Self-Diagnostics
│   ├── Health checks across sisters
│   ├── Consistency verification
│   └── Performance monitoring
│
└── Garbage Collection
    ├── Remove orphaned data
    ├── Clean up expired sessions
    └── Reclaim storage space

RUNS:
- Idle time (when agent not active)
- Scheduled (nightly)
- On-demand (user triggered)
```

---

## 5. Future Sisters Enhancements

> **Origin:** Post-ring upgrade planning

### AgenticReality Additions

```
+ Deployment Context Awareness
  - Know what environment agent is running in
  - Dev vs staging vs production awareness
  - Infrastructure understanding
  - "Don't run destructive commands in prod"
```

### AgenticCognition Additions

```
+ Reputation Modeling
  - How others perceive the agent
  - External feedback integration
  - Perception vs self-model comparison
  - Reputation management suggestions
```

### AgenticLearning (New Sister?)

```
+ Habit Formation
  - Automated routines from repeated actions
  - "You always run tests before commit"
  - Suggest habits based on patterns
  - Habit streak tracking
```

---

## 6. Publishing Infrastructure

> **Origin:** Distribution planning

### npm WASM (All Sisters)

```
STATUS: Published
PACKAGES:
- @agenticamem/memory
- @agenticamem/vision
- @agenticamem/codebase
- @agenticamem/identity
```

### npm N-API (All Sisters)

```
STATUS: Planned (Phase 2)
PACKAGES:
- @agenticamem/memory-native
- @agenticamem/vision-native
- @agenticamem/codebase-native
- @agenticamem/identity-native

PURPOSE:
- Maximum native speed
- "Turbo mode" for heavy workloads
- Platform-specific binaries
```

---

## 7. CI Guardrails

> **Origin:** Release quality enforcement

### Required CI Checks

```
CHECK                               BLOCKS RELEASE IF FAILS
────────────────────────────────────────────────────────────
All tests pass                      ✓
No clippy warnings                  ✓
Formatting (rustfmt)                ✓
Hardening tests pass                ✓
  - Multi-project isolation         ✓
  - Concurrent startup              ✓
  - Restart continuity              ✓
  - Server auth                     ✓
Cross-platform build succeeds       ✓
  - macOS ARM                       ✓
  - macOS x64                       ✓
  - Linux x64                       ✓
  - Windows x64                     ✓
WASM build succeeds                 ✓
Python tests pass                   ✓
MCP integration tests pass          ✓
```

### Release Gate Checklist

```
Before any sister can publish:

□ All CI checks green
□ Hardening tests pass
□ Cross-platform builds succeed
□ Version bumped appropriately
□ CHANGELOG updated
□ README accurate
□ Docs synced to website
□ Previous version deprecated (if breaking)
```

---

## 8. Documentation Sync

> **Origin:** Docs maintenance planning

### SPEC-DOCS-PUBLIC-SYNC.md

```
REQUIREMENT:
Public docs must stay in sync with code.

AUTOMATION:
- CI extracts docs from code comments
- API reference auto-generated
- MCP tool list auto-generated
- Broken link detection
- Version-specific docs

LOCATIONS:
- /docs/public/ in each repo
- Synced to agentralabs.tech/docs
- README.md always current
```

---

## Implementation Priority

```
IMMEDIATE (before next sister):
─────────────────────────────
1. SPEC files creation (5 spec files)
2. CI guardrails implementation
3. Token-based server auth

SHORT-TERM (next 1-2 months):
─────────────────────────────
4. SQLite migration (Phase 2)
5. Hierarchical retention (Phase 3)
6. N-API builds for npm

MEDIUM-TERM (next 3-6 months):
──────────────────────────────
7. Semantic search / embeddings (Phase 4)
8. Encryption at rest (Phase 5)
9. Cross-sister integration (Phase 6)
10. Identity v0.2 (Contextual)

LONG-TERM (6-12 months):
────────────────────────
11. Identity v0.3 (Social Recovery)
12. Identity v0.4 (Reputation)
13. Hydra consolidation daemon
14. Future sister enhancements
```

---

## Relationship to V2 Patterns

```
PRE-PHILIP (this doc)          POST-PHILIP (V2 Patterns)
─────────────────────          ─────────────────────────
Infrastructure                 User-facing capabilities
─────────────────────          ─────────────────────────
SQLite migration               Grounding (anti-hallucination)
Hierarchical retention         Multi-context workspaces
Encryption                     Task continuity
CI guardrails                  Progress tracking
Cross-sister integration       Translation mapping

BOTH ARE NEEDED:
- Pre-Philip = foundation that enables scale
- Post-Philip = features that solve user pain
```

---

## Document Status

```
Created: February 2026
Purpose: Capture planned work before user feedback pivot
Status: CANONICAL — implement alongside V2 patterns
```
