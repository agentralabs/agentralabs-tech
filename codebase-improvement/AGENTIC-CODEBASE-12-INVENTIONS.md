# AgenticCodebase: The 12 Code Inventions

> **Status:** Add after core implementation, before publish
> **Scope:** Advanced code reasoning capabilities
> **Tagline:** "Understanding, not generation. Proof, not claims."

---

## OVERVIEW

These 12 inventions transform AgenticCodebase from a code indexer into a code reasoning engine. They should be implemented as V2 features after the core engine (parsing, graph building, basic queries) is stable.

```
INVENTION CATEGORIES:
═════════════════════

PREDICTION (1-3):    See what's coming before you change
GROUNDING (4-6):     Prove every claim about code
NAVIGATION (7-9):    Find code by meaning, not keywords
COMPARISON (10-12):  Reason across multiple codebases
```

---

# PREDICTION INVENTIONS

## INVENTION 1: IMPACT ANALYSIS

### The Problem
Developer changes a function. AI says "looks good." 47 downstream functions break. The AI had no idea because it only saw the file, not the graph.

### The Solution
Trace forward through the dependency graph to predict ALL affected code before the change is made.

### Data Structures

```rust
/// Result of impact analysis
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImpactAnalysis {
    /// The change being analyzed
    pub change: ProposedChange,
    
    /// Directly affected nodes (immediate callers/dependents)
    pub direct_impact: Vec<ImpactedNode>,
    
    /// Transitively affected nodes (callers of callers, etc.)
    pub transitive_impact: Vec<ImpactedNode>,
    
    /// Risk assessment
    pub risk_level: RiskLevel,
    
    /// Total blast radius
    pub blast_radius: BlastRadius,
    
    /// Suggested mitigations
    pub mitigations: Vec<Mitigation>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProposedChange {
    /// What's being changed
    pub target: CodeNodeId,
    
    /// Type of change
    pub change_type: ChangeType,
    
    /// Description
    pub description: String,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ChangeType {
    /// Signature change (params, return type)
    Signature,
    
    /// Behavior change (same signature, different logic)
    Behavior,
    
    /// Deletion
    Deletion,
    
    /// Rename
    Rename,
    
    /// Move to different module
    Move,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImpactedNode {
    /// The affected node
    pub node: CodeNodeId,
    
    /// Path from change to this node
    pub impact_path: Vec<CodeNodeId>,
    
    /// Distance from original change
    pub distance: u32,
    
    /// How it's affected
    pub impact_type: ImpactType,
    
    /// Confidence this will actually break
    pub break_probability: f64,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ImpactType {
    /// Will definitely break (type error, missing function)
    WillBreak,
    
    /// Might break (behavior change, edge cases)
    MightBreak,
    
    /// Needs review (semantic dependency)
    NeedsReview,
    
    /// Safe (only reads, doesn't depend on changed behavior)
    Safe,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlastRadius {
    /// Number of files affected
    pub files_affected: usize,
    
    /// Number of functions affected
    pub functions_affected: usize,
    
    /// Number of modules affected
    pub modules_affected: usize,
    
    /// Lines of code in blast radius
    pub loc_affected: usize,
    
    /// Test files affected
    pub tests_affected: usize,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum RiskLevel {
    /// Safe to change
    Low,
    
    /// Review recommended
    Medium,
    
    /// Careful review required
    High,
    
    /// Architectural implications
    Critical,
}
```

### MCP Tools

```
codebase_impact_analyze    - Analyze impact of a proposed change
codebase_impact_path       - Show path from change to affected node
codebase_impact_visualize  - Get visualization-ready impact data
```

### Example Flow

```
User: "I want to change the return type of authenticate() from bool to Result<User, Error>"

Agent:
  1. Calls codebase_impact_analyze
  2. Returns:
     - Direct impact: 12 functions call authenticate()
     - Transitive impact: 47 functions depend on those 12
     - Risk: HIGH
     - Blast radius: 8 files, 59 functions
     - Mitigation: "Add compatibility wrapper, deprecate old signature"
```

