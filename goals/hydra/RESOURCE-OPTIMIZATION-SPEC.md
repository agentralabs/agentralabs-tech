# RESOURCE OPTIMIZATION SPECIFICATION

> **Status:** Canonical
> **Version:** 1.0
> **Date:** February 2026

---

## Executive Summary

Hydra is designed to run on **lower system configurations than alternatives**. This document specifies the resource optimization strategies that enable Hydra to operate efficiently on constrained hardware while maintaining full functionality.

### Design Principles

```
1. LAZY LOADING         → Load only what's needed, when needed
2. MEMORY BUDGETING     → Hard caps with graceful degradation
3. INCREMENTAL STORAGE  → Don't rewrite entire files
4. MINIMAL FOOTPRINT    → Core functionality under 100MB RAM
5. OFFLINE CAPABLE      → Full function without network
6. PROGRESSIVE FEATURES → More resources = more features
```

---

## 1. RESOURCE PROFILES

### 1.1 Profile Definitions

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        RESOURCE PROFILES                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  MINIMAL          STANDARD         PERFORMANCE       UNLIMITED              │
│  (Edge/IoT)       (Laptop)         (Desktop)         (Server)               │
│                                                                              │
│  RAM: 256MB       RAM: 1GB         RAM: 4GB          RAM: No limit          │
│  CPU: 1 core      CPU: 2 cores     CPU: 4 cores      CPU: No limit          │
│  Disk: 1GB        Disk: 10GB       Disk: 100GB       Disk: No limit         │
│                                                                              │
│  Features:        Features:        Features:         Features:              │
│  - Core only      - All basic      - All features    - All features         │
│  - No cache       - Basic cache    - Full cache      - Unlimited cache      │
│  - No local LLM   - Small LLM      - Medium LLM      - Large LLM            │
│  - Text only      - Basic vision   - Full vision     - Full vision          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Profile Configuration

```yaml
# hydra_config.yaml

resource_profile: standard  # minimal | standard | performance | unlimited

# Or explicit limits
resources:
  memory:
    max_heap_mb: 512
    max_cache_mb: 256
    eviction_policy: lru  # lru | lfu | fifo
    
  cpu:
    max_threads: 2
    priority: normal  # low | normal | high
    
  storage:
    max_disk_mb: 5000
    temp_dir: /tmp/hydra
    compression: true
    
  network:
    max_concurrent_requests: 5
    request_timeout_ms: 30000
    offline_mode: false
```

---

## 2. MEMORY MANAGEMENT

### 2.1 Memory Budgeting

```rust
// memory_budgeter.rs

pub struct MemoryBudgeter {
    config: MemoryConfig,
    allocator: BudgetedAllocator,
    monitor: MemoryMonitor,
}

impl MemoryBudgeter {
    /// Create with memory limit
    pub fn new(max_heap_mb: usize) -> Self {
        Self {
            config: MemoryConfig {
                max_heap_mb,
                warning_threshold: 0.8,  // Warn at 80%
                critical_threshold: 0.95, // Critical at 95%
            },
            allocator: BudgetedAllocator::new(max_heap_mb),
            monitor: MemoryMonitor::new(),
        }
    }
    
    /// Allocate with budget check
    pub fn allocate(&self, size: usize, purpose: &str) -> Result<Allocation> {
        let current = self.monitor.current_usage();
        let projected = current + size;
        
        if projected > self.config.max_heap_mb * 1024 * 1024 {
            // Try to free memory first
            self.evict_low_priority(size)?;
            
            // Check again
            let current = self.monitor.current_usage();
            if current + size > self.config.max_heap_mb * 1024 * 1024 {
                return Err(Error::MemoryBudgetExceeded {
                    requested: size,
                    available: self.config.max_heap_mb * 1024 * 1024 - current,
                });
            }
        }
        
        self.allocator.allocate(size, purpose)
    }
    
    /// Evict low priority items to free memory
    fn evict_low_priority(&self, needed: usize) -> Result<usize> {
        let mut freed = 0;
        
        // Priority order: cache -> old evidence -> old receipts
        for pool in [Pool::Cache, Pool::Evidence, Pool::Receipts] {
            if freed >= needed {
                break;
            }
            freed += self.evict_from_pool(pool, needed - freed)?;
        }
        
        Ok(freed)
    }
}
```

