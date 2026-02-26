# .amem: 20-Year Lifelong Agent Memory — Vision & Roadmap

> **Status:** Internal vision document — NOT for public release
> **Author:** Omoshola (Agentralabs)
> **Created:** 2026-02-24
> **Last updated:** 2026-02-24

---

## The Goal

A portable, user-owned memory file (`.amem`) that an AI agent accumulates over
a lifetime of companionship with its human. Not cloud-locked. Not
platform-locked. A file the user owns, backs up, guards jealously — a digital
brain that any compatible agent can load.

**The feeling:** Opening a new AI tool in 2041 and it says *"I remember when we
built the agentic sisters together in 2026."*

**Core principles:**
1. **Zero friction** — memory recording happens automatically, no user action required
2. **User-owned** — the `.amem` file belongs to the user, not a platform
3. **Portable** — any compatible agent can load it, regardless of provider
4. **Private** — encrypted at rest, meaningless without the user's key
5. **Durable** — designed for 20-year lifespans, backwards-compatible evolution

---

## The Math

```
Average meaningful content per conversation:  ~10 KB
Conversations per day:                        ~5
Days over 20 years:                           ~7,300
Total conversations:                          ~36,500

Raw content:            ~365 MB
Session summaries:       ~50 MB
Weekly/monthly digests:  ~10 MB
Vector embeddings:      ~200 MB
Indexes + metadata:     ~100 MB
────────────────────────────────
Total:                  ~700 MB – 1.5 GB
```

A 2 GB budget is realistic. Even generous.

Starting size: **1-2 MB** (first days/weeks of use).
Mature size at 15-20 years: **~1-2 GB** with hierarchical summarization.

---

## Where .amem Is Today

- JSON-based graph file (nodes + edges)
- Stores facts, decisions, inferences, corrections, skills, episodes
- Session-based recording with auto-session on MCP connect
- File locking + merge-on-save for concurrent access
- PID-based session IDs for collision avoidance
- Single portable file

**Limitations:**
- JSON doesn't scale past ~50 MB
- No conversation capture (only tool calls + explicit adds)
- No hierarchical summarization
- No encryption
- No vector index for semantic search at scale
- File locking is a workaround (not native concurrency)

---

## Phased Roadmap

### Phase 1: Auto-Capture Conversations (NOW)

**Goal:** Every conversation from today forward gets remembered.

**What to capture:**
- User prompts (what was asked)
- Agent response context (what was decided and why)
- Tool calls and their outcomes (already partially done)
- Relationships between conversations ("continues the npm publishing work")
- Priority/emotional signals ("this is my personal goal")

**Implementation:**
- New node types: `prompt`, `response_context`, `conversation_thread`
- Auto-capture in the MCP protocol handler for every tool call and prompt
- Session episodes already summarize — extend to include conversation flow
- Zero friction: happens in the background, no user action needed

**Trade-offs:**
- More data per session (~10 KB vs ~2 KB today)
- File grows faster — acceptable given the 2 GB 20-year budget

---

### Phase 2: SQLite Migration

**Goal:** Swap JSON backing store for SQLite. Single file, same `.amem` extension.

**Why SQLite:**
- Still a single portable file (user can copy, back up, carry around)
- Native concurrent access (WAL mode) — kills the file locking workaround
- B-tree indexes for fast queries on millions of nodes
- Scales to terabytes
- Battle-tested for 20+ years (SQLite itself will outlast most software)
- ACID-compliant — no corruption on crash

**Schema:**
```sql
-- Core graph
CREATE TABLE nodes (
    id          INTEGER PRIMARY KEY,
    session_id  INTEGER NOT NULL,
    event_type  TEXT NOT NULL,
    content     TEXT NOT NULL,
    confidence  REAL DEFAULT 0.9,
    created_at  INTEGER NOT NULL,  -- unix timestamp
    accessed_at INTEGER,
    access_count INTEGER DEFAULT 0,
    superseded_by INTEGER REFERENCES nodes(id),
    embedding   BLOB    -- vector for semantic search
);

CREATE TABLE edges (
    source_id  INTEGER REFERENCES nodes(id),
    target_id  INTEGER REFERENCES nodes(id),
    edge_type  TEXT NOT NULL,
    weight     REAL DEFAULT 1.0,
    PRIMARY KEY (source_id, target_id, edge_type)
);

-- Session tracking
CREATE TABLE sessions (
    id         INTEGER PRIMARY KEY,
    started_at INTEGER NOT NULL,
    ended_at   INTEGER,
    metadata   TEXT    -- JSON blob
);

-- Indexes for fast retrieval
CREATE INDEX idx_nodes_session ON nodes(session_id);
CREATE INDEX idx_nodes_type    ON nodes(event_type);
CREATE INDEX idx_nodes_created ON nodes(created_at);
CREATE INDEX idx_edges_target  ON edges(target_id);
```

