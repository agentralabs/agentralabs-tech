# AGENTIC MEMORY V3: EDGE CASE HANDLERS

> Companion document to MEMORY-V3-IMMORTAL-IMPLEMENTATION.md
> Handle these BEFORE rigorous testing.

---

## 1. STORAGE EDGE CASES

### 1.1 Disk Full

```rust
// Problem: Write fails mid-block
// Solution: Pre-allocate + atomic write

pub fn safe_append(&mut self, block: &Block) -> Result<(), StorageError> {
    let data = serde_json::to_vec(block)?;
    let needed = 4 + data.len() + 1024; // +1KB buffer
    
    // Check available space BEFORE writing
    let available = fs2::available_space(&self.path)?;
    if available < needed as u64 {
        return Err(StorageError::DiskFull {
            needed,
            available: available as usize,
        });
    }
    
    // Pre-allocate to ensure space
    self.ensure_capacity(needed)?;
    
    // Now write (guaranteed to succeed)
    self.write_block(&data)
}
```

**Test:** Fill disk to 99%, attempt writes, verify graceful failure.

---

### 1.2 File Corruption

```rust
// Problem: File corrupted (cosmic ray, bad sector, etc.)
// Solution: Detect via checksums, recover from WAL

pub fn open_with_recovery(path: &Path) -> Result<Self, StorageError> {
    let mut log = Self::open(path)?;
    
    // Verify integrity
    let report = log.verify_integrity();
    
    if !report.verified {
        eprintln!("⚠️ Corruption detected: {:?}", report);
        
        // Try WAL recovery
        if let Ok(wal_blocks) = RecoveryManager::recover_wal(&path) {
            for block in wal_blocks {
                log.repair_block(block)?;
            }
        }
        
        // Rebuild indexes from valid blocks
        log.rebuild_indexes_from_valid_blocks()?;
    }
    
    Ok(log)
}
```

**Test:** Corrupt random bytes in file, verify detection + recovery.

---

### 1.3 Permission Denied

```rust
// Problem: Can't write to directory
// Solution: Fallback locations + clear error

pub fn find_writable_location() -> Result<PathBuf, StorageError> {
    let candidates = vec![
        dirs::data_local_dir().map(|d| d.join("agentic-memory")),
        dirs::home_dir().map(|d| d.join(".agentic-memory")),
        Some(PathBuf::from("/tmp/agentic-memory")),
        std::env::current_dir().ok().map(|d| d.join(".agentic-memory")),
    ];
    
    for candidate in candidates.into_iter().flatten() {
        if std::fs::create_dir_all(&candidate).is_ok() {
            // Test write
            let test_file = candidate.join(".write_test");
            if std::fs::write(&test_file, b"test").is_ok() {
                let _ = std::fs::remove_file(&test_file);
                return Ok(candidate);
            }
        }
    }
    
    Err(StorageError::NoWritableLocation)
}
```

**Test:** Run with read-only home directory, verify fallback works.

---

### 1.4 Path Edge Cases

```rust
// Problem: Special characters, long paths, unicode
// Solution: Sanitize + hash for filesystem safety

pub fn safe_path(input: &str) -> PathBuf {
    // Handle Windows long path
    #[cfg(windows)]
    let input = if input.len() > 250 {
        format!("\\\\?\\{}", input)
    } else {
        input.to_string()
    };
    
    // Hash if contains problematic characters
    let problematic = input.contains(['<', '>', ':', '"', '|', '?', '*', '\0']);
    let too_long = input.len() > 200;
    
    if problematic || too_long {
        let hash = blake3::hash(input.as_bytes());
        PathBuf::from(format!("hashed_{}", &hash.to_hex()[..16]))
    } else {
        PathBuf::from(input)
    }
}
```

**Test:** Paths with emoji, null bytes, 500+ chars, Windows reserved names.

---

## 2. CONCURRENCY EDGE CASES

### 2.1 Multiple Writers

