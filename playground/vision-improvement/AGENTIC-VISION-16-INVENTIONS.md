# AgenticVision: The 16 Perception Inventions

> **Status:** Add after core implementation, before publish
> **Scope:** Advanced visual reasoning capabilities
> **Tagline:** "Grounded perception. Proof, not claims. Sight beyond sight."

---

## OVERVIEW

These 16 inventions transform AgenticVision from a screenshot tool into a visual cognition engine. They should be implemented as V2 features after the core engine (capture, diff, similar, OCR) is stable.

```
INVENTION CATEGORIES:
═════════════════════

GROUNDING (1-4):     Prove every visual claim
TEMPORAL (5-8):      See through time
PREDICTION (9-12):   See what's coming
COGNITION (13-16):   Understand what you see
```

---

# GROUNDING INVENTIONS

## INVENTION 1: VISUAL GROUNDING

### The Problem
AI says "the submit button is green." Is it? Where's the proof? AI confidently describes UI that doesn't exist.

### The Solution
Every visual claim MUST be backed by a capture. Can't claim what you can't prove.

### Data Structures

```rust
/// A grounded visual claim
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GroundedVisualClaim {
    /// The claim being made
    pub claim: String,
    
    /// The capture proving it
    pub capture_id: CaptureId,
    
    /// Region of capture that proves it
    pub evidence_region: BoundingBox,
    
    /// Extracted evidence (OCR, color, element)
    pub evidence: VisualEvidence,
    
    /// Confidence in grounding
    pub confidence: f64,
    
    /// Is this fully grounded?
    pub fully_grounded: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualEvidence {
    /// Type of evidence
    pub evidence_type: VisualEvidenceType,
    
    /// The evidence value
    pub value: String,
    
    /// Screenshot crop as base64
    pub crop: Option<String>,
    
    /// Timestamp of capture
    pub captured_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum VisualEvidenceType {
    /// Text extracted via OCR
    Text,
    
    /// Color at location
    Color,
    
    /// Element detected
    Element,
    
    /// Layout/position
    Layout,
    
    /// State (visible, enabled, checked)
    State,
    
    /// Comparison result
    Comparison,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BoundingBox {
    pub x: u32,
    pub y: u32,
    pub width: u32,
    pub height: u32,
}

/// A claim that couldn't be grounded
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UngroundedVisualClaim {
    /// The attempted claim
    pub claim: String,
    
    /// Why it couldn't be grounded
    pub reason: UngroundedReason,
    
    /// What would be needed
    pub requirements: Vec<String>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum UngroundedReason {
    /// No capture exists
    NoCaptureExists,
    
    /// Capture exists but doesn't show claimed element
    ElementNotFound,
    
    /// Capture contradicts claim
    Contradicted,
    
    /// Capture is too old
    CaptureStale,
    
    /// Region is obscured/occluded
    Obscured,
}
```

### MCP Tools

```
vision_ground_claim    - Attempt to ground a visual claim
vision_verify_claim    - Verify if a visual claim is true
vision_cite            - Get citation for visual element
vision_contradict      - Find evidence that contradicts a claim
```

### Example Flow

```
User: "Is the checkout button visible?"

Agent:
  1. Calls vision_ground_claim("checkout button is visible")
  2. Finds recent capture of checkout page
  3. Locates button region
  4. Returns:
     GROUNDED: Yes
     
     Evidence:
       Capture: cap_7f3a2b (2 minutes ago)
       Region: (423, 891, 180, 48)
       Element: <button class="checkout-btn">
       State: visible=true, enabled=true
       Text: "Complete Purchase"
       
     Confidence: 97%
```

---

## INVENTION 2: VISUAL HALLUCINATION DETECTOR

### The Problem
AI describes a UI that doesn't exist, or describes it wrong. User trusts AI. Chaos ensues.

### The Solution
Automatically detect when AI visual descriptions contradict actual captures.

### Data Structures

```rust
/// Result of visual hallucination check
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualHallucinationCheck {
    /// The AI output being checked
    pub ai_description: String,
    
    /// Detected hallucinations
    pub hallucinations: Vec<VisualHallucination>,
    
    /// Verified claims
    pub verified_claims: Vec<GroundedVisualClaim>,
    
    /// Overall hallucination score (0 = none, 1 = all)
    pub hallucination_score: f64,
    
    /// Is this description safe to trust?
    pub trustworthy: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualHallucination {
    /// The hallucinated claim
    pub claim: String,
    
    /// Type of hallucination
    pub hallucination_type: VisualHallucinationType,
    
    /// What's actually true
    pub reality: String,
    
    /// Evidence for reality
    pub evidence: VisualEvidence,
    
    /// Severity
    pub severity: HallucinationSeverity,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum VisualHallucinationType {
    /// Element doesn't exist
    NonExistent,
    
    /// Element exists but looks different
    WrongAppearance,
    
    /// Element is in different location
    WrongLocation,
    
    /// Element has different text
    WrongText,
    
    /// Element has different state
    WrongState,
    
    /// Invented UI that was never there
    InventedUI,
    
    /// Describing old state as current
    StaleDescription,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum HallucinationSeverity {
    /// Minor (wrong color shade)
    Minor,
    
    /// Moderate (wrong text)
    Moderate,
    
    /// Severe (element doesn't exist)
    Severe,
    
    /// Critical (would cause user to take wrong action)
    Critical,
}
```

