//! # Agentic Contracts
//!
//! Shared contracts for the AgenticOS ecosystem.
//!
//! This crate defines the traits, types, and standards that ALL sisters must implement.
//! It serves as the single source of truth for:
//!
//! - **Sister trait**: Core lifecycle management
//! - **ContextManagement trait**: Session/workspace/archive handling
//! - **Grounding trait**: V2 evidence verification
//! - **EventEmitter trait**: Observability events
//! - **Queryable trait**: Standard query interface
//! - **FileFormat**: 20-year compatible file headers
//! - **Errors**: Standard error types and codes
//!
//! ## Usage
//!
//! All sisters depend on this crate:
//!
//! ```toml
//! [dependencies]
//! agentic-contracts = "0.1"
//! ```
//!
//! Then implement the required traits:
//!
//! ```rust,ignore
//! use agentic_contracts::prelude::*;
//!
//! pub struct MyNewSister {
//!     // ...
//! }
//!
//! impl Sister for MyNewSister {
//!     const SISTER_TYPE: SisterType = SisterType::Memory;
//!     const FILE_EXTENSION: &'static str = "amem";
//!     // ...
//! }
//! ```
//!
//! ## The Promise
//!
//! - ANY sister can be consumed by Hydra uniformly
//! - ANY sister can work with ANY other sister
//! - ANY file format will be readable in 20 years

pub mod sister;
pub mod context;
pub mod grounding;
pub mod events;
pub mod query;
pub mod errors;
pub mod file_format;
pub mod types;
pub mod receipts;

// Re-export everything in prelude for convenience
pub mod prelude {
    pub use crate::sister::*;
    pub use crate::context::*;
    pub use crate::grounding::*;
    pub use crate::events::*;
    pub use crate::query::*;
    pub use crate::errors::*;
    pub use crate::file_format::*;
    pub use crate::types::*;
    pub use crate::receipts::*;
}

// Also re-export at crate root
pub use prelude::*;
