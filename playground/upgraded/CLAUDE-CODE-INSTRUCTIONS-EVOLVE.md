# CLAUDE-CODE-INSTRUCTIONS-EVOLVE.md

**Sister:** AgenticEvolve  
**Role:** Pattern Library — Crystallizes patterns, provides 80% of function bodies from verified patterns  
**Working Directory:** `/Users/omoshola/Documents/agentralabs-tech/agentic-evolve`  
**Priority:** #3 HIGH (Enables 15-second second builds)

---

## BENCHMARK TARGETS

| Metric | Target |
|--------|--------|
| Tests | 250+ |
| MCP Tools | 14 |
| Inventions | 22 |
| CLI Commands | 35+ |
| MCP Unwraps | 0 |
| Doc Pages | 12 |
| SVG Diagrams | 4 |

---

## WHAT EVOLVE DOES

Evolve is the pattern memory of the system. When code is successfully generated and tested, Evolve crystallizes it into reusable patterns. On subsequent builds, Evolve provides ~80% of function bodies from verified patterns, reducing LLM generation to only ~20% of code.

**First build:** 60 seconds (LLM generates everything)  
**Second build:** 15 seconds (Evolve provides 80% from patterns)

---

## 22 INVENTIONS (5 Tiers + 2)

**TIER 1 - PATTERN STORAGE:**
1. Pattern Store - Stores verified patterns
2. Pattern Index - Indexes patterns for fast lookup
3. Pattern Versioner - Manages pattern versions
4. Pattern Validator - Validates patterns are correct

**TIER 2 - PATTERN MATCHING:**
5. Signature Matcher - Matches function signatures to patterns
6. Context Matcher - Matches based on surrounding context
7. Semantic Matcher - Matches based on semantic meaning
8. Fuzzy Matcher - Handles approximate matches

**TIER 3 - CRYSTALLIZATION:**
9. Pattern Extractor - Extracts patterns from successful code
10. Variable Detector - Detects variables vs constants
11. Template Generator - Generates templates from patterns
12. Confidence Calculator - Calculates pattern confidence

**TIER 4 - COMPOSITION:**
13. Pattern Composer - Composes multiple patterns
14. Gap Filler - Fills gaps between patterns
15. Adapter Generator - Generates adapters between patterns
16. Integration Weaver - Weaves patterns together

**TIER 5 - COLLECTIVE LEARNING:**
17. Usage Tracker - Tracks pattern usage
18. Success Tracker - Tracks pattern success rate
19. Decay Manager - Manages pattern decay
20. Promotion Engine - Promotes high-confidence patterns

**TIER 6 - OPTIMIZATION:**
21. Pattern Optimizer - Optimizes pattern storage
22. Cache Manager - Manages pattern cache

---

## PROJECT STRUCTURE

```
agentic-evolve/
├── Cargo.toml
├── README.md, LICENSE, CHANGELOG.md, SECURITY.md, CONTRIBUTING.md
├── CODE_OF_CONDUCT.md, CLAUDE.md, Makefile, INSTALL.md, GUIDE.md
├── sister.manifest.json
├── .github/workflows/
├── scripts/
├── docs/public/
├── crates/
│   ├── agentic-evolve-core/      # Patterns, matching, crystallization
│   ├── agentic-evolve-mcp/       # 14 MCP tools
│   ├── agentic-evolve-cli/       # 35+ commands
│   └── agentic-evolve-ffi/       # C FFI + Python
├── tests/
├── examples/
└── paper/
```

---

## 14 MCP TOOLS

```
1. evolve_pattern_store          - Store a new pattern
2. evolve_pattern_get            - Get pattern by ID
3. evolve_pattern_search         - Search patterns
4. evolve_pattern_list           - List all patterns
5. evolve_pattern_delete         - Delete a pattern
6. evolve_match_signature        - Match signature to patterns
7. evolve_match_context          - Match with context
8. evolve_crystallize            - Crystallize code to pattern
9. evolve_get_body               - Get function body from pattern
10. evolve_compose               - Compose multiple patterns
11. evolve_coverage              - Get pattern coverage for blueprint
12. evolve_confidence            - Get confidence score
13. evolve_update_usage          - Update usage statistics
14. evolve_optimize              - Optimize pattern storage
```

---