---

## INVENTION 2: CODE PROPHECY

### The Problem
Developer asks "should I refactor this?" AI guesses based on vibes. No data.

### The Solution
Simulate the future state of the codebase based on current trajectory and proposed changes.

### Data Structures

```rust
/// A prophecy about code evolution
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodeProphecy {
    /// What we're prophesying about
    pub subject: ProphecySubject,
    
    /// Time horizon
    pub horizon: ProphecyHorizon,
    
    /// Predicted outcomes
    pub predictions: Vec<Prediction>,
    
    /// Confidence in prophecy
    pub confidence: f64,
    
    /// Evidence supporting prophecy
    pub evidence: Vec<ProphecyEvidence>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ProphecySubject {
    /// Specific function/class
    Node(CodeNodeId),
    
    /// Entire module
    Module(String),
    
    /// Architectural pattern
    Pattern(String),
    
    /// Proposed change
    Change(ProposedChange),
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ProphecyHorizon {
    /// Next few changes
    Immediate,
    
    /// Next sprint/week
    ShortTerm,
    
    /// Next month
    MediumTerm,
    
    /// Next quarter
    LongTerm,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Prediction {
    /// What will happen
    pub outcome: String,
    
    /// Probability (0.0 - 1.0)
    pub probability: f64,
    
    /// Is this good or bad?
    pub sentiment: Sentiment,
    
    /// What triggers this outcome
    pub trigger: String,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum Sentiment {
    Positive,
    Neutral,
    Negative,
    Critical,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProphecyEvidence {
    /// Type of evidence
    pub evidence_type: EvidenceType,
    
    /// The evidence
    pub description: String,
    
    /// Weight in prediction
    pub weight: f64,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum EvidenceType {
    /// Historical pattern in this codebase
    Historical,
    
    /// Structural analysis
    Structural,
    
    /// Complexity metrics
    Complexity,
    
    /// Dependency analysis
    Dependency,
    
    /// Industry pattern
    IndustryPattern,
}
```

### MCP Tools

```
codebase_prophecy          - Generate prophecy for subject
codebase_prophecy_if       - "What if" scenario analysis
codebase_prophecy_compare  - Compare prophecies of different approaches
```

### Example Flow

```
User: "Should I refactor the payment module?"

Agent (via codebase_prophecy):
  "PROPHECY: Payment Module
   
   If you DON'T refactor (next 3 months):
   - 73% chance of bug in edge case handling
   - 45% chance someone duplicates logic (3 near-duplicates already)
   - Estimated +40% time for new payment method integration
   
   If you DO refactor (cost: ~3 days):
   - 89% reduction in integration time for new methods
   - Consolidates 3 near-duplicate implementations
   - Unlocks event-driven payment tracking
   
   Evidence:
   - Cyclomatic complexity: 34 (high)
   - 3 functions with 80%+ code similarity
   - 12 TODO comments mentioning 'cleanup'
   
   RECOMMENDATION: Refactor. ROI positive within 2 sprints."
```

---

## INVENTION 3: REGRESSION ORACLE

### The Problem
"Did my change break anything?" requires running the entire test suite. Slow feedback loop.

### The Solution
Predict which tests are likely to fail based on the change, before running them.

### Data Structures

```rust
/// Prediction of test outcomes
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RegressionOracle {
    /// The change being evaluated
    pub change: ProposedChange,
    
    /// Tests predicted to fail
    pub likely_failures: Vec<TestPrediction>,
    
    /// Tests that should pass but are worth running
    pub recommended_tests: Vec<TestPrediction>,
    
    /// Tests that are definitely unaffected
    pub safe_to_skip: Vec<TestId>,
    
    /// Minimum test set for confidence
    pub minimum_test_set: Vec<TestId>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestPrediction {
    /// The test
    pub test: TestId,
    
    /// Probability of failure
    pub failure_probability: f64,
    
    /// Why we think it might fail
    pub reason: String,
    
    /// Path from change to test
    pub dependency_path: Vec<CodeNodeId>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestId {
    pub file: String,
    pub function: String,
    pub line: u32,
}
```

