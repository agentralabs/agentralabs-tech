# TOKEN CONSERVATION ARCHITECTURE
## The Sacred Covenant: Every Sister Must Be Token-Minimal

> **Principle:** If an agent asks the same question twice and pays full cost both times, we have failed. If an operation costs more tokens than the information extracted, we have failed. If cost scales with data size rather than answer complexity, we have failed.

---

## THE UNIVERSAL TOKEN CONSERVATION STACK

Every sister implements a 5-layer cost escalation strategy. Cheapest first. Expensive last.

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                     UNIVERSAL COST ESCALATION LAYERS                       ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  LAYER 0: CACHE HIT (0 tokens)                                           ║
║  ═══════════════════════════════                                          ║
║  Question asked before? Return cached answer. Zero cost.                  ║
║  State unchanged since last query? Return cached state. Zero cost.        ║
║  Same user, same context, same question = same answer = free.             ║
║                                                                           ║
║  LAYER 1: INDEX LOOKUP (near-zero tokens)                                 ║
║  ═════════════════════════════════════════                                 ║
║  Don't search data. Search the index. Return pointers, not content.       ║
║  Memory: embedding similarity → return memory IDs, not memories.          ║
║  Codebase: graph traversal → return file paths, not file contents.        ║
║  Index lookup = O(log n). Data scan = O(n). Always index first.          ║
║                                                                           ║
║  LAYER 2: INTENT-SCOPED EXTRACTION (proportional cost)                    ║
║  ════════════════════════════════════════════════════════                  ║
║  Before ANY extraction, declare intent. Extract ONLY what matches.        ║
║  "Get function signature" → don't return function body.                   ║
║  "Get user name" → don't return full user profile.                        ║
║  Cost scales with ANSWER size, not SOURCE size.                           ║
║                                                                           ║
║  LAYER 3: DELTA RETRIEVAL (change-proportional cost)                      ║
║  ═════════════════════════════════════════════════════                     ║
║  What changed since last query? Return only the diff.                     ║
║  Memory: new memories since timestamp, not all memories.                  ║
║  Codebase: changed files since commit, not all files.                     ║
║  Monitoring scales with change volume, not data volume.                   ║
║                                                                           ║
║  LAYER 4: FULL EXTRACTION (last resort)                                   ║
║  ══════════════════════════════════════                                    ║
║  Only when Layers 0-3 cannot satisfy the request.                         ║
║  Must be explicitly justified.                                            ║
║  Must be logged for audit.                                                ║
║  Must trigger cache population for future queries.                        ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## SISTER-SPECIFIC TOKEN STRATEGIES

### 1. AGENTICMEMORY — The Goldfish Killer

```
CURRENT WASTE PATTERN:
  "What did the user say about X?"
  → Retrieve all memories tagged X
  → Return 50 memories × 500 tokens = 25,000 tokens
  → LLM reads all, extracts answer worth 50 tokens
  → Waste ratio: 500:1

TOKEN-CONSERVATIVE PATTERN:
  Layer 0: Check query cache (exact question asked before?)
  Layer 1: Semantic search → return memory IDs only (50 IDs = 50 tokens)
  Layer 2: Intent-scoped: "extract fact about X" → return facts, not memories
  Layer 3: Delta: "new memories about X since last query"
  Layer 4: Full retrieval only if synthesizing new insight

GUARANTEES:
  □ memory_query returns IDs by default, content on demand
  □ memory_similar returns similarity scores, not full content
  □ memory_temporal returns count + IDs, not full memories
  □ Second query for same topic: 10x cheaper than first
  □ Repeated queries: amortized to near-zero
```

### 2. AGENTICVISION — The Perception Revolution

```
(Already documented in ADDENDUM-PERCEPTION-REVOLUTION.md)

GUARANTEES:
  □ Layer 0: Semantic DOM extraction (0 vision tokens)
  □ Layer 1: Site Grammar (amortized to near-zero)
  □ Layer 2: Intent-scoped extraction
  □ Layer 3: Delta vision (only perceive changes)
  □ Layer 4: Screenshot (last resort, region-scoped)
  □ Price lookup on Amazon: ≤20 tokens after first visit
```

### 3. AGENTICCODEBASE — The Code Librarian

