//! Core Sister trait that all sisters must implement.

use crate::errors::SisterResult;
use crate::types::{Capability, HealthStatus, SisterType, Version};
use std::path::PathBuf;
use std::collections::HashMap;
use serde::{Deserialize, Serialize};

/// Configuration for initializing a sister.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SisterConfig {
    /// Path to the sister's data file/directory.
    pub data_path: PathBuf,

    /// Whether to create if not exists.
    pub create_if_missing: bool,

    /// Read-only mode.
    pub read_only: bool,

    /// Memory budget in megabytes (optional).
    pub memory_budget_mb: Option<usize>,

    /// Custom options (sister-specific).
    #[serde(default)]
    pub options: HashMap<String, serde_json::Value>,
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

impl SisterConfig {
    /// Create a new config with data path.
    pub fn new(data_path: impl Into<PathBuf>) -> Self {
        Self {
            data_path: data_path.into(),
            ..Default::default()
        }
    }

    /// Set read-only mode.
    pub fn read_only(mut self, read_only: bool) -> Self {
        self.read_only = read_only;
        self
    }

    /// Set create if missing.
    pub fn create_if_missing(mut self, create: bool) -> Self {
        self.create_if_missing = create;
        self
    }

    /// Set memory budget.
    pub fn memory_budget(mut self, mb: usize) -> Self {
        self.memory_budget_mb = Some(mb);
        self
    }

    /// Add a custom option.
    pub fn option(mut self, key: impl Into<String>, value: impl Serialize) -> Self {
        if let Ok(v) = serde_json::to_value(value) {
            self.options.insert(key.into(), v);
        }
        self
    }

    /// Get a custom option.
    pub fn get_option<T: for<'de> Deserialize<'de>>(&self, key: &str) -> Option<T> {
        self.options.get(key).and_then(|v| serde_json::from_value(v.clone()).ok())
    }
}

/// The core trait that ALL sisters must implement.
///
/// This is the foundation of the sister ecosystem. Every sister—Memory, Vision,
/// Codebase, Identity, and all future sisters—must implement this trait.
///
/// # Example
///
/// ```rust,ignore
/// use agentic_contracts::prelude::*;
///
/// pub struct AgenticMemory {
///     config: SisterConfig,
///     // ...
/// }
///
/// impl Sister for AgenticMemory {
///     const SISTER_TYPE: SisterType = SisterType::Memory;
///     const FILE_EXTENSION: &'static str = "amem";
///
///     fn init(config: SisterConfig) -> SisterResult<Self> {
///         // Initialize the sister
///         Ok(Self { config })
///     }
///
///     fn health(&self) -> HealthStatus {
///         HealthStatus::default()
///     }
///
///     fn version(&self) -> Version {
///         Version::new(0, 3, 2)
///     }
///
///     fn shutdown(&mut self) -> SisterResult<()> {
///         // Cleanup
///         Ok(())
///     }
///
///     fn capabilities(&self) -> Vec<Capability> {
///         vec![
///             Capability::new("memory_add", "Add memories to the graph"),
///             Capability::new("memory_query", "Query the memory graph"),
///         ]
///     }
/// }
/// ```
pub trait Sister: Send + Sync {
    /// The type of this sister.
    const SISTER_TYPE: SisterType;

    /// File extension for this sister's format (without dot).
    const FILE_EXTENSION: &'static str;

    /// Initialize the sister with configuration.
    fn init(config: SisterConfig) -> SisterResult<Self>
    where
        Self: Sized;

    /// Check health status.
    fn health(&self) -> HealthStatus;

    /// Get current version.
    fn version(&self) -> Version;

    /// Shutdown gracefully.
    fn shutdown(&mut self) -> SisterResult<()>;

    /// Get capabilities this sister provides.
    fn capabilities(&self) -> Vec<Capability>;

    // ═══════════════════════════════════════════════════════
    // DEFAULT IMPLEMENTATIONS
    // ═══════════════════════════════════════════════════════

    /// Get the sister type.
    fn sister_type(&self) -> SisterType {
        Self::SISTER_TYPE
    }

    /// Get the file extension.
    fn file_extension(&self) -> &'static str {
        Self::FILE_EXTENSION
    }

    /// Check if the sister is healthy.
    fn is_healthy(&self) -> bool {
        self.health().healthy
    }

    /// Get a human-readable name.
    fn name(&self) -> String {
        format!("Agentic{:?}", Self::SISTER_TYPE)
    }

    /// Get MCP tool prefix.
    fn mcp_prefix(&self) -> &'static str {
        Self::SISTER_TYPE.mcp_prefix()
    }
}

/// Information about a sister (for discovery).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SisterInfo {
    pub sister_type: SisterType,
    pub version: Version,
    pub file_extension: String,
    pub capabilities: Vec<Capability>,
    pub mcp_prefix: String,
}

impl SisterInfo {
    /// Create from a sister instance.
    pub fn from_sister<S: Sister>(sister: &S) -> Self {
        Self {
            sister_type: S::SISTER_TYPE,
            version: sister.version(),
            file_extension: S::FILE_EXTENSION.to_string(),
            capabilities: sister.capabilities(),
            mcp_prefix: S::SISTER_TYPE.mcp_prefix().to_string(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_config_builder() {
        let config = SisterConfig::new("/data/memory")
            .read_only(true)
            .memory_budget(512)
            .option("custom_key", "custom_value");

        assert_eq!(config.data_path, PathBuf::from("/data/memory"));
        assert!(config.read_only);
        assert_eq!(config.memory_budget_mb, Some(512));
        assert_eq!(
            config.get_option::<String>("custom_key"),
            Some("custom_value".to_string())
        );
    }
}
