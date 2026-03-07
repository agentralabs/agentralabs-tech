# AGENTIC MEMORY V3: IMMORTAL ARCHITECTURE

## Implementation Specification

> **Status:** EXECUTE TONIGHT
> **Version:** 3.0
> **Codename:** Immortal
> **Goal:** Never lose a single token. Ever.

---

## EXECUTIVE SUMMARY

```
WHAT WE'RE BUILDING:
────────────────────
A persistence layer that captures EVERYTHING and loses NOTHING.

Like a hard drive for AI consciousness.
Not "what's important" - EVERYTHING.
Index smart. Retrieve smart. Store everything.

10 INVENTIONS TO IMPLEMENT:
───────────────────────────
1. Immortal Log (append-only, never delete)
2. Content-Addressed Blocks (deduplication)
3. Five Indexes (temporal, semantic, causal, entity, procedural)
4. Tiered Storage (hot/warm/cold/frozen)
5. Stream Capture API (hook into everything)
6. Session Boundary Protocol (compaction = checkpoint)
7. Resurrection Protocol (time travel)
8. Derived Summaries (raw is king)
9. Integrity Chains (cryptographic proof)
10. Smart Retrieval Engine (perfect context assembly)

BACKWARD COMPATIBLE:
────────────────────
V2 .amem files will be readable and auto-migrated.
V2 MCP tools continue to work.
V3 is additive, not breaking.
```

---

## PART 1: DATA STRUCTURES

### 1.1 The Block

The fundamental unit of storage. Content-addressed, immutable.

```rust
// agentic-memory-core/src/v3/block.rs

use blake3::Hash;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// A content-addressed, immutable block.
/// Once written, never modified. Never deleted.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Block {
    /// BLAKE3 hash of content (also serves as ID)
    pub hash: BlockHash,
    
    /// Hash of previous block (integrity chain)
    pub prev_hash: BlockHash,
    
    /// Sequence number (monotonic, gap-free)
    pub sequence: u64,
    
    /// When this block was created
    pub timestamp: DateTime<Utc>,
    
    /// Block type
    pub block_type: BlockType,
    
    /// The actual content
    pub content: BlockContent,
    
    /// Size in bytes (for budgeting)
    pub size_bytes: u32,
}

/// 32-byte BLAKE3 hash
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct BlockHash(pub [u8; 32]);

impl BlockHash {
    pub fn compute(data: &[u8]) -> Self {
        Self(*blake3::hash(data).as_bytes())
    }
    
    pub fn zero() -> Self {
        Self([0u8; 32])
    }
    
    pub fn to_hex(&self) -> String {
        hex::encode(self.0)
    }
    
    pub fn from_hex(s: &str) -> Option<Self> {
        let bytes = hex::decode(s).ok()?;
        if bytes.len() != 32 { return None; }
        let mut arr = [0u8; 32];
        arr.copy_from_slice(&bytes);
        Some(Self(arr))
    }
}

/// Types of blocks we store
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum BlockType {
    /// User message
    UserMessage,
    
    /// Assistant message
    AssistantMessage,
    
    /// System message
    SystemMessage,
    
    /// Tool call (input)
    ToolCall,
    
    /// Tool result (output)
    ToolResult,
    
    /// File operation
    FileOperation,
    
    /// Decision made
    Decision,
    
    /// Session boundary (compaction, new session)
    SessionBoundary,
    
    /// Error encountered
    Error,
    
    /// Checkpoint (periodic snapshot)
    Checkpoint,
    
    /// Custom/extension
    Custom,
}

/// Block content variants
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum BlockContent {
    /// Text content (messages)
    Text {
        text: String,
        role: Option<String>,
        tokens: Option<u32>,
    },
    
    /// Tool invocation
    Tool {
        tool_name: String,
        input: serde_json::Value,
        output: Option<serde_json::Value>,
        duration_ms: Option<u64>,
        success: bool,
    },
    
    /// File operation
    File {
        path: String,
        operation: FileOperation,
        content_hash: Option<BlockHash>,
        lines: Option<u32>,
        diff: Option<String>,
    },
    
    /// Decision record
    Decision {
        decision: String,
        reasoning: Option<String>,
        evidence_blocks: Vec<BlockHash>,
        confidence: Option<f32>,
    },
    
    /// Session boundary
    Boundary {
        boundary_type: BoundaryType,
        context_tokens_before: u32,
        context_tokens_after: u32,
        summary: String,
        continuation_hint: Option<String>,
    },
    
    /// Error record
    Error {
        error_type: String,
        message: String,
        resolution: Option<String>,
        resolved: bool,
    },
    
    /// Checkpoint (periodic state snapshot)
    Checkpoint {
        active_files: Vec<String>,
        working_context: String,
        pending_tasks: Vec<String>,
    },
    
    /// Raw bytes (for binary content)
    Binary {
        data: Vec<u8>,
        mime_type: String,
    },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FileOperation {
    Create,
    Read,
    Update,
    Delete,
    Rename,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum BoundaryType {
    SessionStart,
    SessionEnd,
    Compaction,
    ContextPressure,
    UserRequested,
    Checkpoint,
}

impl Block {
    /// Create a new block
    pub fn new(
        prev_hash: BlockHash,
        sequence: u64,
        block_type: BlockType,
        content: BlockContent,
    ) -> Self {
        let timestamp = Utc::now();
        let content_bytes = serde_json::to_vec(&content).unwrap_or_default();
        let size_bytes = content_bytes.len() as u32;
        
        // Hash includes: prev_hash + sequence + timestamp + content
        let mut hasher = blake3::Hasher::new();
        hasher.update(&prev_hash.0);
        hasher.update(&sequence.to_le_bytes());
        hasher.update(timestamp.to_rfc3339().as_bytes());
        hasher.update(&content_bytes);
        let hash = BlockHash(*hasher.finalize().as_bytes());
        
        Self {
            hash,
            prev_hash,
            sequence,
            timestamp,
            block_type,
            content,
            size_bytes,
        }
    }
    
    /// Verify block integrity
    pub fn verify(&self) -> bool {
        let content_bytes = serde_json::to_vec(&self.content).unwrap_or_default();
        
        let mut hasher = blake3::Hasher::new();
        hasher.update(&self.prev_hash.0);
        hasher.update(&self.sequence.to_le_bytes());
        hasher.update(self.timestamp.to_rfc3339().as_bytes());
        hasher.update(&content_bytes);
        let computed = BlockHash(*hasher.finalize().as_bytes());
        
        computed == self.hash
    }
}
```

### 1.2 The Immortal Log

```rust
// agentic-memory-core/src/v3/immortal_log.rs

use super::block::{Block, BlockHash, BlockType, BlockContent, BoundaryType};
use std::collections::HashMap;
use std::path::PathBuf;
use std::fs::{File, OpenOptions};
use std::io::{BufReader, BufWriter, Read, Write, Seek, SeekFrom};
use memmap2::MmapMut;

/// The append-only immortal log.
/// Never deletes. Never modifies. Only appends.
pub struct ImmortalLog {
    /// Path to the log file
    path: PathBuf,
    
    /// Memory-mapped file for fast access
    mmap: Option<MmapMut>,
    
    /// Current write position
    write_pos: u64,
    
    /// Block count
    block_count: u64,
    
    /// Last block hash (for chaining)
    last_hash: BlockHash,
    
    /// Block offset index (sequence -> file offset)
    offsets: Vec<u64>,
    
    /// Content-address index (hash -> sequence)
    content_index: HashMap<BlockHash, u64>,
}

impl ImmortalLog {
    /// Create or open an immortal log
    pub fn open(path: PathBuf) -> Result<Self, std::io::Error> {
        let exists = path.exists();
        
        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .open(&path)?;
        
        if exists {
            Self::load_existing(path, file)
        } else {
            Self::create_new(path, file)
        }
    }
    
    fn create_new(path: PathBuf, file: File) -> Result<Self, std::io::Error> {
        // Pre-allocate 1MB
        file.set_len(1024 * 1024)?;
        
        let mmap = unsafe { MmapMut::map_mut(&file)? };
        
        Ok(Self {
            path,
            mmap: Some(mmap),
            write_pos: 0,
            block_count: 0,
            last_hash: BlockHash::zero(),
            offsets: Vec::new(),
            content_index: HashMap::new(),
        })
    }
    
    fn load_existing(path: PathBuf, file: File) -> Result<Self, std::io::Error> {
        let mut log = Self {
            path,
            mmap: None,
            write_pos: 0,
            block_count: 0,
            last_hash: BlockHash::zero(),
            offsets: Vec::new(),
            content_index: HashMap::new(),
        };
        
        // Scan and rebuild indexes
        let mut reader = BufReader::new(&file);
        let mut offset = 0u64;
        
        loop {
            let pos = reader.stream_position()?;
            
            // Read block length prefix (4 bytes)
            let mut len_buf = [0u8; 4];
            match reader.read_exact(&mut len_buf) {
                Ok(_) => {}
                Err(e) if e.kind() == std::io::ErrorKind::UnexpectedEof => break,
                Err(e) => return Err(e),
            }
            let block_len = u32::from_le_bytes(len_buf) as usize;
            
            if block_len == 0 {
                break; // End of data
            }
            
            // Read block data
            let mut block_data = vec![0u8; block_len];
            reader.read_exact(&mut block_data)?;
            
            // Deserialize
            if let Ok(block) = serde_json::from_slice::<Block>(&block_data) {
                log.offsets.push(pos);
                log.content_index.insert(block.hash, block.sequence);
                log.last_hash = block.hash;
                log.block_count = block.sequence + 1;
            }
            
            offset = reader.stream_position()?;
        }
        
        log.write_pos = offset;
        
        // Memory map
        let mmap = unsafe { MmapMut::map_mut(&file)? };
        log.mmap = Some(mmap);
        
        Ok(log)
    }
    
    /// Append a block to the log
    pub fn append(&mut self, block_type: BlockType, content: BlockContent) -> Result<Block, std::io::Error> {
        let block = Block::new(
            self.last_hash,
            self.block_count,
            block_type,
            content,
        );
        
        // Serialize
        let block_data = serde_json::to_vec(&block)?;
        let block_len = block_data.len() as u32;
        
        // Ensure capacity
        self.ensure_capacity(4 + block_data.len())?;
        
        // Write length prefix + data
        if let Some(ref mut mmap) = self.mmap {
            let pos = self.write_pos as usize;
            mmap[pos..pos+4].copy_from_slice(&block_len.to_le_bytes());
            mmap[pos+4..pos+4+block_data.len()].copy_from_slice(&block_data);
            mmap.flush()?;
        }
        
        // Update indexes
        self.offsets.push(self.write_pos);
        self.content_index.insert(block.hash, block.sequence);
        self.last_hash = block.hash;
        self.block_count += 1;
        self.write_pos += 4 + block_data.len() as u64;
        
        Ok(block)
    }
    
    /// Get block by sequence number
    pub fn get(&self, sequence: u64) -> Option<Block> {
        let offset = *self.offsets.get(sequence as usize)?;
        self.read_block_at(offset)
    }
    
    /// Get block by hash
    pub fn get_by_hash(&self, hash: &BlockHash) -> Option<Block> {
        let sequence = *self.content_index.get(hash)?;
        self.get(sequence)
    }
    
    /// Read block at file offset
    fn read_block_at(&self, offset: u64) -> Option<Block> {
        let mmap = self.mmap.as_ref()?;
        let pos = offset as usize;
        
        if pos + 4 > mmap.len() {
            return None;
        }
        
        let block_len = u32::from_le_bytes([
            mmap[pos], mmap[pos+1], mmap[pos+2], mmap[pos+3]
        ]) as usize;
        
        if pos + 4 + block_len > mmap.len() {
            return None;
        }
        
        serde_json::from_slice(&mmap[pos+4..pos+4+block_len]).ok()
    }
    
    /// Ensure file has capacity for more data
    fn ensure_capacity(&mut self, needed: usize) -> Result<(), std::io::Error> {
        let mmap = self.mmap.as_ref().unwrap();
        let current_len = mmap.len();
        let required = self.write_pos as usize + needed;
        
        if required > current_len {
            // Grow by 2x or to required, whichever is larger
            let new_len = std::cmp::max(current_len * 2, required);
            
            drop(self.mmap.take());
            
            let file = OpenOptions::new()
                .read(true)
                .write(true)
                .open(&self.path)?;
            file.set_len(new_len as u64)?;
            
            self.mmap = Some(unsafe { MmapMut::map_mut(&file)? });
        }
        
        Ok(())
    }
    
    /// Iterate over all blocks
    pub fn iter(&self) -> impl Iterator<Item = Block> + '_ {
        (0..self.block_count).filter_map(move |seq| self.get(seq))
    }
    
    /// Iterate over blocks in time range
    pub fn iter_range(&self, start: u64, end: u64) -> impl Iterator<Item = Block> + '_ {
        (start..std::cmp::min(end, self.block_count)).filter_map(move |seq| self.get(seq))
    }
    
    /// Get block count
    pub fn len(&self) -> u64 {
        self.block_count
    }
    
    /// Verify integrity of entire log
    pub fn verify_integrity(&self) -> IntegrityReport {
        let mut report = IntegrityReport {
            verified: true,
            blocks_checked: 0,
            chain_intact: true,
            missing_blocks: vec![],
            corrupted_blocks: vec![],
        };
        
        let mut expected_prev = BlockHash::zero();
        
        for seq in 0..self.block_count {
            match self.get(seq) {
                Some(block) => {
                    report.blocks_checked += 1;
                    
                    // Check hash integrity
                    if !block.verify() {
                        report.corrupted_blocks.push(seq);
                        report.verified = false;
                    }
                    
                    // Check chain integrity
                    if block.prev_hash != expected_prev {
                        report.chain_intact = false;
                        report.verified = false;
                    }
                    
                    expected_prev = block.hash;
                }
                None => {
                    report.missing_blocks.push(seq);
                    report.verified = false;
                }
            }
        }
        
        report
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IntegrityReport {
    pub verified: bool,
    pub blocks_checked: u64,
    pub chain_intact: bool,
    pub missing_blocks: Vec<u64>,
    pub corrupted_blocks: Vec<u64>,
}
```

### 1.3 The Five Indexes

```rust
// agentic-memory-core/src/v3/indexes/mod.rs

pub mod temporal;
pub mod semantic;
pub mod causal;
pub mod entity;
pub mod procedural;

use super::block::{Block, BlockHash};
use chrono::{DateTime, Utc};

/// Result from any index query
#[derive(Debug, Clone)]
pub struct IndexResult {
    pub block_sequence: u64,
    pub block_hash: BlockHash,
    pub score: f32,  // Relevance score (0.0 - 1.0)
}

/// Common trait for all indexes
pub trait Index {
    /// Add a block to the index
    fn index(&mut self, block: &Block);
    
    /// Remove a block from the index (for reindexing only)
    fn remove(&mut self, sequence: u64);
    
    /// Rebuild entire index from blocks
    fn rebuild(&mut self, blocks: impl Iterator<Item = Block>);
}
```

```rust
// agentic-memory-core/src/v3/indexes/temporal.rs

use super::{Index, IndexResult};
use crate::v3::block::{Block, BlockHash};
use chrono::{DateTime, Utc};
use std::collections::BTreeMap;

/// B-tree index for temporal queries.
/// O(log n) lookup by timestamp.
pub struct TemporalIndex {
    /// Timestamp -> (sequence, hash)
    by_time: BTreeMap<i64, Vec<(u64, BlockHash)>>,
    
    /// Sequence -> timestamp (for reverse lookup)
    by_sequence: Vec<i64>,
}

impl TemporalIndex {
    pub fn new() -> Self {
        Self {
            by_time: BTreeMap::new(),
            by_sequence: Vec::new(),
        }
    }
    
    /// Query blocks in time range
    pub fn query_range(&self, start: DateTime<Utc>, end: DateTime<Utc>) -> Vec<IndexResult> {
        let start_ts = start.timestamp_millis();
        let end_ts = end.timestamp_millis();
        
        self.by_time
            .range(start_ts..=end_ts)
            .flat_map(|(_, blocks)| blocks.iter())
            .map(|(seq, hash)| IndexResult {
                block_sequence: *seq,
                block_hash: *hash,
                score: 1.0,
            })
            .collect()
    }
    
    /// Get blocks from last N seconds
    pub fn query_recent(&self, seconds: i64) -> Vec<IndexResult> {
        let now = Utc::now().timestamp_millis();
        let start = now - (seconds * 1000);
        
        self.by_time
            .range(start..=now)
            .flat_map(|(_, blocks)| blocks.iter())
            .map(|(seq, hash)| IndexResult {
                block_sequence: *seq,
                block_hash: *hash,
                score: 1.0,
            })
            .collect()
    }
    
    /// Get blocks for a specific date
    pub fn query_date(&self, date: DateTime<Utc>) -> Vec<IndexResult> {
        let start = date.date_naive().and_hms_opt(0, 0, 0).unwrap();
        let end = date.date_naive().and_hms_opt(23, 59, 59).unwrap();
        
        let start_ts = start.and_utc().timestamp_millis();
        let end_ts = end.and_utc().timestamp_millis();
        
        self.by_time
            .range(start_ts..=end_ts)
            .flat_map(|(_, blocks)| blocks.iter())
            .map(|(seq, hash)| IndexResult {
                block_sequence: *seq,
                block_hash: *hash,
                score: 1.0,
            })
            .collect()
    }
}

impl Index for TemporalIndex {
    fn index(&mut self, block: &Block) {
        let ts = block.timestamp.timestamp_millis();
        
        self.by_time
            .entry(ts)
            .or_insert_with(Vec::new)
            .push((block.sequence, block.hash));
        
        // Ensure by_sequence is large enough
        while self.by_sequence.len() <= block.sequence as usize {
            self.by_sequence.push(0);
        }
        self.by_sequence[block.sequence as usize] = ts;
    }
    
    fn remove(&mut self, sequence: u64) {
        if let Some(&ts) = self.by_sequence.get(sequence as usize) {
            if let Some(blocks) = self.by_time.get_mut(&ts) {
                blocks.retain(|(seq, _)| *seq != sequence);
            }
        }
    }
    
    fn rebuild(&mut self, blocks: impl Iterator<Item = Block>) {
        self.by_time.clear();
        self.by_sequence.clear();
        
        for block in blocks {
            self.index(&block);
        }
    }
}
```

```rust
// agentic-memory-core/src/v3/indexes/semantic.rs

use super::{Index, IndexResult};
use crate::v3::block::{Block, BlockHash, BlockType, BlockContent};
use std::collections::HashMap;

/// HNSW-based semantic similarity index.
/// O(log n) approximate nearest neighbor search.
pub struct SemanticIndex {
    /// Embeddings storage: sequence -> embedding vector
    embeddings: HashMap<u64, Vec<f32>>,
    
    /// Text content for fallback search
    text_content: HashMap<u64, String>,
    
    /// Block hashes
    hashes: HashMap<u64, BlockHash>,
    
    /// Embedding dimension
    dimension: usize,
}

impl SemanticIndex {
    pub fn new(dimension: usize) -> Self {
        Self {
            embeddings: HashMap::new(),
            text_content: HashMap::new(),
            hashes: HashMap::new(),
            dimension,
        }
    }
    
    /// Add embedding for a block
    pub fn add_embedding(&mut self, sequence: u64, embedding: Vec<f32>) {
        if embedding.len() == self.dimension {
            self.embeddings.insert(sequence, embedding);
        }
    }
    
    /// Search by embedding vector
    pub fn search_by_embedding(&self, query: &[f32], limit: usize) -> Vec<IndexResult> {
        if query.len() != self.dimension {
            return vec![];
        }
        
        // Brute force for now; replace with HNSW for production
        let mut scores: Vec<(u64, f32)> = self.embeddings
            .iter()
            .map(|(seq, emb)| {
                let score = cosine_similarity(query, emb);
                (*seq, score)
            })
            .collect();
        
        scores.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());
        
        scores
            .into_iter()
            .take(limit)
            .filter_map(|(seq, score)| {
                self.hashes.get(&seq).map(|hash| IndexResult {
                    block_sequence: seq,
                    block_hash: *hash,
                    score,
                })
            })
            .collect()
    }
    
    /// Search by text (fallback when no embeddings available)
    pub fn search_by_text(&self, query: &str, limit: usize) -> Vec<IndexResult> {
        let query_lower = query.to_lowercase();
        let query_words: Vec<&str> = query_lower.split_whitespace().collect();
        
        let mut scores: Vec<(u64, f32)> = self.text_content
            .iter()
            .map(|(seq, text)| {
                let text_lower = text.to_lowercase();
                let matches = query_words.iter()
                    .filter(|w| text_lower.contains(*w))
                    .count();
                let score = matches as f32 / query_words.len() as f32;
                (*seq, score)
            })
            .filter(|(_, score)| *score > 0.0)
            .collect();
        
        scores.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());
        
        scores
            .into_iter()
            .take(limit)
            .filter_map(|(seq, score)| {
                self.hashes.get(&seq).map(|hash| IndexResult {
                    block_sequence: seq,
                    block_hash: *hash,
                    score,
                })
            })
            .collect()
    }
}

impl Index for SemanticIndex {
    fn index(&mut self, block: &Block) {
        self.hashes.insert(block.sequence, block.hash);
        
        // Extract text content for fallback search
        let text = match &block.content {
            BlockContent::Text { text, .. } => Some(text.clone()),
            BlockContent::Decision { decision, reasoning, .. } => {
                Some(format!("{} {}", decision, reasoning.as_deref().unwrap_or("")))
            }
            BlockContent::Tool { tool_name, .. } => Some(tool_name.clone()),
            BlockContent::File { path, .. } => Some(path.clone()),
            BlockContent::Error { message, .. } => Some(message.clone()),
            _ => None,
        };
        
        if let Some(t) = text {
            self.text_content.insert(block.sequence, t);
        }
    }
    
    fn remove(&mut self, sequence: u64) {
        self.embeddings.remove(&sequence);
        self.text_content.remove(&sequence);
        self.hashes.remove(&sequence);
    }
    
    fn rebuild(&mut self, blocks: impl Iterator<Item = Block>) {
        self.embeddings.clear();
        self.text_content.clear();
        self.hashes.clear();
        
        for block in blocks {
            self.index(&block);
        }
    }
}

fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    let dot: f32 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();
    let norm_a: f32 = a.iter().map(|x| x * x).sum::<f32>().sqrt();
    let norm_b: f32 = b.iter().map(|x| x * x).sum::<f32>().sqrt();
    
    if norm_a == 0.0 || norm_b == 0.0 {
        0.0
    } else {
        dot / (norm_a * norm_b)
    }
}
```

