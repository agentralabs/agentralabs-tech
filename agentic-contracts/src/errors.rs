//! Standard error types for all sisters.
//!
//! All sisters MUST use these error types for consistency.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use thiserror::Error;

/// Standard error type for ALL sisters.
#[derive(Debug, Clone, Error, Serialize, Deserialize)]
#[error("[{code}] {message}")]
pub struct SisterError {
    /// Error code (machine-readable).
    pub code: ErrorCode,

    /// Severity level.
    pub severity: Severity,

    /// Human-readable message.
    pub message: String,

    /// Additional context (for debugging).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub context: Option<HashMap<String, serde_json::Value>>,

    /// Is this recoverable?
    pub recoverable: bool,

    /// Suggested action.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub suggested_action: Option<SuggestedAction>,
}

impl SisterError {
    /// Create a new error.
    pub fn new(code: ErrorCode, message: impl Into<String>) -> Self {
        let severity = code.default_severity();
        let recoverable = code.is_typically_recoverable();

        Self {
            code,
            severity,
            message: message.into(),
            context: None,
            recoverable,
            suggested_action: None,
        }
    }

    /// Add context to the error.
    pub fn with_context(mut self, key: impl Into<String>, value: impl Serialize) -> Self {
        let context = self.context.get_or_insert_with(HashMap::new);
        if let Ok(v) = serde_json::to_value(value) {
            context.insert(key.into(), v);
        }
        self
    }

    /// Set recoverable flag.
    pub fn recoverable(mut self, recoverable: bool) -> Self {
        self.recoverable = recoverable;
        self
    }

    /// Set suggested action.
    pub fn with_suggestion(mut self, action: SuggestedAction) -> Self {
        self.suggested_action = Some(action);
        self
    }

    /// Set severity.
    pub fn with_severity(mut self, severity: Severity) -> Self {
        self.severity = severity;
        self
    }

    // Common error constructors

    /// Not found error.
    pub fn not_found(resource: impl Into<String>) -> Self {
        Self::new(ErrorCode::NotFound, format!("{} not found", resource.into()))
            .with_suggestion(SuggestedAction::Alternative {
                description: "Check the ID or list available items".into(),
            })
    }

    /// Invalid input error.
    pub fn invalid_input(message: impl Into<String>) -> Self {
        Self::new(ErrorCode::InvalidInput, message)
    }

    /// Permission denied error.
    pub fn permission_denied(message: impl Into<String>) -> Self {
        Self::new(ErrorCode::PermissionDenied, message).recoverable(false)
    }

    /// Internal error (bug).
    pub fn internal(message: impl Into<String>) -> Self {
        Self::new(ErrorCode::Internal, message)
            .with_severity(Severity::Fatal)
            .recoverable(false)
            .with_suggestion(SuggestedAction::ReportBug)
    }

    /// Storage error.
    pub fn storage(message: impl Into<String>) -> Self {
        Self::new(ErrorCode::StorageError, message).with_suggestion(SuggestedAction::Retry {
            after_ms: 1000,
        })
    }

    /// Context not found error.
    pub fn context_not_found(context_id: impl Into<String>) -> Self {
        Self::new(
            ErrorCode::ContextNotFound,
            format!("Context {} not found", context_id.into()),
        )
        .with_suggestion(SuggestedAction::Alternative {
            description: "List available contexts or create a new one".into(),
        })
    }

    /// Evidence not found error.
    pub fn evidence_not_found(evidence_id: impl Into<String>) -> Self {
        Self::new(
            ErrorCode::EvidenceNotFound,
            format!("Evidence {} not found", evidence_id.into()),
        )
        .recoverable(false)
    }
}

impl Default for SisterError {
    fn default() -> Self {
        Self::new(ErrorCode::Internal, "Unknown error")
    }
}

/// Standard error codes across ALL sisters.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum ErrorCode {
    // ═══════════════════════════════════════════════════════
    // COMMON ERRORS (All sisters use these)
    // ═══════════════════════════════════════════════════════
    /// Resource not found.
    NotFound,

    /// Invalid input provided.
    InvalidInput,

    /// Operation not permitted.
    PermissionDenied,

    /// Storage error (read/write failed).
    StorageError,

    /// Network error.
    NetworkError,

    /// Operation timed out.
    Timeout,

    /// Resource limits exceeded.
    ResourceExhausted,

    /// Internal error (bug).
    Internal,

    /// Not implemented yet.
    NotImplemented,

    /// Context/session not found.
    ContextNotFound,

    /// Evidence not found.
    EvidenceNotFound,

    /// Grounding failed.
    GroundingFailed,

    /// Version mismatch.
    VersionMismatch,

    /// Checksum mismatch (corruption).
    ChecksumMismatch,

    /// Already exists.
    AlreadyExists,

    /// Invalid state for operation.
    InvalidState,

    // ═══════════════════════════════════════════════════════
    // SISTER-SPECIFIC ERROR PREFIXES
    // ═══════════════════════════════════════════════════════
    /// Memory-specific error.
    MemoryError,

    /// Vision-specific error.
    VisionError,

    /// Codebase-specific error.
    CodebaseError,

    /// Identity-specific error.
    IdentityError,

    /// Time-specific error.
    TimeError,

    /// Contract-specific error.
    ContractError,
}

