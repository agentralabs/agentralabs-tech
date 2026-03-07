# MEMORY LONGEVITY ARCHITECTURE
## From V3 to 20-Year Immortal Cognitive Memory

> **Status:** Architectural Design Document  
> **Date:** March 2026  
> **Scope:** Bridge the gap between AgenticMemory V3 (shipped) and the 20-year memory longevity vision  
> **Principle:** Data created today must be readable, searchable, and meaningful in 2046.

---

## 1. WHERE WE ARE: V3 Reality Check

AgenticMemory V3 (v0.4.2) is a shipped, production system with real capabilities:

**What exists and works:**
- Immortal Log: Append-only WAL with BLAKE3 integrity chains and CRC32 crash recovery
- Five indexes: Temporal, Semantic, Causal, Entity, Procedural
- Tiered storage: Hot → Warm → Cold → Frozen (age-based tier assignment)
- Ghost Writer: Auto-sync to Claude, Cursor, Windsurf, Cody
- 13 MCP tools for capture, retrieval, search, stats
- Binary `.amem` format with LZ4 compression, mmap access
- 470+ tests, 291+ MCP tests, sub-millisecond queries
- Transport WAL (Layer 1) + Extraction (Layer 2) + Daemon (continuous)

**What's missing for true longevity:**
- No cognitive compression hierarchy (Raw → Episodes → Summaries → Patterns → Traits → Identity)
- No significance scoring (everything treated equally)
- No forgetting protocol (storage grows linearly forever)
- No schema versioning or migration engine
- No encryption rotation for long-lived data
- No SQLite backing for structured long-term retention
- No cross-version format compatibility guarantees
- No consolidation daemon (the Hydra-spec version, not the current extraction daemon)
- No storage budget management or projection

**The gap is not in the foundation — the foundation is extraordinary. The gap is in the TEMPORAL INTELLIGENCE layer: the system that makes memory behave like memory over time rather than like a growing log.**

---

## 2. THE LONGEVITY PROBLEM (Quantified)

### 2.1 Storage Growth Without Compression

| Use Case | Events/Day | Raw Size/Year | 5 Years | 20 Years |
|----------|-----------|---------------|---------|----------|
| Personal assistant | 40 | ~24 MB | ~120 MB | ~480 MB |
| Developer copilot | 150 | ~90 MB | ~450 MB | ~1.8 GB |
| Enterprise agent | 500 | ~300 MB | ~1.5 GB | ~6 GB |
| Multi-agent system | 1500 | ~900 MB | ~4.5 GB | ~18 GB |

These numbers are just the raw events. Add embeddings (128-dim × 4 bytes × event count), indexes, and metadata, and you're looking at 3-5x the raw size. A developer copilot at 20 years without compression: **~9 GB**. Manageable but degrading — search time grows linearly, embeddings bloat, and 95% of that data is noise you'll never query again.

### 2.2 Storage With Intelligent Compression

| Use Case | Year 1 (Full) | Years 2-5 (Episodes) | Years 6-10 (Summaries) | Years 11-20 (Patterns) | Total |
|----------|--------------|---------------------|----------------------|----------------------|-------|
| Personal | 24 MB | 20 MB | 10 MB | 5 MB | ~59 MB |
| Developer | 90 MB | 75 MB | 40 MB | 20 MB | ~225 MB |
| Enterprise | 300 MB | 250 MB | 120 MB | 60 MB | ~730 MB |
| Multi-agent | 900 MB | 750 MB | 350 MB | 175 MB | ~2.2 GB |

The compression hierarchy doesn't just save storage. It makes SEARCH FASTER (smaller indexes), RETRIEVAL SMARTER (pre-summarized context), and MEMORY MEANINGFUL (patterns over noise).

### 2.3 The Real Threat