### 2.2 Lazy Loading

```rust
// lazy_loader.rs

pub struct LazyLoader<T> {
    path: PathBuf,
    loaded: Option<T>,
    last_access: Instant,
    size_bytes: usize,
}

impl<T: Loadable> LazyLoader<T> {
    /// Get value, loading if necessary
    pub fn get(&mut self) -> Result<&T> {
        if self.loaded.is_none() {
            self.loaded = Some(T::load(&self.path)?);
            self.size_bytes = self.loaded.as_ref().unwrap().size_in_memory();
            MEMORY_TRACKER.register(self.size_bytes);
        }
        self.last_access = Instant::now();
        Ok(self.loaded.as_ref().unwrap())
    }
    
    /// Unload if not accessed recently
    pub fn maybe_unload(&mut self, idle_threshold: Duration) -> bool {
        if self.loaded.is_some() && self.last_access.elapsed() > idle_threshold {
            MEMORY_TRACKER.unregister(self.size_bytes);
            self.loaded = None;
            true
        } else {
            false
        }
    }
}

/// Lazy sister file handles
pub struct LazySisterFiles {
    memory: LazyLoader<MemoryGraph>,
    vision: LazyLoader<VisionArchive>,
    codebase: LazyLoader<CodebaseGraph>,
    identity: LazyLoader<IdentityStore>,
}

impl LazySisterFiles {
    /// Unload idle files to free memory
    pub fn gc(&mut self, idle_threshold: Duration) {
        self.memory.maybe_unload(idle_threshold);
        self.vision.maybe_unload(idle_threshold);
        self.codebase.maybe_unload(idle_threshold);
        self.identity.maybe_unload(idle_threshold);
    }
}
```

### 2.3 Memory Pools

```rust
// memory_pools.rs

pub struct MemoryPools {
    pools: HashMap<Pool, PoolConfig>,
}

#[derive(Clone, Copy, Hash, Eq, PartialEq)]
pub enum Pool {
    Core,           // Essential runtime (never evicted)
    Sisters,        // Sister file data (evictable)
    Cache,          // Skill cache (first to evict)
    Evidence,       // Evidence data (evictable)
    Receipts,       // Receipt data (evictable, archivable)
    Scratch,        // Temporary allocations (auto-freed)
}

impl MemoryPools {
    pub fn default_config(profile: ResourceProfile) -> Self {
        let total = profile.max_memory_mb();
        
        Self {
            pools: hashmap! {
                Pool::Core => PoolConfig {
                    min_mb: 50,
                    max_mb: 100,
                    priority: Priority::Critical,
                    evictable: false,
                },
                Pool::Sisters => PoolConfig {
                    min_mb: 0,
                    max_mb: total / 4,
                    priority: Priority::High,
                    evictable: true,
                },
                Pool::Cache => PoolConfig {
                    min_mb: 0,
                    max_mb: total / 4,
                    priority: Priority::Low,
                    evictable: true,
                },
                Pool::Evidence => PoolConfig {
                    min_mb: 0,
                    max_mb: total / 4,
                    priority: Priority::Medium,
                    evictable: true,
                },
                Pool::Receipts => PoolConfig {
                    min_mb: 10,
                    max_mb: total / 8,
                    priority: Priority::High,
                    evictable: true,
                },
                Pool::Scratch => PoolConfig {
                    min_mb: 0,
                    max_mb: total / 8,
                    priority: Priority::Low,
                    evictable: true,
                },
            }
        }
    }
}
```

---

## 3. CPU MANAGEMENT

### 3.1 Thread Pool Management