**Migration path:**
- Detect file format on open (JSON vs SQLite magic bytes)
- Auto-migrate JSON → SQLite on first load
- Backwards-compatible: old JSON files still load

---

### Phase 3: Hierarchical Summarization

**Goal:** Keep the file at ~2 GB even after 20 years. Compress old memories while preserving meaning.

**Memory hierarchy (mirrors human memory):**

```
Level 0: Raw interactions (prompts + responses)
         Kept hot for 30 days, then archived/compressed

Level 1: Session episodes (already exist)
         "We built auto-session for the sisters"
         Kept indefinitely

Level 2: Weekly/monthly digests (auto-generated)
         "February 2026: Focused on publishing pipeline,
          concurrent access, auto-session"
         Kept indefinitely

Level 3: Core knowledge (permanent, never expires)
         "User prefers opt-out over opt-in design"
         "Agentic sisters: memory, vision, codebase, identity"
```

**Auto-rollup schedule:**
- Daily: Summarize completed sessions into daily digest
- Weekly: Summarize daily digests into weekly digest
- Monthly: Summarize weekly digests into monthly digest
- Raw Level 0 data older than 30 days: compress (zstd) and archive
- Raw Level 0 data older than 1 year: delete (summaries retained)

**Importance-based retention:**
- Nodes with high access count or high confidence survive longer
- Core knowledge (skills, decisions, corrections) never expires
- Trivial interactions (ping, status checks) expire quickly

---

### Phase 4: Smart Retrieval

**Goal:** The agent just *knows* because it pulls the right memories at the right time.

**At conversation start:**
1. Load core knowledge (Level 3) — always available
2. Load recent session episodes (last 7 days)
3. Semantic search on user's first message → pull relevant memories
4. Temporal context → "last time we discussed X was on [date]"

**During conversation:**
- As topics emerge, background-query for related memories
- Surface relevant past decisions, corrections, preferences
- Link new conversation to existing threads

**Vector search:**
- Store embeddings in SQLite (BLOB column on nodes)
- Use a lightweight embedding model (e.g., sentence-transformers)
- Approximate nearest neighbor search for fast retrieval
- Optional: external vector index (FAISS/Annoy) as sidecar file

---

### Phase 5: Encryption at Rest

**Goal:** The `.amem` file is meaningless without the user's key.

**Approach:**
- AES-256-GCM encryption
- User provides a passphrase → derive key via Argon2
- SQLite encryption extension (SQLCipher) or page-level encryption
- Transparent: encrypt on write, decrypt on read
- Key never stored in the file — user must provide it

**Key management:**
- Passphrase-based (simplest, most portable)
- Optional: system keychain integration (macOS Keychain, Linux Secret Service)
- Optional: hardware key support (YubiKey, etc.)

**Backup safety:**
- Encrypted backups are safe to store in cloud (Dropbox, iCloud, etc.)
- File is useless without passphrase
- No metadata leaks — even file size is padded

---

## Design Principles

### Backwards Compatibility
Every phase must be backwards-compatible. A 2026 `.amem` file must load in
2041. Format version is stored in the file header. Migration is automatic and
non-destructive.

### User Sovereignty
The user owns their memory. No phone-home. No cloud dependency. No platform
lock-in. The `.amem` file is self-contained. Export is trivial (it's already a
file). Import is trivial (just copy it).

### Agent Agnosticism
Any AI agent that speaks the `.amem` protocol can load the file. Claude, GPT,
Gemini, local models — the memory belongs to the user, not the model provider.
The MCP tool interface is the standard contract.

### Graceful Degradation
If the agent can't load the full file (context limits), it degrades gracefully:
1. Load Level 3 (core knowledge) — always fits
2. Load Level 2 (monthly digests) — fits in most contexts
3. Load Level 1 (session episodes) — as space allows
4. Load Level 0 (raw interactions) — only recent, only if relevant

### Privacy by Default
- Auto-session records automatically (opt-out via `--mode minimal`)
- Encryption is encouraged but optional (Phase 5)
- No data leaves the local machine unless the user explicitly exports
- No telemetry, no analytics, no tracking

---

## Success Metrics

| Metric | Year 1 | Year 5 | Year 20 |
|--------|--------|--------|---------|
| File size | 5-20 MB | 100-300 MB | 1-2 GB |
| Nodes | ~5,000 | ~50,000 | ~500,000 |
| Sessions | ~300 | ~2,000 | ~15,000 |
| Retrieval latency | <100ms | <200ms | <500ms |
| Context accuracy | 70% | 85% | 95% |

---

## The 20-Year Promise

In 2046, a user opens their `.amem` file and their agent says:

*"I see we've been working together since February 2026. You started with
four sister projects — memory, vision, codebase, and identity. Your first
priority was making memory work automatically so nothing would be forgotten.
You always preferred opt-out over opt-in, simple solutions over complex ones.
Over the years, we built [everything that followed]. What would you like to
work on today?"*

That's the goal.
