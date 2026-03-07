# CLAUDE-CODE-INSTRUCTIONS-VERITAS.md

**Sister:** AgenticVeritas  
**Role:** Intent Compilation & Uncertainty Detection — Knows what you REALLY mean, admits when uncertain  
**Working Directory:** `/Users/omoshola/Documents/agentralabs-tech/agentic-veritas`  
**Priority:** #4 MEDIUM (Important for non-code use cases)

---

## BENCHMARK TARGETS

| Metric | Target |
|--------|--------|
| Tests | 200+ |
| MCP Tools | 10 |
| Inventions | 20 |
| CLI Commands | 25+ |
| MCP Unwraps | 0 |
| Doc Pages | 12 |
| SVG Diagrams | 4 |

---

## WHAT VERITAS DOES

Veritas is the truth and uncertainty engine. It compiles natural language into formal intent specs, detects uncertainty in claims, verifies facts, and performs causal reasoning. It knows when to say "I don't know" and when to ask for clarification.

**For Coders:** Converts "Build me an API" into formal IntentSpec  
**For Everyone:** Flags uncertain claims, verifies facts, reasons about cause/effect

---

## 20 INVENTIONS (5 Tiers × 4)

**TIER 1 - INTENT COMPILATION:**
1. Intent Parser - Parses natural language to structured intent
2. Domain Classifier - Classifies intent domain
3. Entity Extractor - Extracts entities from description
4. Constraint Detector - Detects constraints and requirements

**TIER 2 - AMBIGUITY RESOLUTION:**
5. Ambiguity Detector - Detects ambiguous terms
6. Question Generator - Generates highest-impact clarification question
7. Default Inferrer - Infers sensible defaults
8. Context Integrator - Integrates context to resolve ambiguity

**TIER 3 - UNCERTAINTY DETECTION:**
9. Confidence Scorer - Scores confidence in claims
10. Source Verifier - Verifies sources of claims
11. Uncertainty Flagger - Flags uncertain claims
12. Caveat Generator - Generates appropriate caveats

**TIER 4 - CAUSAL REASONING:**
13. Causal Parser - Parses causal relationships
14. Consequence Predictor - Predicts consequences
15. Counterfactual Reasoner - Reasons about "what if"
16. Dependency Tracer - Traces causal dependencies

**TIER 5 - TRUTH VERIFICATION:**
17. Claim Extractor - Extracts claims from text
18. Fact Checker - Checks facts against knowledge
19. Consistency Checker - Checks for internal consistency
20. Truth Synthesizer - Synthesizes verified truth

---

## PROJECT STRUCTURE

```
agentic-veritas/
├── Cargo.toml
├── README.md, LICENSE, CHANGELOG.md, SECURITY.md, CONTRIBUTING.md
├── CODE_OF_CONDUCT.md, CLAUDE.md, Makefile, INSTALL.md, GUIDE.md
├── sister.manifest.json
├── .github/workflows/
├── scripts/
├── docs/public/
├── crates/
│   ├── agentic-veritas-core/     # Intent, uncertainty, causal, truth
│   ├── agentic-veritas-mcp/      # 10 MCP tools
│   ├── agentic-veritas-cli/      # 25+ commands
│   └── agentic-veritas-ffi/      # C FFI + Python
├── tests/
├── examples/
└── paper/
```

---

## 10 MCP TOOLS

```
1. veritas_compile_intent     - Compile NL to IntentSpec
2. veritas_detect_ambiguity   - Detect ambiguities in intent
3. veritas_generate_question  - Generate clarification question
4. veritas_score_confidence   - Score confidence in claim
5. veritas_check_uncertainty  - Check uncertainty level
6. veritas_verify_claim       - Verify a factual claim
7. veritas_reason_causally    - Perform causal reasoning
8. veritas_check_consistency  - Check internal consistency
9. veritas_extract_claims     - Extract claims from text
10. veritas_synthesize        - Synthesize verified information
```

---

## PHASE 1: WORKSPACE SETUP

```bash
cd /Users/omoshola/Documents/agentralabs-tech
mkdir -p agentic-veritas/crates/{agentic-veritas-core,agentic-veritas-mcp,agentic-veritas-cli,agentic-veritas-ffi}/src
cd agentic-veritas
```

Create `Cargo.toml`:
```toml
[workspace]
resolver = "2"
members = ["crates/agentic-veritas-core", "crates/agentic-veritas-mcp", "crates/agentic-veritas-cli", "crates/agentic-veritas-ffi"]

[workspace.package]
version = "0.1.0"
edition = "2021"
license = "MIT"
repository = "https://github.com/agentra/agentic-veritas"

[workspace.dependencies]
agentic-veritas-core = { path = "crates/agentic-veritas-core" }
agentic-sdk = "0.2"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tokio = { version = "1.35", features = ["full"] }
async-trait = "0.1"
clap = { version = "4.4", features = ["derive"] }
blake3 = "1.5"
uuid = { version = "1.6", features = ["v4", "serde"] }
thiserror = "1.0"
anyhow = "1.0"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
chrono = { version = "0.4", features = ["serde"] }
tempfile = "3.9"
```