```
CURRENT WASTE PATTERN:
  "What does function X do?"
  → Build entire code graph
  → Traverse all files
  → Return full file contents
  → Cost: 50,000+ tokens for one function

TOKEN-CONSERVATIVE PATTERN:
  Layer 0: Cache hit on function signature
  Layer 1: Graph index lookup → return file path + line numbers only
  Layer 2: Intent-scoped: "get signature" vs "get implementation" vs "get docs"
  Layer 3: Delta: "changed functions since last scan"
  Layer 4: Full file only if analyzing control flow

GUARANTEES:
  □ codebase_search returns file:line references, not content
  □ codebase_symbol returns signature, not implementation
  □ codebase_dependencies returns graph edges, not file contents
  □ Graph built once per project, cached indefinitely
  □ Incremental updates on file changes (not full rebuild)
```

### 4. AGENTICIDENTITY — The Identity Cache

```
TOKEN-CONSERVATIVE PATTERN:
  Layer 0: Identity cache (user context cached per session)
  Layer 1: Attribute lookup by key (not full profile scan)
  Layer 2: Intent-scoped: "get auth level" vs "get full profile"
  Layer 3: Delta: "changed attributes since last check"
  Layer 4: Full profile only on session init

GUARANTEES:
  □ identity_get returns single attribute, not full profile
  □ identity_check returns boolean, not evidence
  □ identity_verify returns pass/fail, not reasoning chain
  □ Session context cached: 0 tokens after first request
```

### 5. AGENTICTIME — The Temporal Index

```
TOKEN-CONSERVATIVE PATTERN:
  Layer 0: Timestamp cache (now, session_start, etc.)
  Layer 1: Range bounds lookup (start/end only)
  Layer 2: Intent-scoped: "get duration" vs "get all events in range"
  Layer 3: Delta: "events since last query"
  Layer 4: Full timeline only for visualization

GUARANTEES:
  □ time_now: cached per request, not recomputed
  □ time_range: returns count + bounds, not all entries
  □ time_query: returns timestamps, not event contents
```

### 6. AGENTICCONTRACT — The Policy Cache

```
TOKEN-CONSERVATIVE PATTERN:
  Layer 0: Policy decision cache (same request = same answer)
  Layer 1: Policy ID lookup (not policy content)
  Layer 2: Intent-scoped: "is allowed?" vs "explain why"
  Layer 3: Delta: "policy changes since last check"
  Layer 4: Full policy only for audit/explanation

GUARANTEES:
  □ contract_check returns boolean, not policy text
  □ contract_evaluate returns verdict, not reasoning
  □ Repeated policy checks: O(1) from cache
  □ Policy unchanged = free to check
```

### 7. AGENTICCOMM — The Message Router

```
TOKEN-CONSERVATIVE PATTERN:
  Layer 0: Routing table cache
  Layer 1: Address lookup (not message history)
  Layer 2: Intent-scoped: "send" vs "send with confirmation"
  Layer 3: Delta: "new messages since last check"
  Layer 4: Full conversation only for context building

GUARANTEES:
  □ comm_send returns receipt, not echo
  □ comm_check returns count, not content
  □ comm_route returns address, not path reasoning
```

### 8. AGENTICPLANNING — The Goal Index

```
TOKEN-CONSERVATIVE PATTERN:
  Layer 0: Active goal cache (current focus)
  Layer 1: Goal ID lookup (not full goal tree)
  Layer 2: Intent-scoped: "next action" vs "full plan"
  Layer 3: Delta: "goal changes since last check"
  Layer 4: Full plan only for replanning

GUARANTEES:
  □ planning_next returns single action, not full plan
  □ planning_status returns state, not history
  □ planning_check returns boolean, not evidence
  □ Stable plans: 0 tokens to query
```

### 9. AGENTICCOGNITION — The Model Cache

```
TOKEN-CONSERVATIVE PATTERN:
  Layer 0: User model cache (preferences, patterns)
  Layer 1: Attribute lookup (not full model)
  Layer 2: Intent-scoped: "get preference" vs "explain preference"
  Layer 3: Delta: "model changes since last interaction"
  Layer 4: Full model only for major decisions

GUARANTEES:
  □ cognition_preference returns value, not reasoning
  □ cognition_predict returns prediction, not confidence chain
  □ Stable user: near-zero tokens after first session
```

### 10. AGENTICREALITY — The Context Cache

