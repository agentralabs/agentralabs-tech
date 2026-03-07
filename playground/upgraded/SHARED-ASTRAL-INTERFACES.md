# SHARED ASTRAL SISTER INTERFACES

> **Copy this entire section into each sister's CLAUDE-CODE-INSTRUCTIONS file**
> **These traits define how sisters communicate - implement trait + NoOp only**

---

## BRIDGE TRAIT DEFINITIONS

```rust
//! Shared bridge interfaces for Astral sisters
//! Location: Copy into each sister's src/bridges/traits.rs

use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// ============================================================================
// FORGE BRIDGE (Called by: Hydra, Aegis, Evolve)
// ============================================================================

#[async_trait]
pub trait ForgeBridge: Send + Sync {
    /// Create a complete project blueprint from intent
    async fn create_blueprint(&self, intent: &IntentSpec) -> Result<Blueprint, BridgeError>;
    
    /// Get existing blueprint by ID
    async fn get_blueprint(&self, id: &str) -> Result<Option<Blueprint>, BridgeError>;
    
    /// Validate a blueprint is buildable
    async fn validate_blueprint(&self, blueprint: &Blueprint) -> Result<ValidationResult, BridgeError>;
    
    /// Update blueprint with new constraints
    async fn update_blueprint(&self, id: &str, updates: &BlueprintUpdate) -> Result<Blueprint, BridgeError>;
    
    /// Get file skeleton from blueprint
    async fn get_skeleton(&self, blueprint_id: &str, file_path: &str) -> Result<FileSkeleton, BridgeError>;
    
    /// Resolve dependencies for blueprint
    async fn resolve_dependencies(&self, blueprint_id: &str) -> Result<DependencyGraph, BridgeError>;
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IntentSpec {
    pub description: String,
    pub domain: String,
    pub entities: Vec<EntitySpec>,
    pub operations: Vec<OperationSpec>,
    pub constraints: Vec<String>,
    pub preferences: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Blueprint {
    pub id: String,
    pub created_at: i64,
    pub intent: IntentSpec,
    pub files: Vec<FileBlueprint>,
    pub dependencies: Vec<Dependency>,
    pub test_cases: Vec<TestCase>,
    pub metadata: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileBlueprint {
    pub path: String,
    pub file_type: FileType,
    pub imports: Vec<String>,
    pub types: Vec<TypeDefinition>,
    pub functions: Vec<FunctionSignature>,
    pub skeleton: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FileType {
    Source,
    Test,
    Config,
    Migration,
    Documentation,
}

// ============================================================================
// AEGIS BRIDGE (Called by: Hydra, Forge, Codebase GhostWriter)
// ============================================================================

#[async_trait]
pub trait AegisBridge: Send + Sync {
    /// Validate code chunk during streaming generation
    async fn validate_streaming(&self, context: &ValidationContext, chunk: &str) -> Result<StreamingValidation, BridgeError>;
    
    /// Shadow execute code before output
    async fn shadow_execute(&self, code: &str, language: &str) -> Result<ExecutionResult, BridgeError>;
    
    /// Check input for prompt injection or manipulation
    async fn validate_input(&self, input: &str) -> Result<InputValidation, BridgeError>;
    
    /// Validate output before showing to user
    async fn validate_output(&self, output: &str, context: &OutputContext) -> Result<OutputValidation, BridgeError>;
    
    /// Get validation status for ongoing generation
    async fn get_validation_status(&self, session_id: &str) -> Result<ValidationStatus, BridgeError>;
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ValidationContext {
    pub session_id: String,
    pub language: String,
    pub file_path: String,
    pub blueprint_id: Option<String>,
    pub accumulated_code: String,
    pub expected_types: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreamingValidation {
    pub valid: bool,
    pub errors: Vec<ValidationError>,
    pub warnings: Vec<ValidationWarning>,
    pub suggestions: Vec<String>,
    pub should_stop: bool,
    pub correction_hint: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExecutionResult {
    pub success: bool,
    pub stdout: String,
    pub stderr: String,
    pub exit_code: i32,
    pub duration_ms: u64,
}

// ============================================================================
// EVOLVE BRIDGE (Called by: Hydra, Forge, Codebase)
// ============================================================================

#[async_trait]
pub trait EvolveBridge: Send + Sync {
    /// Find matching patterns for intent
    async fn find_patterns(&self, intent: &IntentSpec) -> Result<Vec<Pattern>, BridgeError>;
    
    /// Get crystallized skill by ID
    async fn get_skill(&self, skill_id: &str) -> Result<Option<CrystallizedSkill>, BridgeError>;
    
    /// Crystallize new pattern from successful execution
    async fn crystallize(&self, execution: &SuccessfulExecution) -> Result<CrystallizedSkill, BridgeError>;
    
    /// Get function body from pattern library
    async fn get_function_body(&self, signature: &FunctionSignature, context: &PatternContext) -> Result<Option<String>, BridgeError>;
    
    /// Update pattern confidence based on execution result
    async fn update_confidence(&self, skill_id: &str, success: bool) -> Result<(), BridgeError>;
    
    /// Get pattern coverage for blueprint
    async fn get_coverage(&self, blueprint: &Blueprint) -> Result<PatternCoverage, BridgeError>;
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Pattern {
    pub id: String,
    pub name: String,
    pub description: String,
    pub domain: String,
    pub confidence: f64,
    pub usage_count: u64,
    pub template: String,
    pub variables: Vec<PatternVariable>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrystallizedSkill {
    pub id: String,
    pub pattern_id: String,
    pub created_at: i64,
    pub code: String,
    pub language: String,
    pub verified_count: u64,
    pub last_verified: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternCoverage {
    pub total_functions: usize,
    pub covered_by_patterns: usize,
    pub coverage_percent: f64,
    pub uncovered: Vec<String>,
}

// ============================================================================
// VERITAS BRIDGE (Called by: Hydra, Intent Compiler, all sisters)
// ============================================================================

#[async_trait]
pub trait VeritasBridge: Send + Sync {
    /// Compile natural language to formal intent spec
    async fn compile_intent(&self, natural_language: &str) -> Result<IntentCompilation, BridgeError>;
    
    /// Check uncertainty level of a claim
    async fn check_uncertainty(&self, claim: &str, context: &str) -> Result<UncertaintyAssessment, BridgeError>;
    
    /// Verify factual claim
    async fn verify_claim(&self, claim: &str) -> Result<ClaimVerification, BridgeError>;
    
    /// Get confidence score for generated content
    async fn score_confidence(&self, content: &str, content_type: &str) -> Result<ConfidenceScore, BridgeError>;
    
    /// Detect if clarification is needed
    async fn needs_clarification(&self, intent: &str) -> Result<ClarificationNeed, BridgeError>;
    
    /// Perform causal reasoning
    async fn reason_causally(&self, premise: &str, question: &str) -> Result<CausalReasoning, BridgeError>;
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IntentCompilation {
    pub spec: IntentSpec,
    pub confidence: f64,
    pub ambiguities: Vec<Ambiguity>,
    pub clarification_question: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Ambiguity {
    pub aspect: String,
    pub options: Vec<String>,
    pub default: Option<String>,
    pub importance: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UncertaintyAssessment {
    pub uncertainty_level: f64,  // 0.0 = certain, 1.0 = completely uncertain
    pub factors: Vec<UncertaintyFactor>,
    pub should_flag: bool,
    pub suggested_caveat: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClarificationNeed {
    pub needs_clarification: bool,
    pub question: Option<String>,
    pub impact: f64,  // How much clarification would help
}

// ============================================================================
// SHARED TYPES
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EntitySpec {
    pub name: String,
    pub fields: Vec<FieldSpec>,
    pub relationships: Vec<RelationshipSpec>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FieldSpec {
    pub name: String,
    pub field_type: String,
    pub constraints: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OperationSpec {
    pub name: String,
    pub input_type: String,
    pub output_type: String,
    pub errors: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TypeDefinition {
    pub name: String,
    pub definition: String,
    pub derives: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FunctionSignature {
    pub name: String,
    pub params: Vec<(String, String)>,
    pub return_type: String,
    pub is_async: bool,
    pub visibility: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Dependency {
    pub name: String,
    pub version: String,
    pub features: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestCase {
    pub name: String,
    pub description: String,
    pub test_type: TestType,
    pub skeleton: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TestType {
    Unit,
    Integration,
    Property,
    Stress,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ValidationError {
    pub line: usize,
    pub column: usize,
    pub message: String,
    pub severity: Severity,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Severity {
    Error,
    Warning,
    Info,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BridgeError {
    pub code: String,
    pub message: String,
    pub recoverable: bool,
}

// ============================================================================
// NOOP IMPLEMENTATIONS (Every sister implements these for standalone mode)
// ============================================================================

pub struct NoOpForgeBridge;

#[async_trait]
impl ForgeBridge for NoOpForgeBridge {
    async fn create_blueprint(&self, _: &IntentSpec) -> Result<Blueprint, BridgeError> {
        Err(BridgeError {
            code: "BRIDGE_UNAVAILABLE".into(),
            message: "Forge bridge not connected".into(),
            recoverable: false,
        })
    }
    
    async fn get_blueprint(&self, _: &str) -> Result<Option<Blueprint>, BridgeError> {
        Err(BridgeError {
            code: "BRIDGE_UNAVAILABLE".into(),
            message: "Forge bridge not connected".into(),
            recoverable: false,
        })
    }
    
    async fn validate_blueprint(&self, _: &Blueprint) -> Result<ValidationResult, BridgeError> {
        Err(BridgeError {
            code: "BRIDGE_UNAVAILABLE".into(),
            message: "Forge bridge not connected".into(),
            recoverable: false,
        })
    }
    
    async fn update_blueprint(&self, _: &str, _: &BlueprintUpdate) -> Result<Blueprint, BridgeError> {
        Err(BridgeError {
            code: "BRIDGE_UNAVAILABLE".into(),
            message: "Forge bridge not connected".into(),
            recoverable: false,
        })
    }
    
    async fn get_skeleton(&self, _: &str, _: &str) -> Result<FileSkeleton, BridgeError> {
        Err(BridgeError {
            code: "BRIDGE_UNAVAILABLE".into(),
            message: "Forge bridge not connected".into(),
            recoverable: false,
        })
    }
    
    async fn resolve_dependencies(&self, _: &str) -> Result<DependencyGraph, BridgeError> {
        Err(BridgeError {
            code: "BRIDGE_UNAVAILABLE".into(),
            message: "Forge bridge not connected".into(),
            recoverable: false,
        })
    }
}

pub struct NoOpAegisBridge;

#[async_trait]
impl AegisBridge for NoOpAegisBridge {
    async fn validate_streaming(&self, _: &ValidationContext, _: &str) -> Result<StreamingValidation, BridgeError> {
        // In standalone mode, validation passes by default
        Ok(StreamingValidation {
            valid: true,
            errors: vec![],
            warnings: vec![],
            suggestions: vec![],
            should_stop: false,
            correction_hint: None,
        })
    }
    
    async fn shadow_execute(&self, _: &str, _: &str) -> Result<ExecutionResult, BridgeError> {
        Err(BridgeError {
            code: "BRIDGE_UNAVAILABLE".into(),
            message: "Aegis bridge not connected".into(),
            recoverable: false,
        })
    }
    
    async fn validate_input(&self, _: &str) -> Result<InputValidation, BridgeError> {
        Ok(InputValidation { safe: true, issues: vec![] })
    }
    
    async fn validate_output(&self, _: &str, _: &OutputContext) -> Result<OutputValidation, BridgeError> {
        Ok(OutputValidation { safe: true, issues: vec![] })
    }
    
    async fn get_validation_status(&self, _: &str) -> Result<ValidationStatus, BridgeError> {
        Err(BridgeError {
            code: "BRIDGE_UNAVAILABLE".into(),
            message: "Aegis bridge not connected".into(),
            recoverable: false,
        })
    }
}

pub struct NoOpEvolveBridge;

#[async_trait]
impl EvolveBridge for NoOpEvolveBridge {
    async fn find_patterns(&self, _: &IntentSpec) -> Result<Vec<Pattern>, BridgeError> {
        Ok(vec![])  // No patterns in standalone mode
    }
    
    async fn get_skill(&self, _: &str) -> Result<Option<CrystallizedSkill>, BridgeError> {
        Ok(None)
    }
    
    async fn crystallize(&self, _: &SuccessfulExecution) -> Result<CrystallizedSkill, BridgeError> {
        Err(BridgeError {
            code: "BRIDGE_UNAVAILABLE".into(),
            message: "Evolve bridge not connected".into(),
            recoverable: false,
        })
    }
    
    async fn get_function_body(&self, _: &FunctionSignature, _: &PatternContext) -> Result<Option<String>, BridgeError> {
        Ok(None)  // No cached bodies in standalone mode
    }
    
    async fn update_confidence(&self, _: &str, _: bool) -> Result<(), BridgeError> {
        Ok(())  // No-op in standalone mode
    }
    
    async fn get_coverage(&self, _: &Blueprint) -> Result<PatternCoverage, BridgeError> {
        Ok(PatternCoverage {
            total_functions: 0,
            covered_by_patterns: 0,
            coverage_percent: 0.0,
            uncovered: vec![],
        })
    }
}

pub struct NoOpVeritasBridge;

#[async_trait]
impl VeritasBridge for NoOpVeritasBridge {
    async fn compile_intent(&self, natural_language: &str) -> Result<IntentCompilation, BridgeError> {
        // Basic intent parsing in standalone mode
        Ok(IntentCompilation {
            spec: IntentSpec {
                description: natural_language.to_string(),
                domain: "unknown".into(),
                entities: vec![],
                operations: vec![],
                constraints: vec![],
                preferences: HashMap::new(),
            },
            confidence: 0.5,
            ambiguities: vec![],
            clarification_question: Some("Please provide more details".into()),
        })
    }
    
    async fn check_uncertainty(&self, _: &str, _: &str) -> Result<UncertaintyAssessment, BridgeError> {
        Ok(UncertaintyAssessment {
            uncertainty_level: 0.5,
            factors: vec![],
            should_flag: false,
            suggested_caveat: None,
        })
    }
    
    async fn verify_claim(&self, _: &str) -> Result<ClaimVerification, BridgeError> {
        Err(BridgeError {
            code: "BRIDGE_UNAVAILABLE".into(),
            message: "Veritas bridge not connected".into(),
            recoverable: false,
        })
    }
    
    async fn score_confidence(&self, _: &str, _: &str) -> Result<ConfidenceScore, BridgeError> {
        Ok(ConfidenceScore { score: 0.5, factors: vec![] })
    }
    
    async fn needs_clarification(&self, _: &str) -> Result<ClarificationNeed, BridgeError> {
        Ok(ClarificationNeed {
            needs_clarification: true,
            question: None,
            impact: 0.5,
        })
    }
    
    async fn reason_causally(&self, _: &str, _: &str) -> Result<CausalReasoning, BridgeError> {
        Err(BridgeError {
            code: "BRIDGE_UNAVAILABLE".into(),
            message: "Veritas bridge not connected".into(),
            recoverable: false,
        })
    }
}

// ============================================================================
// ADDITIONAL TYPES FOR COMPLETE COMPILATION
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ValidationResult {
    pub valid: bool,
    pub errors: Vec<String>,
    pub warnings: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlueprintUpdate {
    pub add_files: Vec<FileBlueprint>,
    pub remove_files: Vec<String>,
    pub update_dependencies: Vec<Dependency>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileSkeleton {
    pub path: String,
    pub content: String,
    pub placeholders: Vec<Placeholder>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Placeholder {
    pub name: String,
    pub placeholder_type: String,
    pub line_start: usize,
    pub line_end: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DependencyGraph {
    pub dependencies: Vec<ResolvedDependency>,
    pub conflicts: Vec<DependencyConflict>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResolvedDependency {
    pub name: String,
    pub version: String,
    pub features: Vec<String>,
    pub transitive: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DependencyConflict {
    pub package: String,
    pub versions: Vec<String>,
    pub resolution: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InputValidation {
    pub safe: bool,
    pub issues: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OutputContext {
    pub content_type: String,
    pub audience: String,
    pub sensitivity: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OutputValidation {
    pub safe: bool,
    pub issues: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ValidationStatus {
    pub session_id: String,
    pub chunks_validated: usize,
    pub errors_found: usize,
    pub current_state: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ValidationWarning {
    pub line: usize,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternVariable {
    pub name: String,
    pub var_type: String,
    pub default: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SuccessfulExecution {
    pub code: String,
    pub language: String,
    pub intent: IntentSpec,
    pub test_results: Vec<TestResult>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestResult {
    pub name: String,
    pub passed: bool,
    pub duration_ms: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternContext {
    pub blueprint: Option<Blueprint>,
    pub file_path: String,
    pub surrounding_code: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UncertaintyFactor {
    pub factor: String,
    pub contribution: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClaimVerification {
    pub verified: bool,
    pub confidence: f64,
    pub sources: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConfidenceScore {
    pub score: f64,
    pub factors: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CausalReasoning {
    pub conclusion: String,
    pub confidence: f64,
    pub chain: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RelationshipSpec {
    pub target: String,
    pub relationship_type: String,
    pub cardinality: String,
}
```

---

## FOUNDATION SISTER BRIDGES (From shipped sisters)

Each Astral sister also needs bridges to the 10 Foundation sisters. Use this pattern:

```rust
// src/bridges/foundation.rs

pub use agentic_sdk::{
    MemoryBridge,
    VisionBridge,
    CodebaseBridge,
    IdentityBridge,
    TimeBridge,
    ContractBridge,
    CommBridge,
    PlanningBridge,
    CognitionBridge,
    RealityBridge,
};

// Re-export NoOp implementations
pub use agentic_sdk::{
    NoOpMemoryBridge,
    NoOpVisionBridge,
    NoOpCodebaseBridge,
    NoOpIdentityBridge,
    NoOpTimeBridge,
    NoOpContractBridge,
    NoOpCommBridge,
    NoOpPlanningBridge,
    NoOpCognitionBridge,
    NoOpRealityBridge,
};
```