```rust
// thread_pool.rs

pub struct ManagedThreadPool {
    pool: ThreadPool,
    config: CpuConfig,
    load_monitor: LoadMonitor,
}

impl ManagedThreadPool {
    pub fn new(config: CpuConfig) -> Self {
        let num_threads = config.max_threads.min(num_cpus::get());
        
        Self {
            pool: ThreadPool::new(num_threads),
            config,
            load_monitor: LoadMonitor::new(),
        }
    }
    
    /// Submit task with priority
    pub fn submit<F, T>(&self, priority: TaskPriority, f: F) -> JoinHandle<T>
    where
        F: FnOnce() -> T + Send + 'static,
        T: Send + 'static,
    {
        // Check load before submitting
        if self.load_monitor.is_overloaded() && priority == TaskPriority::Low {
            // Queue low priority tasks
            self.queue_for_later(priority, f)
        } else {
            self.pool.spawn(f)
        }
    }
    
    /// Adjust thread count based on load
    pub fn auto_scale(&mut self) {
        let load = self.load_monitor.current_load();
        
        if load > 0.9 && self.pool.thread_count() < self.config.max_threads {
            self.pool.add_thread();
        } else if load < 0.3 && self.pool.thread_count() > 1 {
            self.pool.remove_thread();
        }
    }
}
```

### 3.2 Task Prioritization

```rust
// task_scheduler.rs

pub struct TaskScheduler {
    queues: PriorityQueues,
    thread_pool: ManagedThreadPool,
}

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum TaskPriority {
    Critical,   // Kill switch, safety checks
    High,       // User-initiated actions
    Normal,     // Standard execution
    Low,        // Background tasks
    Idle,       // Maintenance, cleanup
}

impl TaskScheduler {
    /// Schedule task
    pub fn schedule<F>(&self, priority: TaskPriority, task: F) -> TaskHandle
    where
        F: FnOnce() -> Result<()> + Send + 'static,
    {
        let task_id = TaskId::new();
        
        // Critical tasks bypass queue
        if priority == TaskPriority::Critical {
            return self.execute_immediately(task_id, task);
        }
        
        // Others go through priority queue
        self.queues.push(priority, Task { id: task_id, func: Box::new(task) });
        
        TaskHandle { id: task_id }
    }
    
    /// Process queue (called by worker threads)
    fn process_queue(&self) {
        // Always process in priority order
        while let Some(task) = self.queues.pop_highest() {
            if let Err(e) = (task.func)() {
                log::error!("Task {} failed: {}", task.id, e);
            }
        }
    }
}
```

### 3.3 CPU Throttling

```rust
// cpu_throttler.rs

pub struct CpuThrottler {
    config: ThrottleConfig,
    metrics: CpuMetrics,
}

impl CpuThrottler {
    /// Check if we should throttle
    pub fn should_throttle(&self) -> bool {
        let cpu_usage = self.metrics.current_usage();
        
        cpu_usage > self.config.throttle_threshold
    }
    
    /// Apply throttle delay
    pub async fn throttle_if_needed(&self) {
        if self.should_throttle() {
            let delay = self.calculate_delay();
            tokio::time::sleep(delay).await;
        }
    }
    
    fn calculate_delay(&self) -> Duration {
        let cpu_usage = self.metrics.current_usage();
        let overage = cpu_usage - self.config.throttle_threshold;
        
        // Linear backoff: 10ms per 10% over threshold
        Duration::from_millis((overage * 100.0) as u64)
    }
}
```

---

## 4. STORAGE OPTIMIZATION

### 4.1 Incremental Writes

```rust
// incremental_storage.rs

pub struct IncrementalStorage {
    base_path: PathBuf,
    journal: WriteJournal,
    compactor: Compactor,
}

impl IncrementalStorage {
    /// Append-only write
    pub fn append(&mut self, data: &[u8]) -> Result<Offset> {
        let offset = self.journal.append(data)?;
        
        // Compact if journal too large
        if self.journal.size() > self.config.compact_threshold {
            self.compact_async();
        }
        
        Ok(offset)
    }
    
    /// Update with delta
    pub fn update_delta(&mut self, offset: Offset, delta: &Delta) -> Result<()> {
        // Store delta instead of full rewrite
        self.journal.append_delta(offset, delta)?;
        Ok(())
    }
    
    /// Compact journal into main file
    fn compact(&mut self) -> Result<()> {
        let merged = self.journal.merge_with_base()?;
        self.journal.clear()?;
        Ok(())
    }
}
```

### 4.2 Compression