### MCP Tools

```
vision_hallucination_check  - Check AI description for hallucinations
vision_hallucination_fix    - Suggest corrections
```

---

## INVENTION 3: VISUAL TRUTH MAINTENANCE

### The Problem
UI changes. AI's knowledge becomes stale. "The button is blue" was true yesterday, not today.

### The Solution
Track which visual claims have been invalidated by UI changes.

### Data Structures

```rust
/// A maintained visual truth
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MaintainedVisualTruth {
    /// The claim
    pub claim: GroundedVisualClaim,
    
    /// When established
    pub established_at: DateTime<Utc>,
    
    /// Current status
    pub status: VisualTruthStatus,
    
    /// If invalidated, what changed
    pub invalidation: Option<VisualInvalidation>,
    
    /// How often to re-verify
    pub verification_interval: Option<chrono::Duration>,
    
    /// Last verified
    pub last_verified: DateTime<Utc>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum VisualTruthStatus {
    /// Still true (recently verified)
    Valid,
    
    /// Needs re-verification
    Stale,
    
    /// Definitely no longer true
    Invalidated,
    
    /// Page/element no longer exists
    Deleted,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualInvalidation {
    /// When it was invalidated
    pub invalidated_at: DateTime<Utc>,
    
    /// What changed
    pub change: VisualChange,
    
    /// New truth (if any)
    pub new_truth: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualChange {
    /// Type of change
    pub change_type: VisualChangeType,
    
    /// Before state
    pub before: String,
    
    /// After state
    pub after: String,
    
    /// Diff visualization
    pub diff_capture: Option<CaptureId>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum VisualChangeType {
    ColorChange,
    TextChange,
    PositionChange,
    SizeChange,
    StateChange,
    Removal,
    Addition,
    LayoutChange,
}
```

### MCP Tools

```
vision_truth_check    - Check if historical claim still true
vision_truth_refresh  - Re-verify all maintained truths
vision_truth_history  - Get history of a visual truth
```

---

## INVENTION 4: MULTI-CONTEXT VISION

### The Problem
"How does our checkout compare to theirs?" Requires manual side-by-side comparison.

### The Solution
Capture and compare across different contexts (sites, versions, devices, users).

### Data Structures

```rust
/// Multi-context visual comparison
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MultiContextComparison {
    /// Contexts being compared
    pub contexts: Vec<VisualContext>,
    
    /// Element-by-element comparison
    pub element_comparison: Vec<ElementComparison>,
    
    /// Layout comparison
    pub layout_comparison: LayoutComparison,
    
    /// Overall similarity score
    pub similarity_score: f64,
    
    /// Key differences
    pub key_differences: Vec<KeyDifference>,
    
    /// Recommendations
    pub recommendations: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualContext {
    /// Context identifier
    pub id: String,
    
    /// Context type
    pub context_type: ContextType,
    
    /// Capture for this context
    pub capture: CaptureId,
    
    /// Metadata
    pub metadata: ContextMetadata,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ContextType {
    /// Different website
    DifferentSite,
    
    /// Different version of same site
    DifferentVersion,
    
    /// Different device/viewport
    DifferentDevice,
    
    /// Different user/account
    DifferentUser,
    
    /// Different locale/language
    DifferentLocale,
    
    /// A/B test variant
    ABVariant,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ElementComparison {
    /// Element being compared
    pub element: String,
    
    /// Present in which contexts
    pub presence: Vec<(String, bool)>,
    
    /// Appearance in each context
    pub appearances: Vec<ElementAppearance>,
    
    /// Similarity across contexts
    pub similarity: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KeyDifference {
    /// What's different
    pub description: String,
    
    /// Which contexts differ
    pub contexts: Vec<String>,
    
    /// Impact assessment
    pub impact: DifferenceImpact,
    
    /// Visual evidence
    pub evidence: Vec<CaptureId>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum DifferenceImpact {
    /// Cosmetic only
    Cosmetic,
    
    /// UX impact
    UXImpact,
    
    /// Functional difference
    Functional,
    
    /// Critical (affects core flow)
    Critical,
}
```

### MCP Tools

```
vision_compare_contexts  - Compare captures across contexts
vision_compare_sites     - Compare two different websites
vision_compare_versions  - Compare two versions of same site
vision_compare_devices   - Compare same page on different devices
```

---

# TEMPORAL INVENTIONS

## INVENTION 5: TEMPORAL VISION

### The Problem
"What did the page look like yesterday?" If no capture exists, knowledge is lost forever.

### The Solution
Navigate through visual history. Reconstruct what might have been from partial evidence.

### Data Structures