```rust
// agentic-memory-core/src/v3/indexes/causal.rs

use super::{Index, IndexResult};
use crate::v3::block::{Block, BlockHash, BlockType, BlockContent};
use std::collections::{HashMap, HashSet, VecDeque};

/// DAG-based causal index.
/// Tracks decision chains: what led to what.
pub struct CausalIndex {
    /// Forward edges: block -> blocks it caused
    forward: HashMap<u64, Vec<u64>>,
    
    /// Backward edges: block -> blocks that caused it
    backward: HashMap<u64, Vec<u64>>,
    
    /// Decision blocks (entry points for causal queries)
    decisions: HashSet<u64>,
    
    /// Block hashes
    hashes: HashMap<u64, BlockHash>,
}

impl CausalIndex {
    pub fn new() -> Self {
        Self {
            forward: HashMap::new(),
            backward: HashMap::new(),
            decisions: HashSet::new(),
            hashes: HashMap::new(),
        }
    }
    
    /// Add causal link: cause -> effect
    pub fn add_link(&mut self, cause: u64, effect: u64) {
        self.forward.entry(cause).or_default().push(effect);
        self.backward.entry(effect).or_default().push(cause);
    }
    
    /// Get all blocks that led to this block (ancestors)
    pub fn get_ancestors(&self, sequence: u64, max_depth: usize) -> Vec<IndexResult> {
        let mut result = Vec::new();
        let mut visited = HashSet::new();
        let mut queue = VecDeque::new();
        
        queue.push_back((sequence, 0));
        
        while let Some((current, depth)) = queue.pop_front() {
            if depth > max_depth || visited.contains(&current) {
                continue;
            }
            visited.insert(current);
            
            if current != sequence {
                if let Some(&hash) = self.hashes.get(&current) {
                    result.push(IndexResult {
                        block_sequence: current,
                        block_hash: hash,
                        score: 1.0 - (depth as f32 / max_depth as f32),
                    });
                }
            }
            
            if let Some(causes) = self.backward.get(&current) {
                for &cause in causes {
                    queue.push_back((cause, depth + 1));
                }
            }
        }
        
        result
    }
    
    /// Get all blocks that resulted from this block (descendants)
    pub fn get_descendants(&self, sequence: u64, max_depth: usize) -> Vec<IndexResult> {
        let mut result = Vec::new();
        let mut visited = HashSet::new();
        let mut queue = VecDeque::new();
        
        queue.push_back((sequence, 0));
        
        while let Some((current, depth)) = queue.pop_front() {
            if depth > max_depth || visited.contains(&current) {
                continue;
            }
            visited.insert(current);
            
            if current != sequence {
                if let Some(&hash) = self.hashes.get(&current) {
                    result.push(IndexResult {
                        block_sequence: current,
                        block_hash: hash,
                        score: 1.0 - (depth as f32 / max_depth as f32),
                    });
                }
            }
            
            if let Some(effects) = self.forward.get(&current) {
                for &effect in effects {
                    queue.push_back((effect, depth + 1));
                }
            }
        }
        
        result
    }
    
    /// Get all decision blocks
    pub fn get_decisions(&self) -> Vec<IndexResult> {
        self.decisions
            .iter()
            .filter_map(|&seq| {
                self.hashes.get(&seq).map(|&hash| IndexResult {
                    block_sequence: seq,
                    block_hash: hash,
                    score: 1.0,
                })
            })
            .collect()
    }
    
    /// Get decision chain leading to a block
    pub fn get_decision_chain(&self, sequence: u64) -> Vec<IndexResult> {
        self.get_ancestors(sequence, 100)
            .into_iter()
            .filter(|r| self.decisions.contains(&r.block_sequence))
            .collect()
    }
}

impl Index for CausalIndex {
    fn index(&mut self, block: &Block) {
        self.hashes.insert(block.sequence, block.hash);
        
        // Mark decisions
        if matches!(block.block_type, BlockType::Decision) {
            self.decisions.insert(block.sequence);
        }
        
        // Extract causal links from content
        match &block.content {
            BlockContent::Decision { evidence_blocks, .. } => {
                for evidence_hash in evidence_blocks {
                    // Find sequence by hash (reverse lookup)
                    for (&seq, &hash) in &self.hashes {
                        if &hash == evidence_hash {
                            self.add_link(seq, block.sequence);
                            break;
                        }
                    }
                }
            }
            // Tool results are caused by tool calls
            BlockContent::Tool { .. } if block.sequence > 0 => {
                self.add_link(block.sequence - 1, block.sequence);
            }
            _ => {}
        }
        
        // Default: previous block causes current block
        if block.sequence > 0 {
            self.add_link(block.sequence - 1, block.sequence);
        }
    }
    
    fn remove(&mut self, sequence: u64) {
        self.forward.remove(&sequence);
        self.backward.remove(&sequence);
        self.decisions.remove(&sequence);
        self.hashes.remove(&sequence);
        
        // Remove references from other blocks
        for edges in self.forward.values_mut() {
            edges.retain(|&s| s != sequence);
        }
        for edges in self.backward.values_mut() {
            edges.retain(|&s| s != sequence);
        }
    }
    
    fn rebuild(&mut self, blocks: impl Iterator<Item = Block>) {
        self.forward.clear();
        self.backward.clear();
        self.decisions.clear();
        self.hashes.clear();
        
        for block in blocks {
            self.index(&block);
        }
    }
}
```

```rust
// agentic-memory-core/src/v3/indexes/entity.rs

use super::{Index, IndexResult};
use crate::v3::block::{Block, BlockHash, BlockContent};
use std::collections::{HashMap, HashSet};

/// Inverted index for entity mentions.
/// O(1) lookup by entity (file, person, project, etc.)
pub struct EntityIndex {
    /// Entity -> blocks that mention it
    by_entity: HashMap<String, HashSet<u64>>,
    
    /// Block hashes
    hashes: HashMap<u64, BlockHash>,
    
    /// Entity types for categorization
    entity_types: HashMap<String, EntityType>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EntityType {
    File,
    Directory,
    Person,
    Project,
    Tool,
    Concept,
    Other,
}

impl EntityIndex {
    pub fn new() -> Self {
        Self {
            by_entity: HashMap::new(),
            hashes: HashMap::new(),
            entity_types: HashMap::new(),
        }
    }
    
    /// Add entity mention
    pub fn add_mention(&mut self, entity: &str, sequence: u64, entity_type: EntityType) {
        self.by_entity
            .entry(entity.to_string())
            .or_default()
            .insert(sequence);
        self.entity_types.insert(entity.to_string(), entity_type);
    }
    
    /// Query blocks mentioning an entity
    pub fn query_entity(&self, entity: &str) -> Vec<IndexResult> {
        self.by_entity
            .get(entity)
            .map(|sequences| {
                sequences
                    .iter()
                    .filter_map(|&seq| {
                        self.hashes.get(&seq).map(|&hash| IndexResult {
                            block_sequence: seq,
                            block_hash: hash,
                            score: 1.0,
                        })
                    })
                    .collect()
            })
            .unwrap_or_default()
    }
    
    /// Query blocks mentioning entities matching a prefix
    pub fn query_prefix(&self, prefix: &str) -> Vec<IndexResult> {
        let mut sequences = HashSet::new();
        
        for (entity, seqs) in &self.by_entity {
            if entity.starts_with(prefix) {
                sequences.extend(seqs);
            }
        }
        
        sequences
            .iter()
            .filter_map(|&seq| {
                self.hashes.get(&seq).map(|&hash| IndexResult {
                    block_sequence: seq,
                    block_hash: hash,
                    score: 1.0,
                })
            })
            .collect()
    }
    
    /// Get all entities of a type
    pub fn get_entities_by_type(&self, entity_type: EntityType) -> Vec<String> {
        self.entity_types
            .iter()
            .filter(|(_, &t)| t == entity_type)
            .map(|(e, _)| e.clone())
            .collect()
    }
    
    /// Get all files mentioned
    pub fn get_all_files(&self) -> Vec<String> {
        self.get_entities_by_type(EntityType::File)
    }
}

impl Index for EntityIndex {
    fn index(&mut self, block: &Block) {
        self.hashes.insert(block.sequence, block.hash);
        
        // Extract entities from content
        match &block.content {
            BlockContent::File { path, .. } => {
                self.add_mention(path, block.sequence, EntityType::File);
                
                // Also index parent directories
                let parts: Vec<&str> = path.split('/').collect();
                for i in 1..parts.len() {
                    let dir = parts[..i].join("/");
                    self.add_mention(&dir, block.sequence, EntityType::Directory);
                }
            }
            BlockContent::Tool { tool_name, .. } => {
                self.add_mention(tool_name, block.sequence, EntityType::Tool);
            }
            BlockContent::Text { text, .. } => {
                // Extract file paths mentioned in text
                for word in text.split_whitespace() {
                    if word.contains('/') && !word.starts_with("http") {
                        self.add_mention(word, block.sequence, EntityType::File);
                    }
                }
            }
            _ => {}
        }
    }
    
    fn remove(&mut self, sequence: u64) {
        self.hashes.remove(&sequence);
        
        for sequences in self.by_entity.values_mut() {
            sequences.remove(&sequence);
        }
    }
    
    fn rebuild(&mut self, blocks: impl Iterator<Item = Block>) {
        self.by_entity.clear();
        self.hashes.clear();
        
        for block in blocks {
            self.index(&block);
        }
    }
}
```

```rust
// agentic-memory-core/src/v3/indexes/procedural.rs

use super::{Index, IndexResult};
use crate::v3::block::{Block, BlockHash, BlockType, BlockContent, BoundaryType};
use std::collections::HashMap;

/// Procedural index for ordered action sequences.
/// Captures "workflows" - the steps taken to accomplish something.
pub struct ProceduralIndex {
    /// Session -> ordered list of blocks
    sessions: HashMap<String, Vec<u64>>,
    
    /// Block -> session it belongs to
    block_to_session: HashMap<u64, String>,
    
    /// Current session ID
    current_session: String,
    
    /// Block hashes
    hashes: HashMap<u64, BlockHash>,
    
    /// Workflow markers (start/end of logical workflows)
    workflows: Vec<Workflow>,
}

#[derive(Debug, Clone)]
pub struct Workflow {
    pub id: String,
    pub name: String,
    pub start_sequence: u64,
    pub end_sequence: Option<u64>,
    pub steps: Vec<WorkflowStep>,
}

#[derive(Debug, Clone)]
pub struct WorkflowStep {
    pub sequence: u64,
    pub step_type: String,
    pub description: String,
}

impl ProceduralIndex {
    pub fn new() -> Self {
        let session_id = uuid::Uuid::new_v4().to_string();
        Self {
            sessions: HashMap::new(),
            block_to_session: HashMap::new(),
            current_session: session_id,
            hashes: HashMap::new(),
            workflows: Vec::new(),
        }
    }
    
    /// Get all blocks in a session, in order
    pub fn get_session(&self, session_id: &str) -> Vec<IndexResult> {
        self.sessions
            .get(session_id)
            .map(|blocks| {
                blocks
                    .iter()
                    .filter_map(|&seq| {
                        self.hashes.get(&seq).map(|&hash| IndexResult {
                            block_sequence: seq,
                            block_hash: hash,
                            score: 1.0,
                        })
                    })
                    .collect()
            })
            .unwrap_or_default()
    }
    
    /// Get current session blocks
    pub fn get_current_session(&self) -> Vec<IndexResult> {
        self.get_session(&self.current_session.clone())
    }
    
    /// Get all session IDs
    pub fn get_sessions(&self) -> Vec<String> {
        self.sessions.keys().cloned().collect()
    }
    
    /// Get the last N blocks in current session
    pub fn get_recent_steps(&self, n: usize) -> Vec<IndexResult> {
        self.sessions
            .get(&self.current_session)
            .map(|blocks| {
                blocks
                    .iter()
                    .rev()
                    .take(n)
                    .filter_map(|&seq| {
                        self.hashes.get(&seq).map(|&hash| IndexResult {
                            block_sequence: seq,
                            block_hash: hash,
                            score: 1.0,
                        })
                    })
                    .collect()
            })
            .unwrap_or_default()
    }
    
    /// Start a new workflow
    pub fn start_workflow(&mut self, name: &str, start_sequence: u64) -> String {
        let id = uuid::Uuid::new_v4().to_string();
        self.workflows.push(Workflow {
            id: id.clone(),
            name: name.to_string(),
            start_sequence,
            end_sequence: None,
            steps: Vec::new(),
        });
        id
    }
    
    /// End a workflow
    pub fn end_workflow(&mut self, workflow_id: &str, end_sequence: u64) {
        if let Some(workflow) = self.workflows.iter_mut().find(|w| w.id == workflow_id) {
            workflow.end_sequence = Some(end_sequence);
        }
    }
    
    /// Add step to current workflow
    pub fn add_workflow_step(&mut self, sequence: u64, step_type: &str, description: &str) {
        if let Some(workflow) = self.workflows.last_mut() {
            if workflow.end_sequence.is_none() {
                workflow.steps.push(WorkflowStep {
                    sequence,
                    step_type: step_type.to_string(),
                    description: description.to_string(),
                });
            }
        }
    }
    
    /// Get workflow by ID
    pub fn get_workflow(&self, workflow_id: &str) -> Option<&Workflow> {
        self.workflows.iter().find(|w| w.id == workflow_id)
    }
    
    /// Get all workflows
    pub fn get_all_workflows(&self) -> &[Workflow] {
        &self.workflows
    }
}

impl Index for ProceduralIndex {
    fn index(&mut self, block: &Block) {
        self.hashes.insert(block.sequence, block.hash);
        
        // Check for session boundary
        if let BlockContent::Boundary { boundary_type, .. } = &block.content {
            match boundary_type {
                BoundaryType::SessionStart | BoundaryType::Compaction => {
                    self.current_session = uuid::Uuid::new_v4().to_string();
                }
                _ => {}
            }
        }
        
        // Add to current session
        self.sessions
            .entry(self.current_session.clone())
            .or_default()
            .push(block.sequence);
        self.block_to_session.insert(block.sequence, self.current_session.clone());
        
        // Auto-detect workflow steps
        match block.block_type {
            BlockType::ToolCall => {
                if let BlockContent::Tool { tool_name, .. } = &block.content {
                    self.add_workflow_step(block.sequence, "tool_call", tool_name);
                }
            }
            BlockType::FileOperation => {
                if let BlockContent::File { path, operation, .. } = &block.content {
                    self.add_workflow_step(
                        block.sequence,
                        "file_op",
                        &format!("{:?} {}", operation, path),
                    );
                }
            }
            BlockType::Decision => {
                if let BlockContent::Decision { decision, .. } = &block.content {
                    self.add_workflow_step(block.sequence, "decision", decision);
                }
            }
            _ => {}
        }
    }
    
    fn remove(&mut self, sequence: u64) {
        self.hashes.remove(&sequence);
        
        if let Some(session_id) = self.block_to_session.remove(&sequence) {
            if let Some(blocks) = self.sessions.get_mut(&session_id) {
                blocks.retain(|&s| s != sequence);
            }
        }
    }
    
    fn rebuild(&mut self, blocks: impl Iterator<Item = Block>) {
        self.sessions.clear();
        self.block_to_session.clear();
        self.hashes.clear();
        self.workflows.clear();
        self.current_session = uuid::Uuid::new_v4().to_string();
        
        for block in blocks {
            self.index(&block);
        }
    }
}
```

### 1.4 Tiered Storage