```rust
// compression.rs

pub struct CompressionManager {
    config: CompressionConfig,
}

impl CompressionManager {
    /// Compress data for storage
    pub fn compress(&self, data: &[u8]) -> Result<Vec<u8>> {
        match self.config.algorithm {
            Algorithm::Lz4 => {
                // Fast compression, moderate ratio
                lz4::compress(data)
            }
            Algorithm::Zstd => {
                // Better ratio, still fast
                zstd::compress(data, self.config.level)
            }
            Algorithm::None => {
                Ok(data.to_vec())
            }
        }
    }
    
    /// Auto-select algorithm based on data type
    pub fn compress_auto(&self, data: &[u8], hint: DataHint) -> Result<Vec<u8>> {
        let algorithm = match hint {
            DataHint::Receipt => Algorithm::Zstd,     // Small, high ratio
            DataHint::Evidence => Algorithm::Lz4,     // Large, fast access
            DataHint::Cache => Algorithm::Lz4,        // Fast read/write
            DataHint::Archive => Algorithm::Zstd,     // Ratio matters
        };
        
        self.compress_with(data, algorithm)
    }
}
```

### 4.3 Storage Tiering

```rust
// storage_tiers.rs

pub struct TieredStorage {
    hot: HotStorage,      // SSD, fast access
    warm: WarmStorage,    // HDD, moderate access
    cold: ColdStorage,    // Compressed archive
}

impl TieredStorage {
    /// Store data in appropriate tier
    pub fn store(&mut self, key: &str, data: &[u8], access_pattern: AccessPattern) -> Result<()> {
        match access_pattern {
            AccessPattern::Frequent => {
                self.hot.store(key, data)?;
            }
            AccessPattern::Occasional => {
                self.warm.store(key, data)?;
            }
            AccessPattern::Rare => {
                let compressed = self.compress(data)?;
                self.cold.store(key, &compressed)?;
            }
        }
        Ok(())
    }
    
    /// Migrate data between tiers based on access
    pub fn rebalance(&mut self) -> Result<()> {
        // Promote frequently accessed cold data
        for (key, stats) in self.cold.access_stats() {
            if stats.recent_accesses > 5 {
                let data = self.cold.retrieve(&key)?;
                self.warm.store(&key, &data)?;
                self.cold.delete(&key)?;
            }
        }
        
        // Demote rarely accessed hot data
        for (key, stats) in self.hot.access_stats() {
            if stats.last_access.elapsed() > Duration::from_secs(3600) {
                let data = self.hot.retrieve(&key)?;
                self.warm.store(&key, &data)?;
                self.hot.delete(&key)?;
            }
        }
        
        Ok(())
    }
}
```

---

## 5. MINIMAL MODE

### 5.1 Feature Flags

```rust
// feature_flags.rs

pub struct FeatureFlags {
    flags: HashMap<Feature, bool>,
}

#[derive(Clone, Copy, Hash, Eq, PartialEq)]
pub enum Feature {
    // Core (always enabled)
    RunExecution,
    ReceiptLedger,
    SafetyChecks,
    
    // Standard (enabled by default)
    SkillCache,
    LocalSummarizer,
    VisionCapture,
    
    // Advanced (disabled in minimal)
    ActionCompilation,
    SkillFusion,
    ShadowSimulation,
    LocalLlm,
    VoiceControl,
    
    // Premium (disabled in minimal/standard)
    DistributedExecution,
    AdvancedAnalytics,
}

impl FeatureFlags {
    pub fn for_profile(profile: ResourceProfile) -> Self {
        let mut flags = HashMap::new();
        
        // Core always enabled
        flags.insert(Feature::RunExecution, true);
        flags.insert(Feature::ReceiptLedger, true);
        flags.insert(Feature::SafetyChecks, true);
        
        match profile {
            ResourceProfile::Minimal => {
                // Only core features
            }
            ResourceProfile::Standard => {
                flags.insert(Feature::SkillCache, true);
                flags.insert(Feature::LocalSummarizer, true);
                flags.insert(Feature::VisionCapture, true);
            }
            ResourceProfile::Performance => {
                flags.insert(Feature::SkillCache, true);
                flags.insert(Feature::LocalSummarizer, true);
                flags.insert(Feature::VisionCapture, true);
                flags.insert(Feature::ActionCompilation, true);
                flags.insert(Feature::SkillFusion, true);
                flags.insert(Feature::ShadowSimulation, true);
                flags.insert(Feature::LocalLlm, true);
                flags.insert(Feature::VoiceControl, true);
            }
            ResourceProfile::Unlimited => {
                // All features
                for feature in Feature::all() {
                    flags.insert(feature, true);
                }
            }
        }
        
        Self { flags }
    }
    
    pub fn is_enabled(&self, feature: Feature) -> bool {
        *self.flags.get(&feature).unwrap_or(&false)
    }
}
```