The threat isn't running out of disk. The threat is:
1. **Signal-to-noise death**: Year 15, 90% of raw events are irrelevant. Search quality degrades because the important stuff drowns in noise.
2. **Format rot**: The `.amem` binary format from 2026 won't be readable by 2036 software without explicit versioning and migration.
3. **Encryption obsolescence**: AES-256 is fine today. In 10 years, key rotation is mandatory.
4. **Embedding drift**: The embedding model used in 2026 won't exist in 2031. Old vectors become meaningless if you can't re-embed or map between models.
5. **Index bloat**: Five indexes growing linearly means 5x the degradation curve.

---

## 3. ARCHITECTURAL DESIGN: THE LONGEVITY ENGINE

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    AGENTICMEMORY LONGEVITY ENGINE                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    V3 ENGINE (EXISTS)                      │   │
│  │  Immortal Log · 5 Indexes · WAL · Ghost Writer · MCP     │   │
│  └────────────────────────┬─────────────────────────────────┘   │
│                           │                                      │
│  ┌────────────────────────▼─────────────────────────────────┐   │
│  │              LONGEVITY BRIDGE (NEW - V4)                  │   │
│  │                                                           │   │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │   │
│  │  │ Significance │  │ Consolidation│  │ Schema         │  │   │
│  │  │ Scorer       │  │ Engine       │  │ Versioning     │  │   │
│  │  └──────┬──────┘  └──────┬───────┘  └───────┬────────┘  │   │
│  │         │                │                   │            │   │
│  │  ┌──────▼──────┐  ┌─────▼────────┐  ┌──────▼─────────┐  │   │
│  │  │ Memory      │  │ Forgetting   │  │ Encryption     │  │   │
│  │  │ Hierarchy   │  │ Protocol     │  │ Rotation       │  │   │
│  │  └──────┬──────┘  └──────┬───────┘  └───────┬────────┘  │   │
│  │         │                │                   │            │   │
│  │  ┌──────▼──────┐  ┌─────▼────────┐  ┌──────▼─────────┐  │   │
│  │  │ Storage     │  │ Embedding    │  │ Integrity      │  │   │
│  │  │ Budget      │  │ Migration    │  │ Verification   │  │   │
│  │  └─────────────┘  └──────────────┘  └────────────────┘  │   │
│  │                                                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           │                                      │
│  ┌────────────────────────▼─────────────────────────────────┐   │
│  │              PERSISTENCE LAYER (NEW - V4)                 │   │
│  │                                                           │   │
│  │  ┌─────────────────────────────────────────────────────┐ │   │
│  │  │  SQLite Backing Store (long-term structured data)    │ │   │
│  │  │  ├── memories (hierarchical, layer-tagged)           │ │   │
│  │  │  ├── schema_versions (migration history)             │ │   │
│  │  │  ├── encryption_keys (rotated, historical)           │ │   │
│  │  │  ├── consolidation_log (what was compressed when)    │ │   │
│  │  │  ├── embedding_models (version tracking)             │ │   │
│  │  │  └── integrity_proofs (Merkle roots, checksums)      │ │   │
│  │  └─────────────────────────────────────────────────────┘ │   │
│  │                                                           │   │
│  │  ┌─────────────────────────────────────────────────────┐ │   │
│  │  │  .amem File (hot path, binary, mmap-accessible)      │ │   │
│  │  │  Same V3 format, now with version field active       │ │   │
│  │  └─────────────────────────────────────────────────────┘ │   │
│  │                                                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 The Dual-Store Architecture Decision

**Critical design choice: `.amem` binary + SQLite, not one or the other.**

The `.amem` file remains the HOT PATH — the thing that gets mmap'd for sub-millisecond queries during active sessions. It holds the current session's raw events, recent episodes, and the active index set. This is unchanged from V3.

SQLite becomes the COLD PATH — the long-term structured store for compressed memories, consolidation logs, schema versions, and everything that needs to survive decades. SQLite was chosen because:
- It's the most widely deployed database engine in human history
- The file format has a 2050+ longevity guarantee from the SQLite consortium
- It supports encryption (via SQLCipher), full-text search, JSON columns, and WAL mode
- A single `.sqlite` file is as portable as `.amem` — one file, no server, travels with you
- It's already the backing store for AgenticTime and AgenticContract