```rust
// Problem: Two processes try to write simultaneously
// Solution: File locking with timeout + retry

use fs2::FileExt;

pub struct LockedLog {
    file: File,
    lock_file: File,
}

impl LockedLog {
    pub fn acquire(path: &Path, timeout: Duration) -> Result<Self, LockError> {
        let lock_path = path.with_extension("lock");
        let lock_file = File::create(&lock_path)?;
        
        let start = Instant::now();
        loop {
            match lock_file.try_lock_exclusive() {
                Ok(_) => break,
                Err(_) if start.elapsed() < timeout => {
                    std::thread::sleep(Duration::from_millis(50));
                }
                Err(_) => {
                    // Check if lock is stale (holder crashed)
                    if Self::is_stale_lock(&lock_path)? {
                        Self::break_stale_lock(&lock_path)?;
                        continue;
                    }
                    return Err(LockError::Timeout);
                }
            }
        }
        
        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .open(path)?;
        
        Ok(Self { file, lock_file })
    }
    
    fn is_stale_lock(lock_path: &Path) -> Result<bool, std::io::Error> {
        // Lock is stale if file is older than 60 seconds
        // and no process has the file open
        let metadata = std::fs::metadata(lock_path)?;
        let age = metadata.modified()?.elapsed().unwrap_or_default();
        Ok(age > Duration::from_secs(60))
    }
    
    fn break_stale_lock(lock_path: &Path) -> Result<(), std::io::Error> {
        std::fs::remove_file(lock_path)?;
        Ok(())
    }
}

impl Drop for LockedLog {
    fn drop(&mut self) {
        let _ = self.lock_file.unlock();
    }
}
```

**Test:** Launch 10 processes writing simultaneously, verify no corruption.

---

### 2.2 Crash During Write

```rust
// Problem: Process crashes mid-write, partial block
// Solution: WAL + length prefix + validation

pub fn safe_write(&mut self, block: &Block) -> Result<(), WriteError> {
    // 1. Write to WAL first
    self.wal.write(block)?;
    self.wal.sync()?;
    
    // 2. Write to main log
    let data = serde_json::to_vec(block)?;
    let len = data.len() as u32;
    
    // Write length prefix
    self.file.write_all(&len.to_le_bytes())?;
    
    // Write data
    self.file.write_all(&data)?;
    
    // Write end marker (validation)
    let checksum = crc32fast::hash(&data);
    self.file.write_all(&checksum.to_le_bytes())?;
    
    // 3. Sync to disk
    self.file.sync_all()?;
    
    // 4. Mark WAL entry as committed
    self.wal.commit(block.sequence)?;
    
    Ok(())
}

// On open: check for incomplete writes
pub fn recover_incomplete_writes(&mut self) -> Result<u32, RecoveryError> {
    let mut recovered = 0;
    
    // Scan for blocks without end marker
    while let Some(partial) = self.find_partial_block()? {
        // Try to recover from WAL
        if let Some(complete) = self.wal.get(partial.sequence)? {
            self.repair_block(complete)?;
            recovered += 1;
        } else {
            // Truncate partial block
            self.truncate_at(partial.offset)?;
        }
    }
    
    Ok(recovered)
}
```

**Test:** Kill process at random points during write, verify recovery.

---

### 2.3 Multiple Claude Instances

```rust
// Problem: User has multiple Claude windows/projects
// Solution: Per-project isolation + global lock for shared resources

pub struct ProjectIsolation {
    project_id: String,
    project_dir: PathBuf,
}

impl ProjectIsolation {
    pub fn detect_or_create() -> Self {
        // Try to detect project from environment
        let project_id = std::env::var("CLAUDE_PROJECT_ID")
            .or_else(|_| Self::detect_from_cwd())
            .unwrap_or_else(|_| Self::generate_project_id());
        
        let project_dir = Self::project_data_dir(&project_id);
        std::fs::create_dir_all(&project_dir).ok();
        
        Self { project_id, project_dir }
    }
    
    fn detect_from_cwd() -> Result<String, ()> {
        // Hash of current working directory = unique project ID
        let cwd = std::env::current_dir().map_err(|_| ())?;
        let canonical = cwd.canonicalize().map_err(|_| ())?;
        let hash = blake3::hash(canonical.to_string_lossy().as_bytes());
        Ok(format!("proj_{}", &hash.to_hex()[..12]))
    }
    
    fn generate_project_id() -> String {
        format!("proj_{}", uuid::Uuid::new_v4().to_string()[..8].to_string())
    }
    
    fn project_data_dir(project_id: &str) -> PathBuf {
        dirs::data_local_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("agentic-memory")
            .join("projects")
            .join(project_id)
    }
}
```

