# CLAUDE-CODE-SOLIDIFICATION-INSTRUCTIONS.md
## Bringing All 14 Sisters to Memory-Grade Before Hydra

> **Goal:** Every sister matches AgenticMemory v0.4.2 architectural depth
> **Timeline:** 6 weeks before any Hydra code
> **Approach:** Parallel execution across 4-5 Claude Code terminals

---

## EXECUTION OVERVIEW

```
WEEK 1-2: TOKEN CONSERVATION
├── Terminal 1: Foundation sisters (Memory, Vision, Codebase, Identity)
├── Terminal 2: Foundation sisters (Time, Contract, Comm)
├── Terminal 3: Cognitive sisters (Planning, Cognition, Reality)
├── Terminal 4: Astral sisters (Forge, Aegis)
└── Terminal 5: Astral sisters (Veritas, Evolve)

WEEK 3: MCP CONSOLIDATION + BRIDGES
├── Terminal 1-5: Each handles 2-3 sisters

WEEK 4-5: ENTERPRISE BENCHMARKS + FINAL GAPS
├── Terminal 1-5: Each handles 2-3 sisters

WEEK 6: AUDIT + CERTIFICATION
├── All terminals: Run comprehensive audit
└── Fix any remaining gaps
```

---

## PHASE 1: TOKEN CONSERVATION IMPLEMENTATION

### Universal Prompt Template

For each sister, use this prompt in Claude Code:

```
SOLIDIFICATION PHASE 1: Token Conservation Infrastructure
Sister: Agentic{Name}
Working directory: /Users/omoshola/Documents/agentralabs-tech/agentic-{name}

REFERENCE: AgenticMemory v0.4.2 is the gold standard. Match its architecture.

STEP 1: Create cache/ module
─────────────────────────────

Create crates/agentic-{name}-core/src/cache/mod.rs:
```rust
pub mod lru;
pub mod invalidation;
pub mod metrics;

pub use lru::*;
pub use invalidation::*;
pub use metrics::*;
```

Create crates/agentic-{name}-core/src/cache/lru.rs:
```rust
use std::collections::HashMap;
use std::hash::Hash;
use std::sync::RwLock;
use std::time::{Duration, Instant};

pub struct LruCache<K, V> {
    entries: RwLock<HashMap<K, CacheEntry<V>>>,
    max_size: usize,
    ttl: Duration,
}

struct CacheEntry<V> {
    value: V,
    inserted_at: Instant,
    last_accessed: Instant,
    access_count: u64,
}

impl<K: Hash + Eq + Clone, V: Clone> LruCache<K, V> {
    pub fn new(max_size: usize, ttl: Duration) -> Self {
        Self {
            entries: RwLock::new(HashMap::new()),
            max_size,
            ttl,
        }
    }

    pub fn get(&self, key: &K) -> Option<V> {
        let mut entries = self.entries.write().ok()?;
        if let Some(entry) = entries.get_mut(key) {
            if entry.inserted_at.elapsed() < self.ttl {
                entry.last_accessed = Instant::now();
                entry.access_count += 1;
                return Some(entry.value.clone());
            } else {
                entries.remove(key);
            }
        }
        None
    }

    pub fn insert(&self, key: K, value: V) {
        let mut entries = self.entries.write().unwrap();
        
        // Evict if at capacity
        if entries.len() >= self.max_size {
            // Find LRU entry
            if let Some(lru_key) = entries
                .iter()
                .min_by_key(|(_, e)| e.last_accessed)
                .map(|(k, _)| k.clone())
            {
                entries.remove(&lru_key);
            }
        }
        
        entries.insert(key, CacheEntry {
            value,
            inserted_at: Instant::now(),
            last_accessed: Instant::now(),
            access_count: 1,
        });
    }

    pub fn invalidate(&self, key: &K) {
        if let Ok(mut entries) = self.entries.write() {
            entries.remove(key);
        }
    }

    pub fn clear(&self) {
        if let Ok(mut entries) = self.entries.write() {
            entries.clear();
        }
    }
}
```

Create crates/agentic-{name}-core/src/cache/invalidation.rs:
```rust
use std::collections::HashSet;
use std::sync::RwLock;

pub struct InvalidationTracker {
    dirty_keys: RwLock<HashSet<String>>,
}

