# ASTRAL SISTERS SOLIDIFICATION SPEC
## Bringing Forge, Aegis, Veritas, Evolve to Memory's Code Depth

> **Goal:** Every Astral sister must have the same architectural depth as AgenticMemory v0.4.2
> **Principle:** Tests pass ≠ Production ready. We need caching, indexing, metrics, and token conservation.

---

## WHAT MEMORY HAS THAT ASTRAL SISTERS MIGHT LACK

### AgenticMemory Architecture (The Gold Standard)

```
agentic-memory-core/src/
├── cache/
│   ├── lru.rs              # LRU cache with TTL
│   ├── invalidation.rs     # Cache invalidation on mutation
│   └── metrics.rs          # Hit rate, size, evictions
├── index/
│   ├── primary.rs          # ID-based lookup
│   ├── semantic.rs         # Embedding similarity
│   ├── temporal.rs         # Time-based queries
│   ├── tag.rs              # Tag-based queries
│   └── composite.rs        # Multi-index queries
├── query/
│   ├── intent.rs           # Intent declaration & scoping
│   ├── pagination.rs       # Cursor-based pagination
│   ├── delta.rs            # Since/after queries
│   └── budget.rs           # Token budget enforcement
├── metrics/
│   ├── tokens.rs           # Per-call token tracking
│   ├── audit.rs            # Audit log generation
│   └── conservation.rs     # Waste ratio computation
└── transport/
    ├── wal.rs              # Write-ahead log (L1)
    ├── extraction.rs       # Background extraction (L2)
    └── daemon.rs           # Continuous processing
```

---

## SOLIDIFICATION GAPS PER ASTRAL SISTER

### FORGE — Missing Components

```
MISSING FROM FORGE:
━━━━━━━━━━━━━━━━━━

□ cache/
  □ blueprint_cache.rs       # Cache recent blueprints by intent hash
  □ skeleton_cache.rs        # Cache generated skeletons
  □ dependency_cache.rs      # Cache resolved dependency graphs
  □ invalidation.rs          # Invalidate on blueprint mutation

□ index/
  □ intent_index.rs          # Index blueprints by intent signature
  □ domain_index.rs          # Index by domain (web-backend, cli, etc.)
  □ entity_index.rs          # Index entities across blueprints

□ query/
  □ intent_scope.rs          # Scope extraction by intent
  □ pagination.rs            # Cursor-based blueprint listing
  □ delta.rs                 # Changed blueprints since timestamp

□ metrics/
  □ tokens.rs                # Token counting per operation
  □ audit.rs                 # Audit log for every MCP call
  □ conservation.rs          # Waste ratio tracking

□ MCP CHANGES NEEDED:
  □ Add include_content: bool to blueprint queries (default: false)
  □ Add since: Option<i64> for delta retrieval
  □ Add token_budget: Option<u64> for hard caps
  □ Add metrics to every response
  □ Default forge_blueprint_list returns IDs only
```

### AEGIS — Missing Components

```
MISSING FROM AEGIS:
━━━━━━━━━━━━━━━━━━━

□ cache/
  □ validation_cache.rs      # Cache validation results by code hash
  □ session_cache.rs         # Cache active sessions
  □ security_cache.rs        # Cache security scan results

□ index/
  □ code_hash_index.rs       # Index by code content hash
  □ session_index.rs         # Index active sessions
  □ error_index.rs           # Index common error patterns

□ query/
  □ delta_validation.rs      # Validate only changed code
  □ scope.rs                 # Scope validation by intent
  □ incremental.rs           # Incremental validation state

□ metrics/
  □ tokens.rs                # Token counting
  □ audit.rs                 # Audit log
  □ conservation.rs          # Waste tracking

□ MCP CHANGES NEEDED:
  □ Add delta_only: bool to validation (validate changes only)
  □ Add include_details: bool (default: false, just return valid/invalid)
  □ Add code_hash for cache lookup before validation
  □ Cache hit = 0 tokens, return cached result
```

### VERITAS — Missing Components