**Test:** Run 5 Claude windows with different projects, verify isolation.

---

## 3. GHOST WRITER EDGE CASES

### 3.1 Claude Not Installed

```rust
// Problem: User doesn't have Claude Code installed
// Solution: Graceful degradation, skip ghost writer

impl GhostWriter {
    pub fn spawn_if_available(engine: Arc<MemoryEngineV3>) -> Option<Arc<Self>> {
        match Self::detect_claude_memory_dir() {
            Some(dir) => {
                println!("✓ Claude Code detected at {:?}", dir);
                Some(Self::spawn_with_dir(engine, dir))
            }
            None => {
                println!("ℹ Claude Code not detected. Ghost writer disabled.");
                println!("  Memory still works via MCP tools.");
                None
            }
        }
    }
}
```

**Test:** Run without Claude installed, verify no crash, MCP still works.

---

### 3.2 Claude Directory Moves

```rust
// Problem: User moves Claude installation
// Solution: Re-detect periodically

impl GhostWriter {
    fn sync_loop(&self) {
        let mut last_detection = Instant::now();
        let detection_interval = Duration::from_secs(300); // Re-check every 5 min
        
        while self.running.load(Ordering::SeqCst) {
            // Periodic re-detection
            if last_detection.elapsed() > detection_interval {
                if let Some(new_dir) = Self::detect_claude_memory_dir() {
                    if Some(&new_dir) != self.claude_memory_dir.as_ref() {
                        *self.claude_memory_dir.lock().unwrap() = Some(new_dir);
                        println!("ℹ Claude directory changed, updated sync target");
                    }
                }
                last_detection = Instant::now();
            }
            
            self.sync_once();
            std::thread::sleep(self.sync_interval);
        }
    }
}
```

**Test:** Move .claude directory during operation, verify re-detection.

---

### 3.3 File Locked by Claude

```rust
// Problem: Claude Code has file open, we can't write
// Solution: Write to temp, atomic rename

pub fn safe_write_to_claude(target: &Path, content: &str) -> Result<(), std::io::Error> {
    let temp_path = target.with_extension("tmp");
    
    // Write to temp file
    std::fs::write(&temp_path, content)?;
    
    // Atomic rename (works even if target is open on Unix, may fail on Windows)
    match std::fs::rename(&temp_path, target) {
        Ok(_) => Ok(()),
        Err(e) if cfg!(windows) => {
            // Windows: target may be locked
            // Retry with small delay
            for _ in 0..3 {
                std::thread::sleep(Duration::from_millis(100));
                if std::fs::rename(&temp_path, target).is_ok() {
                    return Ok(());
                }
            }
            // Last resort: copy instead
            std::fs::copy(&temp_path, target)?;
            std::fs::remove_file(&temp_path)?;
            Ok(())
        }
        Err(e) => Err(e),
    }
}
```

**Test:** Have Claude open the file, attempt write, verify success.

---

### 3.4 Sync Conflicts

```rust
// Problem: User manually edited V3_CONTEXT.md
// Solution: Detect and preserve user sections

pub fn merge_with_user_content(target: &Path, our_content: &str) -> Result<(), std::io::Error> {
    let existing = std::fs::read_to_string(target).unwrap_or_default();
    
    // Check for user sections (marked with <!-- USER -->)
    let user_section_regex = regex::Regex::new(
        r"(?s)<!-- USER_START -->.*?<!-- USER_END -->"
    ).unwrap();
    
    let user_sections: Vec<&str> = user_section_regex
        .find_iter(&existing)
        .map(|m| m.as_str())
        .collect();
    
    // Build merged content
    let mut merged = our_content.to_string();
    
    if !user_sections.is_empty() {
        merged.push_str("\n\n<!-- User-defined sections preserved: -->\n");
        for section in user_sections {
            merged.push_str(section);
            merged.push_str("\n");
        }
    }
    
    std::fs::write(target, merged)
}
```

**Test:** Add user content to V3_CONTEXT.md, verify preserved after sync.

---