```rust
/// A temporal visual query
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TemporalVisualQuery {
    /// What we're looking for
    pub subject: String,
    
    /// Target time
    pub target_time: DateTime<Utc>,
    
    /// Time tolerance
    pub tolerance: chrono::Duration,
    
    /// Context constraints
    pub constraints: Vec<TemporalConstraint>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TemporalConstraint {
    /// Must be from specific URL
    FromUrl(String),
    
    /// Must contain element
    ContainsElement(String),
    
    /// Must be before/after specific event
    RelativeToEvent { event: String, relation: TimeRelation },
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum TimeRelation {
    Before,
    After,
    During,
}

/// Result of temporal visual query
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TemporalVisualResult {
    /// Found captures
    pub captures: Vec<TemporalCapture>,
    
    /// Timeline of visual state
    pub timeline: VisualTimeline,
    
    /// Gaps in visual history
    pub gaps: Vec<TimeRange>,
    
    /// Reconstructed state (if no exact match)
    pub reconstruction: Option<VisualReconstruction>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TemporalCapture {
    pub capture: CaptureId,
    pub captured_at: DateTime<Utc>,
    pub relevance: f64,
    pub distance_from_target: chrono::Duration,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualTimeline {
    /// States over time
    pub states: Vec<VisualState>,
    
    /// Changes between states
    pub transitions: Vec<VisualTransition>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualReconstruction {
    /// Reconstructed from these captures
    pub sources: Vec<CaptureId>,
    
    /// Confidence in reconstruction
    pub confidence: f64,
    
    /// What's certain vs inferred
    pub certain_elements: Vec<String>,
    pub inferred_elements: Vec<String>,
    
    /// Reconstruction notes
    pub notes: Vec<String>,
}
```

### MCP Tools

```
vision_at_time        - Get visual state at specific time
vision_timeline       - Get visual timeline for element/page
vision_reconstruct    - Reconstruct visual state from partial evidence
```

---

## INVENTION 6: VISUAL ARCHAEOLOGY

### The Problem
UI was deleted/changed. No one captured it. Critical evidence lost.

### The Solution
Reconstruct deleted UI from traces: cached images, partial renders, descriptions, related captures.

### Data Structures

```rust
/// Archaeological dig for lost visual state
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualArchaeology {
    /// What we're trying to reconstruct
    pub target: String,
    
    /// Time period of interest
    pub time_range: TimeRange,
    
    /// Found artifacts
    pub artifacts: Vec<VisualArtifact>,
    
    /// Reconstruction attempt
    pub reconstruction: Option<ArchaeologicalReconstruction>,
    
    /// Confidence in findings
    pub confidence: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualArtifact {
    /// Type of artifact
    pub artifact_type: ArtifactType,
    
    /// The artifact data
    pub data: String,
    
    /// When it's from
    pub timestamp: Option<DateTime<Utc>>,
    
    /// How reliable
    pub reliability: f64,
    
    /// Source
    pub source: String,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ArtifactType {
    /// Partial screenshot
    PartialCapture,
    
    /// Thumbnail/preview
    Thumbnail,
    
    /// Cached image
    CachedImage,
    
    /// Text description (from memory)
    Description,
    
    /// HTML snapshot
    HTMLSnapshot,
    
    /// Style reference
    StyleReference,
    
    /// Related capture (same page, different area)
    RelatedCapture,
    
    /// User report/feedback
    UserReport,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ArchaeologicalReconstruction {
    /// What we could reconstruct
    pub elements: Vec<ReconstructedElement>,
    
    /// What's missing/unknown
    pub unknowns: Vec<String>,
    
    /// Composite visualization
    pub composite: Option<String>,  // Base64 image
    
    /// Confidence map
    pub confidence_map: Vec<(String, f64)>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReconstructedElement {
    pub element: String,
    pub appearance: String,
    pub confidence: f64,
    pub sources: Vec<ArtifactType>,
}
```

### MCP Tools

```
vision_archaeology_dig     - Search for artifacts of lost UI
vision_archaeology_reconstruct - Attempt reconstruction
vision_archaeology_report  - Generate archaeology report
```

---

## INVENTION 7: VISUAL MEMORY CONSOLIDATION

### The Problem
Hours of captures consume gigabytes. Can't keep everything forever. What to keep?

### The Solution
Intelligently consolidate visual history into key moments. Compress without losing meaning.

### Data Structures

