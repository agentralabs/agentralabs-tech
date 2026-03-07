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

*Ready for implementation. Let's build it tonight.* 🚀