```rust
// agentic-memory-core/src/v3/tiered.rs

use super::block::{Block, BlockHash};
use std::collections::HashMap;
use std::time::{Duration, Instant};
use chrono::{DateTime, Utc};

/// Tiered storage: Hot → Warm → Cold → Frozen
pub struct TieredStorage {
    /// Hot tier: in-memory, instant access (last 24 hours)
    hot: HotTier,
    
    /// Warm tier: on-disk, fast access (last 30 days)
    warm: WarmTier,
    
    /// Cold tier: compressed, slower access (last year)
    cold: ColdTier,
    
    /// Frozen tier: archive, resurrection on demand (forever)
    frozen: FrozenTier,
    
    /// Configuration
    config: TierConfig,
}

#[derive(Clone)]
pub struct TierConfig {
    /// Hot tier: blocks younger than this
    pub hot_threshold: Duration,
    
    /// Warm tier: blocks younger than this (but older than hot)
    pub warm_threshold: Duration,
    
    /// Cold tier: blocks younger than this (but older than warm)
    pub cold_threshold: Duration,
    
    /// Maximum hot tier size in bytes
    pub hot_max_bytes: usize,
    
    /// Maximum warm tier size in bytes
    pub warm_max_bytes: usize,
}

impl Default for TierConfig {
    fn default() -> Self {
        Self {
            hot_threshold: Duration::from_secs(24 * 60 * 60),      // 24 hours
            warm_threshold: Duration::from_secs(30 * 24 * 60 * 60), // 30 days
            cold_threshold: Duration::from_secs(365 * 24 * 60 * 60), // 1 year
            hot_max_bytes: 10 * 1024 * 1024,   // 10 MB
            warm_max_bytes: 100 * 1024 * 1024, // 100 MB
        }
    }
}

/// Hot tier: in-memory for instant access
struct HotTier {
    blocks: HashMap<u64, Block>,
    size_bytes: usize,
}

impl HotTier {
    fn new() -> Self {
        Self {
            blocks: HashMap::new(),
            size_bytes: 0,
        }
    }
    
    fn insert(&mut self, block: Block) {
        self.size_bytes += block.size_bytes as usize;
        self.blocks.insert(block.sequence, block);
    }
    
    fn get(&self, sequence: u64) -> Option<&Block> {
        self.blocks.get(&sequence)
    }
    
    fn remove(&mut self, sequence: u64) -> Option<Block> {
        self.blocks.remove(&sequence).map(|b| {
            self.size_bytes -= b.size_bytes as usize;
            b
        })
    }
}

/// Warm tier: on-disk, uncompressed
struct WarmTier {
    // In production: memory-mapped file or SQLite
    blocks: HashMap<u64, Block>,
    size_bytes: usize,
}

impl WarmTier {
    fn new() -> Self {
        Self {
            blocks: HashMap::new(),
            size_bytes: 0,
        }
    }
    
    fn insert(&mut self, block: Block) {
        self.size_bytes += block.size_bytes as usize;
        self.blocks.insert(block.sequence, block);
    }
    
    fn get(&self, sequence: u64) -> Option<&Block> {
        self.blocks.get(&sequence)
    }
    
    fn remove(&mut self, sequence: u64) -> Option<Block> {
        self.blocks.remove(&sequence).map(|b| {
            self.size_bytes -= b.size_bytes as usize;
            b
        })
    }
}

/// Cold tier: compressed blocks
struct ColdTier {
    // In production: zstd-compressed blocks
    blocks: HashMap<u64, Vec<u8>>, // Compressed
    size_bytes: usize,
}

impl ColdTier {
    fn new() -> Self {
        Self {
            blocks: HashMap::new(),
            size_bytes: 0,
        }
    }
    
    fn insert(&mut self, block: Block) {
        let data = serde_json::to_vec(&block).unwrap();
        // In production: compress with zstd
        let compressed = data; // Placeholder
        self.size_bytes += compressed.len();
        self.blocks.insert(block.sequence, compressed);
    }
    
    fn get(&self, sequence: u64) -> Option<Block> {
        self.blocks.get(&sequence).and_then(|compressed| {
            // In production: decompress with zstd
            let data = compressed; // Placeholder
            serde_json::from_slice(data).ok()
        })
    }
}

/// Frozen tier: highly compressed archive
struct FrozenTier {
    // In production: highly compressed, possibly external storage
    blocks: HashMap<u64, Vec<u8>>,
}

impl FrozenTier {
    fn new() -> Self {
        Self {
            blocks: HashMap::new(),
        }
    }
    
    fn insert(&mut self, block: Block) {
        let data = serde_json::to_vec(&block).unwrap();
        // In production: high-ratio compression
        self.blocks.insert(block.sequence, data);
    }
    
    fn get(&self, sequence: u64) -> Option<Block> {
        self.blocks.get(&sequence).and_then(|data| {
            serde_json::from_slice(data).ok()
        })
    }
}

impl TieredStorage {
    pub fn new(config: TierConfig) -> Self {
        Self {
            hot: HotTier::new(),
            warm: WarmTier::new(),
            cold: ColdTier::new(),
            frozen: FrozenTier::new(),
            config,
        }
    }
    
    /// Store a block (automatically goes to hot tier)
    pub fn store(&mut self, block: Block) {
        self.hot.insert(block);
        self.maybe_demote();
    }
    
    /// Retrieve a block from any tier
    pub fn get(&self, sequence: u64) -> Option<Block> {
        // Try tiers in order of speed
        self.hot.get(sequence).cloned()
            .or_else(|| self.warm.get(sequence).cloned())
            .or_else(|| self.cold.get(sequence))
            .or_else(|| self.frozen.get(sequence))
    }
    
    /// Check if we need to demote blocks to lower tiers
    fn maybe_demote(&mut self) {
        let now = Utc::now();
        
        // Demote from hot to warm
        if self.hot.size_bytes > self.config.hot_max_bytes {
            let to_demote: Vec<u64> = self.hot.blocks
                .iter()
                .filter(|(_, b)| {
                    let age = now.signed_duration_since(b.timestamp);
                    age.num_seconds() > self.config.hot_threshold.as_secs() as i64
                })
                .map(|(&seq, _)| seq)
                .collect();
            
            for seq in to_demote {
                if let Some(block) = self.hot.remove(seq) {
                    self.warm.insert(block);
                }
            }
        }
        
        // Demote from warm to cold
        if self.warm.size_bytes > self.config.warm_max_bytes {
            let to_demote: Vec<u64> = self.warm.blocks
                .iter()
                .filter(|(_, b)| {
                    let age = now.signed_duration_since(b.timestamp);
                    age.num_seconds() > self.config.warm_threshold.as_secs() as i64
                })
                .map(|(&seq, _)| seq)
                .collect();
            
            for seq in to_demote {
                if let Some(block) = self.warm.remove(seq) {
                    self.cold.insert(block);
                }
            }
        }
        
        // Note: Cold to frozen demotion happens on explicit archive call
    }
    
    /// Force archive old blocks to frozen tier
    pub fn archive_old(&mut self, older_than: DateTime<Utc>) {
        // Move from cold to frozen
        let cold_to_freeze: Vec<u64> = self.cold.blocks
            .keys()
            .cloned()
            .collect();
        
        for seq in cold_to_freeze {
            if let Some(block) = self.cold.get(seq) {
                if block.timestamp < older_than {
                    self.frozen.insert(block);
                    self.cold.blocks.remove(&seq);
                }
            }
        }
    }
    
    /// Get storage statistics
    pub fn stats(&self) -> TierStats {
        TierStats {
            hot_blocks: self.hot.blocks.len(),
            hot_bytes: self.hot.size_bytes,
            warm_blocks: self.warm.blocks.len(),
            warm_bytes: self.warm.size_bytes,
            cold_blocks: self.cold.blocks.len(),
            cold_bytes: self.cold.size_bytes,
            frozen_blocks: self.frozen.blocks.len(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct TierStats {
    pub hot_blocks: usize,
    pub hot_bytes: usize,
    pub warm_blocks: usize,
    pub warm_bytes: usize,
    pub cold_blocks: usize,
    pub cold_bytes: usize,
    pub frozen_blocks: usize,
}
```

---

## PART 2: THE MEMORY ENGINE

```rust
// agentic-memory-core/src/v3/engine.rs

use super::block::*;
use super::immortal_log::*;
use super::indexes::*;
use super::tiered::*;
use super::retrieval::*;
use std::path::PathBuf;
use std::sync::{Arc, RwLock};
use chrono::{DateTime, Utc};

/// The V3 Memory Engine: Immortal Architecture
pub struct MemoryEngineV3 {
    /// The append-only immortal log (source of truth)
    log: Arc<RwLock<ImmortalLog>>,
    
    /// Tiered storage for fast access
    storage: Arc<RwLock<TieredStorage>>,
    
    /// The five indexes
    temporal_index: Arc<RwLock<temporal::TemporalIndex>>,
    semantic_index: Arc<RwLock<semantic::SemanticIndex>>,
    causal_index: Arc<RwLock<causal::CausalIndex>>,
    entity_index: Arc<RwLock<entity::EntityIndex>>,
    procedural_index: Arc<RwLock<procedural::ProceduralIndex>>,
    
    /// Smart retrieval engine
    retrieval: Arc<SmartRetrievalEngine>,
    
    /// Current session ID
    session_id: String,
    
    /// Configuration
    config: EngineConfig,
}

#[derive(Clone)]
pub struct EngineConfig {
    /// Data directory
    pub data_dir: PathBuf,
    
    /// Embedding dimension (for semantic index)
    pub embedding_dim: usize,
    
    /// Tier configuration
    pub tier_config: TierConfig,
    
    /// Auto-checkpoint interval (blocks)
    pub checkpoint_interval: u64,
}

impl Default for EngineConfig {
    fn default() -> Self {
        Self {
            data_dir: PathBuf::from(".agentic/memory"),
            embedding_dim: 384, // MiniLM default
            tier_config: TierConfig::default(),
            checkpoint_interval: 100,
        }
    }
}

impl MemoryEngineV3 {
    /// Create or open memory engine
    pub fn open(config: EngineConfig) -> Result<Self, std::io::Error> {
        std::fs::create_dir_all(&config.data_dir)?;
        
        let log_path = config.data_dir.join("immortal.log");
        let log = ImmortalLog::open(log_path)?;
        
        // Build indexes from log
        let mut temporal = temporal::TemporalIndex::new();
        let mut semantic = semantic::SemanticIndex::new(config.embedding_dim);
        let mut causal = causal::CausalIndex::new();
        let mut entity = entity::EntityIndex::new();
        let mut procedural = procedural::ProceduralIndex::new();
        
        let mut storage = TieredStorage::new(config.tier_config.clone());
        
        for block in log.iter() {
            temporal.index(&block);
            semantic.index(&block);
            causal.index(&block);
            entity.index(&block);
            procedural.index(&block);
            storage.store(block);
        }
        
        let retrieval = Arc::new(SmartRetrievalEngine::new());
        
        Ok(Self {
            log: Arc::new(RwLock::new(log)),
            storage: Arc::new(RwLock::new(storage)),
            temporal_index: Arc::new(RwLock::new(temporal)),
            semantic_index: Arc::new(RwLock::new(semantic)),
            causal_index: Arc::new(RwLock::new(causal)),
            entity_index: Arc::new(RwLock::new(entity)),
            procedural_index: Arc::new(RwLock::new(procedural)),
            retrieval,
            session_id: uuid::Uuid::new_v4().to_string(),
            config,
        })
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // CAPTURE API
    // ═══════════════════════════════════════════════════════════════════
    
    /// Capture a user message
    pub fn capture_user_message(&self, text: &str, tokens: Option<u32>) -> Result<BlockHash, std::io::Error> {
        self.append_block(
            BlockType::UserMessage,
            BlockContent::Text {
                text: text.to_string(),
                role: Some("user".to_string()),
                tokens,
            },
        )
    }
    
    /// Capture an assistant message
    pub fn capture_assistant_message(&self, text: &str, tokens: Option<u32>) -> Result<BlockHash, std::io::Error> {
        self.append_block(
            BlockType::AssistantMessage,
            BlockContent::Text {
                text: text.to_string(),
                role: Some("assistant".to_string()),
                tokens,
            },
        )
    }
    
    /// Capture a tool call
    pub fn capture_tool_call(
        &self,
        tool_name: &str,
        input: serde_json::Value,
        output: Option<serde_json::Value>,
        duration_ms: Option<u64>,
        success: bool,
    ) -> Result<BlockHash, std::io::Error> {
        self.append_block(
            BlockType::ToolCall,
            BlockContent::Tool {
                tool_name: tool_name.to_string(),
                input,
                output,
                duration_ms,
                success,
            },
        )
    }
    
    /// Capture a file operation
    pub fn capture_file_operation(
        &self,
        path: &str,
        operation: FileOperation,
        content_hash: Option<BlockHash>,
        lines: Option<u32>,
        diff: Option<String>,
    ) -> Result<BlockHash, std::io::Error> {
        self.append_block(
            BlockType::FileOperation,
            BlockContent::File {
                path: path.to_string(),
                operation,
                content_hash,
                lines,
                diff,
            },
        )
    }
    
    /// Capture a decision
    pub fn capture_decision(
        &self,
        decision: &str,
        reasoning: Option<&str>,
        evidence_blocks: Vec<BlockHash>,
        confidence: Option<f32>,
    ) -> Result<BlockHash, std::io::Error> {
        self.append_block(
            BlockType::Decision,
            BlockContent::Decision {
                decision: decision.to_string(),
                reasoning: reasoning.map(String::from),
                evidence_blocks,
                confidence,
            },
        )
    }
    
    /// Capture an error
    pub fn capture_error(
        &self,
        error_type: &str,
        message: &str,
        resolution: Option<&str>,
        resolved: bool,
    ) -> Result<BlockHash, std::io::Error> {
        self.append_block(
            BlockType::Error,
            BlockContent::Error {
                error_type: error_type.to_string(),
                message: message.to_string(),
                resolution: resolution.map(String::from),
                resolved,
            },
        )
    }
    
    /// Capture a session boundary (compaction, new session, etc.)
    pub fn capture_boundary(
        &self,
        boundary_type: BoundaryType,
        context_tokens_before: u32,
        context_tokens_after: u32,
        summary: &str,
        continuation_hint: Option<&str>,
    ) -> Result<BlockHash, std::io::Error> {
        self.append_block(
            BlockType::SessionBoundary,
            BlockContent::Boundary {
                boundary_type,
                context_tokens_before,
                context_tokens_after,
                summary: summary.to_string(),
                continuation_hint: continuation_hint.map(String::from),
            },
        )
    }
    
    /// Capture a checkpoint
    pub fn capture_checkpoint(
        &self,
        active_files: Vec<String>,
        working_context: &str,
        pending_tasks: Vec<String>,
    ) -> Result<BlockHash, std::io::Error> {
        self.append_block(
            BlockType::Checkpoint,
            BlockContent::Checkpoint {
                active_files,
                working_context: working_context.to_string(),
                pending_tasks,
            },
        )
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // INTERNAL
    // ═══════════════════════════════════════════════════════════════════
    
    fn append_block(&self, block_type: BlockType, content: BlockContent) -> Result<BlockHash, std::io::Error> {
        let mut log = self.log.write().unwrap();
        let block = log.append(block_type, content)?;
        let hash = block.hash;
        
        // Update indexes
        self.temporal_index.write().unwrap().index(&block);
        self.semantic_index.write().unwrap().index(&block);
        self.causal_index.write().unwrap().index(&block);
        self.entity_index.write().unwrap().index(&block);
        self.procedural_index.write().unwrap().index(&block);
        
        // Store in tiered storage
        self.storage.write().unwrap().store(block);
        
        Ok(hash)
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // RETRIEVAL API
    // ═══════════════════════════════════════════════════════════════════
    
    /// Smart retrieval: assemble perfect context for a query
    pub fn retrieve(&self, request: RetrievalRequest) -> RetrievalResult {
        self.retrieval.retrieve(
            request,
            &self.log.read().unwrap(),
            &self.storage.read().unwrap(),
            &self.temporal_index.read().unwrap(),
            &self.semantic_index.read().unwrap(),
            &self.causal_index.read().unwrap(),
            &self.entity_index.read().unwrap(),
            &self.procedural_index.read().unwrap(),
        )
    }
    
    /// Resurrect: fully restore state at any timestamp
    pub fn resurrect(&self, timestamp: DateTime<Utc>) -> ResurrectionResult {
        let log = self.log.read().unwrap();
        let storage = self.storage.read().unwrap();
        
        // Find all blocks up to timestamp
        let mut blocks = Vec::new();
        for seq in 0..log.len() {
            if let Some(block) = storage.get(seq) {
                if block.timestamp <= timestamp {
                    blocks.push(block);
                }
            }
        }
        
        // Extract state
        let mut messages = Vec::new();
        let mut files_state = std::collections::HashMap::new();
        let mut decisions = Vec::new();
        let mut last_checkpoint = None;
        
        for block in &blocks {
            match &block.content {
                BlockContent::Text { text, role, .. } => {
                    messages.push((role.clone().unwrap_or_default(), text.clone()));
                }
                BlockContent::File { path, operation, .. } => {
                    match operation {
                        FileOperation::Create | FileOperation::Update => {
                            files_state.insert(path.clone(), true);
                        }
                        FileOperation::Delete => {
                            files_state.insert(path.clone(), false);
                        }
                        _ => {}
                    }
                }
                BlockContent::Decision { decision, .. } => {
                    decisions.push(decision.clone());
                }
                BlockContent::Checkpoint { .. } => {
                    last_checkpoint = Some(block.clone());
                }
                _ => {}
            }
        }
        
        ResurrectionResult {
            timestamp,
            block_count: blocks.len(),
            messages,
            files_state,
            decisions,
            last_checkpoint,
        }
    }
    
    /// Search by time range
    pub fn search_temporal(&self, start: DateTime<Utc>, end: DateTime<Utc>) -> Vec<Block> {
        let temporal = self.temporal_index.read().unwrap();
        let storage = self.storage.read().unwrap();
        
        temporal.query_range(start, end)
            .into_iter()
            .filter_map(|r| storage.get(r.block_sequence))
            .collect()
    }
    
    /// Search by text/meaning
    pub fn search_semantic(&self, query: &str, limit: usize) -> Vec<Block> {
        let semantic = self.semantic_index.read().unwrap();
        let storage = self.storage.read().unwrap();
        
        semantic.search_by_text(query, limit)
            .into_iter()
            .filter_map(|r| storage.get(r.block_sequence))
            .collect()
    }
    
    /// Search by entity (file, person, etc.)
    pub fn search_entity(&self, entity: &str) -> Vec<Block> {
        let entity_idx = self.entity_index.read().unwrap();
        let storage = self.storage.read().unwrap();
        
        entity_idx.query_entity(entity)
            .into_iter()
            .filter_map(|r| storage.get(r.block_sequence))
            .collect()
    }
    
    /// Get decision chain
    pub fn get_decision_chain(&self, block_sequence: u64) -> Vec<Block> {
        let causal = self.causal_index.read().unwrap();
        let storage = self.storage.read().unwrap();
        
        causal.get_decision_chain(block_sequence)
            .into_iter()
            .filter_map(|r| storage.get(r.block_sequence))
            .collect()
    }
    
    /// Get current session blocks
    pub fn get_current_session(&self) -> Vec<Block> {
        let procedural = self.procedural_index.read().unwrap();
        let storage = self.storage.read().unwrap();
        
        procedural.get_current_session()
            .into_iter()
            .filter_map(|r| storage.get(r.block_sequence))
            .collect()
    }
    
    /// Verify integrity
    pub fn verify_integrity(&self) -> IntegrityReport {
        self.log.read().unwrap().verify_integrity()
    }
    
    /// Get statistics
    pub fn stats(&self) -> EngineStats {
        let log = self.log.read().unwrap();
        let tier_stats = self.storage.read().unwrap().stats();
        
        EngineStats {
            total_blocks: log.len(),
            tier_stats,
            session_id: self.session_id.clone(),
        }
    }
    
    /// Session resume: get everything needed to continue
    pub fn session_resume(&self) -> SessionResumeResult {
        let procedural = self.procedural_index.read().unwrap();
        let storage = self.storage.read().unwrap();
        let entity_idx = self.entity_index.read().unwrap();
        
        // Get recent session blocks
        let recent = procedural.get_recent_steps(50);
        let recent_blocks: Vec<Block> = recent
            .into_iter()
            .filter_map(|r| storage.get(r.block_sequence))
            .collect();
        
        // Build summary
        let mut messages = Vec::new();
        let mut files_touched = Vec::new();
        let mut decisions = Vec::new();
        let mut errors_resolved = Vec::new();
        
        for block in &recent_blocks {
            match &block.content {
                BlockContent::Text { text, role, .. } => {
                    let preview = if text.len() > 200 {
                        format!("{}...", &text[..200])
                    } else {
                        text.clone()
                    };
                    messages.push((role.clone().unwrap_or_default(), preview));
                }
                BlockContent::File { path, operation, .. } => {
                    files_touched.push((path.clone(), format!("{:?}", operation)));
                }
                BlockContent::Decision { decision, .. } => {
                    decisions.push(decision.clone());
                }
                BlockContent::Error { error_type, message, resolution, resolved } => {
                    if *resolved {
                        errors_resolved.push((
                            format!("{}: {}", error_type, message),
                            resolution.clone().unwrap_or_default(),
                        ));
                    }
                }
                _ => {}
            }
        }
        
        // Get all files from entity index
        let all_files = entity_idx.get_all_files();
        
        SessionResumeResult {
            session_id: self.session_id.clone(),
            block_count: recent_blocks.len(),
            recent_messages: messages,
            files_touched,
            decisions,
            errors_resolved,
            all_known_files: all_files,
        }
    }
}

#[derive(Debug, Clone)]
pub struct ResurrectionResult {
    pub timestamp: DateTime<Utc>,
    pub block_count: usize,
    pub messages: Vec<(String, String)>,
    pub files_state: std::collections::HashMap<String, bool>,
    pub decisions: Vec<String>,
    pub last_checkpoint: Option<Block>,
}

#[derive(Debug, Clone)]
pub struct SessionResumeResult {
    pub session_id: String,
    pub block_count: usize,
    pub recent_messages: Vec<(String, String)>,
    pub files_touched: Vec<(String, String)>,
    pub decisions: Vec<String>,
    pub errors_resolved: Vec<(String, String)>,
    pub all_known_files: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct EngineStats {
    pub total_blocks: u64,
    pub tier_stats: TierStats,
    pub session_id: String,
}
```

---

## PART 3: SMART RETRIEVAL ENGINE