```rust
/// Visual memory consolidation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualConsolidation {
    /// Time range being consolidated
    pub time_range: TimeRange,
    
    /// Original captures
    pub original_count: usize,
    pub original_size_bytes: u64,
    
    /// Consolidated captures
    pub consolidated: Vec<ConsolidatedCapture>,
    pub consolidated_size_bytes: u64,
    
    /// Compression ratio achieved
    pub compression_ratio: f64,
    
    /// What was preserved
    pub preservation_summary: PreservationSummary,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConsolidatedCapture {
    /// The key capture
    pub capture: CaptureId,
    
    /// Why it was kept
    pub reason: ConsolidationReason,
    
    /// What it represents (time range)
    pub represents: TimeRange,
    
    /// Captures it replaced
    pub replaced_count: usize,
    
    /// Importance score
    pub importance: f64,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ConsolidationReason {
    /// First capture in session
    SessionStart,
    
    /// Last capture in session  
    SessionEnd,
    
    /// Significant visual change
    SignificantChange,
    
    /// User-marked important
    UserMarked,
    
    /// Referenced by memory/decision
    ReferencedByMemory,
    
    /// Part of incident timeline
    IncidentEvidence,
    
    /// Best quality in time range
    BestQuality,
    
    /// Unique state not seen elsewhere
    UniqueState,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreservationSummary {
    /// Key moments preserved
    pub key_moments: Vec<String>,
    
    /// States that can still be queried
    pub queryable_states: Vec<String>,
    
    /// Information lost
    pub lost_detail: Vec<String>,
    
    /// Reconstruction possible?
    pub can_reconstruct_between: bool,
}
```

### MCP Tools

```
vision_consolidate        - Consolidate visual history
vision_consolidate_preview - Preview what would be kept/lost
vision_consolidate_policy  - Set consolidation policy
```

---

## INVENTION 8: VISUAL DÉJÀ VU

### The Problem
"I've seen this bug before." But when? Where? Can't find the previous occurrence.

### The Solution
Automatically detect when current visual state matches a historical pattern.

### Data Structures

```rust
/// Visual déjà vu detection
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualDejaVu {
    /// Current capture
    pub current: CaptureId,
    
    /// Historical matches
    pub matches: Vec<DejaVuMatch>,
    
    /// Pattern detected
    pub pattern: Option<RecurringPattern>,
    
    /// Significance
    pub significance: DejaVuSignificance,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DejaVuMatch {
    /// Historical capture
    pub historical: CaptureId,
    
    /// When it occurred
    pub occurred_at: DateTime<Utc>,
    
    /// Similarity score
    pub similarity: f64,
    
    /// What's similar
    pub similar_elements: Vec<String>,
    
    /// What's different
    pub different_elements: Vec<String>,
    
    /// Context at that time (from memory)
    pub historical_context: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecurringPattern {
    /// Pattern description
    pub description: String,
    
    /// Occurrences
    pub occurrences: Vec<CaptureId>,
    
    /// Frequency
    pub frequency: PatternFrequency,
    
    /// Trigger (if known)
    pub trigger: Option<String>,
    
    /// Resolution (if any occurrence was resolved)
    pub resolution: Option<String>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum PatternFrequency {
    FirstTime,
    Rare,       // 2-3 times
    Occasional, // 4-10 times
    Frequent,   // 10+ times
    Constant,   // Every session
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum DejaVuSignificance {
    /// Interesting but not actionable
    Informational,
    
    /// Might indicate recurring issue
    Warning,
    
    /// Known bug recurring
    KnownBug,
    
    /// Critical issue recurring
    Critical,
}
```

### MCP Tools

```
vision_dejavu_check     - Check if current state has been seen before
vision_dejavu_patterns  - Find recurring visual patterns
vision_dejavu_alert     - Set alerts for specific patterns
```

---

# PREDICTION INVENTIONS

## INVENTION 9: VISUAL PROPHECY

### The Problem
"What will this page look like after the CSS change?" Have to deploy to find out.

### The Solution
Predict visual changes before they happen based on code analysis.

### Data Structures

```rust
/// Visual prophecy - predicted visual state
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualProphecy {
    /// What change is being analyzed
    pub proposed_change: ProposedChange,
    
    /// Current visual state
    pub current_state: CaptureId,
    
    /// Predicted visual changes
    pub predictions: Vec<VisualPrediction>,
    
    /// Affected elements
    pub affected_elements: Vec<AffectedElement>,
    
    /// Risk assessment
    pub risk: VisualRisk,
    
    /// Confidence in prophecy
    pub confidence: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProposedChange {
    /// Type of change
    pub change_type: ChangeType,
    
    /// What's changing
    pub target: String,
    
    /// The change details
    pub details: String,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ChangeType {
    CSS,
    HTML,
    JavaScript,
    Asset,
    Content,
    Layout,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualPrediction {
    /// Element affected
    pub element: String,
    
    /// Predicted change
    pub predicted_change: String,
    
    /// Before (current)
    pub before: ElementState,
    
    /// After (predicted)
    pub after: ElementState,
    
    /// Confidence
    pub confidence: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ElementState {
    pub position: Option<BoundingBox>,
    pub color: Option<String>,
    pub text: Option<String>,
    pub visible: bool,
    pub size: Option<(u32, u32)>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AffectedElement {
    pub element: String,
    pub impact: ElementImpact,
    pub cascade_from: Option<String>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ElementImpact {
    /// Won't visually change
    None,
    
    /// Minor visual change
    Minor,
    
    /// Noticeable change
    Moderate,
    
    /// Major change
    Major,
    
    /// Element will break/disappear
    Breaking,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualRisk {
    /// Overall risk level
    pub level: RiskLevel,
    
    /// Risk factors
    pub factors: Vec<String>,
    
    /// Recommendations
    pub recommendations: Vec<String>,
}
```