## PHASE 1: WORKSPACE SETUP

```bash
cd /Users/omoshola/Documents/agentralabs-tech
mkdir -p agentic-evolve/crates/{agentic-evolve-core,agentic-evolve-mcp,agentic-evolve-cli,agentic-evolve-ffi}/src
cd agentic-evolve
```

Create `Cargo.toml`:
```toml
[workspace]
resolver = "2"
members = ["crates/agentic-evolve-core", "crates/agentic-evolve-mcp", "crates/agentic-evolve-cli", "crates/agentic-evolve-ffi"]

[workspace.package]
version = "0.1.0"
edition = "2021"
license = "MIT"
repository = "https://github.com/agentra/agentic-evolve"

[workspace.dependencies]
agentic-evolve-core = { path = "crates/agentic-evolve-core" }
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
tantivy = "0.21"  # For pattern indexing
```

**CHECKPOINT:** `cargo build --workspace` passes

---

## PHASE 2: TYPES (src/types/)

Create in `crates/agentic-evolve-core/src/types/`:

- `ids.rs` - EvolveId, PatternId, SkillId
- `error.rs` - EvolveError enum
- `pattern.rs` - Pattern, PatternTemplate, PatternVariable
- `skill.rs` - CrystallizedSkill, SkillMetadata
- `match_result.rs` - MatchResult, MatchScore, MatchContext

Key types:
```rust
pub struct Pattern {
    pub id: PatternId,
    pub name: String,
    pub domain: String,
    pub language: Language,
    pub signature: FunctionSignature,
    pub template: String,
    pub variables: Vec<PatternVariable>,
    pub confidence: f64,
    pub usage_count: u64,
    pub success_count: u64,
    pub created_at: i64,
    pub last_used: i64,
}

pub struct PatternVariable {
    pub name: String,
    pub var_type: String,
    pub pattern: Option<String>,  // Regex pattern for validation
    pub default: Option<String>,
}

pub struct CrystallizedSkill {
    pub id: SkillId,
    pub pattern_id: PatternId,
    pub code: String,
    pub bindings: HashMap<String, String>,
    pub verified_count: u64,
    pub last_verified: i64,
}
```

**CHECKPOINT:** `cargo build` passes

---

## PHASE 3: PATTERN STORAGE (src/storage/)

Create pattern storage:

- `store.rs` - PatternStore (save, load, delete, list)
- `index.rs` - PatternIndex (using tantivy for search)
- `versioner.rs` - PatternVersioner
- `format.rs` - .aevolve binary format

**CHECKPOINT:** `cargo test storage::` passes (30+ tests)

---

## PHASE 4: PATTERN MATCHING (src/matching/)

Create pattern matching:

- `signature.rs` - SignatureMatcher
- `context.rs` - ContextMatcher
- `semantic.rs` - SemanticMatcher
- `fuzzy.rs` - FuzzyMatcher
- `composite.rs` - CompositeMatcher (combines all)

Key trait:
```rust
#[async_trait]
pub trait PatternMatcher: Send + Sync {
    async fn find_matches(
        &self,
        signature: &FunctionSignature,
        context: &MatchContext,
        limit: usize,
    ) -> Result<Vec<MatchResult>>;
    
    fn score_match(&self, pattern: &Pattern, signature: &FunctionSignature) -> f64;
}
```

**CHECKPOINT:** `cargo test matching::` passes (40+ tests)

---

## PHASE 5: CRYSTALLIZATION (src/crystallization/)

Create pattern crystallization:

- `extractor.rs` - PatternExtractor
- `variable_detector.rs` - VariableDetector
- `template_generator.rs` - TemplateGenerator
- `confidence.rs` - ConfidenceCalculator

Key function:
```rust
pub async fn crystallize(
    successful_execution: &SuccessfulExecution,
) -> Result<CrystallizedSkill> {
    // 1. Extract function signatures
    let signatures = self.extract_signatures(&successful_execution.code)?;
    
    // 2. Detect variables (things that change between uses)
    let variables = self.detect_variables(&successful_execution.code)?;
    
    // 3. Generate template
    let template = self.generate_template(&successful_execution.code, &variables)?;
    
    // 4. Calculate confidence
    let confidence = self.calculate_confidence(successful_execution)?;
    
    // 5. Create and store pattern
    let pattern = Pattern::new(template, variables, confidence);
    self.store.save(&pattern)?;
    
    Ok(CrystallizedSkill::from(pattern))
}
```

