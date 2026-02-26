# SISTER-HYDRA INTEGRATION CONTRACT

> **Status:** MANDATORY
> **Version:** 1.0
> **Date:** February 2026
> **Compliance:** All sisters MUST comply. No exceptions.

---

## Executive Summary

This document defines the **binding contract** between all sisters and Hydra. Every sister—past, present, and future—MUST implement these interfaces exactly as specified. Deviation breaks Hydra integration and violates the ecosystem promise.

### The Promise

```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ANY sister can be consumed by Hydra uniformly.              ║
║   ANY sister can work with ANY other sister.                  ║
║   ANY file format will be readable in 20 years.               ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

### Sisters Covered

```
FOUNDATION (Shipped):
─────────────────────
✅ AgenticMemory    (.amem)
✅ AgenticVision    (.avis)
✅ AgenticCodebase  (.acb)
✅ AgenticIdentity  (.aid)

FOUNDATION (Planned):
─────────────────────
⏳ AgenticTime      (.atime)
⏳ AgenticContract  (.acon)

COGNITIVE (Planned):
────────────────────
⏳ AgenticComm      (.acomm)
⏳ AgenticPlanning  (.aplan)
⏳ AgenticCognition (.acog)
⏳ AgenticReality   (.areal)

ALL MUST COMPLY WITH THIS CONTRACT.
```

---

## 1. SISTER API CONTRACT

### 1.1 Required Trait

Every sister MUST implement this trait:

```rust
/// The core trait that ALL sisters must implement.
/// This is the contract with Hydra.
pub trait Sister: Send + Sync {
    /// Sister type identifier
    const SISTER_TYPE: SisterType;
    
    /// File extension for this sister's format
    const FILE_EXTENSION: &'static str;
    
    /// Initialize the sister with configuration
    fn init(config: SisterConfig) -> Result<Self, SisterError>
    where
        Self: Sized;
    
    /// Check health status
    fn health(&self) -> HealthStatus;
    
    /// Get current version
    fn version(&self) -> Version;
    
    /// Shutdown gracefully
    fn shutdown(&mut self) -> Result<(), SisterError>;
    
    /// Get capabilities this sister provides
    fn capabilities(&self) -> Vec<Capability>;
}
```

### 1.2 Sister Types (Enum)

```rust
/// All sister types in the ecosystem
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SisterType {
    // Foundation
    Memory,
    Vision,
    Codebase,
    Identity,
    Time,
    Contract,
    
    // Cognitive
    Comm,
    Planning,
    Cognition,
    Reality,
    
    // Future (reserved)
    Attention,
    Affect,
    Motivation,
    Learning,
    Bond,
    Meaning,
    Wonder,
    Imagination,
    Conscience,
    Meta,
    Duration,
}

impl SisterType {
    pub fn file_extension(&self) -> &'static str {
        match self {
            Self::Memory => "amem",
            Self::Vision => "avis",
            Self::Codebase => "acb",
            Self::Identity => "aid",
            Self::Time => "atime",
            Self::Contract => "acon",
            Self::Comm => "acomm",
            Self::Planning => "aplan",
            Self::Cognition => "acog",
            Self::Reality => "areal",
            // ... etc
        }
    }
}
```

### 1.3 Configuration Contract

```rust
/// Standard configuration for all sisters
#[derive(Debug, Clone)]
pub struct SisterConfig {
    /// Path to the sister's data file
    pub data_path: PathBuf,
    
    /// Whether to create if not exists
    pub create_if_missing: bool,
    
    /// Read-only mode
    pub read_only: bool,
    
    /// Memory budget (optional)
    pub memory_budget_mb: Option<usize>,
    
    /// Custom options (sister-specific)
    pub options: HashMap<String, Value>,
}

impl Default for SisterConfig {
    fn default() -> Self {
        Self {
            data_path: PathBuf::from("."),
            create_if_missing: true,
            read_only: false,
            memory_budget_mb: None,
            options: HashMap::new(),
        }
    }
}
```

### 1.4 Health Status Contract

```rust
/// Health status returned by all sisters
#[derive(Debug, Clone)]
pub struct HealthStatus {
    /// Is the sister operational?
    pub healthy: bool,
    
    /// Current status
    pub status: Status,
    
    /// Time since initialization
    pub uptime: Duration,
    
    /// Resource usage
    pub resources: ResourceUsage,
    
    /// Any warnings (non-fatal issues)
    pub warnings: Vec<String>,
    