### MCP Tools

```
codebase_regression_predict  - Predict test outcomes for change
codebase_regression_minimal  - Get minimum test set for confidence
codebase_regression_history  - Historical accuracy of predictions
```

---

# GROUNDING INVENTIONS

## INVENTION 4: CITATION ENGINE

### The Problem
AI says "the authenticate function validates tokens." Is that true? Where's the proof?

### The Solution
Every claim about code MUST be backed by a citation to the actual graph node.

### Data Structures

```rust
/// A grounded claim about code
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GroundedClaim {
    /// The claim being made
    pub claim: String,
    
    /// Citations proving the claim
    pub citations: Vec<Citation>,
    
    /// Confidence based on citation strength
    pub confidence: f64,
    
    /// Is this claim fully grounded?
    pub fully_grounded: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Citation {
    /// The node being cited
    pub node: CodeNodeId,
    
    /// Specific location
    pub location: CodeLocation,
    
    /// The actual code being cited
    pub code_snippet: String,
    
    /// How this supports the claim
    pub relevance: String,
    
    /// Strength of evidence
    pub strength: CitationStrength,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodeLocation {
    pub file: String,
    pub start_line: u32,
    pub end_line: u32,
    pub start_col: u32,
    pub end_col: u32,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum CitationStrength {
    /// Directly proves the claim
    Direct,
    
    /// Strongly supports the claim
    Strong,
    
    /// Partially supports
    Partial,
    
    /// Weak/circumstantial
    Weak,
}

/// A claim that couldn't be grounded
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UngroundedClaim {
    /// The claim attempted
    pub claim: String,
    
    /// Why it couldn't be grounded
    pub reason: UngroundedReason,
    
    /// What would be needed to ground it
    pub requirements: Vec<String>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum UngroundedReason {
    /// No matching code found
    NotFound,
    
    /// Code found but doesn't support claim
    Contradicted,
    
    /// Ambiguous (multiple interpretations)
    Ambiguous,
    
    /// Outside indexed scope
    OutOfScope,
}
```

### MCP Tools

```
codebase_ground_claim    - Attempt to ground a claim with citations
codebase_verify_claim    - Verify if a claim is true
codebase_cite            - Get citation for specific code
codebase_contradict      - Find evidence that contradicts a claim
```

### Example Flow

```
User: "Does the payment module validate credit card numbers?"

Agent:
  1. Calls codebase_ground_claim("payment module validates credit card numbers")
  2. Returns:
     GROUNDED: Yes
     
     Citation 1 (DIRECT):
       File: payment/validators.py
       Line: 45-52
       Code: def validate_card_number(number: str) -> bool:
                 return luhn_check(number) and len(number) in [15, 16]
       
     Citation 2 (STRONG):
       File: payment/processor.py
       Line: 78
       Code: if not validate_card_number(card.number):
                 raise InvalidCardError()
     
     Confidence: 94%
```

---

## INVENTION 5: HALLUCINATION DETECTOR

### The Problem
AI confidently describes code that doesn't exist or works differently than described.

### The Solution
Automatically detect when AI output contradicts the actual codebase.

### Data Structures