**CHECKPOINT:** `cargo test crystallization::` passes (40+ tests)

---

## PHASE 6: COMPOSITION (src/composition/)

Create pattern composition:

- `composer.rs` - PatternComposer
- `gap_filler.rs` - GapFiller
- `adapter.rs` - AdapterGenerator
- `weaver.rs` - IntegrationWeaver

**CHECKPOINT:** `cargo test composition::` passes (30+ tests)

---

## PHASE 7: COLLECTIVE (src/collective/)

Create collective learning:

- `usage.rs` - UsageTracker
- `success.rs` - SuccessTracker
- `decay.rs` - DecayManager
- `promotion.rs` - PromotionEngine

**CHECKPOINT:** `cargo test collective::` passes (25+ tests)

---

## PHASE 8: BRIDGES (src/bridges/)

Create bridge traits:

- `traits.rs` - EvolveBridge trait
- `noop.rs` - NoOpEvolveBridge
- `hydra.rs` - HydraAdapter
- `foundation.rs` - Foundation bridges

**CHECKPOINT:** `cargo test bridges::` passes (20+ tests)

---

## PHASE 9: MCP SERVER

Create strict MCP server with 14 tools in `crates/agentic-evolve-mcp/`

**CRITICAL:** Zero `.unwrap()` calls. Strict validation.

**CHECKPOINT:** `cargo test -p agentic-evolve-mcp` passes (70+ tests)

---

## PHASE 10: CLI

Create 35+ commands in `crates/agentic-evolve-cli/`:

```
evolve pattern store/get/search/list/delete
evolve match signature/context/semantic
evolve crystallize
evolve body get
evolve compose
evolve coverage
evolve stats
evolve optimize
evolve serve
evolve info/version
```

**CHECKPOINT:** `cargo test -p agentic-evolve-cli` passes (35+ tests)

---

## PHASE 11: FFI

Create C FFI and Python bindings

**CHECKPOINT:** Library builds

---

## PHASE 12: TESTS (250+)

**CHECKPOINT:** `cargo test --workspace` passes 250+ tests

---

## PHASE 13: DOCS + CI

**FINAL CHECKPOINT:**
```bash
cargo test --workspace  # 250+ pass
cargo clippy --workspace -- -D warnings  # 0 warnings
./scripts/check-canonical-sister.sh  # All green
```

---

## KEY PATTERNS

### Pattern Matching Pattern
```rust
pub async fn get_function_body(
    signature: &FunctionSignature,
    context: &PatternContext,
) -> Result<Option<String>> {
    // 1. Find matching patterns
    let matches = self.matcher.find_matches(signature, context, 10).await?;
    
    if matches.is_empty() {
        return Ok(None);  // No pattern found, LLM must generate
    }
    
    // 2. Select best match
    let best = matches.into_iter()
        .max_by(|a, b| a.score.partial_cmp(&b.score).unwrap())
        .unwrap();
    
    // 3. Check confidence threshold
    if best.score < 0.8 {
        return Ok(None);  // Low confidence, let LLM generate
    }
    
    // 4. Apply bindings to template
    let body = self.apply_bindings(&best.pattern.template, context)?;
    
    // 5. Update usage stats
    self.usage_tracker.record_use(&best.pattern.id).await?;
    
    Ok(Some(body))
}
```

### Crystallization Pattern
```rust
pub async fn crystallize(exec: &SuccessfulExecution) -> Result<CrystallizedSkill> {
    // 1. Parse code into AST
    let ast = parse(&exec.code, &exec.language)?;
    
    // 2. Extract functions
    let functions = extract_functions(&ast);
    
    // 3. For each function, detect what's variable
    for func in functions {
        let variables = detect_variables(&func);
        let template = templatize(&func, &variables);
        
        // 4. Store pattern if confidence is high enough
        let confidence = calculate_confidence(exec, &func);
        if confidence > 0.7 {
            let pattern = Pattern::new(template, variables, confidence);
            self.store.save(&pattern).await?;
        }
    }
    
    Ok(CrystallizedSkill::new(exec))
}
```