    /// Last error if any
    pub last_error: Option<SisterError>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Status {
    Starting,
    Ready,
    Busy,
    Degraded,
    ShuttingDown,
    Error,
}

#[derive(Debug, Clone, Default)]
pub struct ResourceUsage {
    pub memory_bytes: usize,
    pub disk_bytes: usize,
    pub open_handles: usize,
}
```

---

## 2. CONTEXT/SESSION CONTRACT

### 2.1 The Unified Pattern

Every sister has a domain concept that maps to "Context":

```
┌─────────────────────────────────────────────────────────────┐
│                    CONTEXT MAPPING                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  SISTER          DOMAIN CONCEPT      HYDRA SEES             │
│  ───────────────────────────────────────────────────────    │
│  Memory          Session             Context                │
│  Vision          Archive             Context                │
│  Codebase        Workspace           Context                │
│  Identity        Chain               Context                │
│  Time            Timeline            Context                │
│  Contract        Agreement           Context                │
│  Comm            Channel             Context                │
│  Planning        Goal                Context                │
│  Cognition       Profile             Context                │
│  Reality         World               Context                │
│                                                             │
│  Hydra doesn't care about domain concepts.                  │
│  Hydra works with "Context" uniformly.                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Context Trait

```rust
/// All sisters MUST implement context management
pub trait ContextManagement {
    /// Create a new context
    fn create_context(&mut self, name: &str) -> Result<ContextId, SisterError>;
    
    /// Switch to a different context
    fn switch_context(&mut self, id: ContextId) -> Result<(), SisterError>;
    
    /// Get current context ID
    fn current_context(&self) -> ContextId;
    
    /// Get current context info
    fn current_context_info(&self) -> Result<ContextInfo, SisterError>;
    
    /// List all contexts
    fn list_contexts(&self) -> Result<Vec<ContextSummary>, SisterError>;
    
    /// Delete a context
    fn delete_context(&mut self, id: ContextId) -> Result<(), SisterError>;
    
    /// Export context as snapshot (for backup/transfer)
    fn export_context(&self, id: ContextId) -> Result<ContextSnapshot, SisterError>;
    
    /// Import context from snapshot
    fn import_context(&mut self, snapshot: ContextSnapshot) -> Result<ContextId, SisterError>;
}
```

### 2.3 Context Types

```rust
/// Unique identifier for a context
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct ContextId(pub Uuid);

impl ContextId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
    
    pub fn default() -> Self {
        // The "default" context that always exists
        Self(Uuid::from_bytes([0; 16]))
    }
}

/// Summary information about a context
#[derive(Debug, Clone)]
pub struct ContextSummary {
    pub id: ContextId,
    pub name: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub item_count: usize,
    pub size_bytes: usize,
}

/// Full context information
#[derive(Debug, Clone)]
pub struct ContextInfo {
    pub id: ContextId,
    pub name: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub item_count: usize,
    pub size_bytes: usize,
    pub metadata: HashMap<String, Value>,
}

/// Exportable context snapshot
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContextSnapshot {
    pub sister_type: SisterType,
    pub version: Version,
    pub context_info: ContextInfo,
    pub data: Vec<u8>,  // Sister-specific serialized data
    pub checksum: [u8; 32],
}
```

---

## 3. GROUNDING CONTRACT

### 3.1 The V2 Pattern

All sisters implement identical grounding interface:

```rust
/// Grounding capability - ALL sisters MUST implement
pub trait Grounding {
    /// Ground a claim against evidence
    fn ground(&self, request: GroundingRequest) -> Result<GroundingResult, SisterError>;
    
    /// Get evidence by ID
    fn get_evidence(&self, evidence_id: &str) -> Result<Evidence, SisterError>;
    
    /// List available evidence
    fn list_evidence(&self, filter: EvidenceFilter) -> Result<Vec<EvidenceSummary>, SisterError>;
}
```

### 3.2 Grounding Types

```rust
/// Request to ground a claim
#[derive(Debug, Clone)]
pub struct GroundingRequest {
    /// The claim being made
    pub claim: String,
    
    /// Evidence ID to ground against
    pub evidence_id: String,
    
    /// Optional: specific aspect to check
    pub aspect: Option<String>,
}

/// Result of grounding attempt
#[derive(Debug, Clone)]
pub struct GroundingResult {
    /// Is the claim grounded?
    pub grounded: bool,
    
    /// Confidence level (0.0 - 1.0)
    pub confidence: f64,
    
    /// The evidence used
    pub evidence: Evidence,
    
    /// Explanation of grounding decision
    pub explanation: String,
    
    /// Unique ID for this grounding (for receipts)
    pub grounding_id: String,
    
    /// Timestamp
    pub timestamp: DateTime<Utc>,
}

/// Evidence structure (sister-agnostic)
#[derive(Debug, Clone)]
pub struct Evidence {
    /// Unique evidence ID
    pub id: String,
    
    /// What sister produced this
    pub source_sister: SisterType,
    
    /// Type of evidence
    pub evidence_type: EvidenceType,
    
    /// When captured
    pub captured_at: DateTime<Utc>,
    
    /// Content hash (for verification)
    pub content_hash: [u8; 32],
    
    /// The actual evidence data
    pub content: EvidenceContent,
    
    /// Metadata
    pub metadata: HashMap<String, Value>,
}

#[derive(Debug, Clone)]
pub enum EvidenceType {
    // Memory
    MemoryNode,
    MemoryRelation,
    
    // Vision
    Screenshot,
    DomFingerprint,
    VisualDiff,
    
    // Codebase
    CodeNode,
    ImpactAnalysis,
    Prophecy,
    
    // Identity
    Receipt,
    TrustGrant,
    CompetenceProof,
    
    // Time (future)
    TimelineEvent,
    DurationProof,
    
    // Contract (future)
    Agreement,
    PolicyCheck,
    
    // Generic
    Custom(String),
}

#[derive(Debug, Clone)]
pub enum EvidenceContent {
    /// Text content
    Text(String),
    
    /// Binary content (images, etc.)
    Binary(Vec<u8>),
    
    /// Structured data
    Structured(Value),
    
    /// Reference to external content
    Reference { uri: String, hash: [u8; 32] },
}
```

### 3.3 Grounding Behavior Rules

```
GROUNDING RULES (ALL SISTERS MUST FOLLOW):
──────────────────────────────────────────

1. NEVER throw on missing evidence
   → Return grounded: false, confidence: 0.0

2. ALWAYS return a grounding_id
   → Used for receipt chain

3. ALWAYS include timestamp
   → UTC, ISO 8601

4. Confidence semantics:
   → 0.0 = No support
   → 0.5 = Partial support
   → 1.0 = Full support

5. Explanation MUST be human-readable
   → No technical jargon
   → Clear reason for grounding decision

6. Evidence MUST be retrievable
   → If you return evidence_id, get_evidence(id) MUST work
```

---

## 4. ERROR CONTRACT

### 4.1 Standard Error Type

```rust
/// Standard error type for ALL sisters
#[derive(Debug, Clone)]
pub struct SisterError {
    /// Error code (machine-readable)
    pub code: ErrorCode,
    
    /// Severity level
    pub severity: Severity,
    
    /// Human-readable message
    pub message: String,
    
    /// Additional context (for debugging)
    pub context: Option<HashMap<String, Value>>,
    
    /// Is this recoverable?
    pub recoverable: bool,
    
    /// Suggested action
    pub suggested_action: Option<SuggestedAction>,
    
    /// Source error (if wrapping another error)
    pub source: Option<Box<SisterError>>,
}

impl std::error::Error for SisterError {}

impl std::fmt::Display for SisterError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "[{}] {}", self.code, self.message)
    }
}
```

### 4.2 Error Codes

```rust
/// Standard error codes across ALL sisters
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ErrorCode {
    // ═══════════════════════════════════════════════════════
    // COMMON ERRORS (All sisters use these)
    // ═══════════════════════════════════════════════════════
    
    /// Resource not found
    NotFound,
    
    /// Invalid input provided
    InvalidInput,
    
    /// Operation not permitted
    PermissionDenied,
    
    /// Storage error (read/write failed)
    StorageError,
    
    /// Network error
    NetworkError,
    
    /// Operation timed out
    Timeout,
    
    /// Resource limits exceeded
    ResourceExhausted,
    
    /// Internal error (bug)
    Internal,
    
    /// Not implemented yet
    NotImplemented,
    
    /// Context/session not found
    ContextNotFound,
    
    /// Evidence not found
    EvidenceNotFound,
    
    /// Grounding failed
    GroundingFailed,
    
    /// Version mismatch
    VersionMismatch,
    
    /// Checksum mismatch (corruption)
    ChecksumMismatch,
    
    /// Already exists
    AlreadyExists,
    
    /// Invalid state for operation
    InvalidState,
    
    // ═══════════════════════════════════════════════════════
    // SISTER-SPECIFIC ERRORS (Prefixed)
    // ═══════════════════════════════════════════════════════
    
    /// Memory-specific error
    Memory(MemoryErrorCode),
    
    /// Vision-specific error
    Vision(VisionErrorCode),
    
    /// Codebase-specific error
    Codebase(CodebaseErrorCode),
    
    /// Identity-specific error
    Identity(IdentityErrorCode),
    
    /// Time-specific error
    Time(TimeErrorCode),
    
    /// Contract-specific error
    Contract(ContractErrorCode),
}

// Sister-specific error codes
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MemoryErrorCode {
    NodeNotFound,
    EdgeNotFound,
    InvalidNodeType,
    CycleDetected,
    SessionNotFound,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VisionErrorCode {
    CaptureError,
    InvalidImage,
    ComparisonFailed,
    ArchiveCorrupted,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CodebaseErrorCode {
    ParseError,
    GraphNotBuilt,
    InvalidLanguage,
    ProjectNotFound,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IdentityErrorCode {
    InvalidSignature,
    KeyNotFound,
    ChainBroken,
    TrustExpired,
    SpawnNotAllowed,
}

// ... etc for other sisters
```

### 4.3 Severity Levels

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Severity {
    /// Informational, not really an error
    Info,
    
    /// Warning, operation succeeded but with issues
    Warning,
    
    /// Error, operation failed but recoverable
    Error,
    
    /// Fatal, sister is in bad state
    Fatal,
}
```

### 4.4 Suggested Actions

```rust
#[derive(Debug, Clone)]
pub enum SuggestedAction {
    /// Retry the operation
    Retry { after: Duration },
    