```
MISSING FROM VERITAS:
━━━━━━━━━━━━━━━━━━━━━

□ cache/
  □ intent_cache.rs          # Cache compiled intents by input hash
  □ uncertainty_cache.rs     # Cache uncertainty assessments
  □ claim_cache.rs           # Cache verified claims

□ index/
  □ domain_index.rs          # Index intents by domain
  □ claim_index.rs           # Index verified claims
  □ ambiguity_index.rs       # Index common ambiguities

□ query/
  □ scope.rs                 # Scope by compilation phase
  □ delta.rs                 # New intents since timestamp
  □ similarity.rs            # Similar intent lookup

□ metrics/
  □ tokens.rs
  □ audit.rs
  □ conservation.rs

□ MCP CHANGES NEEDED:
  □ Add phase: Option<CompilationPhase> to scope output
  □ Add include_reasoning: bool (default: false)
  □ Add input_hash for cache lookup
  □ Similar input → return cached intent (0 compilation tokens)
```

### EVOLVE — Missing Components

```
MISSING FROM EVOLVE:
━━━━━━━━━━━━━━━━━━━━

□ cache/
  □ pattern_cache.rs         # Cache pattern matches by signature
  □ body_cache.rs            # Cache generated function bodies
  □ coverage_cache.rs        # Cache coverage analysis

□ index/
  □ signature_index.rs       # Index patterns by signature hash
  □ domain_index.rs          # Index by domain
  □ usage_index.rs           # Index by usage frequency

□ query/
  □ scope.rs                 # Scope pattern search
  □ delta.rs                 # New patterns since timestamp
  □ confidence.rs            # Filter by confidence threshold

□ metrics/
  □ tokens.rs
  □ audit.rs
  □ conservation.rs

□ MCP CHANGES NEEDED:
  □ Add signature_only: bool (return match without body)
  □ Add confidence_threshold: f64 (skip low-confidence)
  □ Add include_body: bool (default: false)
  □ Cache hit on signature → return pattern ID + confidence only
```

---

## IMPLEMENTATION SPEC (Per Sister)

### Phase 1: Caching Layer

```rust
// src/cache/mod.rs

pub mod lru;
pub mod invalidation;
pub mod metrics;

use std::collections::HashMap;
use std::sync::RwLock;
use std::time::{Duration, Instant};

/// Generic LRU cache with TTL
pub struct Cache<K, V> {
    entries: RwLock<HashMap<K, CacheEntry<V>>>,
    max_size: usize,
    ttl: Duration,
    metrics: CacheMetrics,
}

struct CacheEntry<V> {
    value: V,
    inserted_at: Instant,
    last_accessed: Instant,
    access_count: u64,
}

pub struct CacheMetrics {
    pub hits: AtomicU64,
    pub misses: AtomicU64,
    pub evictions: AtomicU64,
    pub current_size: AtomicUsize,
}

impl<K: Hash + Eq + Clone, V: Clone> Cache<K, V> {
    pub fn new(max_size: usize, ttl: Duration) -> Self { ... }
    
    pub fn get(&self, key: &K) -> Option<V> {
        let mut entries = self.entries.write().unwrap();
        if let Some(entry) = entries.get_mut(key) {
            if entry.inserted_at.elapsed() < self.ttl {
                entry.last_accessed = Instant::now();
                entry.access_count += 1;
                self.metrics.hits.fetch_add(1, Ordering::Relaxed);
                return Some(entry.value.clone());
            } else {
                entries.remove(key);
                self.metrics.evictions.fetch_add(1, Ordering::Relaxed);
            }
        }
        self.metrics.misses.fetch_add(1, Ordering::Relaxed);
        None
    }
    
    pub fn insert(&self, key: K, value: V) { ... }
    pub fn invalidate(&self, key: &K) { ... }
    pub fn clear(&self) { ... }
    pub fn hit_rate(&self) -> f64 { ... }
}
```

### Phase 2: Index Layer