### MCP Tools

```
vision_prophecy          - Predict visual impact of change
vision_prophecy_diff     - Generate predicted diff image
vision_prophecy_compare  - Compare prophecy to actual result
```

---

## INVENTION 10: REGRESSION ORACLE

### The Problem
Visual regression tests run AFTER deploy. Too late. Damage done.

### The Solution
Predict visual regressions before code is committed.

### Data Structures

```rust
/// Visual regression prediction
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualRegressionOracle {
    /// Change being analyzed
    pub change: ProposedChange,
    
    /// Predicted regressions
    pub predicted_regressions: Vec<PredictedRegression>,
    
    /// Safe changes
    pub safe_changes: Vec<String>,
    
    /// Recommended visual tests
    pub recommended_tests: Vec<VisualTest>,
    
    /// Overall regression probability
    pub regression_probability: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PredictedRegression {
    /// What will regress
    pub element: String,
    
    /// Page/route affected
    pub page: String,
    
    /// How it will regress
    pub regression_type: RegressionType,
    
    /// Probability
    pub probability: f64,
    
    /// Evidence for prediction
    pub evidence: Vec<String>,
    
    /// Severity
    pub severity: RegressionSeverity,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum RegressionType {
    /// Position shifted
    PositionShift,
    
    /// Size changed
    SizeChange,
    
    /// Color changed
    ColorChange,
    
    /// Text changed/truncated
    TextChange,
    
    /// Element disappeared
    Disappeared,
    
    /// Element overlapping
    Overlap,
    
    /// Layout broken
    LayoutBreak,
    
    /// Responsive breakage
    ResponsiveBreak,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum RegressionSeverity {
    /// Barely noticeable
    Trivial,
    
    /// Noticeable but not blocking
    Minor,
    
    /// Affects usability
    Major,
    
    /// Blocks functionality
    Critical,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualTest {
    /// What to test
    pub target: String,
    
    /// Test type
    pub test_type: VisualTestType,
    
    /// Priority
    pub priority: TestPriority,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum VisualTestType {
    FullPage,
    ElementOnly,
    Responsive,
    Interactive,
    Animation,
}
```

### MCP Tools

```
vision_regression_predict  - Predict regressions from change
vision_regression_test     - Generate visual regression tests
vision_regression_history  - History of regressions for element
```

---

## INVENTION 11: ATTENTION PREDICTION

### The Problem
"Where will users look?" Requires expensive eye-tracking studies.

### The Solution
Predict visual attention patterns from UI structure and design principles.

### Data Structures

```rust
/// Predicted attention pattern
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AttentionPrediction {
    /// Capture being analyzed
    pub capture: CaptureId,
    
    /// Attention heatmap
    pub heatmap: AttentionHeatmap,
    
    /// Scan path prediction
    pub scan_path: Vec<AttentionPoint>,
    
    /// Key focal points
    pub focal_points: Vec<FocalPoint>,
    
    /// Attention score for key elements
    pub element_scores: Vec<ElementAttention>,
    
    /// Recommendations
    pub recommendations: Vec<AttentionRecommendation>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AttentionHeatmap {
    /// Width/height of heatmap
    pub width: u32,
    pub height: u32,
    
    /// Attention values (0.0 - 1.0) per region
    pub values: Vec<Vec<f64>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AttentionPoint {
    /// Position
    pub x: u32,
    pub y: u32,
    
    /// Dwell time prediction (ms)
    pub predicted_dwell_ms: u32,
    
    /// Order in scan path
    pub order: u32,
    
    /// What element is here
    pub element: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FocalPoint {
    /// Region
    pub region: BoundingBox,
    
    /// Attention strength
    pub strength: f64,
    
    /// Why it attracts attention
    pub reason: AttentionReason,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum AttentionReason {
    /// High contrast
    Contrast,
    
    /// Motion/animation
    Motion,
    
    /// Faces/people
    Faces,
    
    /// Text (especially headlines)
    Text,
    
    /// Color pop
    ColorPop,
    
    /// Size dominance
    Size,
    
    /// Position (F-pattern, Z-pattern)
    Position,
    
    /// Visual weight
    Weight,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AttentionRecommendation {
    /// Issue
    pub issue: String,
    
    /// Recommendation
    pub recommendation: String,
    
    /// Expected improvement
    pub expected_improvement: String,
}
```

### MCP Tools

```
vision_attention_predict   - Predict attention patterns
vision_attention_optimize  - Suggest optimizations for attention
vision_attention_compare   - Compare attention between designs
```

---

## INVENTION 12: PHANTOM CAPTURE

### The Problem
"What would this page look like if we used blue instead of green?" Have to actually change it.

### The Solution
Generate synthetic captures showing what WOULD be there under different conditions.

### Data Structures