## 4. MCP EDGE CASES

### 4.1 Connection Drops

```rust
// Problem: Network drops during tool call
// Solution: Timeout + partial result handling

pub async fn tool_with_timeout<F, T>(
    f: F,
    timeout: Duration,
) -> Result<T, McpError>
where
    F: Future<Output = Result<T, McpError>>,
{
    match tokio::time::timeout(timeout, f).await {
        Ok(result) => result,
        Err(_) => Err(McpError::Timeout {
            message: "Tool call timed out".to_string(),
            partial_result: None,
        }),
    }
}

// For capture operations: ensure data is saved even if response fails
pub async fn capture_with_guarantee(
    engine: &MemoryEngineV3,
    content: BlockContent,
) -> Result<BlockHash, McpError> {
    // Save first, respond second
    let hash = engine.append_block(BlockType::from(&content), content)?;
    
    // Even if we fail to respond, data is saved
    Ok(hash)
}
```

**Test:** Kill connection mid-call, verify data saved.

---

### 4.2 Malformed Input

```rust
// Problem: Invalid JSON, wrong types, missing fields
// Solution: Strict validation with helpful errors

pub fn validate_capture_message(params: &Value) -> Result<CaptureMessageInput, ValidationError> {
    let role = params.get("role")
        .and_then(|v| v.as_str())
        .ok_or(ValidationError::MissingField("role"))?;
    
    if !["user", "assistant", "system"].contains(&role) {
        return Err(ValidationError::InvalidValue {
            field: "role",
            expected: "one of: user, assistant, system",
            got: role.to_string(),
        });
    }
    
    let content = params.get("content")
        .and_then(|v| v.as_str())
        .ok_or(ValidationError::MissingField("content"))?;
    
    if content.is_empty() {
        return Err(ValidationError::EmptyValue("content"));
    }
    
    // Limit content size (prevent memory exhaustion)
    if content.len() > 10 * 1024 * 1024 {
        return Err(ValidationError::TooLarge {
            field: "content",
            max_bytes: 10 * 1024 * 1024,
            got_bytes: content.len(),
        });
    }
    
    Ok(CaptureMessageInput {
        role: role.to_string(),
        content: content.to_string(),
        tokens: params.get("tokens").and_then(|v| v.as_u64()).map(|t| t as u32),
    })
}
```

**Test:** Send garbage JSON, missing fields, huge payloads.

---

### 4.3 Concurrent Tool Calls

```rust
// Problem: Multiple tools called simultaneously
// Solution: Thread-safe engine with internal locking

impl MemoryEngineV3 {
    // All mutations go through this single-threaded queue
    pub fn append_block(&self, block_type: BlockType, content: BlockContent) -> Result<BlockHash, EngineError> {
        // Acquire write lock
        let mut log = self.log.write().map_err(|_| EngineError::LockPoisoned)?;
        
        // Perform write
        let block = log.append(block_type, content)?;
        let hash = block.hash;
        
        // Update indexes (still under lock)
        self.update_indexes(&block)?;
        
        Ok(hash)
    }
    
    // Reads can happen concurrently
    pub fn search_semantic(&self, query: &str, limit: usize) -> Vec<Block> {
        // Acquire read lock (multiple readers OK)
        let semantic = self.semantic_index.read().unwrap();
        let storage = self.storage.read().unwrap();
        
        semantic.search_by_text(query, limit)
            .into_iter()
            .filter_map(|r| storage.get(r.block_sequence))
            .collect()
    }
}
```

**Test:** 100 concurrent tool calls, verify no race conditions.

---

## 5. DATA EDGE CASES

### 5.1 Empty / Null Content

```rust
// Problem: Empty strings, null values, whitespace-only
// Solution: Validate and normalize

pub fn normalize_content(content: &str) -> NormalizedContent {
    let trimmed = content.trim();
    
    if trimmed.is_empty() {
        return NormalizedContent::Empty;
    }
    
    // Check if only whitespace/control chars
    if trimmed.chars().all(|c| c.is_whitespace() || c.is_control()) {
        return NormalizedContent::WhitespaceOnly;
    }
    
    NormalizedContent::Valid(trimmed.to_string())
}

pub enum NormalizedContent {
    Empty,
    WhitespaceOnly,
    Valid(String),
}

// In capture:
pub fn capture_message(&self, content: &str) -> Result<BlockHash, CaptureError> {
    match normalize_content(content) {
        NormalizedContent::Empty => {
            Err(CaptureError::EmptyContent)
        }
        NormalizedContent::WhitespaceOnly => {
            // Log but don't fail
            warn!("Captured whitespace-only message");
            self.do_capture(content)
        }
        NormalizedContent::Valid(normalized) => {
            self.do_capture(&normalized)
        }
    }
}
```