```rust
/// Result of hallucination check
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HallucinationCheck {
    /// The AI output being checked
    pub ai_output: String,
    
    /// Detected hallucinations
    pub hallucinations: Vec<Hallucination>,
    
    /// Verified claims
    pub verified_claims: Vec<GroundedClaim>,
    
    /// Overall hallucination score (0 = none, 1 = all)
    pub hallucination_score: f64,
    
    /// Is this output safe to use?
    pub safe_to_use: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Hallucination {
    /// The hallucinated claim
    pub claim: String,
    
    /// Type of hallucination
    pub hallucination_type: HallucinationType,
    
    /// What's actually true
    pub reality: String,
    
    /// Evidence for reality
    pub evidence: Vec<Citation>,
    
    /// Severity
    pub severity: HallucinationSeverity,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum HallucinationType {
    /// Function/class doesn't exist
    NonExistent,
    
    /// Exists but does something different
    WrongBehavior,
    
    /// Wrong signature (params, return type)
    WrongSignature,
    
    /// Wrong location (different file/module)
    WrongLocation,
    
    /// Outdated (was true, no longer)
    Outdated,
    
    /// Invented feature
    InventedFeature,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum HallucinationSeverity {
    /// Minor inaccuracy
    Minor,
    
    /// Would cause confusion
    Moderate,
    
    /// Would cause errors
    Severe,
    
    /// Would cause security/data issues
    Critical,
}
```

### MCP Tools

```
codebase_hallucination_check  - Check AI output for hallucinations
codebase_hallucination_fix    - Suggest corrections for hallucinations
```

---

## INVENTION 6: TRUTH MAINTENANCE

### The Problem
Codebase changes. AI's knowledge becomes stale. Claims that were true are now false.

### The Solution
Track which claims have been invalidated by recent changes.

### Data Structures

```rust
/// Record of a previously-true claim
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MaintainedTruth {
    /// The claim
    pub claim: GroundedClaim,
    
    /// When it was established
    pub established_at: DateTime<Utc>,
    
    /// Current status
    pub status: TruthStatus,
    
    /// If invalidated, what changed
    pub invalidation: Option<TruthInvalidation>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum TruthStatus {
    /// Still true
    Valid,
    
    /// Changed, needs review
    Stale,
    
    /// Definitely no longer true
    Invalidated,
    
    /// Code was deleted
    Deleted,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TruthInvalidation {
    /// When it was invalidated
    pub invalidated_at: DateTime<Utc>,
    
    /// What change invalidated it
    pub change: String,
    
    /// What's true now
    pub new_truth: Option<String>,
}
```

### MCP Tools

```
codebase_truth_check    - Check if a historical claim is still true
codebase_truth_refresh  - Refresh all maintained truths after changes
codebase_truth_diff     - What changed between two graph versions
```

---

# NAVIGATION INVENTIONS

## INVENTION 7: CONCEPT NAVIGATION

### The Problem
"Where is authentication handled?" User has to guess filenames and grep.

### The Solution
Navigate by CONCEPT, not by filename or keyword.

### Data Structures

```rust
/// A semantic concept in the codebase
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodeConcept {
    /// Concept name
    pub name: String,
    
    /// Description
    pub description: String,
    
    /// Nodes that implement this concept
    pub implementations: Vec<ConceptImplementation>,
    
    /// Related concepts
    pub related: Vec<String>,
    
    /// Confidence this concept exists
    pub confidence: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConceptImplementation {
    /// The implementing node
    pub node: CodeNodeId,
    
    /// How strongly it implements the concept
    pub strength: f64,
    
    /// What aspect it implements
    pub aspect: String,
}

/// Query for navigating to a concept
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConceptQuery {
    /// Natural language description
    pub description: String,
    
    /// Optional constraints
    pub constraints: Vec<ConceptConstraint>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ConceptConstraint {
    /// Must be in specific module
    InModule(String),
    
    /// Must be specific type (function, class, etc.)
    OfType(NodeType),
    
    /// Must have specific pattern
    HasPattern(String),
    
    /// Must be called by
    CalledBy(CodeNodeId),
    
    /// Must call
    Calls(CodeNodeId),
}
```

### MCP Tools

```
codebase_concept_find      - Find code implementing a concept
codebase_concept_map       - Map all concepts in codebase
codebase_concept_explain   - Explain how a concept is implemented
```