    /// Use a different approach
    Alternative { description: String },
    
    /// User intervention needed
    UserAction { description: String },
    
    /// Restart the sister
    Restart,
    
    /// Check configuration
    CheckConfig { key: String },
    
    /// Contact support / report bug
    ReportBug,
}
```

### 4.5 Error Conversion

```rust
// All sisters MUST implement From for common error types
impl From<std::io::Error> for SisterError {
    fn from(e: std::io::Error) -> Self {
        SisterError {
            code: ErrorCode::StorageError,
            severity: Severity::Error,
            message: format!("I/O error: {}", e),
            context: None,
            recoverable: true,
            suggested_action: Some(SuggestedAction::Retry { 
                after: Duration::from_secs(1) 
            }),
            source: None,
        }
    }
}

// Similar for other common error types...
```

---

## 5. EVENT CONTRACT

### 5.1 Event Emission

All sisters MUST emit events for observability:

```rust
/// Event emitter trait
pub trait EventEmitter {
    /// Subscribe to events
    fn subscribe(&self, filter: EventFilter) -> EventReceiver;
    
    /// Get recent events
    fn recent_events(&self, limit: usize) -> Vec<SisterEvent>;
}

/// Event receiver (async stream)
pub type EventReceiver = tokio::sync::broadcast::Receiver<SisterEvent>;
```

### 5.2 Standard Events

```rust
/// Events that ALL sisters emit
#[derive(Debug, Clone)]
pub struct SisterEvent {
    /// Unique event ID
    pub id: EventId,
    