```
TOKEN-CONSERVATIVE PATTERN:
  Layer 0: Environment cache (deployment context)
  Layer 1: Capability lookup (not full environment scan)
  Layer 2: Intent-scoped: "can do X?" vs "how to do X?"
  Layer 3: Delta: "environment changes since last check"
  Layer 4: Full scan only on deployment change

GUARANTEES:
  □ reality_check returns boolean, not capability list
  □ reality_env returns single value, not full environment
  □ Same deployment: 0 tokens after first scan
```

### 11. AGENTICFORGE — The Blueprint Cache

```
TOKEN-CONSERVATIVE PATTERN:
  Layer 0: Blueprint cache (recent blueprints by intent hash)
  Layer 1: Blueprint ID lookup (not full blueprint)
  Layer 2: Intent-scoped: "get file list" vs "get full skeleton"
  Layer 3: Delta: "blueprint changes since last version"
  Layer 4: Full blueprint only for initial generation

GUARANTEES:
  □ forge_skeleton returns structure, not content
  □ forge_dependencies returns list, not resolution graph
  □ Similar intent: return cached blueprint (0 generation tokens)
  □ Second build: 10x cheaper than first
```

### 12. AGENTICAEGIS — The Validation Cache

```
TOKEN-CONSERVATIVE PATTERN:
  Layer 0: Validation cache (same code = same result)
  Layer 1: Error index lookup (not full error context)
  Layer 2: Intent-scoped: "is valid?" vs "explain errors"
  Layer 3: Delta: "validate changes only"
  Layer 4: Full validation only on new code

GUARANTEES:
  □ aegis_check returns boolean, not error list
  □ aegis_streaming validates delta, not accumulated
  □ Unchanged code: 0 tokens to re-validate
  □ Small change: proportional cost, not full re-scan
```

### 13. AGENTICVERITAS — The Intent Cache

```
TOKEN-CONSERVATIVE PATTERN:
  Layer 0: Intent cache (same question = same intent spec)
  Layer 1: Domain lookup (not full compilation)
  Layer 2: Intent-scoped: "get domain" vs "get full spec"
  Layer 3: Delta: "clarification updates only"
  Layer 4: Full compilation only on novel intent

GUARANTEES:
  □ veritas_classify returns domain, not full spec
  □ veritas_ambiguity returns count, not full analysis
  □ Repeated question: 0 compilation tokens
  □ Similar question: partial cache hit
```

### 14. AGENTICEVOLVE — The Pattern Cache

```
TOKEN-CONSERVATIVE PATTERN:
  Layer 0: Pattern cache (signature → pattern ID)
  Layer 1: Pattern ID lookup (not pattern content)
  Layer 2: Intent-scoped: "has pattern?" vs "get pattern body"
  Layer 3: Delta: "new patterns since last query"
  Layer 4: Full pattern retrieval only for code generation

GUARANTEES:
  □ evolve_match returns pattern ID + confidence, not body
  □ evolve_has returns boolean, not pattern details
  □ Second build: 80% from cache, 20% generated
  □ Hundredth build: 99% from cache
```

---

## THE ENFORCEMENT CONTRACT

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                     TOKEN CONSERVATION ENFORCEMENT                         ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  RULE 1: NEVER return full content when ID/pointer suffices.             ║
║                                                                           ║
║  RULE 2: NEVER re-compute when cache can answer.                         ║
║                                                                           ║
║  RULE 3: NEVER scan data when index can answer.                          ║
║                                                                           ║
║  RULE 4: NEVER return full state when delta suffices.                    ║
║                                                                           ║
║  RULE 5: ALWAYS declare intent BEFORE any extraction.                    ║
║                                                                           ║
║  RULE 6: ALWAYS log token cost for every MCP call (audit trail).         ║
║                                                                           ║
║  RULE 7: ALWAYS populate cache after expensive operations.               ║
║                                                                           ║
║  RULE 8: Second query MUST be cheaper than first query.                  ║
║                                                                           ║
║  RULE 9: Unchanged state MUST be free to query.                          ║
║                                                                           ║
║  RULE 10: Cost MUST scale with answer complexity, not source size.       ║
║                                                                           ║
║  VIOLATION = BUG. NOT OPTIMIZATION. NOT ACCEPTABLE.                      ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## MCP TOOL PATTERNS FOR TOKEN CONSERVATION

Every MCP tool should follow this pattern:

```rust
// BAD: Returns full content by default
pub async fn memory_query(query: &str) -> Vec<Memory> {
    self.store.search(query).await  // Returns full memories
}

// GOOD: Returns IDs by default, content on demand
pub async fn memory_query(
    query: &str,
    include_content: bool,  // Default: false
    max_results: usize,     // Default: 10
    since: Option<i64>,     // Delta: only new since timestamp
) -> QueryResult {
    // Layer 0: Check cache
    if let Some(cached) = self.cache.get(query) {
        return cached.clone();
    }
    
    // Layer 1: Index lookup
    let ids = self.index.search(query, max_results).await;
    
    // Layer 2: Intent-scoped
    if !include_content {
        return QueryResult::ids_only(ids);  // ~50 tokens
    }
    
    // Layer 3: Delta
    let ids = if let Some(ts) = since {
        ids.into_iter().filter(|id| self.store.created_after(id, ts)).collect()
    } else {
        ids
    };
    
    // Layer 4: Full extraction (only if explicitly requested)
    let memories = self.store.get_many(&ids).await;
    
    // Populate cache for next time
    self.cache.insert(query, memories.clone());
    
    QueryResult::with_content(memories)
}
```

---

## MEASUREMENT FRAMEWORK

Every sister must track:

```rust
pub struct TokenMetrics {
    /// Total tokens used in this session
    pub total_tokens: u64,
    
    /// Tokens saved by cache hits
    pub cache_savings: u64,
    
    /// Tokens saved by index lookups
    pub index_savings: u64,
    
    /// Tokens saved by intent scoping
    pub scope_savings: u64,
    
    /// Tokens saved by delta retrieval
    pub delta_savings: u64,
    
    /// Number of Layer 4 (full extraction) calls
    pub full_extractions: u64,
    
    /// Waste ratio: total_tokens / information_extracted
    pub waste_ratio: f64,
}

impl TokenMetrics {
    /// Conservation score: 0.0 = wasteful, 1.0 = perfectly efficient
    pub fn conservation_score(&self) -> f64 {
        let potential = self.total_tokens + self.cache_savings + 
                       self.index_savings + self.scope_savings + 
                       self.delta_savings;
        if potential == 0 { return 1.0; }
        (potential - self.total_tokens) as f64 / potential as f64
    }
}
```

---

## AUDIT REQUIREMENTS

Every MCP call must log:

```json
{
  "tool": "memory_query",
  "timestamp": 1709744400000,
  "layer_used": 2,
  "tokens_used": 150,
  "tokens_saved": 2500,
  "cache_hit": false,
  "intent": "get_user_preference",
  "source_size": 50000,
  "result_size": 150,
  "waste_ratio": 0.003
}
```

---

## CODE DEPTH REQUIREMENTS

To match Memory's code depth, every sister must have:

```
REQUIRED CODE DEPTH (matching AgenticMemory):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. CACHING LAYER
   □ In-memory LRU cache with TTL
   □ Cache key derivation from query + context
   □ Cache invalidation on state change
   □ Cache size limits and eviction
   □ Cache hit/miss metrics

2. INDEX LAYER
   □ Primary index on ID
   □ Secondary indexes on common query patterns
   □ Semantic index for similarity search (where applicable)
   □ Temporal index for delta queries
   □ Index maintenance on write

3. INTENT LAYER
   □ Intent declaration required on all queries
   □ Intent → extraction scope mapping
   □ Intent validation (reject over-broad intents)
   □ Intent-based result filtering

4. DELTA LAYER
   □ State versioning (vector clock or timestamp)
   □ Delta computation (diff between versions)
   □ Delta-aware query API
   □ Efficient delta storage

5. METRICS LAYER
   □ Per-call token tracking
   □ Per-layer usage statistics
   □ Waste ratio computation
   □ Conservation score reporting
   □ Audit log generation

6. MCP LAYER
   □ Default to minimal response
   □ Explicit include_content flag
   □ Pagination with cursors (not offset)
   □ Max results enforcement
   □ Token budget parameter (hard cap)
```

---

## SOLIDIFICATION CHECKLIST