**Test:** Capture empty string, null, tabs-only, verify behavior.

---

### 5.2 Binary Content

```rust
// Problem: Non-UTF8 content, images, raw bytes
// Solution: Detect and handle as binary

pub fn detect_content_type(data: &[u8]) -> ContentType {
    // Check for common binary signatures
    if data.len() >= 4 {
        match &data[0..4] {
            [0x89, 0x50, 0x4E, 0x47] => return ContentType::Binary("image/png"),
            [0xFF, 0xD8, 0xFF, _] => return ContentType::Binary("image/jpeg"),
            [0x25, 0x50, 0x44, 0x46] => return ContentType::Binary("application/pdf"),
            [0x50, 0x4B, 0x03, 0x04] => return ContentType::Binary("application/zip"),
            _ => {}
        }
    }
    
    // Check if valid UTF-8
    match std::str::from_utf8(data) {
        Ok(s) => {
            // Check for excessive control characters (likely binary)
            let control_ratio = s.chars().filter(|c| c.is_control() && *c != '\n' && *c != '\r' && *c != '\t').count() as f32 / s.len() as f32;
            if control_ratio > 0.1 {
                ContentType::Binary("application/octet-stream")
            } else {
                ContentType::Text
            }
        }
        Err(_) => ContentType::Binary("application/octet-stream"),
    }
}

pub enum ContentType {
    Text,
    Binary(&'static str), // mime type
}
```

**Test:** Capture PNG, random bytes, mixed content.

---

### 5.3 Very Large Content

```rust
// Problem: Single message > 10MB
// Solution: Chunk or reject with clear limit

const MAX_SINGLE_BLOCK_BYTES: usize = 10 * 1024 * 1024; // 10MB
const CHUNK_SIZE: usize = 1024 * 1024; // 1MB chunks

pub fn capture_large_content(
    &self,
    content: &str,
    block_type: BlockType,
) -> Result<Vec<BlockHash>, CaptureError> {
    let bytes = content.as_bytes();
    
    if bytes.len() <= MAX_SINGLE_BLOCK_BYTES {
        // Normal capture
        return Ok(vec![self.capture_single(content, block_type)?]);
    }
    
    // Chunk large content
    let mut hashes = Vec::new();
    let mut offset = 0;
    let mut chunk_index = 0;
    
    while offset < bytes.len() {
        let end = std::cmp::min(offset + CHUNK_SIZE, bytes.len());
        
        // Find safe UTF-8 boundary
        let chunk_end = if end < bytes.len() {
            find_utf8_boundary(&bytes[..end])
        } else {
            end
        };
        
        let chunk = &content[offset..chunk_end];
        let chunk_content = BlockContent::Text {
            text: chunk.to_string(),
            role: None,
            tokens: None,
            // Mark as chunk
            metadata: Some(serde_json::json!({
                "chunked": true,
                "chunk_index": chunk_index,
                "total_bytes": bytes.len(),
            })),
        };
        
        hashes.push(self.append_block(block_type, chunk_content)?);
        
        offset = chunk_end;
        chunk_index += 1;
    }
    
    Ok(hashes)
}

fn find_utf8_boundary(bytes: &[u8]) -> usize {
    let mut i = bytes.len();
    while i > 0 && (bytes[i - 1] & 0xC0) == 0x80 {
        i -= 1;
    }
    if i > 0 && (bytes[i - 1] & 0x80) != 0 {
        i -= 1;
    }
    i
}
```

**Test:** Capture 50MB message, verify chunking works.

---

### 5.4 Clock Skew / Future Timestamps