The user's cognitive data lives in TWO files:
```
~/.agentic/memory/
├── {project}.amem          # Hot: current session, recent events, active indexes
└── {project}.longevity.db  # Cold: compressed hierarchy, proofs, migrations
```

The `.amem` file is the CACHE. The `.longevity.db` is the TRUTH. If the `.amem` file is lost, it can be rebuilt from the SQLite store. If the SQLite store is lost, the `.amem` file preserves recent history while the Phoenix Protocol gathers traces for reconstruction.

---

## 4. THE MEMORY HIERARCHY ENGINE

### 4.1 Six Layers (Implemented Inside SQLite)

```sql
-- The core memories table with hierarchical layers
CREATE TABLE memories (
    id              TEXT PRIMARY KEY,        -- ULID (time-sortable, unique)
    layer           INTEGER NOT NULL,        -- 0=Raw, 1=Episode, 2=Summary, 3=Pattern, 4=Trait, 5=Identity
    content         TEXT NOT NULL,           -- The memory content (JSON)
    content_type    TEXT NOT NULL,           -- 'event', 'episode', 'summary', 'pattern', 'trait', 'identity'
    embedding       BLOB,                   -- Float32 vector (for semantic search)
    embedding_model TEXT,                   -- Which model generated this embedding
    significance    REAL NOT NULL DEFAULT 0.5, -- 0.0 to 1.0, computed by scorer
    access_count    INTEGER DEFAULT 0,      -- How many times retrieved
    last_accessed   TEXT,                   -- ISO 8601 timestamp
    created_at      TEXT NOT NULL,          -- When this memory was created
    original_ids    TEXT,                   -- JSON array of source memory IDs (for compressed memories)
    session_id      TEXT,                   -- Session that created this memory
    project_id      TEXT NOT NULL,          -- Project isolation (canonical-path hash)
    metadata        TEXT,                   -- JSON blob for extensible metadata
    encryption_key_id TEXT,                 -- Which key encrypted this (NULL = plaintext)
    schema_version  INTEGER NOT NULL DEFAULT 1
);

-- Indexes for each query pattern
CREATE INDEX idx_memories_layer ON memories(layer);
CREATE INDEX idx_memories_project ON memories(project_id);
CREATE INDEX idx_memories_created ON memories(created_at);
CREATE INDEX idx_memories_significance ON memories(significance);
CREATE INDEX idx_memories_session ON memories(session_id);
CREATE INDEX idx_memories_layer_created ON memories(layer, created_at);

-- FTS5 for full-text search (replaces BM25 index on raw content)
CREATE VIRTUAL TABLE memories_fts USING fts5(
    content,
    content_id=memories,
    content_rowid=rowid
);

-- Consolidation log: what was compressed, when, and why
CREATE TABLE consolidation_log (
    id              TEXT PRIMARY KEY,
    from_layer      INTEGER NOT NULL,
    to_layer        INTEGER NOT NULL,
    memories_processed INTEGER NOT NULL,
    memories_created   INTEGER NOT NULL,
    compression_ratio  REAL,
    algorithm       TEXT NOT NULL,
    executed_at     TEXT NOT NULL,
    duration_ms     INTEGER
);

-- Embedding model registry (for migration)
CREATE TABLE embedding_models (
    model_id        TEXT PRIMARY KEY,
    model_name      TEXT NOT NULL,
    dimension       INTEGER NOT NULL,
    provider        TEXT,                   -- 'local', 'openai', 'anthropic', etc.
    registered_at   TEXT NOT NULL,
    retired_at      TEXT,                   -- NULL = still active
    mapping_to      TEXT                    -- If retired, which model maps to this one
);

-- Schema versioning
CREATE TABLE schema_versions (
    version         INTEGER PRIMARY KEY,
    applied_at      TEXT NOT NULL,
    description     TEXT,
    migration_sql   TEXT                    -- The SQL that was run
);
```