### 5.2 Minimal Mode Configuration

```yaml
# minimal_mode.yaml

resource_profile: minimal

resources:
  memory:
    max_heap_mb: 256
    max_cache_mb: 0      # No cache in minimal
    eviction_policy: immediate
    
  cpu:
    max_threads: 1
    priority: low
    
  storage:
    max_disk_mb: 1000
    compression: true
    tiering: false       # Single tier only

features:
  skill_cache: false
  local_summarizer: false
  vision_capture: false
  action_compilation: false
  skill_fusion: false
  shadow_simulation: false
  local_llm: false
  voice_control: false

optimizations:
  lazy_load_sisters: true
  aggressive_gc: true
  minimal_logging: true
  skip_analytics: true
```

### 5.3 Graceful Degradation

```rust
// graceful_degradation.rs

pub struct DegradationManager {
    current_level: DegradationLevel,
    monitor: ResourceMonitor,
}

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum DegradationLevel {
    Normal,           // All features
    Reduced,          // Disable non-essential
    Minimal,          // Core only
    Emergency,        // Survival mode
}

impl DegradationManager {
    /// Check and adjust degradation level
    pub fn update(&mut self) -> Option<DegradationChange> {
        let metrics = self.monitor.current_metrics();
        
        let new_level = if metrics.memory_pressure > 0.95 || metrics.cpu_pressure > 0.95 {
            DegradationLevel::Emergency
        } else if metrics.memory_pressure > 0.85 || metrics.cpu_pressure > 0.85 {
            DegradationLevel::Minimal
        } else if metrics.memory_pressure > 0.70 || metrics.cpu_pressure > 0.70 {
            DegradationLevel::Reduced
        } else {
            DegradationLevel::Normal
        };
        
        if new_level != self.current_level {
            let old_level = self.current_level;
            self.current_level = new_level;
            
            Some(DegradationChange {
                from: old_level,
                to: new_level,
                reason: metrics,
            })
        } else {
            None
        }
    }
    
    /// Apply degradation
    pub fn apply(&self, hydra: &mut Hydra) {
        match self.current_level {
            DegradationLevel::Normal => {
                // All features enabled
            }
            DegradationLevel::Reduced => {
                hydra.disable_feature(Feature::ShadowSimulation);
                hydra.disable_feature(Feature::AdvancedAnalytics);
                hydra.reduce_cache_size(0.5);
            }
            DegradationLevel::Minimal => {
                hydra.disable_feature(Feature::SkillCache);
                hydra.disable_feature(Feature::LocalLlm);
                hydra.disable_feature(Feature::VoiceControl);
                hydra.unload_idle_sisters();
            }
            DegradationLevel::Emergency => {
                hydra.pause_non_critical_runs();
                hydra.clear_all_caches();
                hydra.unload_all_sisters();
                hydra.gc_aggressive();
            }
        }
    }
}
```

---

## 6. OFFLINE MODE

### 6.1 Offline Capability

