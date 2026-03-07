# CLAUDE-CODE-INSTRUCTIONS-AEGIS.md

**Sister:** AgenticAegis  
**Role:** Streaming Validation — Validates code DURING generation, not after  
**Working Directory:** `/Users/omoshola/Documents/agentralabs-tech/agentic-aegis`  
**Priority:** #2 HIGH (Enables 99% accuracy by catching errors in real-time)

---

## BENCHMARK TARGETS

| Metric | Target |
|--------|--------|
| Tests | 250+ |
| MCP Tools | 12 |
| Inventions | 20 |
| CLI Commands | 30+ |
| MCP Unwraps | 0 |
| Doc Pages | 12 |
| SVG Diagrams | 4 |

---

## WHAT AEGIS DOES

Aegis validates code AS IT STREAMS from the LLM, catching errors before they compound. It also performs shadow execution before output and protects against malicious inputs.

**Without Aegis:** Generate 500 lines → Check → 23 errors → Restart  
**With Aegis:** Generate line 1 → ✓ → Line 47 → STOP (type mismatch) → Fix → Continue → 0 errors

---

## 20 INVENTIONS (5 Tiers × 4)

**TIER 1 - STREAMING VALIDATION:**
1. Token Stream Validator - Validates each token as it arrives
2. Syntax Accumulator - Builds AST incrementally
3. Type Flow Tracker - Tracks type constraints during generation
4. Error Predictor - Predicts errors before they happen

**TIER 2 - SHADOW EXECUTION:**
5. Shadow Compiler - Compiles code in shadow environment
6. Sandbox Executor - Executes in isolated sandbox
7. Effect Tracker - Tracks side effects
8. Resource Monitor - Monitors resource usage

**TIER 3 - INPUT PROTECTION:**
9. Prompt Injection Detector - Detects manipulation attempts
10. Intent Verifier - Verifies input matches stated intent
11. Payload Scanner - Scans for malicious payloads
12. Rate Limiter - Prevents abuse

**TIER 4 - OUTPUT PROTECTION:**
13. Content Filter - Filters inappropriate content
14. PII Detector - Detects personally identifiable information
15. Code Safety Analyzer - Analyzes code for security issues
16. Output Sanitizer - Sanitizes output before delivery

**TIER 5 - VALIDATION ORCHESTRATION:**
17. Validation Session Manager - Manages validation sessions
18. Correction Hint Generator - Generates hints for fixes
19. Confidence Scorer - Scores confidence in generated code
20. Rollback Engine - Enables rollback on validation failure

---

## PROJECT STRUCTURE

```
agentic-aegis/
├── Cargo.toml
├── README.md, LICENSE, CHANGELOG.md, SECURITY.md, CONTRIBUTING.md
├── CODE_OF_CONDUCT.md, CLAUDE.md, Makefile, INSTALL.md, GUIDE.md
├── sister.manifest.json
├── .github/workflows/            # 5 workflows
├── scripts/                      # 9 scripts
├── docs/public/                  # 12 docs + 4 SVGs
├── crates/
│   ├── agentic-aegis-core/       # Types, validators, shadow, protection
│   ├── agentic-aegis-mcp/        # 12 MCP tools
│   ├── agentic-aegis-cli/        # 30+ commands
│   └── agentic-aegis-ffi/        # C FFI + Python
├── tests/
├── examples/
└── paper/
```

---

## 12 MCP TOOLS

```
1. aegis_validate_streaming    - Validate code chunk during streaming
2. aegis_validate_complete     - Validate complete code block
3. aegis_shadow_execute        - Execute in shadow environment
4. aegis_check_input           - Check input for threats
5. aegis_check_output          - Check output before delivery
6. aegis_session_create        - Create validation session
7. aegis_session_status        - Get session status
8. aegis_session_end           - End validation session
9. aegis_correction_hint       - Get correction hint for error
10. aegis_confidence_score     - Get confidence score
11. aegis_rollback             - Rollback to last valid state
12. aegis_scan_security        - Scan code for security issues
```

---