### 4.2 Significance Scorer

This is the intelligence that makes memory longevity work. Without it, compression is just deletion. With it, compression is WISDOM — knowing what matters.

```
SIGNIFICANCE SCORING MODEL:
═══════════════════════════

Score = weighted combination of:

  Recency Factor (0.0 - 1.0)
  ├── Exponential decay: e^(-λ × days_since_creation)
  ├── λ = 0.01 (slow decay, ~70 day half-life)
  └── Recent events naturally score higher

  Access Frequency (0.0 - 1.0)
  ├── log(access_count + 1) / log(max_access + 1)
  ├── Logarithmic: frequent access matters but diminishing returns
  └── Events retrieved often are important

  Referential Weight (0.0 - 1.0)
  ├── Number of other memories that reference this one
  ├── A fact that caused 10 decisions is more significant than one that caused 0
  └── PageRank-like: importance flows through the causal graph

  Causal Depth (0.0 - 1.0)
  ├── How deep is this in a decision chain?
  ├── Root causes score higher than leaf observations
  └── Decisions > Facts > Observations for causal weight

  Emotional Valence (0.0 - 1.0)
  ├── Detected emotional significance in content
  ├── "I love this approach" > "we used approach X"
  └── User-marked memories get max emotional score

  Contradiction Signal (0.0 - 1.0)
  ├── Memories involved in supersession chains
  ├── A belief that was revised is more significant than one that wasn't
  └── The revision history itself is significant

  Uniqueness (0.0 - 1.0)
  ├── How dissimilar is this from its neighbors?
  ├── Redundant memories score low (they'll merge in compression)
  └── Outlier memories that don't fit patterns are preserved longer

FINAL SCORE:
  significance = 0.15 × recency
               + 0.20 × access_frequency
               + 0.25 × referential_weight
               + 0.15 × causal_depth
               + 0.10 × emotional_valence
               + 0.10 × contradiction_signal
               + 0.05 × uniqueness

THRESHOLDS:
  > 0.8  → IMMUNE from compression (preserved at current layer)
  0.5-0.8 → Normal consolidation schedule
  0.2-0.5 → Accelerated consolidation (compress sooner)
  < 0.2  → Candidate for safe forgetting (after verification)
```

### 4.3 Consolidation Schedule

```
NIGHTLY (2 AM local):
  Raw → Episodes
  ├── Group events by session + topic similarity
  ├── Create episode summaries
  ├── Preserve events with significance > 0.8
  └── Target: 5:1 compression (5 events → 1 episode)

WEEKLY (Sunday 3 AM):
  Episodes → Summaries
  ├── Merge related episodes into key-point summaries
  ├── Extract emerging patterns
  ├── Preserve episodes with significance > 0.7
  └── Target: 10:1 compression

MONTHLY (1st of month, 4 AM):
  Summaries → Patterns
  ├── Crystallize behavioral patterns from summaries
  ├── Identify preferences, habits, recurring decisions
  ├── Preserve summaries with significance > 0.6
  └── Target: 20:1 compression

QUARTERLY (Jan/Apr/Jul/Oct):
  Patterns → Traits
  ├── Distill identity-level attributes from patterns
  ├── "User prefers Rust over Go" (from 47 instances)
  ├── Preserve patterns with significance > 0.5
  └── Target: 100:1 compression

ANNUAL:
  Traits → Identity review
  ├── Human-in-the-loop review of identity core
  ├── "Is this still who the user is?"
  ├── Manual confirmation required for trait changes
  └── Identity layer never auto-compressed
```

---

## 5. SCHEMA VERSIONING AND FORMAT EVOLUTION

### 5.1 The Version Promise

**Any `.amem` file or `.longevity.db` created by any version of AgenticMemory will be readable by any future version.**

This is non-negotiable. It's the difference between a real longevity guarantee and marketing.

### 5.2 Format Versioning Strategy

The `.amem` header already has a `version: u32` field at offset `0x04`. Currently hardcoded to `1`. The longevity engine activates this:

```
VERSION EVOLUTION PLAN:
═══════════════════════

Version 1 (current):  V3 format — flat node table, edge table, content block, indexes
Version 2 (V4):       + layer field in node table (1 byte per node)
                      + significance field (f32 per node)
                      + embedding_model_id in header
Version 3 (future):   + encryption envelope around content block
                      + compressed index sections
Version N:            Reader ALWAYS supports all previous versions.
                      Writer ALWAYS writes the latest version.
                      Migration runs automatically on open.
```

### 5.3 Migration Engine

```
ON FILE OPEN:
  1. Read version from header
  2. If version < CURRENT_VERSION:
     a. Create backup: {file}.v{old_version}.bak
     b. Run migration chain: v1→v2→v3→...→vN
     c. Update header version
     d. Write migrated file
     e. Log migration in consolidation_log
  3. If version == CURRENT_VERSION: open normally
  4. If version > CURRENT_VERSION: error (newer software needed)

MIGRATION RULES:
  - Migrations are ADDITIVE ONLY. New fields get defaults.
  - No field is ever removed. Deprecated fields become ignored.
  - Each migration is a pure function: old_bytes → new_bytes
  - Each migration is tested with real V(N-1) files in CI
  - The test suite carries forward ONE test file per version forever
```

### 5.4 SQLite Schema Migration

```sql
-- The schema_versions table tracks every migration
-- On DB open: check max(version) vs CURRENT_SCHEMA_VERSION
-- If behind, run migrations sequentially

-- Migration example: v1 → v2
INSERT INTO schema_versions (version, applied_at, description, migration_sql)
VALUES (2, datetime('now'), 'Add embedding_model tracking', '
  ALTER TABLE memories ADD COLUMN embedding_model TEXT;
  ALTER TABLE memories ADD COLUMN embedding_model_version TEXT;
');
```

---

## 6. EMBEDDING MIGRATION (The Silent Killer)

This is the problem nobody in the AI memory space is talking about. Embeddings are the backbone of semantic search. But embedding models change every 6-12 months. If you embedded memories with `text-embedding-ada-002` in 2026 and switch to `text-embedding-3-large` in 2027, your old vectors are **meaningless** in the new space.

### 6.1 The Embedding Registry

Every memory records WHICH model generated its embedding. The `embedding_models` table tracks every model ever used.

### 6.2 Migration Strategies

```
STRATEGY 1: LAZY RE-EMBEDDING (Recommended for most cases)
══════════════════════════════════════════════════════════

When a new embedding model is registered:
  - New memories use the new model
  - Old memories keep their old embeddings
  - When an old memory is ACCESSED, re-embed it with the new model
  - Background task re-embeds high-significance memories proactively

Cost: Spread over time. No big-bang migration.
Risk: Mixed-model search results until fully migrated.

STRATEGY 2: PROJECTION MAPPING
══════════════════════════════

Train a lightweight linear mapping: old_space → new_space
  - Use memories that have BOTH old and new embeddings as training pairs
  - Apply projection to remaining old embeddings
  - Fast (~1000 projections/second) and approximate

Cost: One-time training + batch projection.
Risk: Some accuracy loss from imperfect mapping.

STRATEGY 3: SEMANTIC ANCHORS
════════════════════════════

Keep a set of "anchor" memories that are ALWAYS re-embedded with every new model.
  - These anchors form a bridge between embedding spaces
  - Old memories are searched relative to their nearest anchor
  - Anchors are high-significance, diverse, and representative

Cost: Minimal (100-1000 anchor re-embeddings per model change).
Risk: Lower accuracy for memories far from any anchor.

IMPLEMENTATION:
  - V4 uses Strategy 1 (lazy) by default
  - Strategy 2 available as opt-in for users who want faster migration
  - Strategy 3 is the fallback when the old model is no longer available
```

---

## 7. ENCRYPTION ROTATION

### 7.1 Key Management