### Example Flow

```
User: "Take me to where rate limiting happens"

Agent (via codebase_concept_find):
  "CONCEPT: Rate Limiting
   
   Primary implementation:
     middleware/rate_limiter.py:RateLimiter (confidence: 94%)
     - Token bucket algorithm
     - Redis-backed counter
   
   Secondary implementations:
     api/decorators.py:@rate_limit (confidence: 87%)
     - Decorator wrapping RateLimiter
     
     utils/throttle.py:Throttle (confidence: 72%)
     - Simpler, in-memory throttling
   
   Related concepts:
     - Authentication (rate limiting applied after auth)
     - Caching (shares Redis connection)"
```

---

## INVENTION 8: ARCHITECTURE INFERENCE

### The Problem
New developer asks "what's the architecture?" No one documented it.

### The Solution
Infer architecture from the code structure itself.

### Data Structures

```rust
/// Inferred architecture
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InferredArchitecture {
    /// Overall pattern detected
    pub pattern: ArchitecturePattern,
    
    /// Layers/tiers
    pub layers: Vec<ArchitectureLayer>,
    
    /// Key components
    pub components: Vec<ArchitectureComponent>,
    
    /// Data flows
    pub flows: Vec<DataFlow>,
    
    /// Confidence in inference
    pub confidence: f64,
    
    /// Anomalies (violations of pattern)
    pub anomalies: Vec<ArchitectureAnomaly>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ArchitecturePattern {
    Monolith,
    Microservices,
    Layered,
    Hexagonal,
    EventDriven,
    CQRS,
    Serverless,
    MVC,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ArchitectureLayer {
    pub name: String,
    pub purpose: String,
    pub modules: Vec<String>,
    pub depends_on: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ArchitectureComponent {
    pub name: String,
    pub role: ComponentRole,
    pub nodes: Vec<CodeNodeId>,
    pub external_deps: Vec<String>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ComponentRole {
    Entrypoint,
    Controller,
    Service,
    Repository,
    Model,
    Utility,
    Configuration,
    Test,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DataFlow {
    pub name: String,
    pub source: String,
    pub destination: String,
    pub via: Vec<String>,
    pub data_type: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ArchitectureAnomaly {
    pub description: String,
    pub location: CodeNodeId,
    pub expected: String,
    pub actual: String,
    pub severity: AnomalySeverity,
}
```

### MCP Tools

```
codebase_architecture_infer    - Infer architecture from code
codebase_architecture_diagram  - Generate architecture diagram data
codebase_architecture_validate - Check code against expected architecture
```

---

## INVENTION 9: SEMANTIC SEARCH

### The Problem
Grep finds text. But "find error handling" shouldn't just find the word "error".

### The Solution
Search by MEANING, not text.

### Data Structures

```rust
/// Semantic search query
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SemanticQuery {
    /// Natural language query
    pub query: String,
    
    /// Intent (what user is trying to do)
    pub intent: QueryIntent,
    
    /// Scope constraints
    pub scope: SearchScope,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum QueryIntent {
    /// Find implementation of something
    FindImplementation,
    
    /// Find usage of something
    FindUsage,
    
    /// Find similar code
    FindSimilar,
    
    /// Find related concepts
    FindRelated,
    
    /// Understand something
    Understand,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchScope {
    /// Limit to modules
    pub modules: Option<Vec<String>>,
    
    /// Limit to file patterns
    pub file_patterns: Option<Vec<String>>,
    
    /// Limit to node types
    pub node_types: Option<Vec<NodeType>>,
    
    /// Exclude patterns
    pub exclude: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SemanticSearchResult {
    /// Matching nodes
    pub results: Vec<SemanticMatch>,
    
    /// Query interpretation
    pub interpretation: String,
    
    /// Alternative queries suggested
    pub alternatives: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SemanticMatch {
    /// The matching node
    pub node: CodeNodeId,
    
    /// Relevance score
    pub relevance: f64,
    
    /// Why it matched
    pub match_reason: String,
    
    /// Code snippet
    pub snippet: String,
}
```

