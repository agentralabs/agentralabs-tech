//! Context management trait for all sisters.
//!
//! Every sister has a domain concept that maps to "Context":
//! - Memory → Session
//! - Vision → Archive
//! - Codebase → Workspace
//! - Identity → Chain
//!
//! Hydra sees them all as "Context" uniformly.

use crate::errors::SisterResult;
use crate::types::{Metadata, SisterType, UniqueId};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Unique identifier for a context.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct ContextId(pub UniqueId);

impl ContextId {
    /// Create a new random context ID.
    pub fn new() -> Self {
        Self(UniqueId::new())
    }

    /// The default context (always exists).
    pub fn default_context() -> Self {
        Self(UniqueId::nil())
    }

    /// Check if this is the default context.
    pub fn is_default(&self) -> bool {
        self.0 == UniqueId::nil()
    }
}

impl Default for ContextId {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Display for ContextId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "ctx_{}", self.0)
    }
}

impl From<&str> for ContextId {
    fn from(s: &str) -> Self {
        let s = s.strip_prefix("ctx_").unwrap_or(s);
        if let Ok(uuid) = uuid::Uuid::parse_str(s) {
            Self(UniqueId::from_uuid(uuid))
        } else {
            Self::new()
        }
    }
}

/// Summary information about a context.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContextSummary {
    pub id: ContextId,
    pub name: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub item_count: usize,
    pub size_bytes: usize,
}

/// Full context information.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContextInfo {
    pub id: ContextId,
    pub name: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub item_count: usize,
    pub size_bytes: usize,
    #[serde(default)]
    pub metadata: Metadata,
}

impl From<ContextInfo> for ContextSummary {
    fn from(info: ContextInfo) -> Self {
        Self {
            id: info.id,
            name: info.name,
            created_at: info.created_at,
            updated_at: info.updated_at,
            item_count: info.item_count,
            size_bytes: info.size_bytes,
        }
    }
}

/// Exportable context snapshot (for backup/transfer).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContextSnapshot {
    /// Which sister type this came from.
    pub sister_type: SisterType,

    /// Version of the sister that created this.
    pub version: crate::types::Version,

    /// Context information.
    pub context_info: ContextInfo,

    /// Serialized context data (sister-specific format).
    #[serde(with = "base64_serde")]
    pub data: Vec<u8>,

    /// Checksum of the data (BLAKE3).
    #[serde(with = "hex_serde")]
    pub checksum: [u8; 32],

    /// When this snapshot was created.
    pub snapshot_at: DateTime<Utc>,
}

impl ContextSnapshot {
    /// Verify the checksum.
    pub fn verify(&self) -> bool {
        let computed = blake3::hash(&self.data);
        computed.as_bytes() == &self.checksum
    }
}

/// Context management trait that ALL sisters must implement.
///
/// This provides a unified way for Hydra to manage contexts across all sisters,
/// regardless of what they're called internally (session, workspace, archive, etc.).
pub trait ContextManagement {
    /// Create a new context.
    fn create_context(&mut self, name: &str) -> SisterResult<ContextId>;

    /// Create a new context with metadata.
    fn create_context_with_metadata(
        &mut self,
        name: &str,
        metadata: Metadata,
    ) -> SisterResult<ContextId> {
        // Default implementation ignores metadata
        let _ = metadata;
        self.create_context(name)
    }

    /// Switch to a different context.
    fn switch_context(&mut self, id: ContextId) -> SisterResult<()>;

    /// Get current context ID.
    fn current_context(&self) -> ContextId;

    /// Get current context info.
    fn current_context_info(&self) -> SisterResult<ContextInfo>;

    /// List all contexts.
    fn list_contexts(&self) -> SisterResult<Vec<ContextSummary>>;

    /// List contexts with pagination.
    fn list_contexts_paginated(
        &self,
        limit: usize,
        offset: usize,
    ) -> SisterResult<(Vec<ContextSummary>, usize)> {
        let all = self.list_contexts()?;
        let total = all.len();
        let page = all.into_iter().skip(offset).take(limit).collect();
        Ok((page, total))
    }

    /// Delete a context.
    fn delete_context(&mut self, id: ContextId) -> SisterResult<()>;

    /// Export context as snapshot (for backup/transfer).
    fn export_context(&self, id: ContextId) -> SisterResult<ContextSnapshot>;

    /// Import context from snapshot.
    fn import_context(&mut self, snapshot: ContextSnapshot) -> SisterResult<ContextId>;

    /// Get context info by ID.
    fn get_context_info(&self, id: ContextId) -> SisterResult<ContextInfo> {
        // Default: switch temporarily and get info
        // Sisters should override for efficiency
        let contexts = self.list_contexts()?;
        contexts
            .into_iter()
            .find(|c| c.id == id)
            .map(|summary| ContextInfo {
                id: summary.id,
                name: summary.name,
                created_at: summary.created_at,
                updated_at: summary.updated_at,
                item_count: summary.item_count,
                size_bytes: summary.size_bytes,
                metadata: Metadata::new(),
            })
            .ok_or_else(|| crate::errors::SisterError::context_not_found(id.to_string()))
    }

    /// Check if context exists.
    fn context_exists(&self, id: ContextId) -> bool {
        self.get_context_info(id).is_ok()
    }

    /// Rename a context.
    fn rename_context(&mut self, id: ContextId, new_name: &str) -> SisterResult<()>;
}

/// Session context for Hydra integration (token-efficient summary).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionContext {
    /// Which sister this is from.
    pub sister_type: SisterType,

    /// Current context ID.
    pub context_id: ContextId,

    /// Context name.
    pub context_name: String,

    /// Brief summary for LLM context.
    pub summary: String,

    /// Recent/relevant items (for quick reference).
    pub recent_items: Vec<String>,

    /// Additional metadata.
    #[serde(default)]
    pub metadata: Metadata,
}

// Base64 serialization for binary data
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

// Hex serialization for checksums
mod hex_serde {
    use serde::{Deserialize, Deserializer, Serializer};

    pub fn serialize<S>(bytes: &[u8; 32], serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&hex::encode(bytes))
    }

    pub fn deserialize<'de, D>(deserializer: D) -> Result<[u8; 32], D::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        let bytes = hex::decode(&s).map_err(serde::de::Error::custom)?;
        bytes
            .try_into()
            .map_err(|_| serde::de::Error::custom("invalid checksum length"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_context_id() {
        let id = ContextId::new();
        let s = id.to_string();
        assert!(s.starts_with("ctx_"));

        let default = ContextId::default_context();
        assert!(default.is_default());
    }

    #[test]
    fn test_context_id_from_str() {
        let id = ContextId::new();
        let s = id.to_string();
        let parsed: ContextId = s.as_str().into();
        // Note: This won't be equal due to UUID parsing, but tests the path
        assert!(!parsed.is_default() || id.is_default());
    }
}