```rust
/// A phantom (synthetic) capture
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PhantomCapture {
    /// Base capture this is derived from
    pub base_capture: CaptureId,
    
    /// Modifications applied
    pub modifications: Vec<PhantomModification>,
    
    /// Generated image
    pub phantom_image: String,  // Base64
    
    /// Confidence in accuracy
    pub confidence: f64,
    
    /// What's reliable vs uncertain
    pub reliability_map: Vec<(BoundingBox, f64)>,
    
    /// Phantom ID for reference
    pub phantom_id: PhantomId,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PhantomModification {
    /// Type of modification
    pub mod_type: ModificationType,
    
    /// Target element
    pub target: String,
    
    /// The modification
    pub modification: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ModificationType {
    /// Change color
    ColorChange { from: String, to: String },
    
    /// Change text
    TextChange { from: String, to: String },
    
    /// Change size
    SizeChange { scale: f64 },
    
    /// Move element
    Move { dx: i32, dy: i32 },
    
    /// Remove element
    Remove,
    
    /// Add element
    Add { element: String },
    
    /// Change visibility
    Visibility { visible: bool },
    
    /// Apply style
    Style { css: String },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct PhantomId(pub Uuid);
```

### MCP Tools

```
vision_phantom_create    - Create phantom capture with modifications
vision_phantom_compare   - Compare phantom to real capture
vision_phantom_ab_test   - Generate A/B variants as phantoms
```

---

# COGNITION INVENTIONS

## INVENTION 13: SEMANTIC VISION

### The Problem
AI sees pixels. Doesn't understand meaning. "There's a red rectangle" vs "There's an error message."

### The Solution
Understand UI semantics, not just appearance. Know what elements MEAN, not just how they look.

### Data Structures

```rust
/// Semantic understanding of visual state
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SemanticVision {
    /// Capture being analyzed
    pub capture: CaptureId,
    
    /// Semantic elements detected
    pub elements: Vec<SemanticElement>,
    
    /// Page purpose/intent
    pub page_intent: PageIntent,
    
    /// User journey stage
    pub journey_stage: JourneyStage,
    
    /// Actionable elements
    pub actions: Vec<ActionableElement>,
    
    /// Information hierarchy
    pub hierarchy: InformationHierarchy,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SemanticElement {
    /// Visual location
    pub region: BoundingBox,
    
    /// Semantic role
    pub role: SemanticRole,
    
    /// Content/meaning
    pub meaning: String,
    
    /// Importance (0.0 - 1.0)
    pub importance: f64,
    
    /// Relationships to other elements
    pub relationships: Vec<ElementRelationship>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum SemanticRole {
    // Navigation
    Navigation,
    Breadcrumb,
    Menu,
    
    // Content
    Heading,
    Paragraph,
    List,
    Image,
    Video,
    
    // Interaction
    Button,
    Link,
    Input,
    Form,
    
    // Feedback
    Error,
    Warning,
    Success,
    Loading,
    Progress,
    
    // Commerce
    Price,
    CartItem,
    Checkout,
    
    // Identity
    Avatar,
    Username,
    Badge,
    
    // Layout
    Header,
    Footer,
    Sidebar,
    Modal,
    Card,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PageIntent {
    /// Primary purpose
    pub primary: String,
    
    /// Secondary purposes
    pub secondary: Vec<String>,
    
    /// Confidence
    pub confidence: f64,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum JourneyStage {
    Discovery,
    Consideration,
    Decision,
    Action,
    Confirmation,
    Error,
    Support,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActionableElement {
    /// The element
    pub element: SemanticElement,
    
    /// What clicking/interacting does
    pub action: String,
    
    /// Is it the primary action?
    pub is_primary: bool,
    
    /// Prerequisites (e.g., "must fill form first")
    pub prerequisites: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InformationHierarchy {
    /// Most important information
    pub primary: Vec<String>,
    
    /// Supporting information
    pub secondary: Vec<String>,
    
    /// Tertiary/fine print
    pub tertiary: Vec<String>,
}
```

### MCP Tools

```
vision_semantic_analyze   - Analyze semantic meaning of UI
vision_semantic_find      - Find elements by semantic role
vision_semantic_intent    - Determine page/flow intent
```

---

## INVENTION 14: VISUAL REASONING CHAIN

### The Problem
"Why is the user confused?" AI sees UI but can't reason about user experience.

### The Solution
Chain visual observations into reasoning about UX, flows, and user problems.

### Data Structures