**CHECKPOINT:** `cargo build --workspace` passes

---

## PHASE 2: TYPES (src/types/)

Create in `crates/agentic-veritas-core/src/types/`:

- `ids.rs` - VeritasId, IntentId, ClaimId
- `error.rs` - VeritasError enum
- `intent.rs` - IntentSpec, IntentCompilation (re-use from shared interfaces)
- `uncertainty.rs` - UncertaintyAssessment, UncertaintyFactor, ConfidenceScore
- `claim.rs` - Claim, ClaimVerification, ClaimSource
- `causal.rs` - CausalChain, CausalReasoning, Counterfactual

Key types:
```rust
pub struct IntentCompilation {
    pub spec: IntentSpec,
    pub confidence: f64,
    pub ambiguities: Vec<Ambiguity>,
    pub clarification_question: Option<String>,
}

pub struct UncertaintyAssessment {
    pub uncertainty_level: f64,  // 0.0 = certain, 1.0 = uncertain
    pub factors: Vec<UncertaintyFactor>,
    pub should_flag: bool,
    pub suggested_caveat: Option<String>,
}

pub struct Ambiguity {
    pub aspect: String,
    pub options: Vec<String>,
    pub default: Option<String>,
    pub importance: f64,  // How much clarification helps
}

pub struct ClarificationNeed {
    pub needs_clarification: bool,
    pub question: Option<String>,
    pub impact: f64,  // Information gain from clarification
}
```

**CHECKPOINT:** `cargo build` passes

---

## PHASE 3: INTENT COMPILATION (src/intent/)

Create intent compilation:

- `parser.rs` - IntentParser
- `domain.rs` - DomainClassifier
- `entity.rs` - EntityExtractor
- `constraint.rs` - ConstraintDetector

Key function:
```rust
pub async fn compile_intent(natural_language: &str) -> Result<IntentCompilation> {
    // 1. Parse basic structure
    let parsed = self.parser.parse(natural_language)?;
    
    // 2. Classify domain
    let domain = self.domain_classifier.classify(&parsed)?;
    
    // 3. Extract entities
    let entities = self.entity_extractor.extract(&parsed)?;
    
    // 4. Detect constraints
    let constraints = self.constraint_detector.detect(&parsed)?;
    
    // 5. Detect ambiguities
    let ambiguities = self.ambiguity_detector.detect(&parsed)?;
    
    // 6. Generate clarification question if needed
    let question = if ambiguities.iter().any(|a| a.importance > 0.7) {
        Some(self.question_generator.generate(&ambiguities)?)
    } else {
        None
    };
    
    // 7. Calculate confidence
    let confidence = self.calculate_confidence(&parsed, &ambiguities);
    
    Ok(IntentCompilation {
        spec: IntentSpec { domain, entities, constraints, .. },
        confidence,
        ambiguities,
        clarification_question: question,
    })
}
```

**CHECKPOINT:** `cargo test intent::` passes (40+ tests)

---

## PHASE 4: AMBIGUITY (src/ambiguity/)

Create ambiguity handling:

- `detector.rs` - AmbiguityDetector
- `question.rs` - QuestionGenerator (generates ONE high-impact question)
- `defaults.rs` - DefaultInferrer
- `context.rs` - ContextIntegrator

**CRITICAL:** The ONE QUESTION MAX principle. QuestionGenerator must find the single highest-information question, not a list.

```rust
pub fn generate_clarification(ambiguities: &[Ambiguity]) -> Option<String> {
    // 1. Score each ambiguity by information gain
    let scored: Vec<_> = ambiguities.iter()
        .map(|a| (a, self.score_information_gain(a)))
        .collect();
    
    // 2. Find highest impact ambiguity
    let best = scored.iter()
        .max_by(|a, b| a.1.partial_cmp(&b.1).unwrap())?;
    
    // 3. Generate ONE question for it
    if best.1 > 0.3 {  // Threshold for asking
        Some(self.format_question(best.0))
    } else {
        None  // Use defaults instead
    }
}
```

**CHECKPOINT:** `cargo test ambiguity::` passes (30+ tests)

---

## PHASE 5: UNCERTAINTY (src/uncertainty/)

Create uncertainty detection:

- `scorer.rs` - ConfidenceScorer
- `verifier.rs` - SourceVerifier
- `flagger.rs` - UncertaintyFlagger
- `caveat.rs` - CaveatGenerator

**CHECKPOINT:** `cargo test uncertainty::` passes (35+ tests)

---

## PHASE 6: CAUSAL (src/causal/)

Create causal reasoning:

- `parser.rs` - CausalParser
- `predictor.rs` - ConsequencePredictor
- `counterfactual.rs` - CounterfactualReasoner
- `tracer.rs` - DependencyTracer

**CHECKPOINT:** `cargo test causal::` passes (30+ tests)

---

## PHASE 7: TRUTH (src/truth/)

Create truth verification:

- `extractor.rs` - ClaimExtractor
- `checker.rs` - FactChecker
- `consistency.rs` - ConsistencyChecker
- `synthesizer.rs` - TruthSynthesizer