```rust
// offline_mode.rs

pub struct OfflineManager {
    config: OfflineConfig,
    local_cache: LocalCache,
    pending_sync: PendingSync,
}

impl OfflineManager {
    /// Check if we can operate offline
    pub fn can_operate_offline(&self) -> bool {
        // Check if we have essential local resources
        self.local_cache.has_essential_skills() &&
        self.local_cache.has_sister_files()
    }
    
    /// Execute in offline mode
    pub async fn execute_offline(&self, request: &Request) -> Result<Response> {
        // 1. Check if skill is available locally
        let skill = self.local_cache.get_skill(&request.skill_name)?;
        
        // 2. Check if skill can run offline
        if !skill.can_run_offline() {
            return Err(Error::RequiresNetwork(skill.network_requirements()));
        }
        
        // 3. Execute locally
        let result = skill.execute_local(&request.inputs).await?;
        
        // 4. Queue sync for when online
        self.pending_sync.queue(SyncItem {
            receipts: result.receipts.clone(),
            evidence: result.evidence.clone(),
        });
        
        Ok(result)
    }
    
    /// Sync when back online
    pub async fn sync_when_online(&self) -> Result<SyncReport> {
        if !self.is_online() {
            return Err(Error::StillOffline);
        }
        
        let mut report = SyncReport::new();
        
        while let Some(item) = self.pending_sync.pop() {
            match self.sync_item(&item).await {
                Ok(_) => report.synced += 1,
                Err(e) => {
                    report.failed += 1;
                    self.pending_sync.requeue(item);
                }
            }
        }
        
        Ok(report)
    }
}
```

### 6.2 Local Model Support

```rust
// local_models.rs

pub struct LocalModelManager {
    models: HashMap<ModelId, LocalModel>,
    config: LocalModelConfig,
}

impl LocalModelManager {
    /// Load appropriate model for resource profile
    pub fn load_for_profile(profile: ResourceProfile) -> Result<Self> {
        let models = match profile {
            ResourceProfile::Minimal => {
                // No local models
                HashMap::new()
            }
            ResourceProfile::Standard => {
                // Small models only
                hashmap! {
                    ModelId::Summarizer => LocalModel::load("phi-2")?,
                }
            }
            ResourceProfile::Performance => {
                // Medium models
                hashmap! {
                    ModelId::Summarizer => LocalModel::load("phi-3")?,
                    ModelId::Planner => LocalModel::load("llama-7b")?,
                    ModelId::Classifier => LocalModel::load("bert-small")?,
                }
            }
            ResourceProfile::Unlimited => {
                // Large models
                hashmap! {
                    ModelId::Summarizer => LocalModel::load("phi-3")?,
                    ModelId::Planner => LocalModel::load("llama-13b")?,
                    ModelId::Classifier => LocalModel::load("bert-base")?,
                    ModelId::Embedder => LocalModel::load("bge-large")?,
                }
            }
        };
        
        Ok(Self { models, config: LocalModelConfig::default() })
    }
    
    /// Check if local model can handle task
    pub fn can_handle(&self, task: &Task) -> bool {
        match task.required_capability() {
            Capability::Summarize => self.models.contains_key(&ModelId::Summarizer),
            Capability::Plan => self.models.contains_key(&ModelId::Planner),
            Capability::Classify => self.models.contains_key(&ModelId::Classifier),
            Capability::Embed => self.models.contains_key(&ModelId::Embedder),
            _ => false,
        }
    }
}
```

---

## 7. MONITORING & METRICS

### 7.1 Resource Monitor

```rust
// resource_monitor.rs

pub struct ResourceMonitor {
    memory_tracker: MemoryTracker,
    cpu_tracker: CpuTracker,
    storage_tracker: StorageTracker,
}

impl ResourceMonitor {
    /// Get current resource metrics
    pub fn metrics(&self) -> ResourceMetrics {
        ResourceMetrics {
            memory: MemoryMetrics {
                used_mb: self.memory_tracker.used_mb(),
                limit_mb: self.memory_tracker.limit_mb(),
                pressure: self.memory_tracker.pressure(),
            },
            cpu: CpuMetrics {
                usage_percent: self.cpu_tracker.usage_percent(),
                active_threads: self.cpu_tracker.active_threads(),
                queue_depth: self.cpu_tracker.queue_depth(),
            },
            storage: StorageMetrics {
                used_mb: self.storage_tracker.used_mb(),
                limit_mb: self.storage_tracker.limit_mb(),
                io_ops_per_sec: self.storage_tracker.iops(),
            },
        }
    }
    
    /// Start continuous monitoring
    pub fn start_monitoring(&self, interval: Duration) -> MonitorHandle {
        let (tx, rx) = channel();
        
        let tracker = self.clone();
        std::thread::spawn(move || {
            loop {
                let metrics = tracker.metrics();
                if tx.send(metrics).is_err() {
                    break;
                }
                std::thread::sleep(interval);
            }
        });
        
        MonitorHandle { receiver: rx }
    }
}
```