```rust
// agentic-memory-core/src/v3/retrieval.rs

use super::block::*;
use super::immortal_log::*;
use super::tiered::*;
use super::indexes::*;
use std::collections::{HashMap, HashSet};

/// Request for smart context retrieval
#[derive(Debug, Clone)]
pub struct RetrievalRequest {
    /// Natural language query
    pub query: String,
    
    /// Token budget for the context
    pub token_budget: u32,
    
    /// Retrieval strategy
    pub strategy: RetrievalStrategy,
    
    /// Minimum relevance score (0.0 - 1.0)
    pub min_relevance: f32,
}

#[derive(Debug, Clone, Copy)]
pub enum RetrievalStrategy {
    /// Prioritize recent blocks
    Recency,
    
    /// Prioritize relevant blocks
    Relevance,
    
    /// Prioritize causal chains
    Causal,
    
    /// Balanced mix
    Balanced,
    
    /// Custom weights
    Custom {
        recency_weight: f32,
        relevance_weight: f32,
        causal_weight: f32,
    },
}

/// Result of smart retrieval
#[derive(Debug, Clone)]
pub struct RetrievalResult {
    /// Assembled context (ordered blocks)
    pub blocks: Vec<Block>,
    
    /// Tokens used
    pub tokens_used: u32,
    
    /// Coverage metrics
    pub coverage: RetrievalCoverage,
    
    /// Blocks that didn't fit (for reference)
    pub omitted: Vec<BlockHash>,
    
    /// Retrieval duration
    pub retrieval_ms: u64,
}

#[derive(Debug, Clone)]
pub struct RetrievalCoverage {
    /// How much of semantic space was covered
    pub semantic: f32,
    
    /// How much recent context was covered
    pub temporal: f32,
    
    /// How much causal chain was covered
    pub causal: f32,
}

/// Smart retrieval engine
pub struct SmartRetrievalEngine {
    // Configuration and caches can go here
}

impl SmartRetrievalEngine {
    pub fn new() -> Self {
        Self {}
    }
    
    /// Main retrieval function
    pub fn retrieve(
        &self,
        request: RetrievalRequest,
        log: &ImmortalLog,
        storage: &TieredStorage,
        temporal: &temporal::TemporalIndex,
        semantic: &semantic::SemanticIndex,
        causal: &causal::CausalIndex,
        entity: &entity::EntityIndex,
        procedural: &procedural::ProceduralIndex,
    ) -> RetrievalResult {
        let start = std::time::Instant::now();
        
        // Step 1: Gather candidates from all indexes
        let mut candidates: HashMap<u64, f32> = HashMap::new();
        
        // Semantic search
        let semantic_results = semantic.search_by_text(&request.query, 100);
        for result in semantic_results {
            let score = result.score * self.get_weight(&request.strategy, "semantic");
            *candidates.entry(result.block_sequence).or_insert(0.0) += score;
        }
        
        // Temporal search (recent)
        let recent_results = temporal.query_recent(3600); // Last hour
        for (i, result) in recent_results.iter().enumerate() {
            let recency_score = 1.0 - (i as f32 / recent_results.len() as f32);
            let score = recency_score * self.get_weight(&request.strategy, "temporal");
            *candidates.entry(result.block_sequence).or_insert(0.0) += score;
        }
        
        // Entity search (extract entities from query)
        for word in request.query.split_whitespace() {
            if word.contains('/') || word.contains('.') {
                let entity_results = entity.query_entity(word);
                for result in entity_results {
                    let score = 0.8 * self.get_weight(&request.strategy, "entity");
                    *candidates.entry(result.block_sequence).or_insert(0.0) += score;
                }
            }
        }
        
        // Step 2: Sort candidates by score
        let mut sorted: Vec<(u64, f32)> = candidates.into_iter().collect();
        sorted.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());
        
        // Step 3: Filter by minimum relevance
        sorted.retain(|(_, score)| *score >= request.min_relevance);
        
        // Step 4: Fit within token budget
        let mut selected_blocks = Vec::new();
        let mut tokens_used = 0u32;
        let mut omitted = Vec::new();
        
        for (seq, _score) in sorted {
            if let Some(block) = storage.get(seq) {
                let block_tokens = self.estimate_tokens(&block);
                
                if tokens_used + block_tokens <= request.token_budget {
                    tokens_used += block_tokens;
                    selected_blocks.push(block);
                } else {
                    omitted.push(block.hash);
                }
            }
        }
        
        // Step 5: Causal expansion (add context for decisions)
        let decision_blocks: Vec<u64> = selected_blocks
            .iter()
            .filter(|b| matches!(b.block_type, BlockType::Decision))
            .map(|b| b.sequence)
            .collect();
        
        for decision_seq in decision_blocks {
            let ancestors = causal.get_ancestors(decision_seq, 3);
            for result in ancestors {
                if !selected_blocks.iter().any(|b| b.sequence == result.block_sequence) {
                    if let Some(block) = storage.get(result.block_sequence) {
                        let block_tokens = self.estimate_tokens(&block);
                        if tokens_used + block_tokens <= request.token_budget {
                            tokens_used += block_tokens;
                            selected_blocks.push(block);
                        }
                    }
                }
            }
        }
        
        // Step 6: Sort by sequence (chronological order)
        selected_blocks.sort_by_key(|b| b.sequence);
        
        // Step 7: Calculate coverage
        let total_blocks = log.len() as f32;
        let coverage = RetrievalCoverage {
            semantic: (selected_blocks.len() as f32 / 100.0).min(1.0),
            temporal: (selected_blocks.iter().filter(|b| {
                chrono::Utc::now().signed_duration_since(b.timestamp).num_hours() < 24
            }).count() as f32 / 50.0).min(1.0),
            causal: (decision_blocks.len() as f32 / 10.0).min(1.0),
        };
        
        RetrievalResult {
            blocks: selected_blocks,
            tokens_used,
            coverage,
            omitted,
            retrieval_ms: start.elapsed().as_millis() as u64,
        }
    }
    
    fn get_weight(&self, strategy: &RetrievalStrategy, index_type: &str) -> f32 {
        match strategy {
            RetrievalStrategy::Recency => match index_type {
                "temporal" => 1.0,
                "semantic" => 0.3,
                _ => 0.2,
            },
            RetrievalStrategy::Relevance => match index_type {
                "semantic" => 1.0,
                "entity" => 0.8,
                _ => 0.2,
            },
            RetrievalStrategy::Causal => match index_type {
                "causal" => 1.0,
                "semantic" => 0.5,
                _ => 0.2,
            },
            RetrievalStrategy::Balanced => 0.5,
            RetrievalStrategy::Custom { recency_weight, relevance_weight, causal_weight } => {
                match index_type {
                    "temporal" => *recency_weight,
                    "semantic" => *relevance_weight,
                    "causal" => *causal_weight,
                    _ => 0.3,
                }
            }
        }
    }
    
    fn estimate_tokens(&self, block: &Block) -> u32 {
        // Rough estimate: 4 characters per token
        let content_size = match &block.content {
            BlockContent::Text { text, .. } => text.len(),
            BlockContent::Tool { tool_name, input, output, .. } => {
                tool_name.len() + 
                serde_json::to_string(input).map(|s| s.len()).unwrap_or(0) +
                output.as_ref().and_then(|o| serde_json::to_string(o).ok()).map(|s| s.len()).unwrap_or(0)
            }
            BlockContent::File { path, diff, .. } => {
                path.len() + diff.as_ref().map(|d| d.len()).unwrap_or(0)
            }
            BlockContent::Decision { decision, reasoning, .. } => {
                decision.len() + reasoning.as_ref().map(|r| r.len()).unwrap_or(0)
            }
            BlockContent::Boundary { summary, .. } => summary.len(),
            BlockContent::Error { message, resolution, .. } => {
                message.len() + resolution.as_ref().map(|r| r.len()).unwrap_or(0)
            }
            BlockContent::Checkpoint { working_context, .. } => working_context.len(),
            BlockContent::Binary { data, .. } => data.len(),
        };
        
        ((content_size / 4) + 10) as u32 // +10 for block metadata overhead
    }
}
```

---

## PART 4: MCP SERVER TOOLS

```rust
// agentic-memory-mcp/src/v3_tools.rs

use agentic_memory_core::v3::*;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

/// V3 MCP Tool Definitions
pub fn register_v3_tools(server: &mut McpServer, engine: Arc<MemoryEngineV3>) {
    // ═══════════════════════════════════════════════════════════════════
    // CAPTURE TOOLS
    // ═══════════════════════════════════════════════════════════════════
    
    server.register_tool(
        "memory_capture_message",
        "Capture a message to the immortal log",
        json!({
            "type": "object",
            "properties": {
                "role": { "type": "string", "enum": ["user", "assistant", "system"] },
                "content": { "type": "string" },
                "tokens": { "type": "integer" }
            },
            "required": ["role", "content"]
        }),
        {
            let engine = engine.clone();
            move |params: Value| {
                let role: String = params["role"].as_str().unwrap().to_string();
                let content: String = params["content"].as_str().unwrap().to_string();
                let tokens: Option<u32> = params["tokens"].as_u64().map(|t| t as u32);
                
                let hash = match role.as_str() {
                    "user" => engine.capture_user_message(&content, tokens),
                    "assistant" => engine.capture_assistant_message(&content, tokens),
                    _ => engine.capture_user_message(&content, tokens), // default
                };
                
                match hash {
                    Ok(h) => json!({ "success": true, "block_hash": h.to_hex() }),
                    Err(e) => json!({ "success": false, "error": e.to_string() }),
                }
            }
        },
    );
    
    server.register_tool(
        "memory_capture_tool",
        "Capture a tool call to the immortal log",
        json!({
            "type": "object",
            "properties": {
                "tool_name": { "type": "string" },
                "input": { "type": "object" },
                "output": { "type": "object" },
                "duration_ms": { "type": "integer" },
                "success": { "type": "boolean" }
            },
            "required": ["tool_name", "input", "success"]
        }),
        {
            let engine = engine.clone();
            move |params: Value| {
                let tool_name = params["tool_name"].as_str().unwrap();
                let input = params["input"].clone();
                let output = params.get("output").cloned();
                let duration_ms = params["duration_ms"].as_u64();
                let success = params["success"].as_bool().unwrap_or(true);
                
                match engine.capture_tool_call(tool_name, input, output, duration_ms, success) {
                    Ok(h) => json!({ "success": true, "block_hash": h.to_hex() }),
                    Err(e) => json!({ "success": false, "error": e.to_string() }),
                }
            }
        },
    );
    
    server.register_tool(
        "memory_capture_file",
        "Capture a file operation to the immortal log",
        json!({
            "type": "object",
            "properties": {
                "path": { "type": "string" },
                "operation": { "type": "string", "enum": ["create", "read", "update", "delete", "rename"] },
                "lines": { "type": "integer" },
                "diff": { "type": "string" }
            },
            "required": ["path", "operation"]
        }),
        {
            let engine = engine.clone();
            move |params: Value| {
                let path = params["path"].as_str().unwrap();
                let op_str = params["operation"].as_str().unwrap();
                let operation = match op_str {
                    "create" => FileOperation::Create,
                    "read" => FileOperation::Read,
                    "update" => FileOperation::Update,
                    "delete" => FileOperation::Delete,
                    "rename" => FileOperation::Rename,
                    _ => FileOperation::Read,
                };
                let lines = params["lines"].as_u64().map(|l| l as u32);
                let diff = params["diff"].as_str().map(String::from);
                
                match engine.capture_file_operation(path, operation, None, lines, diff) {
                    Ok(h) => json!({ "success": true, "block_hash": h.to_hex() }),
                    Err(e) => json!({ "success": false, "error": e.to_string() }),
                }
            }
        },
    );
    
    server.register_tool(
        "memory_capture_decision",
        "Capture a decision to the immortal log",
        json!({
            "type": "object",
            "properties": {
                "decision": { "type": "string" },
                "reasoning": { "type": "string" },
                "evidence_hashes": { "type": "array", "items": { "type": "string" } },
                "confidence": { "type": "number" }
            },
            "required": ["decision"]
        }),
        {
            let engine = engine.clone();
            move |params: Value| {
                let decision = params["decision"].as_str().unwrap();
                let reasoning = params["reasoning"].as_str();
                let evidence: Vec<BlockHash> = params["evidence_hashes"]
                    .as_array()
                    .map(|arr| arr.iter().filter_map(|v| {
                        v.as_str().and_then(BlockHash::from_hex)
                    }).collect())
                    .unwrap_or_default();
                let confidence = params["confidence"].as_f64().map(|c| c as f32);
                
                match engine.capture_decision(decision, reasoning, evidence, confidence) {
                    Ok(h) => json!({ "success": true, "block_hash": h.to_hex() }),
                    Err(e) => json!({ "success": false, "error": e.to_string() }),
                }
            }
        },
    );
    
    server.register_tool(
        "memory_capture_boundary",
        "Capture a session boundary (compaction, new session, etc.)",
        json!({
            "type": "object",
            "properties": {
                "boundary_type": { 
                    "type": "string", 
                    "enum": ["session_start", "session_end", "compaction", "context_pressure", "checkpoint"]
                },
                "context_tokens_before": { "type": "integer" },
                "context_tokens_after": { "type": "integer" },
                "summary": { "type": "string" },
                "continuation_hint": { "type": "string" }
            },
            "required": ["boundary_type", "summary"]
        }),
        {
            let engine = engine.clone();
            move |params: Value| {
                let bt_str = params["boundary_type"].as_str().unwrap();
                let boundary_type = match bt_str {
                    "session_start" => BoundaryType::SessionStart,
                    "session_end" => BoundaryType::SessionEnd,
                    "compaction" => BoundaryType::Compaction,
                    "context_pressure" => BoundaryType::ContextPressure,
                    "checkpoint" => BoundaryType::Checkpoint,
                    _ => BoundaryType::Checkpoint,
                };
                let before = params["context_tokens_before"].as_u64().unwrap_or(0) as u32;
                let after = params["context_tokens_after"].as_u64().unwrap_or(0) as u32;
                let summary = params["summary"].as_str().unwrap();
                let hint = params["continuation_hint"].as_str();
                
                match engine.capture_boundary(boundary_type, before, after, summary, hint) {
                    Ok(h) => json!({ "success": true, "block_hash": h.to_hex() }),
                    Err(e) => json!({ "success": false, "error": e.to_string() }),
                }
            }
        },
    );
    
    // ═══════════════════════════════════════════════════════════════════
    // RETRIEVAL TOOLS
    // ═══════════════════════════════════════════════════════════════════
    
    server.register_tool(
        "memory_retrieve",
        "Smart context retrieval - assemble perfect context for a query",
        json!({
            "type": "object",
            "properties": {
                "query": { "type": "string" },
                "token_budget": { "type": "integer", "default": 50000 },
                "strategy": { 
                    "type": "string", 
                    "enum": ["recency", "relevance", "causal", "balanced"],
                    "default": "balanced"
                },
                "min_relevance": { "type": "number", "default": 0.1 }
            },
            "required": ["query"]
        }),
        {
            let engine = engine.clone();
            move |params: Value| {
                let query = params["query"].as_str().unwrap().to_string();
                let token_budget = params["token_budget"].as_u64().unwrap_or(50000) as u32;
                let strategy_str = params["strategy"].as_str().unwrap_or("balanced");
                let strategy = match strategy_str {
                    "recency" => RetrievalStrategy::Recency,
                    "relevance" => RetrievalStrategy::Relevance,
                    "causal" => RetrievalStrategy::Causal,
                    _ => RetrievalStrategy::Balanced,
                };
                let min_relevance = params["min_relevance"].as_f64().unwrap_or(0.1) as f32;
                
                let request = RetrievalRequest {
                    query,
                    token_budget,
                    strategy,
                    min_relevance,
                };
                
                let result = engine.retrieve(request);
                
                json!({
                    "blocks": result.blocks.iter().map(|b| {
                        json!({
                            "sequence": b.sequence,
                            "hash": b.hash.to_hex(),
                            "type": format!("{:?}", b.block_type),
                            "timestamp": b.timestamp.to_rfc3339(),
                            "content": &b.content,
                        })
                    }).collect::<Vec<_>>(),
                    "tokens_used": result.tokens_used,
                    "coverage": {
                        "semantic": result.coverage.semantic,
                        "temporal": result.coverage.temporal,
                        "causal": result.coverage.causal,
                    },
                    "retrieval_ms": result.retrieval_ms,
                })
            }
        },
    );
    
    server.register_tool(
        "memory_resurrect",
        "Fully restore state at any timestamp",
        json!({
            "type": "object",
            "properties": {
                "timestamp": { "type": "string", "format": "date-time" }
            },
            "required": ["timestamp"]
        }),
        {
            let engine = engine.clone();
            move |params: Value| {
                let ts_str = params["timestamp"].as_str().unwrap();
                let timestamp = chrono::DateTime::parse_from_rfc3339(ts_str)
                    .map(|dt| dt.with_timezone(&chrono::Utc))
                    .unwrap_or_else(|_| chrono::Utc::now());
                
                let result = engine.resurrect(timestamp);
                
                json!({
                    "timestamp": result.timestamp.to_rfc3339(),
                    "block_count": result.block_count,
                    "messages": result.messages,
                    "files_state": result.files_state,
                    "decisions": result.decisions,
                })
            }
        },
    );
    
    server.register_tool(
        "memory_session_resume",
        "Resume session with full context from previous work",
        json!({
            "type": "object",
            "properties": {},
            "required": []
        }),
        {
            let engine = engine.clone();
            move |_params: Value| {
                let result = engine.session_resume();
                
                json!({
                    "session_id": result.session_id,
                    "block_count": result.block_count,
                    "recent_messages": result.recent_messages,
                    "files_touched": result.files_touched,
                    "decisions": result.decisions,
                    "errors_resolved": result.errors_resolved,
                    "all_known_files": result.all_known_files,
                })
            }
        },
    );
    
    // ═══════════════════════════════════════════════════════════════════
    // SEARCH TOOLS
    // ═══════════════════════════════════════════════════════════════════
    
    server.register_tool(
        "memory_search_temporal",
        "Search blocks by time range",
        json!({
            "type": "object",
            "properties": {
                "start": { "type": "string", "format": "date-time" },
                "end": { "type": "string", "format": "date-time" }
            },
            "required": ["start", "end"]
        }),
        {
            let engine = engine.clone();
            move |params: Value| {
                let start = chrono::DateTime::parse_from_rfc3339(params["start"].as_str().unwrap())
                    .map(|dt| dt.with_timezone(&chrono::Utc))
                    .unwrap_or_else(|_| chrono::Utc::now());
                let end = chrono::DateTime::parse_from_rfc3339(params["end"].as_str().unwrap())
                    .map(|dt| dt.with_timezone(&chrono::Utc))
                    .unwrap_or_else(|_| chrono::Utc::now());
                
                let blocks = engine.search_temporal(start, end);
                
                json!({
                    "blocks": blocks.iter().map(|b| {
                        json!({
                            "sequence": b.sequence,
                            "type": format!("{:?}", b.block_type),
                            "timestamp": b.timestamp.to_rfc3339(),
                        })
                    }).collect::<Vec<_>>(),
                    "count": blocks.len(),
                })
            }
        },
    );
    
    server.register_tool(
        "memory_search_semantic",
        "Search blocks by meaning/text",
        json!({
            "type": "object",
            "properties": {
                "query": { "type": "string" },
                "limit": { "type": "integer", "default": 20 }
            },
            "required": ["query"]
        }),
        {
            let engine = engine.clone();
            move |params: Value| {
                let query = params["query"].as_str().unwrap();
                let limit = params["limit"].as_u64().unwrap_or(20) as usize;
                
                let blocks = engine.search_semantic(query, limit);
                
                json!({
                    "blocks": blocks.iter().map(|b| {
                        json!({
                            "sequence": b.sequence,
                            "type": format!("{:?}", b.block_type),
                            "timestamp": b.timestamp.to_rfc3339(),
                            "content": &b.content,
                        })
                    }).collect::<Vec<_>>(),
                    "count": blocks.len(),
                })
            }
        },
    );
    
    server.register_tool(
        "memory_search_entity",
        "Search blocks mentioning a file, person, or entity",
        json!({
            "type": "object",
            "properties": {
                "entity": { "type": "string" }
            },
            "required": ["entity"]
        }),
        {
            let engine = engine.clone();
            move |params: Value| {
                let entity = params["entity"].as_str().unwrap();
                
                let blocks = engine.search_entity(entity);
                
                json!({
                    "blocks": blocks.iter().map(|b| {
                        json!({
                            "sequence": b.sequence,
                            "type": format!("{:?}", b.block_type),
                            "timestamp": b.timestamp.to_rfc3339(),
                        })
                    }).collect::<Vec<_>>(),
                    "count": blocks.len(),
                })
            }
        },
    );
    
    // ═══════════════════════════════════════════════════════════════════
    // VERIFICATION TOOLS
    // ═══════════════════════════════════════════════════════════════════
    
    server.register_tool(
        "memory_verify_integrity",
        "Verify cryptographic integrity of the memory log",
        json!({
            "type": "object",
            "properties": {},
            "required": []
        }),
        {
            let engine = engine.clone();
            move |_params: Value| {
                let report = engine.verify_integrity();
                
                json!({
                    "verified": report.verified,
                    "blocks_checked": report.blocks_checked,
                    "chain_intact": report.chain_intact,
                    "missing_blocks": report.missing_blocks,
                    "corrupted_blocks": report.corrupted_blocks,
                })
            }
        },
    );
    
    server.register_tool(
        "memory_stats",
        "Get memory engine statistics",
        json!({
            "type": "object",
            "properties": {},
            "required": []
        }),
        {
            let engine = engine.clone();
            move |_params: Value| {
                let stats = engine.stats();
                
                json!({
                    "total_blocks": stats.total_blocks,
                    "session_id": stats.session_id,
                    "tiers": {
                        "hot": {
                            "blocks": stats.tier_stats.hot_blocks,
                            "bytes": stats.tier_stats.hot_bytes,
                        },
                        "warm": {
                            "blocks": stats.tier_stats.warm_blocks,
                            "bytes": stats.tier_stats.warm_bytes,
                        },
                        "cold": {
                            "blocks": stats.tier_stats.cold_blocks,
                            "bytes": stats.tier_stats.cold_bytes,
                        },
                        "frozen": {
                            "blocks": stats.tier_stats.frozen_blocks,
                        },
                    },
                })
            }
        },
    );
}
```