    /// Which sister emitted this
    pub sister_type: SisterType,
    
    /// Event type
    pub event_type: EventType,
    
    /// Timestamp
    pub timestamp: DateTime<Utc>,
    
    /// Event-specific data
    pub data: EventData,
}

#[derive(Debug, Clone)]
pub enum EventType {
    // ═══════════════════════════════════════════════════════
    // LIFECYCLE EVENTS (All sisters)
    // ═══════════════════════════════════════════════════════
    
    /// Sister initialized
    Ready,
    
    /// Sister shutting down
    ShuttingDown,
    
    /// Sister status changed
    StatusChanged { from: Status, to: Status },
    
    // ═══════════════════════════════════════════════════════
    // CONTEXT EVENTS (All sisters)
    // ═══════════════════════════════════════════════════════
    
    /// Context created
    ContextCreated { context_id: ContextId },
    
    /// Context switched
    ContextSwitched { from: ContextId, to: ContextId },
    
    /// Context deleted
    ContextDeleted { context_id: ContextId },
    
    // ═══════════════════════════════════════════════════════
    // OPERATION EVENTS (All sisters)
    // ═══════════════════════════════════════════════════════
    
    /// Operation started
    OperationStarted { 
        operation_id: String, 
        operation_type: String,
    },
    
    /// Operation completed
    OperationCompleted { 
        operation_id: String, 
        duration: Duration,
    },
    
    /// Operation failed
    OperationFailed { 
        operation_id: String, 
        error: SisterError,
    },
    
    // ═══════════════════════════════════════════════════════
    // EVIDENCE EVENTS (All sisters)
    // ═══════════════════════════════════════════════════════
    
    /// Evidence created
    EvidenceCreated { 
        evidence_id: String, 
        evidence_type: EvidenceType,
    },
    
    /// Grounding performed
    GroundingPerformed { 
        grounding_id: String, 
        grounded: bool,
        confidence: f64,
    },
    
    // ═══════════════════════════════════════════════════════
    // RESOURCE EVENTS (All sisters)
    // ═══════════════════════════════════════════════════════
    
    /// Memory pressure
    MemoryPressure { usage_percent: f64 },
    