### 7.2 Metrics Export

```rust
// metrics_export.rs

pub struct MetricsExporter {
    format: ExportFormat,
}

impl MetricsExporter {
    /// Export metrics for display
    pub fn export(&self, metrics: &ResourceMetrics) -> String {
        match self.format {
            ExportFormat::Text => {
                format!(
                    "Memory: {}/{} MB ({:.0}%)\n\
                     CPU: {:.0}% ({} threads)\n\
                     Storage: {}/{} MB",
                    metrics.memory.used_mb,
                    metrics.memory.limit_mb,
                    metrics.memory.pressure * 100.0,
                    metrics.cpu.usage_percent,
                    metrics.cpu.active_threads,
                    metrics.storage.used_mb,
                    metrics.storage.limit_mb,
                )
            }
            ExportFormat::Json => {
                serde_json::to_string_pretty(metrics).unwrap()
            }
            ExportFormat::Prometheus => {
                format!(
                    "hydra_memory_used_bytes {}\n\
                     hydra_memory_limit_bytes {}\n\
                     hydra_cpu_usage_percent {}\n\
                     hydra_storage_used_bytes {}",
                    metrics.memory.used_mb * 1024 * 1024,
                    metrics.memory.limit_mb * 1024 * 1024,
                    metrics.cpu.usage_percent,
                    metrics.storage.used_mb * 1024 * 1024,
                )
            }
        }
    }
}
```

---

## 8. CLI COMMANDS

```bash
# Set resource profile
hydra config set profile minimal
hydra config set profile standard
hydra config set profile performance

# Set specific limits
hydra config set memory.max_mb 512
hydra config set cpu.max_threads 2
hydra config set storage.max_mb 5000

# View current resource usage
hydra resources status

# Output:
# ┌──────────────────────────────────────────┐
# │           RESOURCE STATUS                 │
# ├──────────────────────────────────────────┤
# │ Memory:  384/512 MB  (75%) ████████░░    │
# │ CPU:     45%         (2 threads)          │
# │ Storage: 2.3/5.0 GB  (46%) █████░░░░░    │
# │ Profile: Standard                         │
# │ Mode:    Normal                           │
# └──────────────────────────────────────────┘

# Enable minimal mode
hydra --minimal "do the task"

# Force offline mode
hydra --offline "do the task"

# View degradation status
hydra resources degradation
```

---

## 9. BENCHMARKS

### Target Performance by Profile

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        PERFORMANCE TARGETS                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                   MINIMAL      STANDARD     PERFORMANCE   UNLIMITED          │
│                                                                              │
│  Startup time     < 1s         < 2s         < 3s          < 5s              │
│  Memory idle      < 100 MB     < 300 MB     < 500 MB      < 1 GB            │
│  Memory active    < 256 MB     < 1 GB       < 4 GB        Unlimited         │
│  Simple task      < 100ms      < 50ms       < 20ms        < 10ms            │
│  Complex task     < 5s         < 2s         < 1s          < 500ms           │
│  Disk footprint   < 100 MB     < 500 MB     < 2 GB        Unlimited         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 10. COMPARISON: HYDRA vs ALTERNATIVES

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    RESOURCE COMPARISON                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                       Hydra         OpenClaw      AutoGPT       LangChain   │
│                       (minimal)     (typical)     (typical)     (typical)   │
│                                                                              │
│  Min RAM              256 MB        2 GB          4 GB          1 GB        │
│  Typical RAM          512 MB        4 GB          8 GB          2 GB        │
│  Disk footprint       100 MB        2 GB          5 GB          500 MB      │
│  Startup time         < 1s          5-10s         10-30s        2-5s        │
│  Offline capable      Yes           No            No            Partial     │
│  Resource profiles    Yes           No            No            No          │
│  Graceful degrade     Yes           No            No            No          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

*Document Version: 1.0*
*Status: Canonical*