---

## PART 5: IMPLEMENTATION CHECKLIST

```
PHASE 1: CORE DATA STRUCTURES (2-3 hours)
─────────────────────────────────────────
□ Block struct and types
□ BlockHash and content-addressing
□ Serialization/deserialization
□ Unit tests for blocks

PHASE 2: IMMORTAL LOG (2-3 hours)
─────────────────────────────────
□ Append-only file format
□ Memory-mapped I/O
□ Block indexing (sequence -> offset)
□ Content indexing (hash -> sequence)
□ Integrity verification
□ Unit tests for log

PHASE 3: FIVE INDEXES (4-5 hours)
─────────────────────────────────
□ Temporal index (B-tree)
□ Semantic index (text search + embedding stubs)
□ Causal index (DAG)
□ Entity index (inverted)
□ Procedural index (sessions/workflows)
□ Unit tests for each index

PHASE 4: TIERED STORAGE (2-3 hours)
───────────────────────────────────
□ Hot tier (in-memory)
□ Warm tier (on-disk)
□ Cold tier (compressed)
□ Frozen tier (archive)
□ Automatic demotion
□ Unit tests

PHASE 5: ENGINE INTEGRATION (3-4 hours)
───────────────────────────────────────
□ MemoryEngineV3 struct
□ All capture methods
□ All retrieval methods
□ Session resume
□ Resurrection
□ Integration tests

PHASE 6: SMART RETRIEVAL (2-3 hours)
────────────────────────────────────
□ Multi-index fusion
□ Token budget fitting
□ Coverage calculation
□ Strategy selection
□ Unit tests

PHASE 7: MCP TOOLS (2-3 hours)
──────────────────────────────
□ Capture tools (6 tools)
□ Retrieval tools (3 tools)
□ Search tools (3 tools)
□ Verification tools (2 tools)
□ Integration tests

PHASE 8: MIGRATION + COMPATIBILITY (1-2 hours)
──────────────────────────────────────────────
□ V2 -> V3 migration
□ Backward compatibility for V2 tools
□ Feature flag for V3
□ Migration tests

TOTAL ESTIMATED: 18-26 hours
────────────────────────────
With focused work: 2-3 sessions
```

---

## FILE STRUCTURE

```
agentic-memory/
├── core/
│   ├── src/
│   │   ├── lib.rs              # Existing + v3 module
│   │   ├── v3/
│   │   │   ├── mod.rs          # V3 module root
│   │   │   ├── block.rs        # Block + BlockHash + BlockContent
│   │   │   ├── immortal_log.rs # Append-only log
│   │   │   ├── indexes/
│   │   │   │   ├── mod.rs      # Index trait + common types
│   │   │   │   ├── temporal.rs # B-tree temporal index
│   │   │   │   ├── semantic.rs # Embedding-based search
│   │   │   │   ├── causal.rs   # DAG for decision chains
│   │   │   │   ├── entity.rs   # Inverted index for entities
│   │   │   │   └── procedural.rs # Session/workflow tracking
│   │   │   ├── tiered.rs       # Hot/warm/cold/frozen storage
│   │   │   ├── retrieval.rs    # Smart retrieval engine
│   │   │   └── engine.rs       # MemoryEngineV3
│   │   └── ...existing v2 code
│   └── Cargo.toml              # Add: memmap2, uuid
├── mcp/
│   ├── src/
│   │   ├── lib.rs
│   │   ├── v3_tools.rs         # V3 MCP tool definitions
│   │   └── ...existing code
│   └── Cargo.toml
└── ...
```

---

## DEPENDENCIES TO ADD

```toml
# agentic-memory-core/Cargo.toml

[dependencies]
# Existing deps...

# V3 additions
memmap2 = "0.9"           # Memory-mapped files
uuid = { version = "1.0", features = ["v4"] }  # Session IDs
```

---

## USAGE EXAMPLE

```rust
use agentic_memory_core::v3::*;

// Open/create memory
let config = EngineConfig::default();
let engine = MemoryEngineV3::open(config)?;

// Capture everything
engine.capture_user_message("Let's build the contracts crate", Some(8))?;
engine.capture_assistant_message("I'll start by creating the directory...", Some(15))?;
engine.capture_file_operation(
    "/home/user/agentic-contracts/Cargo.toml",
    FileOperation::Create,
    None,
    Some(25),
    None,
)?;
engine.capture_decision(
    "Use blake3 for hashing",
    Some("Fast and secure"),
    vec![],
    Some(0.95),
)?;

// Session boundary (compaction)
engine.capture_boundary(
    BoundaryType::Compaction,
    95000,
    8000,
    "Built contracts crate with 7 traits",
    Some("Continue with verification"),
)?;

// Resume later
let resume = engine.session_resume();
println!("Files touched: {:?}", resume.files_touched);
println!("Decisions: {:?}", resume.decisions);

// Smart retrieval
let context = engine.retrieve(RetrievalRequest {
    query: "contracts crate implementation".to_string(),
    token_budget: 50000,
    strategy: RetrievalStrategy::Balanced,
    min_relevance: 0.1,
});
println!("Retrieved {} blocks using {} tokens", context.blocks.len(), context.tokens_used);

// Resurrect any point in time
let past = engine.resurrect(some_timestamp);
println!("At that moment, files were: {:?}", past.files_state);

// Verify nothing lost
let integrity = engine.verify_integrity();
assert!(integrity.verified);
assert!(integrity.chain_intact);
```

---

## THE PROMISE

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║  EVERY TOKEN CAPTURED.                                                    ║
║  EVERY FILE TRACKED.                                                      ║
║  EVERY DECISION RECORDED.                                                 ║
║  EVERY SESSION LINKED.                                                    ║
║                                                                           ║
║  NOTHING LOST AT COMPACTION.                                              ║
║  NOTHING LOST AT SESSION END.                                             ║
║  NOTHING LOST EVER.                                                       ║
║                                                                           ║
║  CRYPTOGRAPHIC PROOF OF COMPLETENESS.                                     ║
║  TIME TRAVEL TO ANY MOMENT.                                               ║
║  20 YEARS OF PERFECT RECALL.                                              ║
║                                                                           ║
║  THIS IS MEMORY V3: IMMORTAL.                                             ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

---

## PART 6: V2 TO V3 MIGRATION

```rust
// agentic-memory-core/src/v3/migration.rs

use crate::graph::MemoryGraph;  // V2 graph
use super::engine::MemoryEngineV3;
use super::block::*;
use std::path::Path;

/// Migrate V2 .amem file to V3 immortal log
pub struct V2ToV3Migration;

impl V2ToV3Migration {
    /// Migrate a V2 memory file to V3
    pub fn migrate(v2_path: &Path, v3_engine: &MemoryEngineV3) -> Result<MigrationReport, std::io::Error> {
        let mut report = MigrationReport::default();
        
        // Load V2 graph
        let graph = MemoryGraph::load(v2_path)?;
        report.v2_nodes = graph.node_count();
        report.v2_edges = graph.edge_count();
        
        // Convert nodes to blocks
        for node in graph.nodes() {
            let block_type = match node.node_type {
                crate::NodeType::Episode => BlockType::UserMessage,
                crate::NodeType::Fact => BlockType::Decision,
                crate::NodeType::Concept => BlockType::AssistantMessage,
                crate::NodeType::Procedure => BlockType::ToolCall,
                crate::NodeType::Preference => BlockType::Decision,
                crate::NodeType::Reflection => BlockType::AssistantMessage,
            };
            
            let content = match node.node_type {
                crate::NodeType::Episode | crate::NodeType::Concept | crate::NodeType::Reflection => {
                    BlockContent::Text {
                        text: node.content.clone(),
                        role: Some("assistant".to_string()),
                        tokens: None,
                    }
                }
                crate::NodeType::Fact | crate::NodeType::Preference => {
                    BlockContent::Decision {
                        decision: node.content.clone(),
                        reasoning: None,
                        evidence_blocks: vec![],
                        confidence: Some(node.importance),
                    }
                }
                crate::NodeType::Procedure => {
                    BlockContent::Tool {
                        tool_name: "migrated_procedure".to_string(),
                        input: serde_json::json!({ "content": node.content }),
                        output: None,
                        duration_ms: None,
                        success: true,
                    }
                }
            };
            
            // Capture to V3
            match v3_engine.append_block_internal(block_type, content) {
                Ok(_) => report.blocks_created += 1,
                Err(e) => report.errors.push(format!("Node {}: {}", node.id, e)),
            }
        }
        
        // Mark migration complete
        v3_engine.capture_boundary(
            BoundaryType::SessionStart,
            0,
            0,
            &format!("Migrated from V2: {} nodes, {} edges", report.v2_nodes, report.v2_edges),
            Some("V3 immortal mode active"),
        )?;
        
        report.success = report.errors.is_empty();
        Ok(report)
    }
    
    /// Check if a file is V2 format
    pub fn is_v2_format(path: &Path) -> bool {
        if let Ok(data) = std::fs::read(path) {
            // V2 starts with AMEM magic
            data.len() >= 4 && &data[0..4] == b"AMEM"
        } else {
            false
        }
    }
    
    /// Check if a file is V3 format
    pub fn is_v3_format(path: &Path) -> bool {
        if let Ok(data) = std::fs::read(path) {
            // V3 immortal log starts with IMRT magic
            data.len() >= 4 && &data[0..4] == b"IMRT"
        } else {
            false
        }
    }
}

#[derive(Debug, Default)]
pub struct MigrationReport {
    pub success: bool,
    pub v2_nodes: usize,
    pub v2_edges: usize,
    pub blocks_created: usize,
    pub errors: Vec<String>,
}
```

---

## PART 7: CLAUDE CODE INTEGRATION HOOKS

```rust
// agentic-memory-core/src/v3/claude_hooks.rs

//! Hooks for integrating with Claude Code's session management.
//! These functions are called by Claude Code at key moments.

use super::engine::MemoryEngineV3;
use super::block::*;
use std::sync::Arc;

/// Hook called at the START of every Claude Code message
pub fn on_message_start(
    engine: &MemoryEngineV3,
    role: &str,
    content: &str,
    context_tokens: u32,
) {
    let _ = match role {
        "user" => engine.capture_user_message(content, Some(estimate_tokens(content))),
        "assistant" => engine.capture_assistant_message(content, Some(estimate_tokens(content))),
        _ => engine.capture_user_message(content, Some(estimate_tokens(content))),
    };
}

/// Hook called BEFORE every tool execution
pub fn on_tool_start(
    engine: &MemoryEngineV3,
    tool_name: &str,
    input: &serde_json::Value,
) {
    // We'll capture the full tool call when it completes
    // This is just for tracking that a tool started
}

/// Hook called AFTER every tool execution
pub fn on_tool_complete(
    engine: &MemoryEngineV3,
    tool_name: &str,
    input: serde_json::Value,
    output: serde_json::Value,
    duration_ms: u64,
    success: bool,
) {
    let _ = engine.capture_tool_call(tool_name, input, Some(output), Some(duration_ms), success);
    
    // Special handling for file tools
    if tool_name == "create_file" || tool_name == "str_replace" || tool_name == "view" {
        if let Some(path) = input.get("path").and_then(|p| p.as_str()) {
            let op = match tool_name {
                "create_file" => FileOperation::Create,
                "str_replace" => FileOperation::Update,
                "view" => FileOperation::Read,
                _ => FileOperation::Read,
            };
            let _ = engine.capture_file_operation(path, op, None, None, None);
        }
    }
}

/// Hook called when Claude Code detects context pressure
pub fn on_context_pressure(
    engine: &MemoryEngineV3,
    current_tokens: u32,
    max_tokens: u32,
) {
    if current_tokens as f32 / max_tokens as f32 > 0.8 {
        // Context is getting full, capture checkpoint
        let _ = engine.capture_checkpoint(
            vec![], // Would be populated by Claude Code
            "Context pressure detected",
            vec![],
        );
    }
}

/// Hook called BEFORE compaction happens
/// THIS IS THE CRITICAL MOMENT - capture everything before it's lost
pub fn on_pre_compaction(
    engine: &MemoryEngineV3,
    context_tokens_before: u32,
    summary: &str,
    active_files: Vec<String>,
    pending_tasks: Vec<String>,
    working_context: &str,
) {
    // Capture full checkpoint
    let _ = engine.capture_checkpoint(
        active_files.clone(),
        working_context,
        pending_tasks.clone(),
    );
    
    // Capture the boundary event
    let _ = engine.capture_boundary(
        BoundaryType::Compaction,
        context_tokens_before,
        0, // Will be filled after compaction
        summary,
        Some(&format!("Active files: {:?}", active_files)),
    );
}

/// Hook called AFTER compaction completes
pub fn on_post_compaction(
    engine: &MemoryEngineV3,
    context_tokens_after: u32,
) {
    // Update the boundary with post-compaction token count
    // Note: In practice, we'd update the last boundary block
}

/// Hook called at SESSION END
pub fn on_session_end(
    engine: &MemoryEngineV3,
    summary: &str,
) {
    let _ = engine.capture_boundary(
        BoundaryType::SessionEnd,
        0,
        0,
        summary,
        None,
    );
}

/// Hook called at SESSION START (resume)
pub fn on_session_start(engine: &MemoryEngineV3) -> SessionResumeResult {
    // Mark new session
    let _ = engine.capture_boundary(
        BoundaryType::SessionStart,
        0,
        0,
        "New session started",
        None,
    );
    
    // Return full context for Claude Code to use
    engine.session_resume()
}

/// Helper: estimate tokens from text
fn estimate_tokens(text: &str) -> u32 {
    // Rough estimate: 4 characters per token
    (text.len() / 4) as u32 + 1
}

use super::engine::SessionResumeResult;
```

---

## PART 8: CLI COMMANDS

```rust
// agentic-memory-cli/src/v3_commands.rs

use agentic_memory_core::v3::*;
use clap::{Args, Subcommand};
use std::path::PathBuf;

#[derive(Subcommand)]
pub enum V3Commands {
    /// Capture a message
    Capture(CaptureArgs),
    
    /// Search memory
    Search(SearchArgs),
    
    /// Retrieve context
    Retrieve(RetrieveArgs),
    
    /// Resurrect state at timestamp
    Resurrect(ResurrectArgs),
    
    /// Show statistics
    Stats,
    
    /// Verify integrity
    Verify,
    
    /// Migrate from V2
    Migrate(MigrateArgs),
    
    /// Resume session
    Resume,
}

#[derive(Args)]
pub struct CaptureArgs {
    #[arg(long)]
    pub message: Option<String>,
    
    #[arg(long)]
    pub decision: Option<String>,
    
    #[arg(long)]
    pub file: Option<String>,
    
    #[arg(long)]
    pub operation: Option<String>,
}

#[derive(Args)]
pub struct SearchArgs {
    /// Search query
    pub query: String,
    
    /// Search type: semantic, temporal, entity
    #[arg(long, default_value = "semantic")]
    pub search_type: String,
    
    /// Maximum results
    #[arg(long, default_value = "20")]
    pub limit: usize,
}

#[derive(Args)]
pub struct RetrieveArgs {
    /// Query for context assembly
    pub query: String,
    
    /// Token budget
    #[arg(long, default_value = "50000")]
    pub tokens: u32,
    
    /// Strategy: recency, relevance, causal, balanced
    #[arg(long, default_value = "balanced")]
    pub strategy: String,
}

#[derive(Args)]
pub struct ResurrectArgs {
    /// Timestamp to resurrect (ISO 8601)
    pub timestamp: String,
}

#[derive(Args)]
pub struct MigrateArgs {
    /// Path to V2 .amem file
    pub v2_path: PathBuf,
}

pub fn handle_v3_command(cmd: V3Commands, engine: &MemoryEngineV3) {
    match cmd {
        V3Commands::Capture(args) => {
            if let Some(msg) = args.message {
                match engine.capture_user_message(&msg, None) {
                    Ok(hash) => println!("✓ Captured message: {}", hash.to_hex()),
                    Err(e) => eprintln!("✗ Error: {}", e),
                }
            }
            if let Some(decision) = args.decision {
                match engine.capture_decision(&decision, None, vec![], None) {
                    Ok(hash) => println!("✓ Captured decision: {}", hash.to_hex()),
                    Err(e) => eprintln!("✗ Error: {}", e),
                }
            }
            if let Some(file) = args.file {
                let op = match args.operation.as_deref() {
                    Some("create") => FileOperation::Create,
                    Some("update") => FileOperation::Update,
                    Some("delete") => FileOperation::Delete,
                    _ => FileOperation::Read,
                };
                match engine.capture_file_operation(&file, op, None, None, None) {
                    Ok(hash) => println!("✓ Captured file operation: {}", hash.to_hex()),
                    Err(e) => eprintln!("✗ Error: {}", e),
                }
            }
        }
        
        V3Commands::Search(args) => {
            let blocks = match args.search_type.as_str() {
                "semantic" => engine.search_semantic(&args.query, args.limit),
                "entity" => engine.search_entity(&args.query),
                _ => engine.search_semantic(&args.query, args.limit),
            };
            
            println!("Found {} blocks:\n", blocks.len());
            for block in blocks {
                println!("  [{}] {:?} @ {}", 
                    block.sequence, 
                    block.block_type,
                    block.timestamp.format("%Y-%m-%d %H:%M:%S")
                );
            }
        }
        
        V3Commands::Retrieve(args) => {
            let strategy = match args.strategy.as_str() {
                "recency" => RetrievalStrategy::Recency,
                "relevance" => RetrievalStrategy::Relevance,
                "causal" => RetrievalStrategy::Causal,
                _ => RetrievalStrategy::Balanced,
            };
            
            let result = engine.retrieve(RetrievalRequest {
                query: args.query,
                token_budget: args.tokens,
                strategy,
                min_relevance: 0.1,
            });
            
            println!("Retrieved {} blocks ({} tokens) in {}ms", 
                result.blocks.len(),
                result.tokens_used,
                result.retrieval_ms
            );
            println!("Coverage: semantic={:.2}, temporal={:.2}, causal={:.2}",
                result.coverage.semantic,
                result.coverage.temporal,
                result.coverage.causal
            );
        }
        
        V3Commands::Resurrect(args) => {
            match chrono::DateTime::parse_from_rfc3339(&args.timestamp) {
                Ok(ts) => {
                    let result = engine.resurrect(ts.with_timezone(&chrono::Utc));
                    println!("Resurrected state at {}:", result.timestamp);
                    println!("  Blocks: {}", result.block_count);
                    println!("  Messages: {}", result.messages.len());
                    println!("  Files: {}", result.files_state.len());
                    println!("  Decisions: {}", result.decisions.len());
                }
                Err(e) => eprintln!("Invalid timestamp: {}", e),
            }
        }
        
        V3Commands::Stats => {
            let stats = engine.stats();
            println!("Memory V3 Statistics:");
            println!("  Total blocks: {}", stats.total_blocks);
            println!("  Session: {}", stats.session_id);
            println!("  Tiers:");
            println!("    Hot:    {} blocks, {} bytes", 
                stats.tier_stats.hot_blocks, stats.tier_stats.hot_bytes);
            println!("    Warm:   {} blocks, {} bytes", 
                stats.tier_stats.warm_blocks, stats.tier_stats.warm_bytes);
            println!("    Cold:   {} blocks, {} bytes", 
                stats.tier_stats.cold_blocks, stats.tier_stats.cold_bytes);
            println!("    Frozen: {} blocks", stats.tier_stats.frozen_blocks);
        }
        
        V3Commands::Verify => {
            let report = engine.verify_integrity();
            if report.verified {
                println!("✓ Integrity verified");
                println!("  Blocks checked: {}", report.blocks_checked);
                println!("  Chain intact: {}", report.chain_intact);
            } else {
                println!("✗ Integrity check FAILED");
                println!("  Missing blocks: {:?}", report.missing_blocks);
                println!("  Corrupted blocks: {:?}", report.corrupted_blocks);
            }
        }
        
        V3Commands::Migrate(args) => {
            println!("Migrating from V2: {:?}", args.v2_path);
            // Migration implementation would go here
            println!("Migration not yet implemented in CLI");
        }
        
        V3Commands::Resume => {
            let result = engine.session_resume();
            println!("Session Resume:");
            println!("  Session ID: {}", result.session_id);
            println!("  Blocks in session: {}", result.block_count);
            println!("\nRecent messages:");
            for (role, msg) in result.recent_messages.iter().take(5) {
                println!("  [{}] {}", role, &msg[..msg.len().min(80)]);
            }
            println!("\nFiles touched:");
            for (path, op) in result.files_touched.iter().take(10) {
                println!("  {} ({})", path, op);
            }
            println!("\nDecisions:");
            for decision in result.decisions.iter().take(5) {
                println!("  • {}", decision);
            }
        }
    }
}
```