    /// Storage pressure
    StoragePressure { usage_percent: f64 },
}

#[derive(Debug, Clone)]
pub struct EventData {
    /// Additional event-specific fields
    pub fields: HashMap<String, Value>,
}
```

---

## 6. RECEIPT INTEGRATION

### 6.1 The Rule

```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   IDENTITY IS THE RECEIPT SYSTEM.                             ║
║   ALL SISTERS USE IDENTITY FOR RECEIPTS.                      ║
║   HYDRA QUERIES IDENTITY FOR RECEIPTS.                        ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

### 6.2 Receipt Integration Trait

```rust
/// All sisters that create auditable actions MUST use Identity for receipts
pub trait ReceiptIntegration {
    /// Create a receipt for an action (via Identity)
    fn create_receipt(&self, action: ActionRecord) -> Result<ReceiptId, SisterError>;
    
    /// Get receipt by ID (from Identity)
    fn get_receipt(&self, id: ReceiptId) -> Result<Receipt, SisterError>;
    
    /// List receipts for this sister
    fn list_receipts(&self, filter: ReceiptFilter) -> Result<Vec<Receipt>, SisterError>;
}

/// Action record to be receipted
#[derive(Debug, Clone)]
pub struct ActionRecord {
    /// What sister performed this
    pub sister_type: SisterType,
    
    /// What action was performed
    pub action_type: String,
    
    /// Action parameters (sanitized)
    pub parameters: HashMap<String, Value>,
    
    /// Outcome
    pub outcome: ActionOutcome,
    
    /// Evidence pointers
    pub evidence_ids: Vec<String>,
    
    /// Context ID where this happened
    pub context_id: ContextId,
}

#[derive(Debug, Clone)]
pub enum ActionOutcome {
    Success { result: Value },
    Failure { error: SisterError },
    Partial { result: Value, warnings: Vec<String> },
}
```

### 6.3 Receipt Flow

```
RECEIPT CREATION FLOW:
──────────────────────

1. Sister performs action
2. Sister calls Identity.create_receipt(action)
3. Identity:
   a. Creates receipt record
   b. Signs with Identity key
   c. Adds to hash chain
   d. Returns ReceiptId
4. Sister stores ReceiptId with its data
5. Hydra can query Identity for all receipts

NEVER:
──────
• Sisters creating their own receipt chains
• Receipts without Identity signatures
• Unsigned action records
```

---

## 7. FILE FORMAT CONTRACT

### 7.1 Header Structure

ALL sister file formats MUST have this header:

```rust
/// Standard file header for ALL .a* formats
#[repr(C, packed)]
pub struct SisterFileHeader {
    /// Magic bytes: "AGNT" (0x41474E54)
    pub magic: [u8; 4],
    
    /// Sister type (1 byte)
    pub sister_type: u8,
    
    /// Format version (major.minor.patch as 3 bytes)
    pub version_major: u8,
    pub version_minor: u8,
    pub version_patch: u8,
    
    /// Flags (reserved for future use)
    pub flags: u32,
    
    /// Header checksum
    pub header_checksum: u32,
    
    /// Content checksum (BLAKE3)
    pub content_checksum: [u8; 32],
    
    /// Content offset (where actual data starts)
    pub content_offset: u64,
    
    /// Content length
    pub content_length: u64,
    
    /// Created timestamp (Unix timestamp)
    pub created_at: u64,
    
    /// Updated timestamp (Unix timestamp)
    pub updated_at: u64,
    
    /// Reserved for future use
    pub reserved: [u8; 32],
}

// Total header size: 96 bytes (fixed)

impl SisterFileHeader {
    pub const MAGIC: [u8; 4] = [0x41, 0x47, 0x4E, 0x54]; // "AGNT"
    pub const HEADER_SIZE: usize = 96;
    
    pub fn validate(&self) -> Result<(), SisterError> {
        if self.magic != Self::MAGIC {
            return Err(SisterError {
                code: ErrorCode::InvalidInput,
                message: "Invalid file magic".into(),
                ..Default::default()
            });
        }
        
        // Verify header checksum
        let computed = self.compute_header_checksum();
        if computed != self.header_checksum {
            return Err(SisterError {
                code: ErrorCode::ChecksumMismatch,
                message: "Header checksum mismatch".into(),
                ..Default::default()
            });
        }
        
        Ok(())
    }
}
```

### 7.2 Sister Type Bytes

```rust
impl SisterType {
    pub fn to_byte(&self) -> u8 {
        match self {
            Self::Memory => 0x01,
            Self::Vision => 0x02,
            Self::Codebase => 0x03,
            Self::Identity => 0x04,
            Self::Time => 0x05,
            Self::Contract => 0x06,
            Self::Comm => 0x07,
            Self::Planning => 0x08,
            Self::Cognition => 0x09,
            Self::Reality => 0x0A,
            Self::Attention => 0x0B,
            Self::Affect => 0x0C,
            Self::Motivation => 0x0D,
            Self::Learning => 0x0E,
            Self::Bond => 0x0F,
            Self::Meaning => 0x10,
            Self::Wonder => 0x11,
            Self::Imagination => 0x12,
            Self::Conscience => 0x13,
            Self::Meta => 0x14,
            Self::Duration => 0x15,
        }
    }
    
    pub fn from_byte(byte: u8) -> Option<Self> {
        match byte {
            0x01 => Some(Self::Memory),
            0x02 => Some(Self::Vision),
            0x03 => Some(Self::Codebase),
            0x04 => Some(Self::Identity),
            // ... etc
            _ => None,
        }
    }
}
```

### 7.3 Version Compatibility Rules

```
╔═══════════════════════════════════════════════════════════════╗
║                 20-YEAR COMPATIBILITY PROMISE                  ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  1. BACKWARD COMPATIBLE ALWAYS                                ║
║     • v2 reader MUST read v1 files                           ║
║     • v3 reader MUST read v1 and v2 files                    ║
║     • No exceptions. Ever.                                    ║
║                                                               ║
║  2. MIGRATION ON READ                                         ║
║     • If old version detected, auto-upgrade in memory        ║
║     • Only write upgraded version if file is modified        ║
║     • Keep original file as backup before upgrade            ║
║                                                               ║
║  3. VERSION SEMANTICS                                         ║
║     • Major: Breaking changes (require migration)            ║
║     • Minor: New features (backward compatible)              ║
║     • Patch: Bug fixes (fully compatible)                    ║
║                                                               ║
║  4. SCHEMA EVOLUTION RULES                                    ║
║     • ADD field: OK (provide default for old files)         ║
║     • REMOVE field: OK (ignore on read)                     ║
║     • CHANGE field type: NEVER                              ║
║     • RENAME field: NEVER                                   ║
║                                                               ║
║  5. DEPRECATION POLICY                                        ║
║     • Deprecated features: 2 major versions notice          ║
║     • Removed features: Never (backward compat)             ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

### 7.4 File Reader Contract

```rust
/// All sisters MUST implement this for file reading
pub trait FileFormatReader {
    /// Read file with version handling
    fn read_file(path: &Path) -> Result<Self, SisterError>
    where
        Self: Sized;
    