```rust
// src/index/mod.rs

pub mod primary;
pub mod secondary;
pub mod composite;

/// Primary index: ID → Entity
pub struct PrimaryIndex<T> {
    entries: HashMap<EntityId, T>,
}

/// Secondary index: Attribute → Vec<EntityId>
pub struct SecondaryIndex {
    entries: HashMap<String, Vec<EntityId>>,
}

/// Composite query across multiple indexes
pub struct CompositeQuery {
    primary: Option<EntityId>,
    secondary_filters: Vec<(String, String)>,
    temporal_range: Option<(i64, i64)>,
    limit: usize,
}

impl<T> PrimaryIndex<T> {
    pub fn get(&self, id: &EntityId) -> Option<&T> { ... }
    pub fn insert(&mut self, id: EntityId, value: T) { ... }
    pub fn remove(&mut self, id: &EntityId) -> Option<T> { ... }
}

impl SecondaryIndex {
    pub fn query(&self, attribute: &str, value: &str) -> Vec<EntityId> { ... }
    pub fn add(&mut self, attribute: &str, value: &str, id: EntityId) { ... }
    pub fn remove(&mut self, attribute: &str, value: &str, id: &EntityId) { ... }
}
```

### Phase 3: Intent Scoping

```rust
// src/query/intent.rs

/// Intent declaration for scoped extraction
#[derive(Debug, Clone)]
pub enum ExtractionIntent {
    /// Just check existence
    Exists,
    /// Get IDs only
    IdsOnly,
    /// Get summary/metadata
    Summary,
    /// Get specific fields
    Fields(Vec<String>),
    /// Get full content
    Full,
}

impl ExtractionIntent {
    /// Estimate token cost for this intent
    pub fn estimated_tokens(&self) -> u64 {
        match self {
            Self::Exists => 1,
            Self::IdsOnly => 10,
            Self::Summary => 50,
            Self::Fields(f) => 20 * f.len() as u64,
            Self::Full => 500,
        }
    }
    
    /// Apply scope to result
    pub fn apply<T: Scopeable>(&self, value: &T) -> ScopedResult {
        match self {
            Self::Exists => ScopedResult::Bool(true),
            Self::IdsOnly => ScopedResult::Id(value.id()),
            Self::Summary => ScopedResult::Summary(value.summarize()),
            Self::Fields(f) => ScopedResult::Fields(value.extract_fields(f)),
            Self::Full => ScopedResult::Full(value.to_json()),
        }
    }
}

pub trait Scopeable {
    fn id(&self) -> String;
    fn summarize(&self) -> String;
    fn extract_fields(&self, fields: &[String]) -> HashMap<String, Value>;
    fn to_json(&self) -> Value;
}
```

### Phase 4: Delta Retrieval

```rust
// src/query/delta.rs

/// Delta query for change-proportional retrieval
pub struct DeltaQuery<T> {
    since: i64,  // Unix timestamp
    until: Option<i64>,
    change_types: Vec<ChangeType>,
    _phantom: PhantomData<T>,
}

#[derive(Debug, Clone)]
pub enum ChangeType {
    Created,
    Updated,
    Deleted,
}

#[derive(Debug, Clone)]
pub struct DeltaResult<T> {
    pub changes: Vec<Change<T>>,
    pub from_version: u64,
    pub to_version: u64,
    pub has_more: bool,
}

#[derive(Debug, Clone)]
pub struct Change<T> {
    pub id: EntityId,
    pub change_type: ChangeType,
    pub timestamp: i64,
    pub old_value: Option<T>,
    pub new_value: Option<T>,
}

impl<T> DeltaQuery<T> {
    pub fn since(timestamp: i64) -> Self { ... }
    pub fn until(mut self, timestamp: i64) -> Self { ... }
    pub fn filter(mut self, change_type: ChangeType) -> Self { ... }
}
```

### Phase 5: Token Metrics