## PHASE 1: WORKSPACE SETUP

```bash
cd /Users/omoshola/Documents/agentralabs-tech
mkdir -p agentic-aegis/crates/{agentic-aegis-core,agentic-aegis-mcp,agentic-aegis-cli,agentic-aegis-ffi}/src
cd agentic-aegis
```

Create `Cargo.toml`:
```toml
[workspace]
resolver = "2"
members = ["crates/agentic-aegis-core", "crates/agentic-aegis-mcp", "crates/agentic-aegis-cli", "crates/agentic-aegis-ffi"]

[workspace.package]
version = "0.1.0"
edition = "2021"
license = "MIT"
repository = "https://github.com/agentra/agentic-aegis"

[workspace.dependencies]
agentic-aegis-core = { path = "crates/agentic-aegis-core" }
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
tree-sitter = "0.20"  # For incremental parsing
regex = "1.10"
```

**CHECKPOINT:** `cargo build --workspace` passes

---

## PHASE 2: TYPES (src/types/)

Create in `crates/agentic-aegis-core/src/types/`:

- `ids.rs` - AegisId, SessionId, ValidationId
- `error.rs` - AegisError enum
- `validation.rs` - ValidationContext, StreamingValidation, ValidationResult, ValidationError
- `session.rs` - ValidationSession, SessionState, SessionConfig
- `security.rs` - ThreatLevel, SecurityScan, SecurityIssue

Key types:
```rust
pub struct ValidationContext {
    pub session_id: SessionId,
    pub language: Language,
    pub file_path: String,
    pub blueprint_id: Option<String>,
    pub accumulated_code: String,
    pub expected_types: Vec<String>,
}

pub struct StreamingValidation {
    pub valid: bool,
    pub errors: Vec<ValidationError>,
    pub warnings: Vec<ValidationWarning>,
    pub should_stop: bool,
    pub correction_hint: Option<String>,
}
```

**CHECKPOINT:** `cargo build` passes

---

## PHASE 3: VALIDATORS (src/validators/)

Create streaming validators:

- `token_validator.rs` - Validates tokens as they arrive
- `syntax_validator.rs` - Incremental syntax validation using tree-sitter
- `type_validator.rs` - Type flow validation
- `semantic_validator.rs` - Semantic validation

Key trait:
```rust
#[async_trait]
pub trait StreamingValidator: Send + Sync {
    async fn validate_chunk(
        &self,
        context: &ValidationContext,
        chunk: &str,
    ) -> Result<StreamingValidation>;
    
    fn can_continue(&self, validation: &StreamingValidation) -> bool;
}
```

**CHECKPOINT:** `cargo test validators::` passes (40+ tests)

---

## PHASE 4: SHADOW EXECUTION (src/shadow/)

Create shadow execution components:

- `compiler.rs` - ShadowCompiler (compiles in isolated env)
- `executor.rs` - SandboxExecutor (runs in sandbox)
- `tracker.rs` - EffectTracker (tracks side effects)
- `monitor.rs` - ResourceMonitor (monitors resources)

Key struct:
```rust
pub struct ExecutionResult {
    pub success: bool,
    pub stdout: String,
    pub stderr: String,
    pub exit_code: i32,
    pub duration_ms: u64,
    pub resource_usage: ResourceUsage,
}
```

**CHECKPOINT:** `cargo test shadow::` passes (30+ tests)

---

## PHASE 5: PROTECTION (src/protection/)

Create input/output protection:

- `input/prompt_injection.rs` - Detects prompt injection
- `input/intent_verifier.rs` - Verifies intent
- `input/payload_scanner.rs` - Scans payloads
- `output/content_filter.rs` - Filters content
- `output/pii_detector.rs` - Detects PII
- `output/code_safety.rs` - Analyzes code safety

**CHECKPOINT:** `cargo test protection::` passes (40+ tests)

---

## PHASE 6: SESSION MANAGEMENT (src/session/)

Create session management:

- `manager.rs` - SessionManager
- `state.rs` - SessionState machine
- `rollback.rs` - RollbackEngine
- `hints.rs` - CorrectionHintGenerator