    /// Check if file is readable (without full parse)
    fn can_read(path: &Path) -> Result<FileInfo, SisterError>;
    
    /// Get file version without full parse
    fn file_version(path: &Path) -> Result<Version, SisterError>;
    
    /// Migrate old version to current (in memory)
    fn migrate(data: &[u8], from_version: Version) -> Result<Vec<u8>, SisterError>;
}

#[derive(Debug, Clone)]
pub struct FileInfo {
    pub sister_type: SisterType,
    pub version: Version,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub size_bytes: u64,
    pub needs_migration: bool,
}
```

---

## 8. QUERY CONTRACT

### 8.1 Standard Query Interface

```rust
/// All sisters MUST support standard query patterns
pub trait Queryable {
    /// Query with flexible parameters
    fn query(&self, query: Query) -> Result<QueryResult, SisterError>;
    
    /// Check if query is supported
    fn supports_query(&self, query_type: &str) -> bool;
    
    /// List supported query types
    fn query_types(&self) -> Vec<QueryTypeInfo>;
}

#[derive(Debug, Clone)]
pub struct Query {
    /// Query type (sister-specific but standard names)
    pub query_type: String,
    
    /// Query parameters
    pub params: HashMap<String, Value>,
    
    /// Maximum results
    pub limit: Option<usize>,
    
    /// Offset for pagination
    pub offset: Option<usize>,
    
    /// Context to query in (None = current)
    pub context_id: Option<ContextId>,
}

#[derive(Debug, Clone)]
pub struct QueryResult {
    /// Query that produced this result
    pub query: Query,
    
    /// Results (sister-specific structure)
    pub results: Vec<Value>,
    
    /// Total count (if known)
    pub total_count: Option<usize>,
    
    /// Whether there are more results
    pub has_more: bool,
    
    /// Query duration
    pub duration: Duration,
}
```

### 8.2 Standard Query Types

```
QUERY TYPES EVERY SISTER SHOULD SUPPORT:
────────────────────────────────────────

"list"        → List items with optional filters
"get"         → Get item by ID
"search"      → Full-text search
"recent"      → Get recent items
"related"     → Get related items
"temporal"    → Query by time range

Sister-specific query types are allowed but must be documented.
```

---

## 9. HYDRA INTEGRATION INTERFACE

### 9.1 The Bridge Trait

```rust
/// This is what Hydra calls to interact with any sister
pub trait HydraBridge: Sister + ContextManagement + Grounding + EventEmitter + Queryable {
    /// Get session context for Hydra (for token efficiency)
    fn session_context(&self) -> Result<SessionContext, SisterError>;
    
    /// Restore from session context
    fn restore_session(&mut self, context: SessionContext) -> Result<(), SisterError>;
    
    /// Get summary for display
    fn summary(&self) -> Result<SisterSummary, SisterError>;
    
    /// Execute sister-specific command (escape hatch)
    fn execute(&mut self, command: Command) -> Result<CommandResult, SisterError>;
}

/// Session context for efficient Hydra integration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionContext {
    pub sister_type: SisterType,
    pub context_id: ContextId,
    pub summary: String,
    pub recent_items: Vec<String>,
    pub metadata: HashMap<String, Value>,
}