```rust
// src/metrics/tokens.rs

use std::sync::atomic::{AtomicU64, Ordering};

/// Token usage tracking per sister
pub struct TokenMetrics {
    /// Total tokens used
    pub total: AtomicU64,
    
    /// Tokens by layer
    pub layer0_cache: AtomicU64,
    pub layer1_index: AtomicU64,
    pub layer2_scoped: AtomicU64,
    pub layer3_delta: AtomicU64,
    pub layer4_full: AtomicU64,
    
    /// Savings tracking
    pub cache_savings: AtomicU64,
    pub scope_savings: AtomicU64,
    pub delta_savings: AtomicU64,
}

impl TokenMetrics {
    pub fn record(&self, layer: Layer, tokens: u64, potential: u64) {
        self.total.fetch_add(tokens, Ordering::Relaxed);
        
        match layer {
            Layer::Cache => self.layer0_cache.fetch_add(tokens, Ordering::Relaxed),
            Layer::Index => self.layer1_index.fetch_add(tokens, Ordering::Relaxed),
            Layer::Scoped => self.layer2_scoped.fetch_add(tokens, Ordering::Relaxed),
            Layer::Delta => self.layer3_delta.fetch_add(tokens, Ordering::Relaxed),
            Layer::Full => self.layer4_full.fetch_add(tokens, Ordering::Relaxed),
        };
        
        let saved = potential.saturating_sub(tokens);
        match layer {
            Layer::Cache => self.cache_savings.fetch_add(saved, Ordering::Relaxed),
            Layer::Scoped => self.scope_savings.fetch_add(saved, Ordering::Relaxed),
            Layer::Delta => self.delta_savings.fetch_add(saved, Ordering::Relaxed),
            _ => {}
        };
    }
    
    pub fn conservation_score(&self) -> f64 {
        let total = self.total.load(Ordering::Relaxed);
        let saved = self.cache_savings.load(Ordering::Relaxed)
            + self.scope_savings.load(Ordering::Relaxed)
            + self.delta_savings.load(Ordering::Relaxed);
        
        let potential = total + saved;
        if potential == 0 { return 1.0; }
        
        saved as f64 / potential as f64
    }
}

/// Audit log entry
#[derive(Debug, Serialize)]
pub struct AuditEntry {
    pub timestamp: i64,
    pub tool: String,
    pub layer: Layer,
    pub tokens_used: u64,
    pub tokens_saved: u64,
    pub cache_hit: bool,
    pub intent: String,
    pub source_size: u64,
    pub result_size: u64,
}
```

### Phase 6: MCP Response Enhancement

```rust
// src/mcp/response.rs

/// Enhanced MCP response with metrics
#[derive(Debug, Serialize)]
pub struct McpResponse<T> {
    /// The actual result
    pub result: T,
    
    /// Token metrics for this call
    pub metrics: ResponseMetrics,
}

#[derive(Debug, Serialize)]
pub struct ResponseMetrics {
    /// Layer used for this response
    pub layer: Layer,
    
    /// Tokens used for this response
    pub tokens_used: u64,
    
    /// Tokens saved (vs full extraction)
    pub tokens_saved: u64,
    
    /// Was this a cache hit?
    pub cache_hit: bool,
    
    /// Response size in bytes
    pub response_size: usize,
}

impl<T: Serialize> McpResponse<T> {
    pub fn from_cache(result: T, full_cost: u64) -> Self {
        Self {
            result,
            metrics: ResponseMetrics {
                layer: Layer::Cache,
                tokens_used: 0,
                tokens_saved: full_cost,
                cache_hit: true,
                response_size: 0,  // Computed on serialize
            },
        }
    }
    
    pub fn from_query(result: T, layer: Layer, tokens: u64, full_cost: u64) -> Self {
        Self {
            result,
            metrics: ResponseMetrics {
                layer,
                tokens_used: tokens,
                tokens_saved: full_cost.saturating_sub(tokens),
                cache_hit: false,
                response_size: 0,
            },
        }
    }
}
```

---

## TEST REQUIREMENTS

Each sister must have these token conservation tests:

```rust
#[cfg(test)]
mod conservation_tests {
    use super::*;
    
    #[test]
    fn test_second_query_cheaper() {
        let sister = TestSister::new();
        
        // First query: full cost
        let (result1, metrics1) = sister.query("test", Intent::Full);
        
        // Second identical query: should be from cache
        let (result2, metrics2) = sister.query("test", Intent::Full);
        
        assert!(metrics2.cache_hit);
        assert_eq!(metrics2.tokens_used, 0);
        assert!(metrics2.tokens_saved > 0);
    }
    
    #[test]
    fn test_scoped_query_cheaper() {
        let sister = TestSister::new();
        
        // Full query
        let (_, full_metrics) = sister.query("test", Intent::Full);
        
        // Scoped query: should be cheaper
        let (_, scoped_metrics) = sister.query("test", Intent::IdsOnly);
        
        assert!(scoped_metrics.tokens_used < full_metrics.tokens_used);
        assert!(scoped_metrics.tokens_used < full_metrics.tokens_used / 10);
    }
    
    #[test]
    fn test_delta_query_proportional() {
        let sister = TestSister::new();
        
        // Insert 100 items
        for i in 0..100 {
            sister.insert(format!("item_{}", i));
        }
        
        // Full query
        let (_, full_metrics) = sister.query_all();
        
        // Add 1 more item
        sister.insert("item_100".to_string());
        let timestamp = sister.last_change_timestamp();
        
        // Delta query: should only return 1 item
        let (delta, delta_metrics) = sister.query_since(timestamp);
        
        assert_eq!(delta.len(), 1);
        assert!(delta_metrics.tokens_used < full_metrics.tokens_used / 50);
    }
    
    #[test]
    fn test_unchanged_state_free() {
        let sister = TestSister::new();
        sister.insert("item".to_string());
        
        let timestamp = sister.last_change_timestamp();
        
        // Query with no changes since timestamp
        let (delta, metrics) = sister.query_since(timestamp);
        
        assert!(delta.is_empty());
        assert!(metrics.tokens_used < 10);  // Near-zero cost
    }
    
    #[test]
    fn test_conservation_score_improves() {
        let sister = TestSister::new();
        
        // First 10 queries: cold cache
        for i in 0..10 {
            sister.query(&format!("query_{}", i), Intent::Full);
        }
        let score_cold = sister.conservation_score();
        
        // Repeat same 10 queries: warm cache
        for i in 0..10 {
            sister.query(&format!("query_{}", i), Intent::Full);
        }
        let score_warm = sister.conservation_score();
        
        // Conservation should improve with cache hits
        assert!(score_warm > score_cold);
    }
}
```

---

## CLAUDE CODE INSTRUCTIONS

For each Astral sister, add this prompt:

```
SOLIDIFICATION PHASE: Add token conservation infrastructure.

Working directory: /Users/omoshola/Documents/agentralabs-tech/agentic-{sister}

1. Create src/cache/ module:
   - lru.rs: Generic LRU cache with TTL
   - invalidation.rs: Cache invalidation on mutation
   - metrics.rs: Hit rate, size, evictions

2. Create src/index/ module:
   - primary.rs: ID-based lookup
   - secondary.rs: Attribute-based lookup
   - composite.rs: Multi-index queries

3. Create src/query/ module:
   - intent.rs: Intent declaration and scoping
   - delta.rs: Since/after queries
   - budget.rs: Token budget enforcement

4. Create src/metrics/ module:
   - tokens.rs: Per-call token tracking
   - audit.rs: Audit log generation
   - conservation.rs: Waste ratio computation

5. Update MCP tools:
   - Add include_content: bool (default: false)
   - Add since: Option<i64> for delta
   - Add token_budget: Option<u64> for hard cap
   - Add metrics to every response

6. Add conservation tests:
   - Second query cheaper test
   - Scoped query cheaper test
   - Delta query proportional test
   - Unchanged state free test
   - Conservation score improves test

Run after each phase:
  cargo test --workspace
  cargo clippy -- -D warnings
```

---

## SUCCESS CRITERIA

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                    SOLIDIFICATION COMPLETE WHEN:                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  □ Every sister has cache/, index/, query/, metrics/ modules             ║
║  □ Every MCP tool has include_content, since, token_budget params        ║
║  □ Every MCP response includes ResponseMetrics                           ║
║  □ Every sister passes conservation tests                                 ║
║  □ Second identical query is ≥10x cheaper                                ║
║  □ Scoped query is ≥10x cheaper than full query                          ║
║  □ Delta query cost proportional to changes, not data size               ║
║  □ Unchanged state queries are near-zero cost                            ║
║  □ Conservation score is ≥0.7 after warm-up                              ║
║  □ Audit log captures every MCP call                                     ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```