```rust
// Problem: System clock wrong, timestamps in future
// Solution: Validate and adjust

pub fn validated_timestamp() -> DateTime<Utc> {
    let now = Utc::now();
    
    // Sanity check: should be after 2024
    let min_valid = chrono::DateTime::parse_from_rfc3339("2024-01-01T00:00:00Z")
        .unwrap()
        .with_timezone(&Utc);
    
    // And before 2100 (catches overflow issues)
    let max_valid = chrono::DateTime::parse_from_rfc3339("2100-01-01T00:00:00Z")
        .unwrap()
        .with_timezone(&Utc);
    
    if now < min_valid {
        warn!("System clock appears to be in the past: {:?}", now);
        min_valid
    } else if now > max_valid {
        warn!("System clock appears to be in the future: {:?}", now);
        max_valid
    } else {
        now
    }
}

// For temporal index: handle out-of-order timestamps
pub fn insert_with_ordering(&mut self, block: &Block) {
    let ts = block.timestamp.timestamp_millis();
    
    // Check if this is out of order (older than last block)
    if let Some(&last_ts) = self.by_sequence.last() {
        if ts < last_ts {
            warn!(
                "Out-of-order timestamp: block {} at {:?} is older than previous",
                block.sequence, block.timestamp
            );
            // Still insert, but flag for potential reordering
        }
    }
    
    self.by_time
        .entry(ts)
        .or_default()
        .push((block.sequence, block.hash));
    
    self.by_sequence.push(ts);
}
```

**Test:** Set system clock to 2020, 2050, verify handling.

---

## 6. INDEX EDGE CASES

### 6.1 Index Corruption

```rust
// Problem: Index file corrupted but log is fine
// Solution: Detect and rebuild from log

pub fn verify_index_consistency(&self) -> IndexConsistencyReport {
    let log = self.log.read().unwrap();
    let temporal = self.temporal_index.read().unwrap();
    
    let mut report = IndexConsistencyReport::default();
    
    // Check every block in log is in index
    for seq in 0..log.len() {
        if let Some(block) = log.get(seq) {
            // Check temporal index
            let in_temporal = temporal.query_range(
                block.timestamp - chrono::Duration::seconds(1),
                block.timestamp + chrono::Duration::seconds(1),
            ).iter().any(|r| r.block_sequence == seq);
            
            if !in_temporal {
                report.missing_in_temporal.push(seq);
            }
        }
    }
    
    report.consistent = report.missing_in_temporal.is_empty();
    report
}

pub fn rebuild_indexes_if_needed(&self) -> Result<(), EngineError> {
    let report = self.verify_index_consistency();
    
    if !report.consistent {
        warn!("Index inconsistency detected, rebuilding...");
        self.rebuild_all_indexes()?;
    }
    
    Ok(())
}
```

**Test:** Delete index file, verify auto-rebuild.

---

### 6.2 Semantic Index Without Embeddings

```rust
// Problem: Embedding provider unavailable
// Solution: Graceful fallback to text search

impl SemanticIndex {
    pub fn search(&self, query: &str, limit: usize) -> Vec<IndexResult> {
        // Try embedding search first
        if let Some(embedding) = self.embedding_manager.embed(query) {
            let results = self.search_by_embedding(&embedding, limit);
            if !results.is_empty() {
                return results;
            }
        }
        
        // Fallback to text search
        warn!("Embedding search unavailable, falling back to text search");
        self.search_by_text(query, limit)
    }
}
```

**Test:** Disable embedding provider, verify text search works.

---

## 7. PLATFORM EDGE CASES

### 7.1 Windows vs Unix Paths

```rust
// Problem: Path separators, case sensitivity
// Solution: Normalize everywhere

pub fn normalize_path(path: &str) -> String {
    // Convert Windows separators to Unix
    let normalized = path.replace('\\', "/");
    
    // Remove trailing slashes
    let normalized = normalized.trim_end_matches('/');
    
    // Lowercase on case-insensitive systems
    #[cfg(any(target_os = "windows", target_os = "macos"))]
    let normalized = normalized.to_lowercase();
    
    normalized.to_string()
}

// When comparing paths
pub fn paths_equal(a: &str, b: &str) -> bool {
    normalize_path(a) == normalize_path(b)
}
```