/// Sister summary for UI display
#[derive(Debug, Clone)]
pub struct SisterSummary {
    pub sister_type: SisterType,
    pub status: Status,
    pub context_name: String,
    pub item_count: usize,
    pub last_activity: Option<DateTime<Utc>>,
    pub highlights: Vec<String>,
}
```

### 9.2 Integration Checklist

```
EVERY SISTER MUST PASS THIS CHECKLIST BEFORE RELEASE:
─────────────────────────────────────────────────────

□ TRAITS IMPLEMENTED
  □ Sister
  □ ContextManagement
  □ Grounding
  □ EventEmitter
  □ Queryable
  □ ReceiptIntegration
  □ FileFormatReader
  □ HydraBridge

□ ERROR HANDLING
  □ Uses standard SisterError
  □ Uses standard ErrorCode
  □ All errors are recoverable where possible
  □ Suggested actions provided

□ EVENTS
  □ Emits all required event types
  □ Events contain required fields
  □ Subscribe/recent_events work

□ FILE FORMAT
  □ Standard header implemented
  □ Version in header
  □ Backward compatibility tested
  □ Migration path documented

□ GROUNDING
  □ ground() returns consistent structure
  □ Confidence semantics correct
  □ Evidence retrievable

□ CONTEXT
  □ create/switch/list/delete work
  □ export/import work
  □ Default context exists

□ RECEIPTS
  □ Integrates with Identity
  □ All auditable actions receipted

□ TESTS
  □ All trait methods have tests
  □ Error cases tested
  □ Version migration tested
```

---

## 10. VERIFICATION: EXISTING SISTERS

### 10.1 Compliance Status

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    EXISTING SISTER COMPLIANCE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  SISTER          API    CONTEXT   GROUNDING  ERRORS   EVENTS   FILE        │
│  ──────────────────────────────────────────────────────────────────────    │
│  Memory          ✅     ✅        ✅         ⚠️       ⚠️       ✅          │
│  Vision          ✅     ⚠️        ✅         ⚠️       ⚠️       ✅          │
│  Codebase        ✅     ⚠️        ✅         ⚠️       ⚠️       ✅          │
│  Identity        ✅     ⚠️        ✅         ⚠️       ⚠️       ✅          │
│                                                                             │
│  ✅ = Fully compliant                                                       │
│  ⚠️ = Needs verification/update                                             │
│  ❌ = Missing                                                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 10.2 Required Updates

```
MEMORY (agentic-memory):
────────────────────────
□ Verify error types match standard
□ Add standard event emission
□ Context = Session (verify mapping)
□ Add HydraBridge implementation

VISION (agentic-vision):
────────────────────────
□ Verify error types match standard
□ Add standard event emission
□ Add explicit ContextManagement (Archive → Context)
□ Add HydraBridge implementation

CODEBASE (agentic-codebase):
────────────────────────────
□ Verify error types match standard
□ Add standard event emission
□ Add explicit ContextManagement (Workspace → Context)
□ Add HydraBridge implementation

IDENTITY (agentic-identity):
────────────────────────────
□ Verify error types match standard
□ Add standard event emission
□ Add explicit ContextManagement (Chain → Context)
□ Add HydraBridge implementation
□ Verify receipt schema matches Hydra needs
```

---

## 11. FUTURE SISTERS: TEMPLATE

### 11.1 New Sister Checklist

When creating a NEW sister, use this template:

```rust
// new_sister/src/lib.rs

use agentic_contracts::*;  // Shared contract crate

pub struct AgenticNewSister {
    config: SisterConfig,
    // ...
}

// MUST implement all these traits:

impl Sister for AgenticNewSister {
    const SISTER_TYPE: SisterType = SisterType::NewSister;
    const FILE_EXTENSION: &'static str = "anew";
    
    fn init(config: SisterConfig) -> Result<Self, SisterError> { ... }
    fn health(&self) -> HealthStatus { ... }
    fn version(&self) -> Version { ... }
    fn shutdown(&mut self) -> Result<(), SisterError> { ... }
    fn capabilities(&self) -> Vec<Capability> { ... }
}

impl ContextManagement for AgenticNewSister {
    fn create_context(&mut self, name: &str) -> Result<ContextId, SisterError> { ... }
    fn switch_context(&mut self, id: ContextId) -> Result<(), SisterError> { ... }
    fn current_context(&self) -> ContextId { ... }
    fn current_context_info(&self) -> Result<ContextInfo, SisterError> { ... }
    fn list_contexts(&self) -> Result<Vec<ContextSummary>, SisterError> { ... }
    fn delete_context(&mut self, id: ContextId) -> Result<(), SisterError> { ... }
    fn export_context(&self, id: ContextId) -> Result<ContextSnapshot, SisterError> { ... }
    fn import_context(&mut self, snapshot: ContextSnapshot) -> Result<ContextId, SisterError> { ... }
}