```
KEY LIFECYCLE:
═════════════

  Generate Key K1 (2026) → Active
  │
  ├── All new memories encrypted with K1
  │
  │ [1 year later]
  │
  Generate Key K2 (2027) → Active
  K1 → Retired (kept for decryption)
  │
  ├── New memories: K2
  ├── Old memories: still K1 (lazy re-encryption)
  ├── Accessed old memories: re-encrypted to K2
  │
  │ [1 year later]
  │
  Generate Key K3 (2028) → Active
  K2 → Retired
  K1 → Still kept (some memories not yet re-encrypted)
  │
  │ [After all K1 memories re-encrypted]
  │
  K1 → Archived (kept in key history, never deleted)

KEY STORAGE (in SQLite, encrypted with master password):
  CREATE TABLE encryption_keys (
      key_id      TEXT PRIMARY KEY,
      algorithm   TEXT NOT NULL,        -- 'AES-256-GCM', 'ChaCha20-Poly1305'
      created_at  TEXT NOT NULL,
      retired_at  TEXT,
      status      TEXT NOT NULL,        -- 'active', 'retired', 'archived'
      key_blob    BLOB NOT NULL         -- Encrypted with master key
  );

MASTER KEY:
  - Derived from user passphrase via Argon2id
  - Never stored. Re-derived on each unlock.
  - If user forgets passphrase → unrecoverable (by design)
  - Optional: recovery key (printed, stored physically)
```

---

## 8. THE CONSOLIDATION DAEMON (V4)

The current AgenticMemory has a daemon for continuous extraction. V4 extends this into a full consolidation daemon that handles compression, budget management, and integrity.

### 8.1 Daemon Architecture

```
CONSOLIDATION DAEMON:
═════════════════════

  ┌───────────────────────────────────────────────────┐
  │                  DAEMON SCHEDULER                  │
  │                                                     │
  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐ │
  │  │ Nightly  │  │ Weekly   │  │ On-Demand        │ │
  │  │ Tasks    │  │ Tasks    │  │ Tasks            │ │
  │  └────┬─────┘  └────┬─────┘  └────────┬─────────┘ │
  │       │              │                  │           │
  └───────┼──────────────┼──────────────────┼───────────┘
          │              │                  │
  ┌───────▼──────────────▼──────────────────▼───────────┐
  │                    TASK QUEUE                         │
  │                                                       │
  │  ┌──────────────────────────────────────────────────┐│
  │  │ 1. Layer Consolidation (Raw→Episode→Summary→...) ││
  │  │ 2. Significance Recalculation                    ││
  │  │ 3. Index Reorganization                          ││
  │  │ 4. Embedding Migration (lazy re-embed)           ││
  │  │ 5. Encryption Rotation (lazy re-encrypt)         ││
  │  │ 6. Budget Check + Projection                     ││
  │  │ 7. Integrity Verification (Merkle spot-checks)   ││
  │  │ 8. .amem ↔ SQLite Sync                           ││
  │  │ 9. Garbage Collection (orphaned references)       ││
  │  │ 10. Self-Diagnostics + Health Report             ││
  │  └──────────────────────────────────────────────────┘│
  │                                                       │
  └───────────────────────────────────────────────────────┘
```

### 8.2 .amem ↔ SQLite Sync Protocol

This is the critical bridge between the hot path and cold path:

```
SYNC DIRECTION 1: .amem → SQLite (Nightly)
════════════════════════════════════════════
  1. Read all events from .amem WAL that haven't been synced
  2. Insert into SQLite memories table (layer = Raw, significance = computed)
  3. Mark events as synced in .amem WAL metadata
  4. Events older than 72 hours in .amem: mark for tier promotion

SYNC DIRECTION 2: SQLite → .amem (On session start)
════════════════════════════════════════════════════
  1. Load recent high-significance memories from SQLite
  2. Load relevant patterns/traits for current project context
  3. Populate .amem hot cache with this pre-loaded context
  4. Ghost Writer generates context file from this pre-loaded set

CONFLICT RESOLUTION:
  - .amem is authoritative for events < 72 hours old
  - SQLite is authoritative for everything older
  - Integrity hashes resolve any discrepancy
```

