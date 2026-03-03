//! AgenticCognition — The Mirror
//!
//! Longitudinal user modeling — living models of human consciousness for AI agents.
//! Sister #9 of 25 in the Agentra ecosystem.
//!
//! ## Modules
//!
//! - `types`      — Core domain types (ids, beliefs, soul, consciousness, etc.)
//! - `engine`     — Write/query engines and the CognitionStore
//! - `inventions` — Novel algorithms (soul reflection, preference oracle, simulation)
//! - `bridges`    — Sister bridge traits and NoOp defaults
//! - `contracts`  — agentic-sdk v0.2.0 trait implementations (CognitionSister)
//! - `format`     — .acog binary file format

pub mod types;
pub mod engine;
pub mod inventions;
pub mod bridges;
pub mod contracts;
pub mod format;
pub mod storage;
pub mod audit;
pub mod validation;

// Re-export commonly used types
pub use types::{
    ModelId, BeliefId, PatternId, DriftId, BlindspotId, ProjectionId,
    BiasId, TriggerId, PredictionId, SimulationId, CollapseId,
    EntanglementId, FingerprintId, ThreadId, ReflectionId, FossilId,
    StratumId, Timestamp,
    LivingUserModel, ModelVitals, ModelLifecycleStage, ConsentStatus, PrivacySettings,
    Belief, BeliefDomain, BeliefState, BeliefGraph, BeliefConnection, ConnectionType,
    KeystoneBelief, BeliefContradiction, BeliefCrystallization, BeliefEntanglement,
    ModelSoul, ConsciousnessState, SelfConceptTopology,
    DecisionFingerprint, ShadowMap, BiasField, DriftTimeline,
    CognitionError, CognitionResult,
};

pub use engine::{WriteEngine, QueryEngine, CognitionStore};
pub use contracts::CognitionSister;