```rust
/// Visual reasoning chain
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualReasoningChain {
    /// Starting observation
    pub observation: VisualObservation,
    
    /// Reasoning steps
    pub reasoning: Vec<ReasoningStep>,
    
    /// Conclusion
    pub conclusion: ReasoningConclusion,
    
    /// Confidence in reasoning
    pub confidence: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualObservation {
    /// What was observed
    pub observation: String,
    
    /// Evidence (capture + region)
    pub evidence: Vec<(CaptureId, BoundingBox)>,
    
    /// Observation type
    pub observation_type: ObservationType,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ObservationType {
    /// UI state observation
    StateObservation,
    
    /// Change observation
    ChangeObservation,
    
    /// Pattern observation
    PatternObservation,
    
    /// Anomaly observation
    AnomalyObservation,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReasoningStep {
    /// The reasoning
    pub reasoning: String,
    
    /// Type of reasoning
    pub reasoning_type: ReasoningType,
    
    /// Supporting evidence
    pub evidence: Vec<String>,
    
    /// Leads to next step
    pub leads_to: Option<String>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ReasoningType {
    /// Causal reasoning
    Causal,
    
    /// Comparative reasoning
    Comparative,
    
    /// Analogical reasoning
    Analogical,
    
    /// Deductive reasoning
    Deductive,
    
    /// Inductive reasoning
    Inductive,
    
    /// UX principle application
    UXPrinciple,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReasoningConclusion {
    /// The conclusion
    pub conclusion: String,
    
    /// Type of conclusion
    pub conclusion_type: ConclusionType,
    
    /// Actionable recommendations
    pub recommendations: Vec<String>,
    
    /// Alternative conclusions considered
    pub alternatives: Vec<String>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ConclusionType {
    /// Problem identified
    ProblemIdentified,
    
    /// Root cause found
    RootCauseFound,
    
    /// User need identified
    UserNeedIdentified,
    
    /// Design flaw found
    DesignFlawFound,
    
    /// Opportunity identified
    OpportunityIdentified,
}
```

### MCP Tools

```
vision_reason             - Build reasoning chain from observations
vision_reason_about       - Reason about specific UX question
vision_reason_diagnose    - Diagnose UX problem from symptoms
```

---

## INVENTION 15: CROSS-MODAL BINDING

### The Problem
Visual state lives separate from code, memory, identity. Can't connect "the button" in screenshot to "the button" in code.

### The Solution
Bind visual elements to their representations in other sisters.

### Data Structures

```rust
/// Cross-modal binding
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrossModalBinding {
    /// Visual element
    pub visual: VisualElement,
    
    /// Bindings to other modalities
    pub bindings: Vec<ModalBinding>,
    
    /// Binding strength
    pub strength: f64,
    
    /// Last verified
    pub verified_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualElement {
    /// Capture containing element
    pub capture: CaptureId,
    
    /// Region in capture
    pub region: BoundingBox,
    
    /// Element identifier (if known)
    pub selector: Option<String>,
    
    /// Visual signature (for matching)
    pub signature: VisualSignature,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualSignature {
    /// CLIP embedding
    pub embedding: Vec<f32>,
    
    /// Color histogram
    pub colors: Vec<(String, f64)>,
    
    /// Text content
    pub text: Option<String>,
    
    /// Shape descriptor
    pub shape: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ModalBinding {
    /// Binding to code (Codebase)
    Code {
        node_id: String,  // CodeNodeId from Codebase
        binding_type: CodeBindingType,
    },
    
    /// Binding to memory (Memory)
    Memory {
        node_id: String,  // MemoryNodeId
        binding_type: MemoryBindingType,
    },
    
    /// Binding to identity action (Identity)
    Identity {
        receipt_id: String,
        binding_type: IdentityBindingType,
    },
    
    /// Binding to temporal entity (Time)
    Time {
        entity_id: String,  // TemporalId
        binding_type: TimeBindingType,
    },
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum CodeBindingType {
    /// Element rendered by this component
    RenderedBy,
    
    /// Element styled by this CSS
    StyledBy,
    
    /// Element controlled by this handler
    ControlledBy,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum MemoryBindingType {
    /// Decision that affected this element
    AffectedByDecision,
    
    /// Fact about this element
    FactAbout,
    
    /// Episode involving this element
    InvolvedInEpisode,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum IdentityBindingType {
    /// Action that modified this element
    ModifiedBy,
    
    /// Agent responsible for element
    OwnedBy,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum TimeBindingType {
    /// Deadline related to element
    HasDeadline,
    
    /// Scheduled change to element
    ScheduledChange,
}
```

### MCP Tools

```
vision_bind_code        - Bind visual element to code
vision_bind_memory      - Bind visual element to memory
vision_bind_identity    - Bind visual element to identity receipt
vision_bind_time        - Bind visual element to temporal entity
vision_traverse_binding - Navigate across modal bindings
```

---

## INVENTION 16: VISUAL GESTALT

### The Problem
AI sees elements. Doesn't see the whole. Misses emergent properties of the complete design.

### The Solution
Understand UI as a gestalt — the whole that's greater than the sum of parts.

### Data Structures