### MCP Tools

```
codebase_search_semantic  - Semantic search
codebase_search_similar   - Find similar code
codebase_search_explain   - Explain why results matched
```

---

# COMPARISON INVENTIONS

## INVENTION 10: MULTI-CODEBASE COMPARISON

### The Problem
"How does their auth differ from ours?" Requires manually reading two codebases.

### The Solution
Load multiple .acb graphs and reason across them.

### Data Structures

```rust
/// Comparison between codebases
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodebaseComparison {
    /// Codebases being compared
    pub codebases: Vec<CodebaseRef>,
    
    /// Structural differences
    pub structural_diff: StructuralDiff,
    
    /// Conceptual differences
    pub conceptual_diff: ConceptualDiff,
    
    /// Pattern differences
    pub pattern_diff: PatternDiff,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodebaseRef {
    pub name: String,
    pub path: String,
    pub version: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StructuralDiff {
    /// Modules only in A
    pub only_in_a: Vec<String>,
    
    /// Modules only in B
    pub only_in_b: Vec<String>,
    
    /// Modules in both with differences
    pub different: Vec<ModuleDiff>,
    
    /// Modules that are identical
    pub identical: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConceptualDiff {
    /// How the same concept is implemented differently
    pub concept: String,
    pub implementation_a: String,
    pub implementation_b: String,
    pub key_differences: Vec<String>,
    pub recommendation: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternDiff {
    /// Patterns in A not in B
    pub patterns_only_a: Vec<String>,
    
    /// Patterns in B not in A
    pub patterns_only_b: Vec<String>,
    
    /// Same pattern, different implementation
    pub pattern_variations: Vec<PatternVariation>,
}
```

### MCP Tools

```
codebase_compare           - Compare two codebases
codebase_compare_concept   - Compare how concept is implemented
codebase_compare_migrate   - Generate migration plan from A to B
```

---

## INVENTION 11: VERSION ARCHAEOLOGY

### The Problem
"Why was this code written this way?" History is in git, but not connected to semantics.

### The Solution
Connect git history to semantic graph. Navigate through time.

### Data Structures

```rust
/// Historical analysis of code
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodeArchaeology {
    /// The node being investigated
    pub node: CodeNodeId,
    
    /// Evolution timeline
    pub evolution: Vec<CodeEvolution>,
    
    /// Key decision points
    pub decisions: Vec<HistoricalDecision>,
    
    /// Authors involved
    pub contributors: Vec<Contributor>,
    
    /// Patterns in changes
    pub change_patterns: Vec<ChangePattern>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodeEvolution {
    /// Version/commit
    pub version: String,
    
    /// When
    pub timestamp: DateTime<Utc>,
    
    /// What changed
    pub change_type: HistoricalChangeType,
    
    /// Commit message / reason
    pub reason: Option<String>,
    
    /// Author
    pub author: String,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum HistoricalChangeType {
    Created,
    Modified,
    Refactored,
    BugFix,
    FeatureAdd,
    Optimization,
    Deleted,
    Moved,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HistoricalDecision {
    /// What was decided
    pub decision: String,
    
    /// When
    pub timestamp: DateTime<Utc>,
    
    /// Evidence (commit, comment, etc.)
    pub evidence: String,
    
    /// Is this decision still valid?
    pub still_valid: bool,
}
```

### MCP Tools

```
codebase_archaeology_node    - History of specific node
codebase_archaeology_why     - Why is this code this way?
codebase_archaeology_when    - When did this pattern emerge?
```

---

## INVENTION 12: PATTERN EXTRACTION

### The Problem
Codebase has patterns, but they're implicit. New code doesn't follow them.