**CHECKPOINT:** `cargo test truth::` passes (30+ tests)

---

## PHASE 8: BRIDGES (src/bridges/)

Create bridge traits:

- `traits.rs` - VeritasBridge trait
- `noop.rs` - NoOpVeritasBridge
- `hydra.rs` - HydraAdapter
- `foundation.rs` - Foundation bridges

**CHECKPOINT:** `cargo test bridges::` passes (15+ tests)

---

## PHASE 9: MCP SERVER

Create strict MCP server with 10 tools in `crates/agentic-veritas-mcp/`

**CRITICAL:** Zero `.unwrap()` calls. Strict validation.

**CHECKPOINT:** `cargo test -p agentic-veritas-mcp` passes (50+ tests)

---

## PHASE 10: CLI

Create 25+ commands in `crates/agentic-veritas-cli/`:

```
veritas intent compile/parse/classify
veritas ambiguity detect/resolve
veritas question generate
veritas confidence score
veritas uncertainty check/flag
veritas claim extract/verify
veritas causal reason/predict/trace
veritas consistency check
veritas serve
veritas info/version
```

**CHECKPOINT:** `cargo test -p agentic-veritas-cli` passes (25+ tests)

---

## PHASE 11: FFI

Create C FFI and Python bindings

**CHECKPOINT:** Library builds

---

## PHASE 12: TESTS (200+)

**CHECKPOINT:** `cargo test --workspace` passes 200+ tests

---

## PHASE 13: DOCS + CI

**FINAL CHECKPOINT:**
```bash
cargo test --workspace  # 200+ pass
cargo clippy --workspace -- -D warnings  # 0 warnings
./scripts/check-canonical-sister.sh  # All green
```

---

## KEY PATTERNS

### Intent Compilation Pattern
```rust
pub async fn compile_intent(nl: &str) -> Result<IntentCompilation> {
    // 1. Tokenize and parse
    let tokens = tokenize(nl);
    let parsed = parse(&tokens);
    
    // 2. Classify domain with confidence
    let (domain, domain_confidence) = classify_domain(&parsed);
    
    // 3. Extract entities
    let entities = extract_entities(&parsed);
    
    // 4. Detect ambiguities
    let ambiguities = detect_ambiguities(&parsed);
    
    // 5. Generate ONE clarification question if needed
    let question = if should_clarify(&ambiguities) {
        Some(generate_best_question(&ambiguities))
    } else {
        None
    };
    
    // 6. Infer defaults for unspecified aspects
    let defaults = infer_defaults(&parsed, &domain);
    
    Ok(IntentCompilation {
        spec: IntentSpec::new(nl)
            .with_domain(domain)
            .with_entities(entities)
            .with_defaults(defaults),
        confidence: domain_confidence,
        ambiguities,
        clarification_question: question,
    })
}
```

### Uncertainty Detection Pattern
```rust
pub fn check_uncertainty(claim: &str, context: &str) -> UncertaintyAssessment {
    let mut factors = Vec::new();
    let mut uncertainty = 0.0;
    
    // 1. Check if claim contains hedging language
    if has_hedging_language(claim) {
        factors.push(UncertaintyFactor::HedgingLanguage);
        uncertainty += 0.2;
    }
    
    // 2. Check if claim is verifiable
    if !is_verifiable(claim) {
        factors.push(UncertaintyFactor::NotVerifiable);
        uncertainty += 0.3;
    }
    
    // 3. Check recency (old info may be outdated)
    if references_time_sensitive_info(claim) {
        factors.push(UncertaintyFactor::TimeSensitive);
        uncertainty += 0.2;
    }
    
    // 4. Check if outside knowledge domain
    if outside_confident_domain(claim) {
        factors.push(UncertaintyFactor::OutsideDomain);
        uncertainty += 0.3;
    }
    
    UncertaintyAssessment {
        uncertainty_level: uncertainty.min(1.0),
        factors,
        should_flag: uncertainty > 0.5,
        suggested_caveat: if uncertainty > 0.5 {
            Some(generate_caveat(&factors))
        } else {
            None
        },
    }
}
```

### One Question Max Pattern
```rust
pub fn generate_clarification(ambiguities: &[Ambiguity]) -> Option<String> {
    // Sort by information gain (importance * options.len())
    let mut sorted = ambiguities.to_vec();
    sorted.sort_by(|a, b| {
        let score_a = a.importance * (a.options.len() as f64).log2();
        let score_b = b.importance * (b.options.len() as f64).log2();
        score_b.partial_cmp(&score_a).unwrap()
    });
    
    // Take the highest impact ambiguity
    let best = sorted.first()?;
    
    // Only ask if impact is significant
    if best.importance < 0.3 {
        return None;  // Use defaults instead
    }
    
    // Generate a single, clear question
    Some(format!(
        "Should I use {} or {}?",
        best.options.first().unwrap_or(&"option A".to_string()),
        best.default.as_ref().unwrap_or(&"the default".to_string())
    ))
}
```