**CHECKPOINT:** `cargo test session::` passes (30+ tests)

---

## PHASE 7: BRIDGES (src/bridges/)

Create bridge traits:

- `traits.rs` - AegisBridge trait definition
- `noop.rs` - NoOpAegisBridge for standalone
- `hydra.rs` - HydraAdapter
- `foundation.rs` - Foundation sister bridges

**CHECKPOINT:** `cargo test bridges::` passes (20+ tests)

---

## PHASE 8: MCP SERVER

Create strict MCP server with 12 tools in `crates/agentic-aegis-mcp/`:

- `main.rs`, `server.rs`, `validator.rs`
- `tools/validation.rs` - Validation tools
- `tools/shadow.rs` - Shadow execution tools
- `tools/session.rs` - Session management tools
- `tools/security.rs` - Security scanning tools

**CRITICAL:** Zero `.unwrap()` calls. Strict parameter validation.

**CHECKPOINT:** `cargo test -p agentic-aegis-mcp` passes (80+ tests)

---

## PHASE 9: CLI

Create 30+ commands in `crates/agentic-aegis-cli/`:

```
aegis validate stream/complete/file
aegis shadow execute/compile
aegis session create/status/end/list
aegis scan input/output/code
aegis hint get
aegis rollback
aegis serve
aegis info/version
```

**CHECKPOINT:** `cargo test -p agentic-aegis-cli` passes (30+ tests)

---

## PHASE 10: FFI

Create C FFI and Python bindings in `crates/agentic-aegis-ffi/`

**CHECKPOINT:** Library builds successfully

---

## PHASE 11: TESTS (250+)

- `tests/unit/` - Unit tests
- `tests/integration/` - Integration tests
- `tests/mcp/` - MCP tests with strict validation
- `tests/stress/` - Concurrent validation streams

**CHECKPOINT:** `cargo test --workspace` passes 250+ tests

---

## PHASE 12: DOCS + CI

Create 12 doc pages, 4 SVGs, 5 CI workflows, 9 scripts

**FINAL CHECKPOINT:**
```bash
cargo test --workspace  # 250+ pass
cargo clippy --workspace -- -D warnings  # 0 warnings
./scripts/check-canonical-sister.sh  # All green
```

---

## KEY PATTERNS

### Streaming Validation Pattern
```rust
pub async fn validate_streaming(
    ctx: &ValidationContext,
    chunk: &str,
) -> Result<StreamingValidation> {
    // 1. Append chunk to accumulated code
    let accumulated = format!("{}{}", ctx.accumulated_code, chunk);
    
    // 2. Run incremental parse
    let parse_result = self.parser.parse_incremental(&accumulated)?;
    
    // 3. Check for errors
    if parse_result.has_errors() {
        return Ok(StreamingValidation {
            valid: false,
            should_stop: true,
            errors: parse_result.errors,
            correction_hint: self.generate_hint(&parse_result),
            ..Default::default()
        });
    }
    
    // 4. Check type constraints
    let type_result = self.type_checker.check_incremental(&accumulated)?;
    
    // 5. Return validation result
    Ok(StreamingValidation {
        valid: true,
        should_stop: false,
        ..Default::default()
    })
}
```

### Shadow Execution Pattern
```rust
pub async fn shadow_execute(code: &str, language: &str) -> Result<ExecutionResult> {
    // 1. Create isolated sandbox
    let sandbox = Sandbox::new()?;
    
    // 2. Write code to temp file
    let temp_file = sandbox.write_file("main", code)?;
    
    // 3. Compile (if needed)
    let compile_result = sandbox.compile(&temp_file, language)?;
    if !compile_result.success {
        return Ok(ExecutionResult::compile_failed(compile_result));
    }
    
    // 4. Execute with resource limits
    let exec_result = sandbox.execute_with_limits(
        &compile_result.binary,
        ResourceLimits::default(),
    )?;
    
    // 5. Cleanup and return
    sandbox.cleanup()?;
    Ok(exec_result)
}
```