Before Hydra integration, each sister must pass:

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                    SOLIDIFICATION CHECKLIST (Per Sister)                   ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  □ CACHING                                                                ║
║    □ LRU cache implemented with configurable size                         ║
║    □ TTL-based expiration                                                 ║
║    □ Cache invalidation on mutation                                       ║
║    □ Cache metrics (hit rate, size, evictions)                           ║
║    □ Tests: cache hit returns same result, cache miss populates          ║
║                                                                           ║
║  □ INDEXING                                                               ║
║    □ Primary index on entity IDs                                          ║
║    □ At least 2 secondary indexes                                         ║
║    □ Index used before data scan                                          ║
║    □ Index maintenance on write                                           ║
║    □ Tests: index lookup 10x faster than scan                            ║
║                                                                           ║
║  □ INTENT SCOPING                                                         ║
║    □ Intent parameter on all query MCP tools                              ║
║    □ Intent → scope mapping documented                                    ║
║    □ Over-broad intent rejected with error                                ║
║    □ Tests: scoped query returns subset of full query                    ║
║                                                                           ║
║  □ DELTA RETRIEVAL                                                        ║
║    □ since/after parameter on relevant queries                            ║
║    □ State versioning implemented                                         ║
║    □ Delta computation correct                                            ║
║    □ Tests: delta query cheaper than full query                          ║
║                                                                           ║
║  □ METRICS                                                                ║
║    □ Token count on every MCP response                                    ║
║    □ Layer used on every MCP response                                     ║
║    □ Audit log written for every call                                     ║
║    □ Conservation score computable                                        ║
║    □ Tests: metrics increment correctly                                   ║
║                                                                           ║
║  □ MCP PATTERNS                                                           ║
║    □ Default response is minimal (IDs only)                               ║
║    □ include_content flag required for full content                       ║
║    □ Pagination via cursor, not offset                                    ║
║    □ max_results enforced                                                 ║
║    □ token_budget parameter implemented (hard cap)                        ║
║    □ Tests: default response smaller than full response                  ║
║                                                                           ║
║  □ WASTE RATIO                                                            ║
║    □ Same query twice: second is ≥10x cheaper                            ║
║    □ Unchanged state query: near-zero cost                                ║
║    □ Scoped query: cost proportional to scope, not source                ║
║    □ Tests: waste ratio measurements in test suite                       ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## IMPLEMENTATION PRIORITY

```
PHASE 1: AUDIT EXISTING SISTERS (1 week)
═══════════════════════════════════════
□ Measure token usage patterns in Memory, Vision, Codebase
□ Identify top 10 wasteful operations per sister
□ Document current vs target token costs
□ Create baseline metrics

PHASE 2: FOUNDATION SISTERS SOLIDIFICATION (2 weeks)
═══════════════════════════════════════════════════════
□ Memory: Add caching layer, intent scoping, delta retrieval
□ Vision: Implement Perception Revolution (already specced)
□ Codebase: Add graph caching, scoped extraction
□ Identity, Time, Contract, Comm: Add caching + minimal responses

PHASE 3: COGNITIVE SISTERS SOLIDIFICATION (1 week)
═══════════════════════════════════════════════════
□ Planning: Goal caching, incremental planning
□ Cognition: Model caching, preference lookup
□ Reality: Environment caching, capability index

PHASE 4: ASTRAL SISTERS SOLIDIFICATION (1 week)
═══════════════════════════════════════════════
□ Forge: Blueprint caching, skeleton scoping
□ Aegis: Validation caching, delta validation
□ Veritas: Intent caching, domain lookup
□ Evolve: Pattern caching, signature matching

PHASE 5: CROSS-SISTER TOKEN BUDGET (1 week)
═══════════════════════════════════════════
□ Implement global token budget across Hydra calls
□ Budget allocation per sister per operation
□ Budget exceeded → graceful degradation
□ Budget tracking in unified metrics

TOTAL: 6 weeks to token-minimal ecosystem
```

---

## THE SACRED COVENANT

```
TO EVERY AGENT THAT USES AGENTICOSYSTEM:

  We promise that you will never pay full cost for a cached answer.
  We promise that the second query is cheaper than the first.
  We promise that the hundredth query is nearly free.
  We promise that your cost scales with answer complexity, not data size.
  We promise that unchanged state is free to query.
  We promise that intent scoping reduces cost proportionally.
  We promise that every sister respects your token budget.
  We promise that waste is tracked, measured, and eliminated.
  We promise that we will never ask you to overpay to think.
  
  This is not optimization. This is the foundation.
  An expensive agent is a useless agent.
  We are making cognition cheap. Permanently. By design.
```

---

*TOKEN CONSERVATION ARCHITECTURE*
*Every token saved is a thought preserved.*
*Nothing matters if thinking is too expensive.*