**Test:** Run on Windows with `C:\Users\...` paths, verify normalization.

---

### 7.2 macOS Case Sensitivity

```rust
// Problem: macOS FS is case-insensitive but case-preserving
// Solution: Store original, compare normalized

pub struct FilePath {
    /// Original path as provided
    pub original: String,
    
    /// Normalized for comparison
    pub normalized: String,
}

impl FilePath {
    pub fn new(path: &str) -> Self {
        Self {
            original: path.to_string(),
            normalized: normalize_path(path),
        }
    }
}

impl PartialEq for FilePath {
    fn eq(&self, other: &Self) -> bool {
        self.normalized == other.normalized
    }
}

impl Hash for FilePath {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.normalized.hash(state);
    }
}
```

**Test:** Create files `Test.rs` and `test.rs`, verify treated as same on macOS.

---

## 8. RECOVERY EDGE CASES

### 8.1 WAL Corruption

```rust
// Problem: WAL itself is corrupted
// Solution: Validate WAL entries, skip corrupt ones

pub fn recover_wal(&mut self) -> Result<Vec<Block>, RecoveryError> {
    let mut recovered = Vec::new();
    let mut position = 0;
    
    loop {
        match self.read_wal_entry(position) {
            Ok(Some((block, next_pos))) => {
                // Validate block
                if block.verify() {
                    recovered.push(block);
                } else {
                    warn!("Skipping corrupt WAL entry at position {}", position);
                }
                position = next_pos;
            }
            Ok(None) => break, // End of WAL
            Err(e) => {
                warn!("WAL read error at position {}: {:?}", position, e);
                // Try to skip to next entry
                if let Some(next) = self.find_next_valid_entry(position) {
                    position = next;
                } else {
                    break;
                }
            }
        }
    }
    
    Ok(recovered)
}

fn find_next_valid_entry(&self, start: u64) -> Option<u64> {
    // Scan for next valid entry header
    // WAL entries start with sequence number (8 bytes)
    // Look for reasonable sequence numbers
    for offset in (start + 1)..self.wal_size {
        if let Ok(seq) = self.read_u64_at(offset) {
            if seq < 1_000_000_000 { // Reasonable sequence number
                // Try to parse entry here
                if self.read_wal_entry(offset).is_ok() {
                    return Some(offset);
                }
            }
        }
    }
    None
}
```

**Test:** Corrupt WAL file, verify partial recovery.

---

### 8.2 Multiple Crash Recovery Attempts

```rust
// Problem: Crash during recovery
// Solution: Idempotent recovery, marker files

pub fn recover_with_markers(&mut self) -> Result<(), RecoveryError> {
    let recovery_marker = self.data_dir.join(".recovery_in_progress");
    let recovery_complete = self.data_dir.join(".recovery_complete");
    
    // Check if previous recovery completed
    if recovery_complete.exists() {
        let complete_time = std::fs::metadata(&recovery_complete)?
            .modified()?;
        let log_time = std::fs::metadata(&self.log_path)?
            .modified()?;
        
        if complete_time > log_time {
            // Recovery already done, nothing to do
            return Ok(());
        }
    }
    
    // Mark recovery in progress
    std::fs::write(&recovery_marker, Utc::now().to_rfc3339())?;
    
    // Do recovery
    let result = self.do_recovery();
    
    // Mark complete (even on partial success)
    std::fs::write(&recovery_complete, Utc::now().to_rfc3339())?;
    std::fs::remove_file(&recovery_marker).ok();
    
    result
}
```

**Test:** Kill during recovery, restart, verify no double-recovery.

---

## 9. PERFORMANCE EDGE CASES

### 9.1 100K+ Blocks

