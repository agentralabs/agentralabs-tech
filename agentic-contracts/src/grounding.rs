//! Grounding trait for evidence verification (V2 Pattern).
//!
//! Grounding is the mechanism by which claims are verified against evidence.
//! All sisters implement the same grounding interface, enabling Hydra to
//! verify claims uniformly across the ecosystem.

use crate::errors::SisterResult;
use crate::types::{Metadata, SisterType};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Request to ground a claim against evidence.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GroundingRequest {
    /// The claim being made (natural language).
    pub claim: String,

    /// Evidence ID to ground against.
    pub evidence_id: String,

    /// Optional: specific aspect to check.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub aspect: Option<String>,
}

impl GroundingRequest {
    /// Create a new grounding request.
    pub fn new(claim: impl Into<String>, evidence_id: impl Into<String>) -> Self {
        Self {
            claim: claim.into(),
            evidence_id: evidence_id.into(),
            aspect: None,
        }
    }

    /// Add an aspect to check.
    pub fn with_aspect(mut self, aspect: impl Into<String>) -> Self {
        self.aspect = Some(aspect.into());
        self
    }
}

/// Result of a grounding attempt.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GroundingResult {
    /// Is the claim grounded (supported by evidence)?
    pub grounded: bool,

    /// Confidence level (0.0 = no support, 1.0 = full support).
    pub confidence: f64,

    /// The evidence used.
    pub evidence: Evidence,

    /// Human-readable explanation of grounding decision.
    pub explanation: String,

    /// Unique ID for this grounding (for receipts).
    pub grounding_id: String,

    /// Timestamp of grounding.
    pub timestamp: DateTime<Utc>,
}

impl GroundingResult {
    /// Check if strongly grounded (confidence > 0.8).
    pub fn is_strongly_grounded(&self) -> bool {
        self.grounded && self.confidence > 0.8
    }

    /// Check if weakly grounded (confidence > 0.5).
    pub fn is_weakly_grounded(&self) -> bool {
        self.grounded && self.confidence > 0.5
    }
}

/// Type of evidence.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EvidenceType {
    // Memory evidence
    MemoryNode,
    MemoryRelation,
    MemorySession,

    // Vision evidence
    Screenshot,
    DomFingerprint,
    VisualDiff,
    VisualComparison,

    // Codebase evidence
    CodeNode,
    ImpactAnalysis,
    Prophecy,
    DependencyGraph,

    // Identity evidence
    Receipt,
    TrustGrant,
    CompetenceProof,
    Signature,

    // Time evidence
    TimelineEvent,
    DurationProof,
    DeadlineCheck,

    // Contract evidence
    Agreement,
    PolicyCheck,
    BoundaryVerification,

    // Generic
    Custom(String),
}

impl std::fmt::Display for EvidenceType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Custom(s) => write!(f, "{}", s),
            other => write!(f, "{:?}", other),
        }
    }
}

/// Content of evidence.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum EvidenceContent {
    /// Text content.
    Text { text: String },

    /// Binary content (base64 encoded in JSON).
    Binary {
        #[serde(with = "base64_serde")]
        data: Vec<u8>,
        mime_type: String,
    },

    /// Structured data.
    Structured { data: serde_json::Value },

    /// Reference to external content.
    Reference {
        uri: String,
        #[serde(with = "hex_serde")]
        hash: [u8; 32],
    },
}

/// Evidence structure (sister-agnostic).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Evidence {
    /// Unique evidence ID.
    pub id: String,

    /// What sister produced this.
    pub source_sister: SisterType,

    /// Type of evidence.
    pub evidence_type: EvidenceType,

    /// When captured.
    pub captured_at: DateTime<Utc>,

    /// Content hash (for verification).
    #[serde(with = "hex_serde")]
    pub content_hash: [u8; 32],

    /// The actual evidence content.
    pub content: EvidenceContent,

    /// Optional summary (for display).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub summary: Option<String>,

    /// Metadata.
    #[serde(default)]
    pub metadata: Metadata,
}