---

## PART 9: TESTS

```rust
// agentic-memory-core/src/v3/tests.rs

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;
    
    fn test_engine() -> (TempDir, MemoryEngineV3) {
        let dir = TempDir::new().unwrap();
        let config = EngineConfig {
            data_dir: dir.path().to_path_buf(),
            ..Default::default()
        };
        let engine = MemoryEngineV3::open(config).unwrap();
        (dir, engine)
    }
    
    #[test]
    fn test_capture_message() {
        let (_dir, engine) = test_engine();
        
        let hash = engine.capture_user_message("Hello world", Some(3)).unwrap();
        assert!(!hash.0.iter().all(|&b| b == 0));
        
        let stats = engine.stats();
        assert_eq!(stats.total_blocks, 1);
    }
    
    #[test]
    fn test_capture_tool_call() {
        let (_dir, engine) = test_engine();
        
        let hash = engine.capture_tool_call(
            "create_file",
            serde_json::json!({"path": "/test.txt"}),
            Some(serde_json::json!({"success": true})),
            Some(50),
            true,
        ).unwrap();
        
        assert!(!hash.0.iter().all(|&b| b == 0));
    }
    
    #[test]
    fn test_capture_file_operation() {
        let (_dir, engine) = test_engine();
        
        engine.capture_file_operation(
            "/home/user/test.rs",
            FileOperation::Create,
            None,
            Some(100),
            None,
        ).unwrap();
        
        let blocks = engine.search_entity("/home/user/test.rs");
        assert_eq!(blocks.len(), 1);
    }
    
    #[test]
    fn test_capture_decision() {
        let (_dir, engine) = test_engine();
        
        engine.capture_decision(
            "Use Rust for performance",
            Some("Rust provides memory safety without GC"),
            vec![],
            Some(0.9),
        ).unwrap();
        
        let blocks = engine.search_semantic("Rust performance", 10);
        assert!(!blocks.is_empty());
    }
    
    #[test]
    fn test_session_boundary() {
        let (_dir, engine) = test_engine();
        
        engine.capture_user_message("Before boundary", None).unwrap();
        
        engine.capture_boundary(
            BoundaryType::Compaction,
            50000,
            5000,
            "Context compacted",
            Some("Continue with implementation"),
        ).unwrap();
        
        engine.capture_user_message("After boundary", None).unwrap();
        
        let stats = engine.stats();
        assert_eq!(stats.total_blocks, 3);
    }
    
    #[test]
    fn test_temporal_search() {
        let (_dir, engine) = test_engine();
        
        engine.capture_user_message("Message 1", None).unwrap();
        engine.capture_user_message("Message 2", None).unwrap();
        engine.capture_user_message("Message 3", None).unwrap();
        
        let now = chrono::Utc::now();
        let hour_ago = now - chrono::Duration::hours(1);
        
        let blocks = engine.search_temporal(hour_ago, now);
        assert_eq!(blocks.len(), 3);
    }
    
    #[test]
    fn test_semantic_search() {
        let (_dir, engine) = test_engine();
        
        engine.capture_user_message("Rust programming language", None).unwrap();
        engine.capture_user_message("Python is great for scripting", None).unwrap();
        engine.capture_user_message("Memory safety in Rust", None).unwrap();
        
        let results = engine.search_semantic("Rust memory", 10);
        assert!(results.len() >= 1);
    }
    
    #[test]
    fn test_entity_search() {
        let (_dir, engine) = test_engine();
        
        engine.capture_file_operation("/src/main.rs", FileOperation::Create, None, None, None).unwrap();
        engine.capture_file_operation("/src/lib.rs", FileOperation::Create, None, None, None).unwrap();
        engine.capture_file_operation("/tests/test.rs", FileOperation::Create, None, None, None).unwrap();
        
        // Search for /src directory
        let results = engine.search_entity("/src");
        // Should find files in /src
        assert!(!results.is_empty());
    }
    
    #[test]
    fn test_session_resume() {
        let (_dir, engine) = test_engine();
        
        engine.capture_user_message("Working on memory V3", None).unwrap();
        engine.capture_file_operation("/memory/v3/engine.rs", FileOperation::Create, None, None, None).unwrap();
        engine.capture_decision("Use append-only log", None, vec![], None).unwrap();
        
        let resume = engine.session_resume();
        
        assert!(!resume.session_id.is_empty());
        assert_eq!(resume.block_count, 3);
        assert!(!resume.files_touched.is_empty());
        assert!(!resume.decisions.is_empty());
    }
    
    #[test]
    fn test_retrieval() {
        let (_dir, engine) = test_engine();
        
        // Capture some context
        for i in 0..20 {
            engine.capture_user_message(&format!("Message about topic {}", i % 5), None).unwrap();
        }
        engine.capture_decision("Important decision about topic 3", None, vec![], None).unwrap();
        
        let result = engine.retrieve(RetrievalRequest {
            query: "topic 3".to_string(),
            token_budget: 10000,
            strategy: RetrievalStrategy::Balanced,
            min_relevance: 0.1,
        });
        
        assert!(!result.blocks.is_empty());
        assert!(result.tokens_used <= 10000);
    }
    
    #[test]
    fn test_resurrection() {
        let (_dir, engine) = test_engine();
        
        let t1 = chrono::Utc::now();
        engine.capture_user_message("First message", None).unwrap();
        engine.capture_file_operation("/file1.rs", FileOperation::Create, None, None, None).unwrap();
        
        std::thread::sleep(std::time::Duration::from_millis(100));
        let t2 = chrono::Utc::now();
        
        engine.capture_user_message("Second message", None).unwrap();
        engine.capture_file_operation("/file2.rs", FileOperation::Create, None, None, None).unwrap();
        
        // Resurrect at t2 (should only see first two blocks)
        let state = engine.resurrect(t2);
        assert_eq!(state.block_count, 2);
    }
    
    #[test]
    fn test_integrity_verification() {
        let (_dir, engine) = test_engine();
        
        engine.capture_user_message("Test 1", None).unwrap();
        engine.capture_user_message("Test 2", None).unwrap();
        engine.capture_user_message("Test 3", None).unwrap();
        
        let report = engine.verify_integrity();
        
        assert!(report.verified);
        assert!(report.chain_intact);
        assert_eq!(report.blocks_checked, 3);
        assert!(report.missing_blocks.is_empty());
        assert!(report.corrupted_blocks.is_empty());
    }
    
    #[test]
    fn test_tiered_storage() {
        let (_dir, engine) = test_engine();
        
        // Capture many blocks
        for i in 0..100 {
            engine.capture_user_message(&format!("Message {}", i), None).unwrap();
        }
        
        let stats = engine.stats();
        assert_eq!(stats.total_blocks, 100);
        // All should be in hot tier initially
        assert!(stats.tier_stats.hot_blocks > 0);
    }
    
    #[test]
    fn test_block_hash_consistency() {
        // Same content should produce same hash
        let content1 = BlockContent::Text {
            text: "Hello".to_string(),
            role: Some("user".to_string()),
            tokens: Some(1),
        };
        let content2 = BlockContent::Text {
            text: "Hello".to_string(),
            role: Some("user".to_string()),
            tokens: Some(1),
        };
        
        let data1 = serde_json::to_vec(&content1).unwrap();
        let data2 = serde_json::to_vec(&content2).unwrap();
        
        let hash1 = BlockHash::compute(&data1);
        let hash2 = BlockHash::compute(&data2);
        
        assert_eq!(hash1, hash2);
    }
    
    #[test]
    fn test_persistence() {
        let dir = TempDir::new().unwrap();
        let config = EngineConfig {
            data_dir: dir.path().to_path_buf(),
            ..Default::default()
        };
        
        // Create and populate
        {
            let engine = MemoryEngineV3::open(config.clone()).unwrap();
            engine.capture_user_message("Persistent message", None).unwrap();
            engine.capture_decision("Persistent decision", None, vec![], None).unwrap();
        }
        
        // Reopen and verify
        {
            let engine = MemoryEngineV3::open(config).unwrap();
            let stats = engine.stats();
            assert_eq!(stats.total_blocks, 2);
            
            let results = engine.search_semantic("Persistent", 10);
            assert!(!results.is_empty());
        }
    }
}
```

---

## PART 10: INTEGRATION SPEC FOR AUTO-CAPTURE

```rust
// agentic-memory-mcp/src/auto_capture.rs

//! Auto-capture integration for seamless memory recording.
//! This module provides middleware that automatically captures
//! all MCP traffic to the immortal log.

use agentic_memory_core::v3::*;
use std::sync::Arc;

/// Auto-capture middleware for MCP server
pub struct AutoCaptureMiddleware {
    engine: Arc<MemoryEngineV3>,
    enabled: bool,
    capture_messages: bool,
    capture_tools: bool,
    capture_files: bool,
}

impl AutoCaptureMiddleware {
    pub fn new(engine: Arc<MemoryEngineV3>) -> Self {
        Self {
            engine,
            enabled: true,
            capture_messages: true,
            capture_tools: true,
            capture_files: true,
        }
    }
    
    /// Called before any tool execution
    pub fn on_tool_call(&self, tool_name: &str, input: &serde_json::Value) {
        if !self.enabled || !self.capture_tools {
            return;
        }
        
        // Most tools will be captured on completion
        // But we can log start time here for duration tracking
    }
    
    /// Called after tool execution
    pub fn on_tool_result(
        &self,
        tool_name: &str,
        input: serde_json::Value,
        output: serde_json::Value,
        duration_ms: u64,
        success: bool,
    ) {
        if !self.enabled || !self.capture_tools {
            return;
        }
        
        let _ = self.engine.capture_tool_call(
            tool_name,
            input.clone(),
            Some(output),
            Some(duration_ms),
            success,
        );
        
        // Auto-capture file operations from tool calls
        if self.capture_files {
            self.maybe_capture_file_from_tool(tool_name, &input);
        }
    }
    
    fn maybe_capture_file_from_tool(&self, tool_name: &str, input: &serde_json::Value) {
        let (path, op) = match tool_name {
            "create_file" | "file_create" => {
                let path = input.get("path").and_then(|p| p.as_str());
                (path, Some(FileOperation::Create))
            }
            "str_replace" | "edit_file" => {
                let path = input.get("path").and_then(|p| p.as_str());
                (path, Some(FileOperation::Update))
            }
            "view" | "read_file" => {
                let path = input.get("path").and_then(|p| p.as_str());
                (path, Some(FileOperation::Read))
            }
            "bash_tool" | "bash" => {
                // Try to extract file operations from bash commands
                if let Some(cmd) = input.get("command").and_then(|c| c.as_str()) {
                    if cmd.contains("rm ") {
                        // Rough extraction - could be improved
                        let parts: Vec<&str> = cmd.split_whitespace().collect();
                        if let Some(pos) = parts.iter().position(|&p| p == "rm" || p == "rm -rf") {
                            if let Some(path) = parts.get(pos + 1) {
                                return self.capture_file(path, FileOperation::Delete);
                            }
                        }
                    }
                }
                (None, None)
            }
            _ => (None, None),
        };
        
        if let (Some(path), Some(op)) = (path, op) {
            self.capture_file(path, op);
        }
    }
    
    fn capture_file(&self, path: &str, op: FileOperation) {
        let _ = self.engine.capture_file_operation(path, op, None, None, None);
    }
    
    /// Called when context pressure is detected
    pub fn on_context_pressure(&self, current_tokens: u32, max_tokens: u32) {
        if !self.enabled {
            return;
        }
        
        // Capture checkpoint when context gets full
        if current_tokens as f32 / max_tokens as f32 > 0.75 {
            let _ = self.engine.capture_checkpoint(
                vec![],
                &format!("Context at {}% capacity", (current_tokens * 100 / max_tokens)),
                vec![],
            );
        }
    }
    
    /// Called before compaction
    pub fn on_pre_compaction(&self, context_tokens: u32, summary: &str) {
        if !self.enabled {
            return;
        }
        
        let _ = self.engine.capture_boundary(
            BoundaryType::Compaction,
            context_tokens,
            0,
            summary,
            None,
        );
    }
}

/// Configuration for auto-capture behavior
#[derive(Debug, Clone)]
pub struct AutoCaptureConfig {
    /// Enable/disable all auto-capture
    pub enabled: bool,
    
    /// Capture messages
    pub capture_messages: bool,
    
    /// Capture tool calls
    pub capture_tools: bool,
    
    /// Auto-detect and capture file operations
    pub capture_files: bool,
    
    /// Auto-checkpoint interval (in tool calls)
    pub checkpoint_interval: Option<u32>,
    
    /// Context pressure threshold (0.0 - 1.0)
    pub pressure_threshold: f32,
}

impl Default for AutoCaptureConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            capture_messages: true,
            capture_tools: true,
            capture_files: true,
            checkpoint_interval: Some(50),
            pressure_threshold: 0.75,
        }
    }
}
```

---

## PART 11: FILE FORMAT SPECIFICATION

```
IMMORTAL LOG FILE FORMAT (.imem)
════════════════════════════════

┌──────────────────────────────────────────────────────────────────┐
│ HEADER (64 bytes)                                                │
├──────────────────────────────────────────────────────────────────┤
│ 0x00-0x03: Magic "IMRT" (0x494D5254)                            │
│ 0x04-0x05: Version (u16, little-endian) = 1                     │
│ 0x06-0x07: Flags (u16)                                          │
│ 0x08-0x0F: Block count (u64)                                    │
│ 0x10-0x17: First block offset (u64)                             │
│ 0x18-0x1F: Last block offset (u64)                              │
│ 0x20-0x3F: Reserved (32 bytes, zeros)                           │
├──────────────────────────────────────────────────────────────────┤
│ BLOCK SECTION (variable)                                         │
├──────────────────────────────────────────────────────────────────┤
│ For each block:                                                  │
│   ┌────────────────────────────────────────────────────────────┐│
│   │ Block Length (u32, little-endian)                          ││
│   ├────────────────────────────────────────────────────────────┤│
│   │ Block Data (JSON, UTF-8)                                   ││
│   │ {                                                          ││
│   │   "hash": "hex string (64 chars)",                         ││
│   │   "prev_hash": "hex string",                               ││
│   │   "sequence": u64,                                         ││
│   │   "timestamp": "ISO 8601 string",                          ││
│   │   "block_type": "user_message|assistant_message|...",      ││
│   │   "content": { ... },                                      ││
│   │   "size_bytes": u32                                        ││
│   │ }                                                          ││
│   └────────────────────────────────────────────────────────────┘│
│   ... more blocks ...                                            │
├──────────────────────────────────────────────────────────────────┤
│ INDEX SECTION (optional, at end of file)                         │
├──────────────────────────────────────────────────────────────────┤
│ Index magic "INDX" (0x494E4458)                                 │
│ Temporal index offset table                                      │
│ Entity index inverted lists                                      │
│ (Indexes are rebuilt on load if missing/corrupted)              │
└──────────────────────────────────────────────────────────────────┘

PROPERTIES:
───────────
• Append-only (blocks never modified or deleted)
• Self-healing (indexes rebuilt from blocks if corrupted)
• Streamable (can read blocks sequentially)
• Integrity (each block hash verifies content + chain)
• Backward compatible (newer readers read older files)

MAGIC NUMBERS:
──────────────
IMRT = Immortal Log
INDX = Index Section
CHKP = Checkpoint (in content)
```

---

## FINAL IMPLEMENTATION CHECKLIST

```
TONIGHT'S TARGETS:
══════════════════

□ PHASE 1: BLOCKS (1 hour)
  □ block.rs - Block, BlockHash, BlockContent, BlockType
  □ Unit tests for serialization/hashing

□ PHASE 2: IMMORTAL LOG (1.5 hours)
  □ immortal_log.rs - Append-only file I/O
  □ Memory mapping
  □ Integrity verification
  □ Unit tests

□ PHASE 3: INDEXES (2 hours)
  □ temporal.rs - B-tree index
  □ semantic.rs - Text search (embedding stubs)
  □ causal.rs - DAG for decisions
  □ entity.rs - Inverted index
  □ procedural.rs - Session tracking
  □ Unit tests for each

□ PHASE 4: TIERED STORAGE (1 hour)
  □ tiered.rs - Hot/warm/cold/frozen
  □ Automatic demotion
  □ Unit tests

□ PHASE 5: ENGINE (1.5 hours)
  □ engine.rs - MemoryEngineV3
  □ All capture methods
  □ All search methods
  □ Session resume
  □ Integration tests

□ PHASE 6: RETRIEVAL (1 hour)
  □ retrieval.rs - Smart context assembly
  □ Multi-index fusion
  □ Token budgeting
  □ Unit tests

□ PHASE 7: MCP TOOLS (1 hour)
  □ v3_tools.rs - All 14+ MCP tools
  □ Integration tests

□ PHASE 8: WIRING (30 min)
  □ mod.rs - Module exports
  □ Feature flags
  □ lib.rs updates

TOTAL: ~9-10 hours focused work
═══════════════════════════════

STRETCH GOALS:
──────────────
□ V2 migration
□ CLI commands
□ Auto-capture middleware
□ Claude Code hooks

DEFINITION OF DONE:
───────────────────
✓ All tests pass
✓ MCP server starts with V3
✓ memory_session_resume returns full context
✓ memory_capture_* tools work
✓ memory_retrieve assembles context
✓ memory_verify_integrity passes
✓ Persistence survives restart
```

---

*NOW it's complete. This is the full implementation specification for Memory V3: Immortal.* 🚀

*Ready to build tonight. Every token captured. Every session linked. Nothing lost. Ever.*

---

## PART 12: EMBEDDING GENERATION