### The Solution
Extract implicit patterns and make them explicit, enforceable.

### Data Structures

```rust
/// An extracted pattern
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExtractedPattern {
    /// Pattern name
    pub name: String,
    
    /// Description
    pub description: String,
    
    /// Where it's used
    pub instances: Vec<PatternInstance>,
    
    /// The pattern structure
    pub structure: PatternStructure,
    
    /// Confidence it's intentional
    pub confidence: f64,
    
    /// Violations (code that should follow but doesn't)
    pub violations: Vec<PatternViolation>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternInstance {
    /// Where
    pub location: CodeNodeId,
    
    /// How well it matches
    pub match_strength: f64,
    
    /// Any deviations
    pub deviations: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternStructure {
    /// Template description
    pub template: String,
    
    /// Required elements
    pub required: Vec<String>,
    
    /// Optional elements
    pub optional: Vec<String>,
    
    /// Anti-patterns (what NOT to do)
    pub anti_patterns: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternViolation {
    /// Where
    pub location: CodeNodeId,
    
    /// What's wrong
    pub violation: String,
    
    /// How to fix
    pub suggested_fix: String,
    
    /// Severity
    pub severity: ViolationSeverity,
}
```

### MCP Tools

```
codebase_pattern_extract   - Extract patterns from codebase
codebase_pattern_check     - Check code against patterns
codebase_pattern_suggest   - Suggest patterns for new code
codebase_pattern_enforce   - Generate linting rules from patterns
```

---

# IMPLEMENTATION NOTES

## Priority Order

```
HIGH PRIORITY (Core V2):
  1. Impact Analysis       - The killer feature
  4. Citation Engine       - Grounding is our differentiator
  5. Hallucination Detector- Trust builder

MEDIUM PRIORITY (V2.1):
  2. Code Prophecy         - Builds on impact analysis
  7. Concept Navigation    - Major UX improvement
  8. Architecture Inference- Documentation killer
  10. Multi-Codebase Compare- Enterprise feature

LOWER PRIORITY (V2.2+):
  3. Regression Oracle     - Needs test graph integration
  6. Truth Maintenance     - Needs persistence
  9. Semantic Search       - Needs embeddings
  11. Version Archaeology  - Needs git integration
  12. Pattern Extraction   - Advanced analysis
```

## Integration with Sisters

- **Memory**: Store WHY decisions were made (connects to HistoricalDecision)
- **Identity**: Track WHO made changes (connects to CodeArchaeology)
- **Time**: WHEN should this be refactored? Decay models for tech debt
- **Contract**: Enforce patterns as policies

---

# SUMMARY

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║  THE 12 CODE INVENTIONS                                                   ║
║                                                                           ║
║  PREDICTION:                                                              ║
║   1. Impact Analysis       - What breaks if I change this?                ║
║   2. Code Prophecy         - What will happen to this code?               ║
║   3. Regression Oracle     - Which tests will fail?                       ║
║                                                                           ║
║  GROUNDING:                                                               ║
║   4. Citation Engine       - Prove every claim about code                 ║
║   5. Hallucination Detector- Catch AI lies about code                     ║
║   6. Truth Maintenance     - Track when truths become false               ║
║                                                                           ║
║  NAVIGATION:                                                              ║
║   7. Concept Navigation    - Find code by meaning                         ║
║   8. Architecture Inference- Discover architecture from code              ║
║   9. Semantic Search       - Search by intent, not keywords               ║
║                                                                           ║
║  COMPARISON:                                                              ║
║  10. Multi-Codebase Compare- Reason across codebases                      ║
║  11. Version Archaeology   - Why is this code this way?                   ║
║  12. Pattern Extraction    - Make implicit patterns explicit              ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  "GitNexus shows you structure.                                           ║
║   AgenticCodebase shows you consequences."                                ║
║                                                                           ║
║  "They see what IS.                                                       ║
║   We see what WILL BE."                                                   ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```