impl InvalidationTracker {
    pub fn new() -> Self {
        Self {
            dirty_keys: RwLock::new(HashSet::new()),
        }
    }

    pub fn mark_dirty(&self, key: &str) {
        if let Ok(mut keys) = self.dirty_keys.write() {
            keys.insert(key.to_string());
        }
    }

    pub fn is_dirty(&self, key: &str) -> bool {
        self.dirty_keys
            .read()
            .map(|keys| keys.contains(key))
            .unwrap_or(false)
    }

    pub fn clear_dirty(&self, key: &str) {
        if let Ok(mut keys) = self.dirty_keys.write() {
            keys.remove(key);
        }
    }

    pub fn clear_all(&self) {
        if let Ok(mut keys) = self.dirty_keys.write() {
            keys.clear();
        }
    }
}

impl Default for InvalidationTracker {
    fn default() -> Self {
        Self::new()
    }
}
```

Create crates/agentic-{name}-core/src/cache/metrics.rs:
```rust
use std::sync::atomic::{AtomicU64, Ordering};

pub struct CacheMetrics {
    pub hits: AtomicU64,
    pub misses: AtomicU64,
    pub evictions: AtomicU64,
    pub invalidations: AtomicU64,
}

impl CacheMetrics {
    pub fn new() -> Self {
        Self {
            hits: AtomicU64::new(0),
            misses: AtomicU64::new(0),
            evictions: AtomicU64::new(0),
            invalidations: AtomicU64::new(0),
        }
    }

    pub fn record_hit(&self) {
        self.hits.fetch_add(1, Ordering::Relaxed);
    }

    pub fn record_miss(&self) {
        self.misses.fetch_add(1, Ordering::Relaxed);
    }

    pub fn record_eviction(&self) {
        self.evictions.fetch_add(1, Ordering::Relaxed);
    }

    pub fn record_invalidation(&self) {
        self.invalidations.fetch_add(1, Ordering::Relaxed);
    }

    pub fn hit_rate(&self) -> f64 {
        let hits = self.hits.load(Ordering::Relaxed);
        let misses = self.misses.load(Ordering::Relaxed);
        let total = hits + misses;
        if total == 0 {
            0.0
        } else {
            hits as f64 / total as f64
        }
    }
}

impl Default for CacheMetrics {
    fn default() -> Self {
        Self::new()
    }
}
```

STEP 2: Create query/ module
────────────────────────────

Create crates/agentic-{name}-core/src/query/mod.rs:
```rust
pub mod intent;
pub mod delta;
pub mod budget;
pub mod pagination;

pub use intent::*;
pub use delta::*;
pub use budget::*;
pub use pagination::*;
```

Create crates/agentic-{name}-core/src/query/intent.rs:
```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ExtractionIntent {
    /// Just check if entity exists
    Exists,
    /// Return IDs only
    IdsOnly,
    /// Return summary/metadata
    Summary,
    /// Return specific fields
    Fields(Vec<String>),
    /// Return full content
    Full,
}

impl ExtractionIntent {
    pub fn estimated_tokens(&self) -> u64 {
        match self {
            Self::Exists => 1,
            Self::IdsOnly => 10,
            Self::Summary => 50,
            Self::Fields(f) => 20 * f.len() as u64,
            Self::Full => 500,
        }
    }

    pub fn is_minimal(&self) -> bool {
        matches!(self, Self::Exists | Self::IdsOnly)
    }
}