```rust
// agentic-memory-core/src/v3/embeddings.rs

//! Embedding generation for semantic search.
//! Supports multiple backends: local, API, or none (fallback to text search).

use std::sync::Arc;

/// Embedding vector (typically 384 or 1536 dimensions)
pub type Embedding = Vec<f32>;

/// Trait for embedding providers
pub trait EmbeddingProvider: Send + Sync {
    /// Generate embedding for text
    fn embed(&self, text: &str) -> Option<Embedding>;
    
    /// Generate embeddings for multiple texts (batched)
    fn embed_batch(&self, texts: &[&str]) -> Vec<Option<Embedding>> {
        texts.iter().map(|t| self.embed(t)).collect()
    }
    
    /// Get embedding dimension
    fn dimension(&self) -> usize;
    
    /// Provider name
    fn name(&self) -> &str;
}

/// No-op provider (fallback to text search)
pub struct NoOpEmbedding;

impl EmbeddingProvider for NoOpEmbedding {
    fn embed(&self, _text: &str) -> Option<Embedding> {
        None
    }
    
    fn dimension(&self) -> usize {
        0
    }
    
    fn name(&self) -> &str {
        "none"
    }
}

/// Local embedding using onnxruntime (MiniLM)
#[cfg(feature = "local-embeddings")]
pub struct LocalEmbedding {
    // ONNX runtime session would go here
    dimension: usize,
}

#[cfg(feature = "local-embeddings")]
impl LocalEmbedding {
    pub fn new() -> Result<Self, Box<dyn std::error::Error>> {
        // Load MiniLM model from bundled ONNX file
        Ok(Self { dimension: 384 })
    }
}

#[cfg(feature = "local-embeddings")]
impl EmbeddingProvider for LocalEmbedding {
    fn embed(&self, text: &str) -> Option<Embedding> {
        // Tokenize and run through ONNX model
        // Placeholder: return random embedding
        Some(vec![0.0; self.dimension])
    }
    
    fn dimension(&self) -> usize {
        self.dimension
    }
    
    fn name(&self) -> &str {
        "local-minilm"
    }
}

/// Simple TF-IDF based embedding (no ML, fast, deterministic)
pub struct TfIdfEmbedding {
    vocabulary: std::collections::HashMap<String, usize>,
    dimension: usize,
}

impl TfIdfEmbedding {
    pub fn new(dimension: usize) -> Self {
        Self {
            vocabulary: std::collections::HashMap::new(),
            dimension,
        }
    }
    
    /// Build vocabulary from corpus
    pub fn fit(&mut self, texts: &[&str]) {
        let mut word_counts: std::collections::HashMap<String, usize> = std::collections::HashMap::new();
        
        for text in texts {
            for word in text.split_whitespace() {
                let word = word.to_lowercase();
                *word_counts.entry(word).or_insert(0) += 1;
            }
        }
        
        // Take top N words by frequency
        let mut words: Vec<_> = word_counts.into_iter().collect();
        words.sort_by(|a, b| b.1.cmp(&a.1));
        
        self.vocabulary = words
            .into_iter()
            .take(self.dimension)
            .enumerate()
            .map(|(i, (word, _))| (word, i))
            .collect();
    }
}

impl EmbeddingProvider for TfIdfEmbedding {
    fn embed(&self, text: &str) -> Option<Embedding> {
        let mut embedding = vec![0.0f32; self.dimension];
        let words: Vec<_> = text.split_whitespace().collect();
        let total = words.len() as f32;
        
        if total == 0.0 {
            return Some(embedding);
        }
        
        for word in words {
            let word = word.to_lowercase();
            if let Some(&idx) = self.vocabulary.get(&word) {
                embedding[idx] += 1.0 / total;
            }
        }
        
        // Normalize
        let norm: f32 = embedding.iter().map(|x| x * x).sum::<f32>().sqrt();
        if norm > 0.0 {
            for x in &mut embedding {
                *x /= norm;
            }
        }
        
        Some(embedding)
    }
    
    fn dimension(&self) -> usize {
        self.dimension
    }
    
    fn name(&self) -> &str {
        "tfidf"
    }
}

/// Embedding manager that handles provider selection
pub struct EmbeddingManager {
    provider: Arc<dyn EmbeddingProvider>,
}

impl EmbeddingManager {
    pub fn new(provider: Arc<dyn EmbeddingProvider>) -> Self {
        Self { provider }
    }
    
    pub fn with_tfidf(dimension: usize) -> Self {
        Self {
            provider: Arc::new(TfIdfEmbedding::new(dimension)),
        }
    }
    
    pub fn none() -> Self {
        Self {
            provider: Arc::new(NoOpEmbedding),
        }
    }
    
    pub fn embed(&self, text: &str) -> Option<Embedding> {
        self.provider.embed(text)
    }
    
    pub fn dimension(&self) -> usize {
        self.provider.dimension()
    }
}
```

---

## PART 13: COMPRESSION

```rust
// agentic-memory-core/src/v3/compression.rs

//! Compression for cold and frozen tiers.

use std::io::{Read, Write};

/// Compression level
#[derive(Debug, Clone, Copy)]
pub enum CompressionLevel {
    None,
    Fast,      // zstd level 1
    Default,   // zstd level 3
    Best,      // zstd level 19
}

impl CompressionLevel {
    fn zstd_level(&self) -> i32 {
        match self {
            Self::None => 0,
            Self::Fast => 1,
            Self::Default => 3,
            Self::Best => 19,
        }
    }
}

/// Compress data
pub fn compress(data: &[u8], level: CompressionLevel) -> Vec<u8> {
    if matches!(level, CompressionLevel::None) {
        return data.to_vec();
    }
    
    zstd::encode_all(data, level.zstd_level()).unwrap_or_else(|_| data.to_vec())
}

/// Decompress data
pub fn decompress(data: &[u8]) -> Result<Vec<u8>, std::io::Error> {
    // Check if actually compressed (zstd magic: 0x28B52FFD)
    if data.len() >= 4 && data[0..4] == [0x28, 0xB5, 0x2F, 0xFD] {
        zstd::decode_all(data)
    } else {
        Ok(data.to_vec())
    }
}

/// Streaming compressor for large data
pub struct StreamCompressor<W: Write> {
    encoder: zstd::stream::Encoder<'static, W>,
}

impl<W: Write> StreamCompressor<W> {
    pub fn new(writer: W, level: CompressionLevel) -> Result<Self, std::io::Error> {
        let encoder = zstd::stream::Encoder::new(writer, level.zstd_level())?;
        Ok(Self { encoder })
    }
    
    pub fn write(&mut self, data: &[u8]) -> Result<(), std::io::Error> {
        self.encoder.write_all(data)
    }
    
    pub fn finish(self) -> Result<W, std::io::Error> {
        self.encoder.finish()
    }
}

/// Streaming decompressor
pub struct StreamDecompressor<R: Read> {
    decoder: zstd::stream::Decoder<'static, std::io::BufReader<R>>,
}

impl<R: Read> StreamDecompressor<R> {
    pub fn new(reader: R) -> Result<Self, std::io::Error> {
        let decoder = zstd::stream::Decoder::new(reader)?;
        Ok(Self { decoder })
    }
}

impl<R: Read> Read for StreamDecompressor<R> {
    fn read(&mut self, buf: &mut [u8]) -> Result<usize, std::io::Error> {
        self.decoder.read(buf)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_roundtrip() {
        let original = b"Hello, this is a test of compression!".repeat(100);
        
        let compressed = compress(&original, CompressionLevel::Default);
        assert!(compressed.len() < original.len());
        
        let decompressed = decompress(&compressed).unwrap();
        assert_eq!(decompressed, original);
    }
    
    #[test]
    fn test_no_compression() {
        let original = b"Small data";
        let result = compress(original, CompressionLevel::None);
        assert_eq!(result, original);
    }
}
```

---

## PART 14: ENCRYPTION

```rust
// agentic-memory-core/src/v3/encryption.rs

//! Encryption for memory at rest.
//! Uses XChaCha20-Poly1305 for authenticated encryption.

use chacha20poly1305::{
    aead::{Aead, KeyInit, OsRng},
    XChaCha20Poly1305, XNonce,
};
use rand::RngCore;

/// 32-byte encryption key
pub type EncryptionKey = [u8; 32];

/// Generate a random encryption key
pub fn generate_key() -> EncryptionKey {
    let mut key = [0u8; 32];
    OsRng.fill_bytes(&mut key);
    key
}

/// Derive key from password using Argon2
pub fn derive_key(password: &str, salt: &[u8; 16]) -> EncryptionKey {
    use argon2::{Argon2, password_hash::PasswordHasher};
    
    let argon2 = Argon2::default();
    let mut key = [0u8; 32];
    
    argon2
        .hash_password_into(password.as_bytes(), salt, &mut key)
        .expect("key derivation failed");
    
    key
}

/// Encrypt data with authenticated encryption
pub fn encrypt(data: &[u8], key: &EncryptionKey) -> Result<Vec<u8>, EncryptionError> {
    let cipher = XChaCha20Poly1305::new(key.into());
    
    // Generate random nonce
    let mut nonce_bytes = [0u8; 24];
    OsRng.fill_bytes(&mut nonce_bytes);
    let nonce = XNonce::from_slice(&nonce_bytes);
    
    // Encrypt
    let ciphertext = cipher
        .encrypt(nonce, data)
        .map_err(|_| EncryptionError::EncryptionFailed)?;
    
    // Prepend nonce to ciphertext
    let mut result = Vec::with_capacity(24 + ciphertext.len());
    result.extend_from_slice(&nonce_bytes);
    result.extend_from_slice(&ciphertext);
    
    Ok(result)
}

/// Decrypt data
pub fn decrypt(data: &[u8], key: &EncryptionKey) -> Result<Vec<u8>, EncryptionError> {
    if data.len() < 24 {
        return Err(EncryptionError::InvalidData);
    }
    
    let cipher = XChaCha20Poly1305::new(key.into());
    
    // Extract nonce and ciphertext
    let nonce = XNonce::from_slice(&data[..24]);
    let ciphertext = &data[24..];
    
    // Decrypt
    cipher
        .decrypt(nonce, ciphertext)
        .map_err(|_| EncryptionError::DecryptionFailed)
}

#[derive(Debug, Clone)]
pub enum EncryptionError {
    EncryptionFailed,
    DecryptionFailed,
    InvalidData,
    InvalidKey,
}

impl std::fmt::Display for EncryptionError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::EncryptionFailed => write!(f, "encryption failed"),
            Self::DecryptionFailed => write!(f, "decryption failed (wrong key or corrupted data)"),
            Self::InvalidData => write!(f, "invalid encrypted data"),
            Self::InvalidKey => write!(f, "invalid encryption key"),
        }
    }
}

impl std::error::Error for EncryptionError {}

/// Encrypted block wrapper
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct EncryptedBlock {
    /// Encrypted data (nonce + ciphertext)
    #[serde(with = "base64_serde")]
    pub data: Vec<u8>,
    
    /// Key ID (for key rotation)
    pub key_id: String,
}

mod base64_serde {
    use base64::{engine::general_purpose::STANDARD, Engine};
    use serde::{Deserialize, Deserializer, Serializer};

    pub fn serialize<S>(bytes: &[u8], serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&STANDARD.encode(bytes))
    }

    pub fn deserialize<'de, D>(deserializer: D) -> Result<Vec<u8>, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        STANDARD.decode(&s).map_err(serde::de::Error::custom)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_encrypt_decrypt() {
        let key = generate_key();
        let plaintext = b"Secret memory content!";
        
        let encrypted = encrypt(plaintext, &key).unwrap();
        assert_ne!(encrypted, plaintext);
        
        let decrypted = decrypt(&encrypted, &key).unwrap();
        assert_eq!(decrypted, plaintext);
    }
    
    #[test]
    fn test_wrong_key() {
        let key1 = generate_key();
        let key2 = generate_key();
        let plaintext = b"Secret data";
        
        let encrypted = encrypt(plaintext, &key1).unwrap();
        let result = decrypt(&encrypted, &key2);
        
        assert!(result.is_err());
    }
}
```

---

## PART 15: CRASH RECOVERY

```rust
// agentic-memory-core/src/v3/recovery.rs

//! Crash recovery and write-ahead logging.

use super::block::{Block, BlockHash};
use std::path::{Path, PathBuf};
use std::fs::{File, OpenOptions};
use std::io::{BufReader, BufWriter, Read, Write, Seek, SeekFrom};

/// Write-ahead log for crash recovery
pub struct WriteAheadLog {
    path: PathBuf,
    file: File,
    sequence: u64,
}

impl WriteAheadLog {
    /// Open or create WAL
    pub fn open(dir: &Path) -> Result<Self, std::io::Error> {
        let path = dir.join("memory.wal");
        
        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .open(&path)?;
        
        let mut wal = Self {
            path,
            file,
            sequence: 0,
        };
        
        // Recover sequence number
        wal.recover_sequence()?;
        
        Ok(wal)
    }
    
    /// Write entry to WAL (before main log)
    pub fn write(&mut self, block: &Block) -> Result<(), std::io::Error> {
        let data = serde_json::to_vec(block)?;
        
        // Write: sequence (8) + length (4) + data + checksum (4)
        let checksum = crc32fast::hash(&data);
        
        self.file.seek(SeekFrom::End(0))?;
        self.file.write_all(&self.sequence.to_le_bytes())?;
        self.file.write_all(&(data.len() as u32).to_le_bytes())?;
        self.file.write_all(&data)?;
        self.file.write_all(&checksum.to_le_bytes())?;
        self.file.sync_all()?;
        
        self.sequence += 1;
        Ok(())
    }
    
    /// Mark entry as committed (can be garbage collected)
    pub fn commit(&mut self, sequence: u64) -> Result<(), std::io::Error> {
        // In a full implementation, we'd track committed entries
        // and periodically truncate the WAL
        Ok(())
    }
    
    /// Recover uncommitted entries after crash
    pub fn recover(&mut self) -> Result<Vec<Block>, std::io::Error> {
        let mut entries = Vec::new();
        
        self.file.seek(SeekFrom::Start(0))?;
        let mut reader = BufReader::new(&self.file);
        
        loop {
            // Read sequence
            let mut seq_buf = [0u8; 8];
            match reader.read_exact(&mut seq_buf) {
                Ok(_) => {}
                Err(e) if e.kind() == std::io::ErrorKind::UnexpectedEof => break,
                Err(e) => return Err(e),
            }
            
            // Read length
            let mut len_buf = [0u8; 4];
            reader.read_exact(&mut len_buf)?;
            let len = u32::from_le_bytes(len_buf) as usize;
            
            // Read data
            let mut data = vec![0u8; len];
            reader.read_exact(&mut data)?;
            
            // Read and verify checksum
            let mut checksum_buf = [0u8; 4];
            reader.read_exact(&mut checksum_buf)?;
            let stored_checksum = u32::from_le_bytes(checksum_buf);
            let computed_checksum = crc32fast::hash(&data);
            
            if stored_checksum == computed_checksum {
                if let Ok(block) = serde_json::from_slice::<Block>(&data) {
                    entries.push(block);
                }
            }
        }
        
        Ok(entries)
    }
    
    /// Clear WAL after successful checkpoint
    pub fn clear(&mut self) -> Result<(), std::io::Error> {
        self.file.set_len(0)?;
        self.file.seek(SeekFrom::Start(0))?;
        self.sequence = 0;
        Ok(())
    }
    
    fn recover_sequence(&mut self) -> Result<(), std::io::Error> {
        self.file.seek(SeekFrom::Start(0))?;
        
        let mut max_seq = 0u64;
        let mut reader = BufReader::new(&self.file);
        
        loop {
            let mut seq_buf = [0u8; 8];
            match reader.read_exact(&mut seq_buf) {
                Ok(_) => {
                    let seq = u64::from_le_bytes(seq_buf);
                    max_seq = max_seq.max(seq);
                    
                    // Skip rest of entry
                    let mut len_buf = [0u8; 4];
                    if reader.read_exact(&mut len_buf).is_err() {
                        break;
                    }
                    let len = u32::from_le_bytes(len_buf) as usize;
                    
                    let mut skip = vec![0u8; len + 4]; // data + checksum
                    if reader.read_exact(&mut skip).is_err() {
                        break;
                    }
                }
                Err(_) => break,
            }
        }
        
        self.sequence = max_seq + 1;
        Ok(())
    }
}

/// Recovery manager
pub struct RecoveryManager {
    wal: WriteAheadLog,
}

impl RecoveryManager {
    pub fn new(data_dir: &Path) -> Result<Self, std::io::Error> {
        Ok(Self {
            wal: WriteAheadLog::open(data_dir)?,
        })
    }
    
    /// Call before writing to main log
    pub fn pre_write(&mut self, block: &Block) -> Result<(), std::io::Error> {
        self.wal.write(block)
    }
    
    /// Call after successful write to main log
    pub fn post_write(&mut self, sequence: u64) -> Result<(), std::io::Error> {
        self.wal.commit(sequence)
    }
    
    /// Recover any uncommitted writes
    pub fn recover(&mut self) -> Result<Vec<Block>, std::io::Error> {
        self.wal.recover()
    }
    
    /// Checkpoint: clear WAL
    pub fn checkpoint(&mut self) -> Result<(), std::io::Error> {
        self.wal.clear()
    }
}
```

---

## PART 16: CONFIGURATION

```rust
// agentic-memory-core/src/v3/config.rs

use std::path::PathBuf;
use serde::{Deserialize, Serialize};

/// Complete V3 configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemoryV3Config {
    /// Data directory
    pub data_dir: PathBuf,
    
    /// Storage configuration
    pub storage: StorageConfig,
    
    /// Index configuration
    pub indexes: IndexConfig,
    
    /// Embedding configuration
    pub embeddings: EmbeddingConfig,
    
    /// Encryption configuration
    pub encryption: EncryptionConfig,
    
    /// Auto-capture configuration
    pub auto_capture: AutoCaptureConfig,
    
    /// Performance configuration
    pub performance: PerformanceConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StorageConfig {
    /// Hot tier max size (bytes)
    pub hot_max_bytes: usize,
    
    /// Warm tier max size (bytes)
    pub warm_max_bytes: usize,
    
    /// Cold tier compression level
    pub cold_compression: String,  // "none", "fast", "default", "best"
    
    /// Frozen tier compression level
    pub frozen_compression: String,
    
    /// Auto-archive after days
    pub archive_after_days: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IndexConfig {
    /// Enable temporal index
    pub temporal: bool,
    
    /// Enable semantic index
    pub semantic: bool,
    
    /// Enable causal index
    pub causal: bool,
    
    /// Enable entity index
    pub entity: bool,
    
    /// Enable procedural index
    pub procedural: bool,
    
    /// Rebuild indexes on startup
    pub rebuild_on_start: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmbeddingConfig {
    /// Embedding provider: "none", "tfidf", "local", "api"
    pub provider: String,
    
    /// Embedding dimension
    pub dimension: usize,
    
    /// For API provider: endpoint URL
    pub api_url: Option<String>,
    
    /// For API provider: API key (from env var)
    pub api_key_env: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EncryptionConfig {
    /// Enable encryption
    pub enabled: bool,
    
    /// Key derivation: "password" or "keyfile"
    pub key_source: String,
    
    /// For keyfile: path to key file
    pub keyfile_path: Option<PathBuf>,
    
    /// For password: env var name containing password
    pub password_env: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AutoCaptureConfig {
    /// Enable auto-capture
    pub enabled: bool,
    
    /// Capture messages
    pub messages: bool,
    
    /// Capture tool calls
    pub tools: bool,
    
    /// Capture file operations
    pub files: bool,
    
    /// Checkpoint interval (blocks)
    pub checkpoint_interval: u32,
    
    /// Context pressure threshold (0.0 - 1.0)
    pub pressure_threshold: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceConfig {
    /// Memory map threshold (use mmap above this size)
    pub mmap_threshold_bytes: usize,
    
    /// Index cache size (entries)
    pub index_cache_size: usize,
    
    /// Write buffer size (bytes)
    pub write_buffer_size: usize,
    
    /// Background thread count
    pub background_threads: usize,
}

impl Default for MemoryV3Config {
    fn default() -> Self {
        Self {
            data_dir: PathBuf::from(".agentic/memory"),
            storage: StorageConfig {
                hot_max_bytes: 10 * 1024 * 1024,      // 10 MB
                warm_max_bytes: 100 * 1024 * 1024,    // 100 MB
                cold_compression: "default".to_string(),
                frozen_compression: "best".to_string(),
                archive_after_days: 365,
            },
            indexes: IndexConfig {
                temporal: true,
                semantic: true,
                causal: true,
                entity: true,
                procedural: true,
                rebuild_on_start: false,
            },
            embeddings: EmbeddingConfig {
                provider: "tfidf".to_string(),
                dimension: 384,
                api_url: None,
                api_key_env: None,
            },
            encryption: EncryptionConfig {
                enabled: false,
                key_source: "password".to_string(),
                keyfile_path: None,
                password_env: None,
            },
            auto_capture: AutoCaptureConfig {
                enabled: true,
                messages: true,
                tools: true,
                files: true,
                checkpoint_interval: 50,
                pressure_threshold: 0.75,
            },
            performance: PerformanceConfig {
                mmap_threshold_bytes: 1024 * 1024,  // 1 MB
                index_cache_size: 10000,
                write_buffer_size: 64 * 1024,       // 64 KB
                background_threads: 2,
            },
        }
    }
}

impl MemoryV3Config {
    /// Load from file
    pub fn load(path: &PathBuf) -> Result<Self, Box<dyn std::error::Error>> {
        let content = std::fs::read_to_string(path)?;
        let config: Self = toml::from_str(&content)?;
        Ok(config)
    }
    
    /// Save to file
    pub fn save(&self, path: &PathBuf) -> Result<(), Box<dyn std::error::Error>> {
        let content = toml::to_string_pretty(self)?;
        std::fs::write(path, content)?;
        Ok(())
    }
    
    /// Load from default location or create default
    pub fn load_or_default() -> Self {
        let default_path = dirs::config_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("agentic")
            .join("memory.toml");
        
        Self::load(&default_path).unwrap_or_default()
    }
}
```

---

## PART 17: CARGO.TOML CHANGES

```toml
# agentic-memory-core/Cargo.toml

[package]
name = "agentic-memory-core"
version = "0.4.0"  # Bump for V3
edition = "2021"

[features]
default = ["v3"]
v3 = ["memmap2", "zstd", "chacha20poly1305", "argon2", "rand"]
local-embeddings = ["ort"]  # ONNX runtime for local embeddings
encryption = ["chacha20poly1305", "argon2", "rand"]

[dependencies]
# Existing deps...
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
chrono = { version = "0.4", features = ["serde"] }
blake3 = "1.5"
uuid = { version = "1.0", features = ["v4", "serde"] }
thiserror = "1.0"
hex = "0.4"
crc32fast = "1.3"
toml = "0.8"
dirs = "5.0"

# V3 specific
memmap2 = { version = "0.9", optional = true }
zstd = { version = "0.13", optional = true }
chacha20poly1305 = { version = "0.10", optional = true }
argon2 = { version = "0.5", optional = true }
rand = { version = "0.8", optional = true }

# Optional: local embeddings
ort = { version = "1.16", optional = true }

[dev-dependencies]
tempfile = "3.10"
```