impl ErrorCode {
    /// Get default severity for this error code.
    pub fn default_severity(&self) -> Severity {
        match self {
            Self::Internal | Self::ChecksumMismatch => Severity::Fatal,
            Self::PermissionDenied | Self::VersionMismatch => Severity::Error,
            Self::NotFound | Self::InvalidInput | Self::AlreadyExists => Severity::Error,
            Self::Timeout | Self::NetworkError | Self::StorageError => Severity::Error,
            Self::ResourceExhausted => Severity::Warning,
            _ => Severity::Error,
        }
    }

    /// Check if this error is typically recoverable.
    pub fn is_typically_recoverable(&self) -> bool {
        match self {
            Self::Internal | Self::ChecksumMismatch | Self::VersionMismatch => false,
            Self::NotFound | Self::EvidenceNotFound => true, // Can try different ID
            Self::Timeout | Self::NetworkError | Self::StorageError => true, // Can retry
            Self::ResourceExhausted => true, // Can wait
            Self::InvalidInput | Self::InvalidState => true, // Can fix input
            Self::AlreadyExists => true, // Can use existing
            _ => true,
        }
    }
}

impl std::fmt::Display for ErrorCode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            Self::NotFound => "NOT_FOUND",
            Self::InvalidInput => "INVALID_INPUT",
            Self::PermissionDenied => "PERMISSION_DENIED",
            Self::StorageError => "STORAGE_ERROR",
            Self::NetworkError => "NETWORK_ERROR",
            Self::Timeout => "TIMEOUT",
            Self::ResourceExhausted => "RESOURCE_EXHAUSTED",
            Self::Internal => "INTERNAL",
            Self::NotImplemented => "NOT_IMPLEMENTED",
            Self::ContextNotFound => "CONTEXT_NOT_FOUND",
            Self::EvidenceNotFound => "EVIDENCE_NOT_FOUND",
            Self::GroundingFailed => "GROUNDING_FAILED",
            Self::VersionMismatch => "VERSION_MISMATCH",
            Self::ChecksumMismatch => "CHECKSUM_MISMATCH",
            Self::AlreadyExists => "ALREADY_EXISTS",
            Self::InvalidState => "INVALID_STATE",
            Self::MemoryError => "MEMORY_ERROR",
            Self::VisionError => "VISION_ERROR",
            Self::CodebaseError => "CODEBASE_ERROR",
            Self::IdentityError => "IDENTITY_ERROR",
            Self::TimeError => "TIME_ERROR",
            Self::ContractError => "CONTRACT_ERROR",
        };
        write!(f, "{}", s)
    }
}

/// Severity levels.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Severity {
    /// Informational, not really an error.
    Info,

    /// Warning, operation succeeded but with issues.
    Warning,

    /// Error, operation failed but recoverable.
    Error,

    /// Fatal, sister is in bad state.
    Fatal,
}

impl std::fmt::Display for Severity {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Info => write!(f, "info"),
            Self::Warning => write!(f, "warning"),
            Self::Error => write!(f, "error"),
            Self::Fatal => write!(f, "fatal"),
        }
    }
}

/// Suggested actions for error recovery.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum SuggestedAction {
    /// Retry the operation.
    Retry {
        /// Milliseconds to wait before retry.
        after_ms: u64,
    },

    /// Use a different approach.
    Alternative {
        /// Description of the alternative.
        description: String,
    },

    /// User intervention needed.
    UserAction {
        /// Description of what the user should do.
        description: String,
    },

    /// Restart the sister.
    Restart,

    /// Check configuration.
    CheckConfig {
        /// Configuration key to check.
        key: String,
    },

    /// Contact support / report bug.
    ReportBug,
}

// Implement From for common error types

impl From<std::io::Error> for SisterError {
    fn from(e: std::io::Error) -> Self {
        SisterError::new(ErrorCode::StorageError, format!("I/O error: {}", e))
            .with_context("io_error_kind", format!("{:?}", e.kind()))
            .with_suggestion(SuggestedAction::Retry { after_ms: 1000 })
    }
}

impl From<serde_json::Error> for SisterError {
    fn from(e: serde_json::Error) -> Self {
        SisterError::new(ErrorCode::InvalidInput, format!("JSON error: {}", e))
    }
}

/// Result type alias for sister operations.
pub type SisterResult<T> = Result<T, SisterError>;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_error_creation() {
        let err = SisterError::not_found("node_123");
        assert_eq!(err.code, ErrorCode::NotFound);
        assert!(err.recoverable);
        assert!(err.message.contains("node_123"));
    }

    #[test]
    fn test_error_with_context() {
        let err = SisterError::invalid_input("bad param")
            .with_context("field", "name")
            .with_context("provided", "");

        assert!(err.context.is_some());
        let ctx = err.context.unwrap();
        assert_eq!(ctx.get("field").unwrap(), "name");
    }

    #[test]
    fn test_error_serialization() {
        let err = SisterError::not_found("test");
        let json = serde_json::to_string(&err).unwrap();
        assert!(json.contains("NOT_FOUND"));

        let recovered: SisterError = serde_json::from_str(&json).unwrap();
        assert_eq!(recovered.code, ErrorCode::NotFound);
    }
}