---

## 9. STORAGE BUDGET MANAGEMENT

### 9.1 Budget Allocation

```
DEFAULT BUDGET: 10 GB per project (configurable)

LAYER ALLOCATION:
  Raw (Layer 0):      15% = 1.5 GB    ← Active session cache
  Episodes (Layer 1): 25% = 2.5 GB    ← Recent memory
  Summaries (Layer 2):25% = 2.5 GB    ← Working memory
  Patterns (Layer 3): 20% = 2.0 GB    ← Long-term patterns
  Traits (Layer 4):   10% = 1.0 GB    ← Identity attributes
  Identity (Layer 5):  5% = 0.5 GB    ← Core identity

PROJECTIONS (example: developer copilot):
  Year 1:  ~225 MB (well within budget)
  Year 5:  ~600 MB (healthy)
  Year 10: ~1.2 GB (comfortable)
  Year 20: ~2.2 GB (22% of budget — excellent)

ALERTS:
  80% of any layer → Warning (accelerate consolidation)
  95% of any layer → Critical (emergency compression)
  95% total         → User notification (increase budget or review)
```

---

## 10. IMPLEMENTATION PHASES

### Phase 1: Foundation (V4.0) — The Dual Store

**Goal:** Introduce SQLite backing without breaking V3.

- Add `longevity.db` creation alongside `.amem`
- Implement nightly sync: `.amem` WAL → SQLite Raw layer
- Add `layer` and `significance` fields to the memory data model
- Implement basic significance scorer (recency + access count only)
- Add schema versioning infrastructure (migration engine)
- Add `embedding_model` tracking to all new memories
- Ship as AgenticMemory 0.5.0

**Success criteria:** All V3 tests still pass. SQLite store accumulates memories. No user-facing behavior changes. New `amem longevity-stats` CLI command shows dual-store health.

### Phase 2: Compression (V4.1) — The Hierarchy

**Goal:** Implement the 6-layer compression hierarchy.

- Implement EventGrouping algorithm (Raw → Episode)
- Implement TextSummarization (Episode → Summary) — uses LLM via configurable provider
- Implement PatternExtraction (Summary → Pattern) — pure algorithmic, no LLM
- Implement TraitDistillation (Pattern → Trait) — LLM-assisted
- Implement nightly consolidation task
- Implement weekly + monthly + quarterly schedules
- Implement significance scorer (full model with all 7 factors)
- Ship as AgenticMemory 0.6.0

**Success criteria:** After 1 week of normal use, Raw layer is compressed into Episodes. Significance scores are computed for all memories. Storage growth rate drops 50%+ vs V3. Compressed memories are searchable with same query patterns.

**LLM dependency note:** TextSummarization and TraitDistillation require LLM calls. These MUST be configurable (local model, API, or disabled). If disabled, compression falls back to pure algorithmic methods (keyword extraction, TF-IDF summaries). The system must work WITHOUT any LLM for compression — LLM just makes it better.

### Phase 3: Survival (V4.2) — The Guarantees

**Goal:** Make the 20-year promise real.

- Implement .amem format versioning (activate version field, write migration chain)
- Implement embedding migration (lazy re-embedding strategy)
- Implement encryption rotation (key management, lazy re-encryption)
- Implement storage budget management and projection
- Implement integrity verification (periodic Merkle spot-checks)
- Implement safe forgetting protocol (significance < 0.2 after all checks)
- Carry forward V1 test files in CI (the "forever test")
- Ship as AgenticMemory 0.7.0

**Success criteria:** Can migrate a V3 `.amem` file to V4 format automatically. Can switch embedding models with zero data loss. Can project storage needs for 20 years. CI includes a test file from every previous format version.

### Phase 4: Intelligence (V4.3) — The Prophecy

**Goal:** Memory that sees what's coming.