impl Evidence {
    /// Verify the content hash.
    pub fn verify_hash(&self) -> bool {
        let computed = match &self.content {
            EvidenceContent::Text { text } => blake3::hash(text.as_bytes()),
            EvidenceContent::Binary { data, .. } => blake3::hash(data),
            EvidenceContent::Structured { data } => {
                blake3::hash(serde_json::to_string(data).unwrap_or_default().as_bytes())
            }
            EvidenceContent::Reference { .. } => {
                // For references, the hash IS the content identifier
                return true;
            }
        };
        computed.as_bytes() == &self.content_hash
    }
}

/// Summary of evidence (for listing).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EvidenceSummary {
    pub id: String,
    pub evidence_type: EvidenceType,
    pub captured_at: DateTime<Utc>,
    pub summary: Option<String>,
    pub size_bytes: usize,
}

/// Filter for listing evidence.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct EvidenceFilter {
    /// Filter by evidence type.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub evidence_type: Option<EvidenceType>,

    /// Filter by capture time (after).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub after: Option<DateTime<Utc>>,

    /// Filter by capture time (before).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub before: Option<DateTime<Utc>>,

    /// Maximum results.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub limit: Option<usize>,

    /// Offset for pagination.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub offset: Option<usize>,
}

impl EvidenceFilter {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_type(mut self, evidence_type: EvidenceType) -> Self {
        self.evidence_type = Some(evidence_type);
        self
    }

    pub fn after(mut self, time: DateTime<Utc>) -> Self {
        self.after = Some(time);
        self
    }

    pub fn before(mut self, time: DateTime<Utc>) -> Self {
        self.before = Some(time);
        self
    }

    pub fn limit(mut self, limit: usize) -> Self {
        self.limit = Some(limit);
        self
    }

    pub fn offset(mut self, offset: usize) -> Self {
        self.offset = Some(offset);
        self
    }
}

/// Grounding capability - ALL sisters MUST implement.
///
/// This trait enables Hydra to verify claims against evidence from any sister.
/// The grounding pattern is central to the V2 multi-context architecture.
pub trait Grounding {
    /// Ground a claim against evidence.
    ///
    /// Returns a `GroundingResult` indicating whether the claim is supported
    /// by the specified evidence, along with confidence and explanation.
    fn ground(&self, request: GroundingRequest) -> SisterResult<GroundingResult>;

    /// Get evidence by ID.
    fn get_evidence(&self, evidence_id: &str) -> SisterResult<Evidence>;

    /// List available evidence.
    fn list_evidence(&self, filter: EvidenceFilter) -> SisterResult<Vec<EvidenceSummary>>;

    /// Check if evidence exists.
    fn evidence_exists(&self, evidence_id: &str) -> bool {
        self.get_evidence(evidence_id).is_ok()
    }

    /// Create evidence from content (sister-specific).
    /// Default implementation returns NotImplemented.
    fn create_evidence(
        &mut self,
        _evidence_type: EvidenceType,
        _content: EvidenceContent,
        _metadata: Metadata,
    ) -> SisterResult<Evidence> {
        Err(crate::errors::SisterError::new(
            crate::errors::ErrorCode::NotImplemented,
            "create_evidence not implemented for this sister",
        ))
    }
}

// Base64 serialization helper
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

// Hex serialization helper
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
            .map_err(|_| serde::de::Error::custom("invalid hash length"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_grounding_request() {
        let req = GroundingRequest::new("The meeting was on Monday", "ev_123")
            .with_aspect("date");

        assert_eq!(req.claim, "The meeting was on Monday");
        assert_eq!(req.evidence_id, "ev_123");
        assert_eq!(req.aspect, Some("date".to_string()));
    }

    #[test]
    fn test_evidence_filter() {
        let filter = EvidenceFilter::new()
            .with_type(EvidenceType::Screenshot)
            .limit(10)
            .offset(5);

        assert_eq!(filter.evidence_type, Some(EvidenceType::Screenshot));
        assert_eq!(filter.limit, Some(10));
        assert_eq!(filter.offset, Some(5));
    }
}
