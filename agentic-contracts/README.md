# agentic-contracts

**Shared contracts for the AgenticOS ecosystem.**

This crate defines the traits, types, and standards that ALL sisters must implement. It serves as the single source of truth for the ecosystem.

## The Promise

```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ANY sister can be consumed by Hydra uniformly.              ║
║   ANY sister can work with ANY other sister.                  ║
║   ANY file format will be readable in 20 years.               ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

## Installation

```toml
[dependencies]
agentic-contracts = "0.1"
```

## Core Traits

### Sister Trait
The foundation that all sisters implement:

```rust
use agentic_contracts::prelude::*;

pub struct MyNewSister { /* ... */ }

impl Sister for MyNewSister {
    const SISTER_TYPE: SisterType = SisterType::Memory;
    const FILE_EXTENSION: &'static str = "amem";

    fn init(config: SisterConfig) -> SisterResult<Self> { /* ... */ }
    fn health(&self) -> HealthStatus { /* ... */ }
    fn version(&self) -> Version { /* ... */ }
    fn shutdown(&mut self) -> SisterResult<()> { /* ... */ }
    fn capabilities(&self) -> Vec<Capability> { /* ... */ }
}
```

### ContextManagement Trait
Unified context handling (session/workspace/archive):

```rust
impl ContextManagement for MyNewSister {
    fn create_context(&mut self, name: &str) -> SisterResult<ContextId> { /* ... */ }
    fn switch_context(&mut self, id: ContextId) -> SisterResult<()> { /* ... */ }
    fn current_context(&self) -> ContextId { /* ... */ }
    fn list_contexts(&self) -> SisterResult<Vec<ContextSummary>> { /* ... */ }
    // ... etc
}
```

### Grounding Trait
V2 evidence verification:

```rust
impl Grounding for MyNewSister {
    fn ground(&self, request: GroundingRequest) -> SisterResult<GroundingResult> { /* ... */ }
    fn get_evidence(&self, evidence_id: &str) -> SisterResult<Evidence> { /* ... */ }
    fn list_evidence(&self, filter: EvidenceFilter) -> SisterResult<Vec<EvidenceSummary>> { /* ... */ }
}
```

### EventEmitter Trait
Observability events:

```rust
impl EventEmitter for MyNewSister {
    fn subscribe(&self, filter: EventFilter) -> EventReceiver { /* ... */ }
    fn recent_events(&self, limit: usize) -> Vec<SisterEvent> { /* ... */ }
    fn emit(&self, event: SisterEvent) { /* ... */ }
}
```

### Queryable Trait
Standard query interface:

```rust
impl Queryable for MyNewSister {
    fn query(&self, query: Query) -> SisterResult<QueryResult> { /* ... */ }
    fn supports_query(&self, query_type: &str) -> bool { /* ... */ }
    fn query_types(&self) -> Vec<QueryTypeInfo> { /* ... */ }
}
```

## File Format

All sister files use a standard 96-byte header:

```rust
use agentic_contracts::file_format::*;

// Create a new file header
let header = SisterFileHeader::new(SisterType::Memory, Version::new(0, 3, 2));

// Write to file
header.write_to(&mut file)?;

// Read from file
let header = SisterFileHeader::read_from(&mut file)?;
header.validate()?;
```

## Error Handling

Standard errors across all sisters:

```rust
use agentic_contracts::errors::*;

// Create errors
let err = SisterError::not_found("node_123");
let err = SisterError::invalid_input("name cannot be empty");
let err = SisterError::storage("Failed to write file");

// With context
let err = SisterError::invalid_input("bad param")
    .with_context("field", "name")
    .with_suggestion(SuggestedAction::Retry { after_ms: 1000 });
```

## Sisters Covered

| Sister | Type | Extension | Status |
|--------|------|-----------|--------|
| Memory | `SisterType::Memory` | `.amem` | ✅ Shipped |
| Vision | `SisterType::Vision` | `.avis` | ✅ Shipped |
| Codebase | `SisterType::Codebase` | `.acb` | ✅ Shipped |
| Identity | `SisterType::Identity` | `.aid` | ✅ Shipped |
| Time | `SisterType::Time` | `.atime` | ⏳ Planned |
| Contract | `SisterType::Contract` | `.acon` | ⏳ Planned |
| ... | ... | ... | ... |

## Related Documents

- `SISTER-HYDRA-INTEGRATION-CONTRACT.md` - Native Rust integration contract
- `MCP-TOOL-STANDARDS.md` - MCP protocol contract

## License

MIT OR Apache-2.0