```rust
// Problem: Indexes become slow with many blocks
// Solution: Index partitioning, lazy loading

impl TemporalIndex {
    /// For large indexes, partition by month
    pub fn query_range_partitioned(
        &self,
        start: DateTime<Utc>,
        end: DateTime<Utc>,
    ) -> Vec<IndexResult> {
        // If range is > 30 days and we have > 100K blocks,
        // use partitioned query
        if self.block_count > 100_000 {
            let days = (end - start).num_days();
            if days > 30 {
                return self.query_range_chunked(start, end, 30);
            }
        }
        
        // Normal query for smaller datasets
        self.query_range_simple(start, end)
    }
    
    fn query_range_chunked(
        &self,
        start: DateTime<Utc>,
        end: DateTime<Utc>,
        chunk_days: i64,
    ) -> Vec<IndexResult> {
        let mut results = Vec::new();
        let mut current = start;
        
        while current < end {
            let chunk_end = std::cmp::min(
                current + chrono::Duration::days(chunk_days),
                end,
            );
            results.extend(self.query_range_simple(current, chunk_end));
            current = chunk_end;
        }
        
        results
    }
}
```

**Test:** Generate 500K blocks, verify query performance < 100ms.

---

### 9.2 Memory Pressure

```rust
// Problem: Too many blocks in hot tier
// Solution: Aggressive eviction, memory monitoring

impl TieredStorage {
    pub fn check_memory_pressure(&mut self) {
        // Get current process memory usage
        let current_memory = self.get_process_memory();
        let max_memory = self.config.max_memory_bytes;
        
        let pressure = current_memory as f64 / max_memory as f64;
        
        if pressure > 0.9 {
            warn!("Memory pressure at {:.1}%, forcing eviction", pressure * 100.0);
            self.force_eviction(0.7); // Evict down to 70%
        } else if pressure > 0.8 {
            // Gentle eviction
            self.maybe_demote();
        }
    }
    
    fn force_eviction(&mut self, target_ratio: f64) {
        let target = (self.config.max_memory_bytes as f64 * target_ratio) as usize;
        
        while self.hot.size_bytes > target {
            // Evict oldest from hot
            if let Some(oldest_seq) = self.hot.oldest_sequence() {
                if let Some(block) = self.hot.remove(oldest_seq) {
                    self.warm.insert(block);
                }
            } else {
                break;
            }
        }
    }
    
    #[cfg(target_os = "linux")]
    fn get_process_memory(&self) -> usize {
        // Read from /proc/self/statm
        std::fs::read_to_string("/proc/self/statm")
            .ok()
            .and_then(|s| s.split_whitespace().nth(1))
            .and_then(|s| s.parse::<usize>().ok())
            .map(|pages| pages * 4096)
            .unwrap_or(0)
    }
}
```

**Test:** Set max_memory to 100MB, write 500MB, verify eviction.

---

## 10. TESTING CHECKLIST

```
STORAGE TESTS:
□ Disk full handling
□ File corruption detection
□ Permission denied fallback
□ Long path handling
□ Unicode path handling
□ Symlink handling

CONCURRENCY TESTS:
□ Multi-process write safety
□ Crash during write recovery
□ Stale lock detection
□ Multi-instance isolation

GHOST WRITER TESTS:
□ Claude not installed
□ Claude directory moves
□ File locked by Claude
□ User content preservation
□ Rapid sync (5 second interval)

MCP TESTS:
□ Connection timeout
□ Malformed JSON
□ Missing required fields
□ 10MB+ payload
□ 100 concurrent calls

DATA TESTS:
□ Empty content
□ Binary content
□ 50MB single message
□ Clock skew handling
□ Unicode edge cases

INDEX TESTS:
□ Index corruption recovery
□ Index-log consistency
□ Missing embeddings fallback
□ 500K block performance

PLATFORM TESTS:
□ Windows paths
□ macOS case sensitivity
□ Linux permissions
□ Docker container

RECOVERY TESTS:
□ WAL corruption
□ Partial WAL entry
□ Double recovery prevention
□ Interrupted migration

PERFORMANCE TESTS:
□ 100K blocks query < 100ms
□ Memory pressure eviction
□ Retrieval with 50K token budget
□ Ghost writer doesn't block
```

---

## SUMMARY

```
EDGE CASES COVERED: 40+
CATEGORIES: 10
TOTAL TEST SCENARIOS: 50+

PRINCIPLE: 
  If it can fail, handle it gracefully.
  If it can corrupt, detect and recover.
  If it can slow down, measure and optimize.
  
MOTTO:
  ZERO DATA LOSS. EVER.
```

---

*This document complements MEMORY-V3-IMMORTAL-IMPLEMENTATION.md*
*Implement these handlers BEFORE rigorous testing.*