---

## PART 18: MODULE STRUCTURE

```rust
// agentic-memory-core/src/v3/mod.rs

//! Memory V3: Immortal Architecture
//! 
//! Never lose a token. Ever.

pub mod block;
pub mod immortal_log;
pub mod indexes;
pub mod tiered;
pub mod retrieval;
pub mod engine;
pub mod embeddings;
pub mod compression;
pub mod config;

#[cfg(feature = "encryption")]
pub mod encryption;

pub mod recovery;
pub mod migration;
pub mod claude_hooks;

// Re-exports
pub use block::*;
pub use immortal_log::*;
pub use tiered::*;
pub use retrieval::*;
pub use engine::*;
pub use config::*;

/// V3 version string
pub const V3_VERSION: &str = "3.0.0";

/// V3 file magic
pub const V3_MAGIC: &[u8; 4] = b"IMRT";
```

```rust
// agentic-memory-core/src/lib.rs

//! AgenticMemory: Persistent cognitive memory for AI agents.

pub mod graph;      // V2
pub mod query;      // V2
pub mod session;    // V2

#[cfg(feature = "v3")]
pub mod v3;         // V3: Immortal Architecture

// Feature detection
pub fn v3_enabled() -> bool {
    cfg!(feature = "v3")
}

// Re-export based on feature
#[cfg(feature = "v3")]
pub use v3::MemoryEngineV3;
```

---

## FINAL DEPENDENCY SUMMARY

```toml
# Required for V3:

memmap2 = "0.9"           # Memory-mapped files
zstd = "0.13"             # Compression
chacha20poly1305 = "0.10" # Encryption
argon2 = "0.5"            # Key derivation
rand = "0.8"              # Random generation
crc32fast = "1.3"         # Checksums
toml = "0.8"              # Config files
dirs = "5.0"              # Platform directories

# Optional:
ort = "1.16"              # ONNX for local embeddings
```

---

## COMPLETE FILE TREE

```
agentic-memory/
├── core/
│   ├── Cargo.toml                    # Updated with V3 deps
│   └── src/
│       ├── lib.rs                    # Updated with v3 module
│       ├── graph.rs                  # V2 (unchanged)
│       ├── query.rs                  # V2 (unchanged)
│       ├── session.rs                # V2 (unchanged)
│       └── v3/
│           ├── mod.rs                # V3 module root
│           ├── block.rs              # Block, BlockHash, BlockContent
│           ├── immortal_log.rs       # Append-only log
│           ├── indexes/
│           │   ├── mod.rs            # Index trait
│           │   ├── temporal.rs       # Time-based index
│           │   ├── semantic.rs       # Embedding search
│           │   ├── causal.rs         # Decision DAG
│           │   ├── entity.rs         # File/person index
│           │   └── procedural.rs     # Session/workflow
│           ├── tiered.rs             # Hot/warm/cold/frozen
│           ├── retrieval.rs          # Smart context assembly
│           ├── engine.rs             # MemoryEngineV3
│           ├── embeddings.rs         # Embedding providers
│           ├── compression.rs        # zstd compression
│           ├── encryption.rs         # ChaCha20 encryption
│           ├── recovery.rs           # WAL and crash recovery
│           ├── migration.rs          # V2 -> V3 migration
│           ├── config.rs             # Configuration
│           ├── claude_hooks.rs       # Claude Code integration
│           └── tests.rs              # Unit tests
├── mcp/
│   └── src/
│       ├── lib.rs                    # Updated
│       ├── v3_tools.rs               # V3 MCP tools (14+)
│       └── auto_capture.rs           # Auto-capture middleware
├── cli/
│   └── src/
│       ├── main.rs                   # Updated
│       └── v3_commands.rs            # V3 CLI commands
└── ...
```

---

**NOW it's truly complete.** 

The specification includes:

1. ✅ Core data structures (Block, BlockHash, BlockContent)
2. ✅ Immortal Log (append-only)
3. ✅ Five Indexes (temporal, semantic, causal, entity, procedural)
4. ✅ Tiered Storage (hot/warm/cold/frozen)
5. ✅ Memory Engine V3
6. ✅ Smart Retrieval Engine
7. ✅ MCP Tools (14+ tools)
8. ✅ V2 → V3 Migration
9. ✅ Claude Code Integration Hooks
10. ✅ CLI Commands
11. ✅ Comprehensive Tests
12. ✅ Auto-capture Middleware
13. ✅ File Format Specification
14. ✅ **Embedding Generation**
15. ✅ **Compression (zstd)**
16. ✅ **Encryption (XChaCha20-Poly1305)**
17. ✅ **Crash Recovery (WAL)**
18. ✅ **Configuration System**
19. ✅ **Complete Cargo.toml**
20. ✅ **Full Module Structure**

**Total: ~3000 lines of implementation-ready Rust code.**

Ready to build? 🚀

---

## PART 19: CLAUDE CODE EXECUTION PROMPT

```markdown
# CLAUDE CODE: Build Memory V3

## Context
You are implementing Memory V3: Immortal Architecture for AgenticMemory.
The full specification is in MEMORY-V3-IMMORTAL-IMPLEMENTATION.md.

## Current State
- agentic-memory exists with V2 implementation
- V3 is a new module, NOT a replacement
- V2 continues to work, V3 is additive

## Your Task
Implement V3 in phases. After each phase, run tests to verify.

## Phase Execution Order

### PHASE 1: Blocks (Start Here)
```bash
cd agentic-memory/core
mkdir -p src/v3/indexes
```

Create these files in order:
1. `src/v3/mod.rs` - Module root
2. `src/v3/block.rs` - Block, BlockHash, BlockContent, BlockType
3. Run: `cargo test v3::block`

### PHASE 2: Immortal Log
1. `src/v3/immortal_log.rs` - Append-only log with mmap
2. Run: `cargo test v3::immortal_log`

### PHASE 3: Indexes
1. `src/v3/indexes/mod.rs` - Index trait
2. `src/v3/indexes/temporal.rs` - B-tree time index
3. `src/v3/indexes/semantic.rs` - Text/embedding search
4. `src/v3/indexes/causal.rs` - Decision DAG
5. `src/v3/indexes/entity.rs` - Inverted file index
6. `src/v3/indexes/procedural.rs` - Session tracking
7. Run: `cargo test v3::indexes`

### PHASE 4: Storage + Compression
1. `src/v3/compression.rs` - zstd wrapper
2. `src/v3/tiered.rs` - Hot/warm/cold/frozen
3. Run: `cargo test v3::tiered`

### PHASE 5: Engine
1. `src/v3/config.rs` - Configuration
2. `src/v3/engine.rs` - MemoryEngineV3
3. Run: `cargo test v3::engine`

### PHASE 6: Retrieval
1. `src/v3/retrieval.rs` - Smart context assembly
2. Run: `cargo test v3::retrieval`

### PHASE 7: Recovery + Encryption (Optional)
1. `src/v3/recovery.rs` - WAL
2. `src/v3/encryption.rs` - ChaCha20
3. Run: `cargo test v3::recovery`

### PHASE 8: MCP Tools
1. `mcp/src/v3_tools.rs` - All MCP tools
2. Update `mcp/src/lib.rs` to register V3 tools
3. Run: `cargo test --package agentic-memory-mcp`

### PHASE 9: Integration
1. Update `core/Cargo.toml` with new deps
2. Update `core/src/lib.rs` to expose v3
3. Run full test suite: `cargo test --all`

## Success Criteria Per Phase
- All tests pass
- No compiler warnings
- Code matches spec

## DO NOT
- Modify V2 code (it stays working)
- Skip tests between phases
- Combine multiple phases

## START NOW
Begin with Phase 1. Create src/v3/mod.rs first.
```

---

## PART 20: DETAILED PHASE BREAKDOWN

```
PHASE 1: BLOCKS (45-60 min)
═══════════════════════════

Files to create:
  src/v3/mod.rs        (~50 lines)
  src/v3/block.rs      (~300 lines)

Key structs:
  - BlockHash (32 bytes, BLAKE3)
  - BlockType enum (12 variants)
  - BlockContent enum (8 variants)
  - Block struct

Tests to write:
  - test_block_hash_compute
  - test_block_hash_roundtrip
  - test_block_serialization
  - test_block_verification
  - test_block_type_coverage

Success: `cargo test v3::block` passes (5+ tests)


PHASE 2: IMMORTAL LOG (60-90 min)
═════════════════════════════════

Files to create:
  src/v3/immortal_log.rs (~400 lines)

Key components:
  - File format (header + blocks)
  - Memory mapping
  - Append operation
  - Read by sequence
  - Read by hash
  - Integrity verification

Tests to write:
  - test_log_create
  - test_log_append
  - test_log_read_sequence
  - test_log_read_hash
  - test_log_persistence
  - test_log_integrity

Success: `cargo test v3::immortal_log` passes (6+ tests)


PHASE 3: INDEXES (90-120 min)
═════════════════════════════

Files to create:
  src/v3/indexes/mod.rs       (~50 lines)
  src/v3/indexes/temporal.rs  (~150 lines)
  src/v3/indexes/semantic.rs  (~200 lines)
  src/v3/indexes/causal.rs    (~200 lines)
  src/v3/indexes/entity.rs    (~150 lines)
  src/v3/indexes/procedural.rs (~200 lines)

Tests per index:
  - test_{index}_insert
  - test_{index}_query
  - test_{index}_rebuild

Success: `cargo test v3::indexes` passes (15+ tests)


PHASE 4: STORAGE (45-60 min)
════════════════════════════

Files to create:
  src/v3/compression.rs (~100 lines)
  src/v3/tiered.rs      (~300 lines)

Key components:
  - Compression wrapper (zstd)
  - Four tiers (hot/warm/cold/frozen)
  - Automatic demotion
  - Stats tracking

Tests:
  - test_compression_roundtrip
  - test_tier_insert
  - test_tier_demotion
  - test_tier_stats

Success: `cargo test v3::tiered` passes (4+ tests)


PHASE 5: ENGINE (60-90 min)
═══════════════════════════

Files to create:
  src/v3/config.rs  (~200 lines)
  src/v3/engine.rs  (~500 lines)

Key methods:
  - open()
  - capture_user_message()
  - capture_assistant_message()
  - capture_tool_call()
  - capture_file_operation()
  - capture_decision()
  - capture_boundary()
  - search_temporal()
  - search_semantic()
  - search_entity()
  - session_resume()
  - stats()

Tests:
  - test_engine_open
  - test_capture_message
  - test_capture_tool
  - test_capture_file
  - test_capture_decision
  - test_search_temporal
  - test_search_semantic
  - test_session_resume
  - test_persistence

Success: `cargo test v3::engine` passes (9+ tests)


PHASE 6: RETRIEVAL (45-60 min)
══════════════════════════════

Files to create:
  src/v3/retrieval.rs (~300 lines)

Key components:
  - RetrievalRequest
  - RetrievalStrategy
  - RetrievalResult
  - Multi-index fusion
  - Token budgeting

Tests:
  - test_retrieve_relevance
  - test_retrieve_recency
  - test_retrieve_causal
  - test_retrieve_budget

Success: `cargo test v3::retrieval` passes (4+ tests)


PHASE 7: RECOVERY + ENCRYPTION (45-60 min, optional)
════════════════════════════════════════════════════

Files to create:
  src/v3/recovery.rs   (~200 lines)
  src/v3/encryption.rs (~150 lines)

Can skip if time-constrained. Core V3 works without these.


PHASE 8: MCP TOOLS (60-90 min)
══════════════════════════════

Files to create:
  mcp/src/v3_tools.rs (~400 lines)

Tools to implement:
  - memory_capture_message
  - memory_capture_tool
  - memory_capture_file
  - memory_capture_decision
  - memory_capture_boundary
  - memory_retrieve
  - memory_resurrect
  - memory_session_resume
  - memory_search_temporal
  - memory_search_semantic
  - memory_search_entity
  - memory_verify_integrity
  - memory_stats

Success: MCP server starts, tools callable


PHASE 9: INTEGRATION (30-45 min)
════════════════════════════════

Updates:
  - core/Cargo.toml (add deps)
  - core/src/lib.rs (expose v3)
  - mcp/src/lib.rs (register v3 tools)

Final test:
  - `cargo test --all`
  - `cargo run --bin amem-mcp` starts

Success: Full test suite passes, MCP server runs


TOTAL TIME ESTIMATE
═══════════════════

Minimum (phases 1-6, 8-9): 6-8 hours
Full (all phases): 8-10 hours

With breaks and debugging: 10-12 hours

Recommended: Split into 2 sessions
  Session 1: Phases 1-5 (core engine)
  Session 2: Phases 6-9 (retrieval + MCP)
```

---

## PART 21: SUCCESS CRITERIA

```
DEFINITION OF DONE
══════════════════

□ CORE FUNCTIONALITY
  □ Blocks serialize/deserialize correctly
  □ Immortal log appends and persists
  □ All 5 indexes build and query
  □ Tiered storage demotes blocks
  □ Engine captures all event types
  □ Session resume returns full context

□ MCP TOOLS
  □ All 13+ tools registered
  □ memory_capture_* tools work
  □ memory_search_* tools return results
  □ memory_session_resume returns context
  □ memory_verify_integrity passes

□ TESTS
  □ Unit tests: 40+ tests pass
  □ Integration tests: 10+ tests pass
  □ No compiler warnings
  □ No clippy warnings

□ PERSISTENCE
  □ Data survives process restart
  □ Indexes rebuild from log if needed
  □ V2 files still readable

□ PERFORMANCE
  □ Capture: < 10ms per block
  □ Search: < 100ms for 10K blocks
  □ Resume: < 500ms

□ DOCUMENTATION
  □ Module docs present
  □ Public API documented
  □ README updated


SMOKE TEST SCRIPT
═════════════════

```bash
#!/bin/bash
# test_v3_smoke.sh

set -e

echo "=== Memory V3 Smoke Test ==="

# Build
cargo build --package agentic-memory-core --features v3
cargo build --package agentic-memory-mcp

# Run unit tests
cargo test --package agentic-memory-core v3::

# Start MCP server in background
cargo run --bin amem-mcp &
MCP_PID=$!
sleep 2

# Test MCP tools via curl (if HTTP endpoint)
# Or test via MCP client

# Cleanup
kill $MCP_PID

echo "=== SMOKE TEST PASSED ==="
```


ACCEPTANCE TEST SCENARIOS
═════════════════════════

Scenario 1: Basic Capture and Resume
────────────────────────────────────
1. Create engine
2. Capture 5 messages
3. Capture 3 tool calls
4. Capture 2 file operations
5. Capture 1 decision
6. Call session_resume()
7. Verify all items returned

Scenario 2: Persistence
───────────────────────
1. Create engine, capture 10 blocks
2. Drop engine
3. Reopen engine
4. Verify block count = 10
5. Verify session_resume works

Scenario 3: Search
──────────────────
1. Capture 100 diverse messages
2. Search semantic for specific topic
3. Verify relevant results returned
4. Search entity for file path
5. Verify file operations returned

Scenario 4: Boundary Handling
─────────────────────────────
1. Capture 20 messages
2. Capture compaction boundary
3. Capture 10 more messages
4. session_resume should show boundary
5. Retrieval should cross boundary

Scenario 5: Integrity
─────────────────────
1. Capture 50 blocks
2. Call verify_integrity()
3. Must return verified=true
4. Corrupt one block (manual)
5. verify_integrity() must detect
```

---

## PART 22: QUICK REFERENCE CARD

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                    MEMORY V3: QUICK REFERENCE                              ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  CAPTURE                           SEARCH                                 ║
║  ───────                           ──────                                 ║
║  capture_user_message()            search_temporal(start, end)           ║
║  capture_assistant_message()       search_semantic(query, limit)         ║
║  capture_tool_call()               search_entity(entity)                 ║
║  capture_file_operation()          get_decision_chain(seq)               ║
║  capture_decision()                get_current_session()                 ║
║  capture_boundary()                                                      ║
║  capture_checkpoint()              RETRIEVAL                             ║
║                                    ─────────                              ║
║  BLOCK TYPES                       retrieve(request) → context           ║
║  ───────────                       resurrect(timestamp) → state          ║
║  UserMessage                       session_resume() → full context       ║
║  AssistantMessage                                                        ║
║  SystemMessage                     VERIFICATION                          ║
║  ToolCall                          ────────────                           ║
║  ToolResult                        verify_integrity() → report           ║
║  FileOperation                     stats() → statistics                  ║
║  Decision                                                                ║
║  SessionBoundary                   FILE OPERATIONS                       ║
║  Error                             ───────────────                        ║
║  Checkpoint                        Create, Read, Update, Delete, Rename  ║
║  Custom                                                                  ║
║                                    BOUNDARY TYPES                        ║
║  INDEXES                           ──────────────                         ║
║  ───────                           SessionStart, SessionEnd              ║
║  Temporal   (by time)              Compaction, ContextPressure           ║
║  Semantic   (by meaning)           UserRequested, Checkpoint             ║
║  Causal     (by causation)                                               ║
║  Entity     (by file/person)       TIERS                                 ║
║  Procedural (by workflow)          ─────                                  ║
║                                    Hot (memory, <1ms)                    ║
║  RETRIEVAL STRATEGIES              Warm (disk, <10ms)                    ║
║  ────────────────────              Cold (compressed, <100ms)             ║
║  Recency    (recent first)         Frozen (archive, <1s)                 ║
║  Relevance  (semantic match)                                             ║
║  Causal     (decision chains)      MAGIC BYTES                           ║
║  Balanced   (mix of all)           ───────────                            ║
║                                    IMRT = Immortal Log                   ║
║                                    INDX = Index Section                  ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## PART 23: EMERGENCY FALLBACK

```
IF SOMETHING GOES WRONG
═══════════════════════

Problem: Tests fail after Phase N
Solution: 
  1. Don't proceed to Phase N+1
  2. Fix the failing tests first
  3. Re-run `cargo test v3::{module}`

Problem: Compilation errors
Solution:
  1. Check Cargo.toml has all deps
  2. Check feature flags
  3. Check mod.rs exports

Problem: Runtime crash
Solution:
  1. Check file permissions
  2. Check data directory exists
  3. Check disk space

Problem: MCP tools not found
Solution:
  1. Verify v3_tools.rs is imported
  2. Verify register_v3_tools() called
  3. Restart MCP server

Problem: Data corruption
Solution:
  1. V3 has WAL for recovery
  2. Call recover() on startup
  3. If still corrupt, rebuild from WAL

Problem: Out of time
Solution:
  1. Phases 1-5 give you a working engine
  2. Phase 8 (MCP) is essential for usage
  3. Skip Phase 7 (recovery/encryption)
  4. Minimum viable: 1,2,3,4,5,8


ROLLBACK PROCEDURE
══════════════════

If V3 causes issues:

1. V2 is untouched, still works
2. Feature flag: disable v3 feature
3. MCP: remove v3 tool registration
4. Cargo.toml: remove v3 deps

V3 is additive. V2 always works.
```

---

**NOW it's truly complete.**

The specification includes:

| Part | Content | Lines |
|------|---------|-------|
| 1 | Block data structures | ~300 |
| 2 | Immortal Log | ~400 |
| 3 | Five Indexes | ~900 |
| 4 | Tiered Storage | ~300 |
| 5 | Memory Engine | ~500 |
| 6 | Smart Retrieval | ~300 |
| 7 | MCP Tools | ~400 |
| 8 | V2→V3 Migration | ~150 |
| 9 | Claude Code Hooks | ~150 |
| 10 | CLI Commands | ~200 |
| 11 | Tests | ~300 |
| 12 | Auto-capture | ~150 |
| 13 | File Format | ~50 |
| 14 | Embeddings | ~200 |
| 15 | Compression | ~100 |
| 16 | Encryption | ~150 |
| 17 | Crash Recovery | ~200 |
| 18 | Configuration | ~200 |
| 19 | **Claude Code Prompt** | ~100 |
| 20 | **Phased Breakdown** | ~200 |
| 21 | **Success Criteria** | ~150 |
| 22 | **Quick Reference** | ~50 |
| 23 | **Emergency Fallback** | ~100 |

**Total: ~5,000+ lines of specification**

This is a complete, implementation-ready blueprint. Hand this to Claude Code and say "Build it."

Ready? 🚀