- Implement predictive recall (pre-load memories you'll need based on session context)
- Implement memory dreams (idle-time consolidation and pattern discovery)
- Implement belief revision tracking (when a fact changes, trace impact)
- Implement self-awareness (what do I know? what are my gaps?)
- Ship as AgenticMemory 0.8.0

**This is where Memory stops being a storage system and becomes a cognitive system.**

---

## 11. NEW MCP TOOLS (V4)

```
LONGEVITY TOOLS:
  memory_longevity_stats       ← Storage budget, layer distribution, projections
  memory_longevity_project     ← Project storage needs for N years
  memory_longevity_health      ← Overall health score and recommendations
  memory_longevity_consolidate ← Trigger manual consolidation

HIERARCHY TOOLS:
  memory_hierarchy_query       ← Query at a specific layer (episodes, patterns, traits)
  memory_hierarchy_navigate    ← Drill down: trait → patterns → episodes → raw
  memory_hierarchy_significance ← Get/set significance for a memory

SCHEMA TOOLS:
  memory_schema_version        ← Current schema version and history
  memory_schema_migrate        ← Trigger migration (usually automatic)

EMBEDDING TOOLS:
  memory_embedding_status      ← Which models are in use, migration progress
  memory_embedding_migrate     ← Trigger embedding re-embedding for a model

INTEGRITY TOOLS:
  memory_verify_integrity      ← (Exists in V3, extended for SQLite)
  memory_integrity_report      ← Full integrity report across both stores
```

---

## 12. WHAT STAYS PRIVATE (Hydra Integration Points)

The longevity engine is OPEN SOURCE. It ships with AgenticMemory. But the following capabilities are reserved for Hydra and remain proprietary:

- **Omniscience Loop**: Cross-sister memory querying (Memory + Codebase + Identity + Time in one query)
- **Soul Persistence**: Hydra's ability to snapshot and resurrect its own cognitive state using Memory
- **Collective Consciousness**: Multi-agent shared memory pools (Invention 10)
- **Telepathic Memory**: Real-time memory sync between agents (Invention 12)
- **Consciousness Crystal**: The ultimate distillation of agent identity (Invention 23)

The open-source longevity engine gives every AgenticMemory user 20-year memory survival. The proprietary Hydra layer gives Agentralabs customers memory that TRANSCENDS individual agents.

---

## 13. RISK REGISTER

| Risk | Severity | Mitigation |
|------|----------|------------|
| LLM-dependent compression breaks when API changes | High | Fallback to pure algorithmic compression. Never REQUIRE LLM for longevity. |
| SQLite corruption | Medium | WAL mode + periodic backups + `.amem` as secondary source |
| Embedding model discontinued | High | Embedding registry + lazy re-embedding + projection mapping fallback |
| User loses master passphrase | Critical | Recovery key (printed), optional passphrase reset via identity verification |
| 20-year format becomes obsolete | Low | Version migration chain tested in CI with real files from every version |
| Consolidation daemon crashes mid-compression | Medium | Atomic transactions in SQLite. Originals only deleted after compressed versions verified. |
| Significance scorer assigns wrong weights | Medium | User can manually mark memories as significant. Override always wins. |

---

## 14. SUCCESS METRICS

```
YEAR 1:
  □ Storage growth rate: < 50% of V3 (compression working)
  □ Search quality: no degradation from compression
  □ Zero data loss across 1000 consolidation cycles
  □ Format migration: V3 → V4 automatic, tested, reversible

YEAR 5:
  □ Storage within 30% of budget projection
  □ At least 1 embedding model migration completed successfully
  □ At least 1 encryption key rotation completed
  □ Significance scorer accuracy: > 80% agreement with user feedback

YEAR 20:
  □ All memories from Year 1 still accessible
  □ Identity layer captures user's cognitive essence in < 1 MB
  □ Total storage: < 25 GB for heaviest use case
  □ Query time: < 100ms at any layer, any age
```

---

*Document: MEMORY-LONGEVITY-ARCHITECTURE.md*  
*The memory that never forgets. The memory that knows what to remember.*