```rust
/// Gestalt analysis of visual state
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualGestalt {
    /// Capture analyzed
    pub capture: CaptureId,
    
    /// Gestalt principles detected
    pub principles: Vec<GestaltPrinciple>,
    
    /// Emergent patterns
    pub emergent_patterns: Vec<EmergentPattern>,
    
    /// Visual harmony score
    pub harmony_score: f64,
    
    /// Tension points (where gestalt breaks)
    pub tension_points: Vec<TensionPoint>,
    
    /// Overall impression
    pub impression: VisualImpression,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GestaltPrinciple {
    /// Which principle
    pub principle: GestaltType,
    
    /// Where it's applied
    pub elements: Vec<BoundingBox>,
    
    /// How strongly
    pub strength: f64,
    
    /// Is it helping or hurting?
    pub effect: GestaltEffect,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum GestaltType {
    /// Similar elements grouped
    Similarity,
    
    /// Close elements grouped
    Proximity,
    
    /// Continuous elements grouped
    Continuity,
    
    /// Incomplete shapes completed
    Closure,
    
    /// Figure/ground separation
    FigureGround,
    
    /// Symmetrical elements grouped
    Symmetry,
    
    /// Common fate (moving together)
    CommonFate,
    
    /// Past experience influences perception
    PastExperience,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum GestaltEffect {
    /// Helps comprehension
    Positive,
    
    /// Neutral
    Neutral,
    
    /// Hinders comprehension
    Negative,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmergentPattern {
    /// Pattern description
    pub pattern: String,
    
    /// Elements creating pattern
    pub elements: Vec<BoundingBox>,
    
    /// Is this intentional?
    pub intentional: bool,
    
    /// Impact on user
    pub impact: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TensionPoint {
    /// Where tension exists
    pub location: BoundingBox,
    
    /// What's causing tension
    pub cause: String,
    
    /// Impact on perception
    pub impact: String,
    
    /// Suggestion to resolve
    pub resolution: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualImpression {
    /// One-word impression
    pub keyword: String,
    
    /// Emotional tone
    pub tone: EmotionalTone,
    
    /// Professionalism level
    pub professionalism: f64,
    
    /// Clarity level
    pub clarity: f64,
    
    /// Trust level
    pub trust: f64,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum EmotionalTone {
    Calm,
    Energetic,
    Professional,
    Playful,
    Serious,
    Trustworthy,
    Urgent,
    Confused,
    Chaotic,
}
```

### MCP Tools

```
vision_gestalt_analyze    - Analyze gestalt properties
vision_gestalt_harmony    - Measure visual harmony
vision_gestalt_improve    - Suggest improvements for gestalt
```

---

# IMPLEMENTATION NOTES

## Priority Order

```
HIGH PRIORITY (Core V2):
  1. Visual Grounding         - Differentiator
  2. Hallucination Detector   - Trust builder
  4. Multi-Context Vision     - Enterprise feature
  9. Visual Prophecy          - Prediction edge

MEDIUM PRIORITY (V2.1):
  3. Visual Truth Maintenance - Long-term accuracy
  5. Temporal Vision          - History navigation
  8. Visual Déjà Vu           - Pattern detection
  13. Semantic Vision         - Understanding depth
  15. Cross-Modal Binding     - Sister integration

LOWER PRIORITY (V2.2+):
  6. Visual Archaeology       - Advanced reconstruction
  7. Visual Memory Consolidation - Storage optimization
  10. Regression Oracle       - CI integration
  11. Attention Prediction    - UX optimization
  12. Phantom Capture         - Synthetic generation
  14. Visual Reasoning Chain  - Advanced reasoning
  16. Visual Gestalt          - Design analysis
```

## Integration with Sisters

- **Memory**: Visual evidence linked to decisions, facts, episodes
- **Codebase**: Visual elements bound to code that renders them
- **Identity**: Visual changes tracked to agent actions via receipts
- **Time**: Visual state changes scheduled, deadlines for fixes

---

# SUMMARY

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║  THE 16 PERCEPTION INVENTIONS                                             ║
║                                                                           ║
║  GROUNDING:                                                               ║
║   1. Visual Grounding        - Prove every visual claim                   ║
║   2. Hallucination Detector  - Catch AI lies about UI                     ║
║   3. Visual Truth Maintenance- Track when visual truths change            ║
║   4. Multi-Context Vision    - Compare across sites/versions/devices      ║
║                                                                           ║
║  TEMPORAL:                                                                ║
║   5. Temporal Vision         - See UI at any point in time                ║
║   6. Visual Archaeology      - Reconstruct deleted UI from traces         ║
║   7. Visual Memory Consolidation - Compress history intelligently         ║
║   8. Visual Déjà Vu          - Detect recurring visual patterns           ║
║                                                                           ║
║  PREDICTION:                                                              ║
║   9. Visual Prophecy         - Predict visual changes before deploy       ║
║  10. Regression Oracle       - Predict visual regressions                 ║
║  11. Attention Prediction    - Predict where users will look              ║
║  12. Phantom Capture         - Generate "what if" synthetic captures      ║
║                                                                           ║
║  COGNITION:                                                               ║
║  13. Semantic Vision         - Understand UI meaning, not just pixels     ║
║  14. Visual Reasoning Chain  - Reason about UX from observations          ║
║  15. Cross-Modal Binding     - Connect vision to code/memory/identity     ║
║  16. Visual Gestalt          - See the whole, not just the parts          ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  "Screenshot tools see pixels.                                            ║
║   AgenticVision sees meaning."                                            ║
║                                                                           ║
║  "They capture what IS.                                                   ║
║   We see what WAS, what WILL BE, and what SHOULD BE."                     ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```