impl Default for ExtractionIntent {
    fn default() -> Self {
        Self::IdsOnly  // Default to minimal
    }
}
```

Create crates/agentic-{name}-core/src/query/delta.rs:
```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeltaQuery {
    pub since: i64,
    pub until: Option<i64>,
    pub change_types: Vec<ChangeType>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub enum ChangeType {
    Created,
    Updated,
    Deleted,
}

impl DeltaQuery {
    pub fn since(timestamp: i64) -> Self {
        Self {
            since: timestamp,
            until: None,
            change_types: vec![ChangeType::Created, ChangeType::Updated, ChangeType::Deleted],
        }
    }

    pub fn until(mut self, timestamp: i64) -> Self {
        self.until = Some(timestamp);
        self
    }

    pub fn filter_type(mut self, change_type: ChangeType) -> Self {
        self.change_types = vec![change_type];
        self
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeltaResult<T> {
    pub changes: Vec<Change<T>>,
    pub from_version: u64,
    pub to_version: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Change<T> {
    pub id: String,
    pub change_type: ChangeType,
    pub timestamp: i64,
    pub value: Option<T>,
}
```

Create crates/agentic-{name}-core/src/query/budget.rs:
```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TokenBudget {
    pub max_tokens: u64,
    pub used_tokens: u64,
}

impl TokenBudget {
    pub fn new(max_tokens: u64) -> Self {
        Self {
            max_tokens,
            used_tokens: 0,
        }
    }

    pub fn remaining(&self) -> u64 {
        self.max_tokens.saturating_sub(self.used_tokens)
    }

    pub fn consume(&mut self, tokens: u64) -> bool {
        if self.used_tokens + tokens <= self.max_tokens {
            self.used_tokens += tokens;
            true
        } else {
            false
        }
    }

    pub fn is_exhausted(&self) -> bool {
        self.used_tokens >= self.max_tokens
    }

    pub fn usage_ratio(&self) -> f64 {
        if self.max_tokens == 0 {
            1.0
        } else {
            self.used_tokens as f64 / self.max_tokens as f64
        }
    }
}

impl Default for TokenBudget {
    fn default() -> Self {
        Self::new(10000)  // Default 10K token budget
    }
}
```

Create crates/agentic-{name}-core/src/query/pagination.rs:
```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Cursor {
    pub position: String,
    pub direction: Direction,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum Direction {
    Forward,
    Backward,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Page<T> {
    pub items: Vec<T>,
    pub next_cursor: Option<Cursor>,
    pub prev_cursor: Option<Cursor>,
    pub total_count: Option<u64>,
}

impl<T> Page<T> {
    pub fn empty() -> Self {
        Self {
            items: Vec::new(),
            next_cursor: None,
            prev_cursor: None,
            total_count: Some(0),
        }
    }

    pub fn has_next(&self) -> bool {
        self.next_cursor.is_some()
    }

    pub fn has_prev(&self) -> bool {
        self.prev_cursor.is_some()
    }
}
```

STEP 3: Create metrics/ module
──────────────────────────────

Create crates/agentic-{name}-core/src/metrics/mod.rs:
```rust
pub mod tokens;
pub mod audit;
pub mod conservation;

pub use tokens::*;
pub use audit::*;
pub use conservation::*;
```

Create crates/agentic-{name}-core/src/metrics/tokens.rs:
```rust
use std::sync::atomic::{AtomicU64, Ordering};
use serde::{Deserialize, Serialize};

#[derive(Debug, Default)]
pub struct TokenMetrics {
    pub total_used: AtomicU64,
    pub cache_hits: AtomicU64,
    pub cache_misses: AtomicU64,
    pub cache_savings: AtomicU64,
    pub scope_savings: AtomicU64,
    pub delta_savings: AtomicU64,
}

impl TokenMetrics {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn record_usage(&self, tokens: u64, layer: Layer) {
        self.total_used.fetch_add(tokens, Ordering::Relaxed);
        match layer {
            Layer::Cache => self.cache_hits.fetch_add(1, Ordering::Relaxed),
            _ => self.cache_misses.fetch_add(1, Ordering::Relaxed),
        };
    }

    pub fn record_savings(&self, saved: u64, layer: Layer) {
        match layer {
            Layer::Cache => self.cache_savings.fetch_add(saved, Ordering::Relaxed),
            Layer::Scoped => self.scope_savings.fetch_add(saved, Ordering::Relaxed),
            Layer::Delta => self.delta_savings.fetch_add(saved, Ordering::Relaxed),
            _ => {}
        };
    }

    pub fn conservation_score(&self) -> f64 {
        let total = self.total_used.load(Ordering::Relaxed);
        let saved = self.cache_savings.load(Ordering::Relaxed)
            + self.scope_savings.load(Ordering::Relaxed)
            + self.delta_savings.load(Ordering::Relaxed);
        
        let potential = total + saved;
        if potential == 0 {
            1.0
        } else {
            saved as f64 / potential as f64
        }
    }
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum Layer {
    Cache,
    Index,
    Scoped,
    Delta,
    Full,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResponseMetrics {
    pub layer: Layer,
    pub tokens_used: u64,
    pub tokens_saved: u64,
    pub cache_hit: bool,
}
```

Create crates/agentic-{name}-core/src/metrics/audit.rs:
```rust
use serde::{Deserialize, Serialize};
use std::sync::RwLock;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditEntry {
    pub timestamp: i64,
    pub tool: String,
    pub layer: super::Layer,
    pub tokens_used: u64,
    pub tokens_saved: u64,
    pub cache_hit: bool,
    pub intent: String,
}

pub struct AuditLog {
    entries: RwLock<Vec<AuditEntry>>,
    max_entries: usize,
}

impl AuditLog {
    pub fn new(max_entries: usize) -> Self {
        Self {
            entries: RwLock::new(Vec::new()),
            max_entries,
        }
    }

    pub fn record(&self, entry: AuditEntry) {
        if let Ok(mut entries) = self.entries.write() {
            if entries.len() >= self.max_entries {
                entries.remove(0);
            }
            entries.push(entry);
        }
    }

    pub fn entries(&self) -> Vec<AuditEntry> {
        self.entries.read().map(|e| e.clone()).unwrap_or_default()
    }

    pub fn clear(&self) {
        if let Ok(mut entries) = self.entries.write() {
            entries.clear();
        }
    }
}

impl Default for AuditLog {
    fn default() -> Self {
        Self::new(10000)
    }
}
```

Create crates/agentic-{name}-core/src/metrics/conservation.rs:
```rust
use super::TokenMetrics;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConservationReport {
    pub total_tokens_used: u64,
    pub total_tokens_saved: u64,
    pub cache_hit_rate: f64,
    pub conservation_score: f64,
    pub layer_breakdown: LayerBreakdown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LayerBreakdown {
    pub cache_percent: f64,
    pub index_percent: f64,
    pub scoped_percent: f64,
    pub delta_percent: f64,
    pub full_percent: f64,
}

impl ConservationReport {
    pub fn from_metrics(metrics: &TokenMetrics) -> Self {
        let total_used = metrics.total_used.load(std::sync::atomic::Ordering::Relaxed);
        let cache_savings = metrics.cache_savings.load(std::sync::atomic::Ordering::Relaxed);
        let scope_savings = metrics.scope_savings.load(std::sync::atomic::Ordering::Relaxed);
        let delta_savings = metrics.delta_savings.load(std::sync::atomic::Ordering::Relaxed);
        let total_saved = cache_savings + scope_savings + delta_savings;

        let hits = metrics.cache_hits.load(std::sync::atomic::Ordering::Relaxed);
        let misses = metrics.cache_misses.load(std::sync::atomic::Ordering::Relaxed);
        let hit_rate = if hits + misses == 0 {
            0.0
        } else {
            hits as f64 / (hits + misses) as f64
        };

        Self {
            total_tokens_used: total_used,
            total_tokens_saved: total_saved,
            cache_hit_rate: hit_rate,
            conservation_score: metrics.conservation_score(),
            layer_breakdown: LayerBreakdown {
                cache_percent: 0.0,  // Compute from actual layer usage
                index_percent: 0.0,
                scoped_percent: 0.0,
                delta_percent: 0.0,
                full_percent: 0.0,
            },
        }
    }
}
```

STEP 4: Update lib.rs
─────────────────────

Add to crates/agentic-{name}-core/src/lib.rs:
```rust
pub mod cache;
pub mod query;
pub mod metrics;

pub use cache::*;
pub use query::*;
pub use metrics::*;
```

STEP 5: Add conservation tests
──────────────────────────────

Create tests/conservation_test.rs:
```rust
use agentic_{name}_core::*;

#[test]
fn test_cache_hit_cheaper() {
    let cache = LruCache::new(100, std::time::Duration::from_secs(300));
    
    // First access: miss
    assert!(cache.get(&"key1").is_none());
    
    // Insert
    cache.insert("key1", "value1".to_string());
    
    // Second access: hit
    assert!(cache.get(&"key1").is_some());
    // In real usage, hit returns cached value at 0 token cost
}

#[test]
fn test_scoped_cheaper_than_full() {
    let intent_minimal = ExtractionIntent::IdsOnly;
    let intent_full = ExtractionIntent::Full;
    
    assert!(intent_minimal.estimated_tokens() < intent_full.estimated_tokens());
    assert!(intent_minimal.estimated_tokens() < intent_full.estimated_tokens() / 10);
}

#[test]
fn test_delta_proportional() {
    let delta = DeltaQuery::since(0);
    assert_eq!(delta.change_types.len(), 3);  // All change types
    
    let filtered = delta.filter_type(ChangeType::Created);
    assert_eq!(filtered.change_types.len(), 1);  // Only creates
}

#[test]
fn test_budget_enforcement() {
    let mut budget = TokenBudget::new(100);
    
    assert!(budget.consume(50));
    assert_eq!(budget.remaining(), 50);
    
    assert!(budget.consume(50));
    assert!(budget.is_exhausted());
    
    assert!(!budget.consume(1));  // Can't exceed budget
}

#[test]
fn test_conservation_score() {
    let metrics = TokenMetrics::new();
    
    // Use 100 tokens
    metrics.record_usage(100, Layer::Full);
    
    // Save 400 tokens via cache
    metrics.record_savings(400, Layer::Cache);
    
    // Conservation = 400 / 500 = 0.8
    assert!(metrics.conservation_score() > 0.7);
}
```

STEP 6: Verify
──────────────

cargo build --workspace
cargo test --workspace
cargo clippy --workspace -- -D warnings

CHECKPOINT:
- cache/ module exists with lru.rs, invalidation.rs, metrics.rs
- query/ module exists with intent.rs, delta.rs, budget.rs, pagination.rs  
- metrics/ module exists with tokens.rs, audit.rs, conservation.rs
- All conservation tests pass
- 0 clippy warnings

⛔ DO NOT PROCEED until checkpoint passes
```

---

## PHASE 2: MCP TOOL UPDATE

### MCP Response Enhancement Prompt

```
SOLIDIFICATION PHASE 2: MCP Tool Token Conservation
Sister: Agentic{Name}
Working directory: /Users/omoshola/Documents/agentralabs-tech/agentic-{name}

Update ALL MCP tools to support token conservation parameters.

STEP 1: Add common response type
────────────────────────────────

Add to crates/agentic-{name}-mcp/src/types.rs:
```rust
use serde::{Deserialize, Serialize};
use agentic_{name}_core::{ExtractionIntent, ResponseMetrics, Layer};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpResponse<T> {
    pub result: T,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metrics: Option<ResponseMetrics>,
}

impl<T> McpResponse<T> {
    pub fn new(result: T) -> Self {
        Self { result, metrics: None }
    }

    pub fn with_metrics(result: T, metrics: ResponseMetrics) -> Self {
        Self { result, metrics: Some(metrics) }
    }

    pub fn from_cache(result: T, tokens_saved: u64) -> Self {
        Self {
            result,
            metrics: Some(ResponseMetrics {
                layer: Layer::Cache,
                tokens_used: 0,
                tokens_saved,
                cache_hit: true,
            }),
        }
    }
}
```

STEP 2: Update query tools with standard parameters
───────────────────────────────────────────────────

For EVERY query/list/search tool, add these parameters:

```rust
#[derive(Debug, Deserialize)]
pub struct QueryParams {
    // Existing params...
    
    // Token conservation params (add to all query tools)
    #[serde(default)]
    pub include_content: bool,  // Default: false (IDs only)
    
    #[serde(default)]
    pub intent: Option<String>,  // "exists", "ids", "summary", "fields", "full"
    
    pub since: Option<i64>,  // Delta: only items after this timestamp
    
    pub token_budget: Option<u64>,  // Hard cap on tokens
    
    pub max_results: Option<usize>,  // Limit results (default: 10)
    
    pub cursor: Option<String>,  // For pagination
}
```

STEP 3: Update tool implementation pattern
──────────────────────────────────────────

```rust
pub async fn handle_query(params: QueryParams) -> Result<McpResponse<QueryResult>> {
    let intent = params.intent
        .map(|s| parse_intent(&s))
        .unwrap_or(ExtractionIntent::IdsOnly);  // Default minimal
    
    let budget = params.token_budget
        .map(TokenBudget::new)
        .unwrap_or_default();
    
    // Layer 0: Check cache
    let cache_key = compute_cache_key(&params);
    if let Some(cached) = CACHE.get(&cache_key) {
        return Ok(McpResponse::from_cache(cached, estimate_full_cost(&params)));
    }
    
    // Layer 1: Index lookup
    let ids = INDEX.query(&params)?;
    
    // Layer 2: Apply intent scoping
    let result = if params.include_content {
        // Full extraction (Layer 4)
        let items = STORE.get_many(&ids)?;
        QueryResult::with_content(items)
    } else {
        // Minimal response (Layer 2)
        QueryResult::ids_only(ids)
    };
    
    // Layer 3: Apply delta filter if requested
    let result = if let Some(since) = params.since {
        result.filter_since(since)
    } else {
        result
    };
    
    // Apply budget truncation
    let result = result.truncate_to_budget(&budget);
    
    // Populate cache
    CACHE.insert(cache_key, result.clone());
    
    // Compute metrics
    let metrics = ResponseMetrics {
        layer: if params.include_content { Layer::Full } else { Layer::Scoped },
        tokens_used: estimate_tokens(&result),
        tokens_saved: estimate_savings(&params, &result),
        cache_hit: false,
    };
    
    Ok(McpResponse::with_metrics(result, metrics))
}
```

STEP 4: Verify all tools updated
────────────────────────────────

Check that EVERY MCP tool has:
□ include_content parameter (default: false)
□ intent parameter (optional)
□ since parameter (optional, for delta)
□ token_budget parameter (optional)
□ max_results parameter (default: 10)
□ ResponseMetrics in response

CHECKPOINT:
- All query tools have token conservation params
- Default response is minimal (IDs only)
- Cache integration working
- Tests pass

⛔ DO NOT PROCEED until checkpoint passes
```

---

## PHASE 3: BENCHMARK SUITE

### Benchmark Implementation Prompt

```
SOLIDIFICATION PHASE 3: Enterprise Benchmarks
Sister: Agentic{Name}
Working directory: /Users/omoshola/Documents/agentralabs-tech/agentic-{name}

Create comprehensive benchmark suite matching Memory's standard.

STEP 1: Create benches/ directory structure
───────────────────────────────────────────

mkdir -p benches

STEP 2: Create CLI benchmarks
─────────────────────────────

Create benches/cli_bench.rs:
```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn cli_parsing_benchmark(c: &mut Criterion) {
    c.bench_function("cli_parse_help", |b| {
        b.iter(|| {
            let args = vec!["agentic-{name}", "--help"];
            // Parse args without execution
            black_box(args);
        })
    });
}

fn cli_config_benchmark(c: &mut Criterion) {
    c.bench_function("cli_load_config", |b| {
        b.iter(|| {
            // Load config
        })
    });
}

criterion_group!(cli_benches, cli_parsing_benchmark, cli_config_benchmark);
criterion_main!(cli_benches);
```

STEP 3: Create MCP benchmarks
─────────────────────────────

Create benches/mcp_bench.rs:
```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn mcp_dispatch_benchmark(c: &mut Criterion) {
    c.bench_function("mcp_tool_dispatch", |b| {
        b.iter(|| {
            // Dispatch tool call
        })
    });
}

fn mcp_json_benchmark(c: &mut Criterion) {
    c.bench_function("mcp_json_parse", |b| {
        b.iter(|| {
            let json = r#"{"jsonrpc":"2.0","method":"tools/call","params":{},"id":1}"#;
            black_box(serde_json::from_str::<serde_json::Value>(json).unwrap());
        })
    });
}

fn mcp_throughput_benchmark(c: &mut Criterion) {
    c.bench_function("mcp_1000_calls", |b| {
        b.iter(|| {
            for _ in 0..1000 {
                // Simulate tool call
            }
        })
    });
}

criterion_group!(mcp_benches, mcp_dispatch_benchmark, mcp_json_benchmark, mcp_throughput_benchmark);
criterion_main!(mcp_benches);
```

STEP 4: Create core benchmarks
──────────────────────────────

Create benches/core_bench.rs:
```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn core_primary_op_benchmark(c: &mut Criterion) {
    c.bench_function("core_create", |b| {
        b.iter(|| {
            // Primary operation
        })
    });
}

fn core_cache_benchmark(c: &mut Criterion) {
    use agentic_{name}_core::LruCache;
    use std::time::Duration;
    
    let cache = LruCache::new(1000, Duration::from_secs(300));
    
    c.bench_function("cache_insert", |b| {
        b.iter(|| {
            cache.insert("key".to_string(), "value".to_string());
        })
    });
    
    c.bench_function("cache_get", |b| {
        cache.insert("test".to_string(), "value".to_string());
        b.iter(|| {
            black_box(cache.get(&"test".to_string()));
        })
    });
}

fn core_index_benchmark(c: &mut Criterion) {
    c.bench_function("index_lookup", |b| {
        b.iter(|| {
            // Index lookup
        })
    });
}

criterion_group!(core_benches, core_primary_op_benchmark, core_cache_benchmark, core_index_benchmark);
criterion_main!(core_benches);
```

STEP 5: Create stress benchmarks
────────────────────────────────

Create benches/stress_bench.rs:
```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn stress_volume_benchmark(c: &mut Criterion) {
    c.bench_function("stress_10k_creates", |b| {
        b.iter(|| {
            for i in 0..10000 {
                // Create entity
                black_box(i);
            }
        })
    });
}

fn stress_concurrent_benchmark(c: &mut Criterion) {
    use std::thread;
    
    c.bench_function("stress_concurrent_10_threads", |b| {
        b.iter(|| {
            let handles: Vec<_> = (0..10)
                .map(|_| {
                    thread::spawn(|| {
                        for _ in 0..100 {
                            // Concurrent operation
                        }
                    })
                })
                .collect();
            
            for handle in handles {
                handle.join().unwrap();
            }
        })
    });
}

criterion_group!(stress_benches, stress_volume_benchmark, stress_concurrent_benchmark);
criterion_main!(stress_benches);
```

STEP 6: Update Cargo.toml
─────────────────────────

Add to workspace Cargo.toml:
```toml
[dev-dependencies]
criterion = "0.5"

[[bench]]
name = "cli_bench"
harness = false

[[bench]]
name = "mcp_bench"
harness = false

[[bench]]
name = "core_bench"
harness = false

[[bench]]
name = "stress_bench"
harness = false
```

STEP 7: Create bench.sh script
──────────────────────────────

Create scripts/bench.sh:
```bash
#!/bin/bash
set -e

echo "Running benchmarks..."
cargo bench --workspace

echo ""
echo "Benchmark complete. Results in target/criterion/"
```

chmod +x scripts/bench.sh

CHECKPOINT:
- benches/ directory exists with 4 benchmark files
- scripts/bench.sh executable
- cargo bench runs without errors
- Results documented in docs/public/benchmarks.md

⛔ DO NOT PROCEED until checkpoint passes
```

---

## TERMINAL ASSIGNMENTS

```
TERMINAL 1: Foundation Group A
─────────────────────────────
cd /Users/omoshola/Documents/agentralabs-tech
claude --dangerously-skip-permissions
# Process: memory (reference), vision, codebase, identity

TERMINAL 2: Foundation Group B  
─────────────────────────────
cd /Users/omoshola/Documents/agentralabs-tech
claude --dangerously-skip-permissions
# Process: time, contract, comm

TERMINAL 3: Cognitive
─────────────────────
cd /Users/omoshola/Documents/agentralabs-tech
claude --dangerously-skip-permissions
# Process: planning, cognition, reality

TERMINAL 4: Astral Group A
──────────────────────────
cd /Users/omoshola/Documents/agentralabs-tech
claude --dangerously-skip-permissions
# Process: forge, aegis

TERMINAL 5: Astral Group B
──────────────────────────
cd /Users/omoshola/Documents/agentralabs-tech
claude --dangerously-skip-permissions
# Process: veritas, evolve
```

---

## SUCCESS CRITERIA

```
PER-SISTER COMPLETION:
□ cache/ module with lru, invalidation, metrics
□ query/ module with intent, delta, budget, pagination
□ metrics/ module with tokens, audit, conservation
□ All MCP tools have token conservation params
□ Default response is minimal (IDs only)
□ Conservation tests pass (5 tests)
□ Benchmark suite (4 files)
□ Conservation score ≥0.8 after warmup
□ 0 new clippy warnings
□ Tests still pass

ECOSYSTEM COMPLETION:
□ All 14 sisters have token conservation
□ All 14 sisters have benchmarks
□ All 14 sisters have conservation score ≥0.8
□ audit-all-sisters.sh shows 0 blocking issues
```