impl Grounding for AgenticNewSister {
    fn ground(&self, request: GroundingRequest) -> Result<GroundingResult, SisterError> { ... }
    fn get_evidence(&self, evidence_id: &str) -> Result<Evidence, SisterError> { ... }
    fn list_evidence(&self, filter: EvidenceFilter) -> Result<Vec<EvidenceSummary>, SisterError> { ... }
}

impl EventEmitter for AgenticNewSister {
    fn subscribe(&self, filter: EventFilter) -> EventReceiver { ... }
    fn recent_events(&self, limit: usize) -> Vec<SisterEvent> { ... }
}

impl Queryable for AgenticNewSister {
    fn query(&self, query: Query) -> Result<QueryResult, SisterError> { ... }
    fn supports_query(&self, query_type: &str) -> bool { ... }
    fn query_types(&self) -> Vec<QueryTypeInfo> { ... }
}

impl ReceiptIntegration for AgenticNewSister {
    fn create_receipt(&self, action: ActionRecord) -> Result<ReceiptId, SisterError> { ... }
    fn get_receipt(&self, id: ReceiptId) -> Result<Receipt, SisterError> { ... }
    fn list_receipts(&self, filter: ReceiptFilter) -> Result<Vec<Receipt>, SisterError> { ... }
}

impl FileFormatReader for AgenticNewSister {
    fn read_file(path: &Path) -> Result<Self, SisterError> { ... }
    fn can_read(path: &Path) -> Result<FileInfo, SisterError> { ... }
    fn file_version(path: &Path) -> Result<Version, SisterError> { ... }
    fn migrate(data: &[u8], from_version: Version) -> Result<Vec<u8>, SisterError> { ... }
}

impl HydraBridge for AgenticNewSister {
    fn session_context(&self) -> Result<SessionContext, SisterError> { ... }
    fn restore_session(&mut self, context: SessionContext) -> Result<(), SisterError> { ... }
    fn summary(&self) -> Result<SisterSummary, SisterError> { ... }
    fn execute(&mut self, command: Command) -> Result<CommandResult, SisterError> { ... }
}
```

---

## 12. SHARED CONTRACTS CRATE

### 12.1 Create agentic-contracts

```
CREATE A SHARED CRATE:
──────────────────────

agentic-contracts/
├── Cargo.toml
├── src/
│   ├── lib.rs
│   ├── sister.rs        # Sister trait
│   ├── context.rs       # ContextManagement trait
│   ├── grounding.rs     # Grounding trait
│   ├── events.rs        # EventEmitter trait
│   ├── query.rs         # Queryable trait
│   ├── receipts.rs      # ReceiptIntegration trait
│   ├── file_format.rs   # FileFormatReader trait
│   ├── hydra_bridge.rs  # HydraBridge trait
│   ├── errors.rs        # SisterError, ErrorCode
│   └── types.rs         # Shared types

ALL SISTERS DEPEND ON THIS CRATE.
HYDRA DEPENDS ON THIS CRATE.
SINGLE SOURCE OF TRUTH.
```

### 12.2 Cargo.toml

```toml
[package]
name = "agentic-contracts"
version = "0.1.0"
edition = "2021"
description = "Shared contracts for the AgenticOS ecosystem"
license = "MIT OR Apache-2.0"

[dependencies]
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
chrono = { version = "0.4", features = ["serde"] }
uuid = { version = "1.0", features = ["v4", "serde"] }
tokio = { version = "1.0", features = ["sync"] }
thiserror = "1.0"
blake3 = "1.0"
```

---

## 13. SUMMARY

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                     SISTER-HYDRA INTEGRATION CONTRACT                      ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  This document is MANDATORY for all sisters.                              ║
║                                                                           ║
║  REQUIRED IMPLEMENTATIONS:                                                ║
║  ─────────────────────────                                                ║
║  1. Sister trait            Core lifecycle                                ║
║  2. ContextManagement       Session/workspace/archive handling            ║
║  3. Grounding               V2 evidence verification                      ║
║  4. EventEmitter            Observability events                          ║
║  5. Queryable               Standard query interface                      ║
║  6. ReceiptIntegration      Via Identity                                  ║
║  7. FileFormatReader        Version-safe file handling                    ║
║  8. HydraBridge             Hydra-specific integration                    ║
║                                                                           ║
║  REQUIRED STANDARDS:                                                      ║
║  ───────────────────                                                      ║
║  • Standard error types (SisterError, ErrorCode)                          ║
║  • Standard file header (96 bytes, versioned)                             ║
║  • Standard event types (Ready, Operation*, Evidence*)                    ║
║  • 20-year backward compatibility                                         ║
║                                                                           ║
║  BEFORE RELEASE:                                                          ║
║  ───────────────                                                          ║
║  Every sister MUST pass the integration checklist.                        ║
║  No exceptions.                                                           ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

*Document Version: 1.0*
*Status: MANDATORY*
*Compliance Required: All sisters, past and future*
