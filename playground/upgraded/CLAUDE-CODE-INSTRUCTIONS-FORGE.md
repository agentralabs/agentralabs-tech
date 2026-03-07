# CLAUDE-CODE-INSTRUCTIONS-FORGE.md

**Sister:** AgenticForge  
**Role:** Blueprint Engine — Complete project architecture BEFORE any code generation  
**Working Directory:** `/Users/omoshola/Documents/agentralabs-tech/agentic-forge`  
**Priority:** #1 MOST CRITICAL

---

## BENCHMARK TARGETS

| Metric | Target |
|--------|--------|
| Tests | 300+ |
| MCP Tools | 15 |
| Inventions | 32 |
| CLI Commands | 40+ |
| MCP Unwraps | 0 |
| Doc Pages | 12 |
| SVG Diagrams | 4 |

---

## WHAT FORGE DOES

Forge creates COMPLETE project blueprints (all files, types, signatures, deps, tests) BEFORE any LLM code generation. The LLM then only fills function bodies within tight constraints, achieving 99% accuracy.

---

## 32 INVENTIONS (8 Tiers × 4)

**TIER 1 - DECOMPOSITION:** Layer Decomposition Engine, Concern Separation Analyzer, Boundary Inference, Cross-Cutting Detector

**TIER 2 - ENTITY:** Entity Inference, Relationship Mapper, Field Derivation Engine, Validation Rule Generator

**TIER 3 - OPERATION:** Operation Inference, Signature Generator, Error Flow Designer, Async/Concurrency Analyzer

**TIER 4 - STRUCTURE:** File Structure Generator, Import Graph Generator, Module Hierarchy Builder, Config Structure Designer

**TIER 5 - DEPENDENCY:** Dependency Inference Engine, Version Resolver, API Specification Extractor, Conflict Resolver

**TIER 6 - BLUEPRINT:** Skeleton Generator, Type-First Materialization, Contract Specification, Generation Order Planner

**TIER 7 - INTEGRATION:** Component Wiring Diagram, Data Flow Specification, Initialization Sequence, Shutdown Sequence

**TIER 8 - TEST:** Test Case Generator, Test Fixture Designer, Integration Test Planner, Mock Specification

---

## PROJECT STRUCTURE

```
agentic-forge/
├── Cargo.toml                    # Workspace root
├── README.md, LICENSE, CHANGELOG.md, SECURITY.md, CONTRIBUTING.md
├── CODE_OF_CONDUCT.md, CLAUDE.md, Makefile, INSTALL.md, GUIDE.md
├── sister.manifest.json
├── .github/workflows/            # ci.yml, release.yml, canonical.yml, install-test.yml, hardening.yml
├── scripts/                      # install.sh, release.sh, check-*.sh (9 scripts)
├── docs/public/                  # 12 doc pages + 4 SVGs
├── crates/
│   ├── agentic-forge-core/       # Types, storage, engine, inventions, bridges
│   ├── agentic-forge-mcp/        # 15 MCP tools, validator, server
│   ├── agentic-forge-cli/        # 40+ commands
│   └── agentic-forge-ffi/        # C FFI + Python bindings
├── tests/                        # unit/, integration/, mcp/, stress/
├── examples/                     # 4 examples
└── paper/                        # Research paper
```

---

## 15 MCP TOOLS

```
1. forge_blueprint_create      - Create blueprint from intent
2. forge_blueprint_get         - Get blueprint by ID
3. forge_blueprint_update      - Update existing blueprint
4. forge_blueprint_validate    - Validate blueprint is buildable
5. forge_blueprint_list        - List all blueprints
6. forge_entity_add            - Add entity to blueprint
7. forge_entity_infer          - Infer entities from description
8. forge_dependency_resolve    - Resolve all dependencies
9. forge_dependency_add        - Add dependency manually
10. forge_structure_generate   - Generate file structure
11. forge_skeleton_create      - Create code skeletons
12. forge_test_generate        - Generate test architecture
13. forge_import_graph         - Generate import graph
14. forge_wiring_create        - Create component wiring
15. forge_export               - Export blueprint to files
```

---

## PHASE 1: WORKSPACE SETUP

```bash
cd /Users/omoshola/Documents/agentralabs-tech
mkdir -p agentic-forge/crates/{agentic-forge-core,agentic-forge-mcp,agentic-forge-cli,agentic-forge-ffi}/src
cd agentic-forge
```

Create `Cargo.toml`:
```toml
[workspace]
resolver = "2"
members = ["crates/agentic-forge-core", "crates/agentic-forge-mcp", "crates/agentic-forge-cli", "crates/agentic-forge-ffi"]

[workspace.package]
version = "0.1.0"
edition = "2021"
license = "MIT"
repository = "https://github.com/agentra/agentic-forge"

[workspace.dependencies]
agentic-forge-core = { path = "crates/agentic-forge-core" }
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

Create these modules in `crates/agentic-forge-core/src/types/`:

- `mod.rs` - Module exports
- `ids.rs` - ForgeId, BlueprintId, EntityId, OperationId, FileId, DependencyId, TestCaseId
- `error.rs` - ForgeError enum with error codes
- `intent.rs` - IntentSpec, Domain, EntitySpec, FieldSpec, OperationSpec, Constraint
- `blueprint.rs` - Blueprint, FileBlueprint, TypeDefinition, FunctionBlueprint, Dependency, TestCase

**CHECKPOINT:** `cargo build` passes, types compile

---

## PHASE 3: STORAGE (src/storage/)

Create these modules in `crates/agentic-forge-core/src/storage/`:

- `mod.rs` - Module exports
- `format.rs` - ForgeHeader (256 bytes), ForgeFooter (64 bytes), Section, SectionType
- `store.rs` - BlueprintStore with save/load/delete/list

**CHECKPOINT:** `cargo test storage::` passes (10+ tests)

---

## PHASE 4: ENGINE (src/engine/)

Create these modules in `crates/agentic-forge-core/src/engine/`:

- `mod.rs` - Module exports
- `write.rs` - WriteEngine (50+ mutation operations)
- `query.rs` - QueryEngine (40+ read operations)  
- `validator.rs` - BlueprintValidator

Key operations:
- WriteEngine: create_blueprint, add_entity, add_field, add_operation, add_file, add_dependency, add_test, update_*, delete_*
- QueryEngine: get_blueprint, get_entity, get_file, list_*, search_*, validate_*

**CHECKPOINT:** `cargo test engine::` passes (60+ tests)

---

## PHASE 5: INVENTIONS (src/inventions/)

Create 8 tier files implementing all 32 inventions:

- `tier1_decomposition.rs` - LayerDecomposer, ConcernAnalyzer, BoundaryInferrer, CrossCuttingDetector
- `tier2_entity.rs` - EntityInferrer, RelationshipMapper, FieldDeriver, ValidationRuleGenerator
- `tier3_operation.rs` - OperationInferrer, SignatureGenerator, ErrorFlowDesigner, AsyncAnalyzer
- `tier4_structure.rs` - FileStructureGenerator, ImportGraphGenerator, ModuleHierarchyBuilder, ConfigDesigner
- `tier5_dependency.rs` - DependencyInferrer, VersionResolver, ApiSpecExtractor, ConflictResolver
- `tier6_blueprint.rs` - SkeletonGenerator, TypeFirstMaterializer, ContractSpecifier, GenerationPlanner
- `tier7_integration.rs` - WiringDiagramBuilder, DataFlowSpecifier, InitSequencer, ShutdownSequencer
- `tier8_test.rs` - TestCaseGenerator, TestFixtureDesigner, IntegrationTestPlanner, MockSpecifier

**CHECKPOINT:** `cargo test inventions::` passes (80+ tests)

---

## PHASE 6: BRIDGES (src/bridges/)

Create bridge traits for all sisters:

- `traits.rs` - ForgeBridge, AegisBridge, EvolveBridge, VeritasBridge traits
- `noop.rs` - NoOp implementations for standalone mode
- `hydra.rs` - HydraAdapter for orchestration
- `foundation.rs` - Re-export foundation sister bridges from agentic-sdk

**CHECKPOINT:** `cargo test bridges::` passes (20+ tests)

---

## PHASE 7: MCP SERVER (crates/agentic-forge-mcp/)

Create strict MCP server with 15 tools:

- `main.rs` - Entry point, stdio JSON-RPC
- `server.rs` - Request handler, tool dispatcher
- `validator.rs` - McpValidator (strict, no silent fallbacks)
- `tools/` - One file per tool category

**CRITICAL:** Zero `.unwrap()` in MCP code. All errors return proper MCP error responses.

**CHECKPOINT:** `cargo test -p agentic-forge-mcp` passes (100+ tests)

---

## PHASE 8: CLI (crates/agentic-forge-cli/)

Create 40+ CLI commands using clap:

```
aforge blueprint create/get/list/validate/export
aforge entity add/infer/list
aforge dependency resolve/add/list
aforge structure generate
aforge skeleton create
aforge test generate
aforge serve
aforge info/version
```

**CHECKPOINT:** `cargo test -p agentic-forge-cli` passes (40+ tests)

---

## PHASE 9: FFI (crates/agentic-forge-ffi/)

Create C FFI and Python bindings:

- `c_api.rs` - C-compatible functions
- `include/agentic_forge.h` - C header (generated by cbindgen)
- `python/` - Python wrapper using PyO3 or ctypes

**CHECKPOINT:** `cargo build -p agentic-forge-ffi` produces library

---

## PHASE 10: TESTS (300+)

Create comprehensive test suites:

- `tests/unit/` - Per-module unit tests
- `tests/integration/` - Cross-module integration tests
- `tests/mcp/` - MCP tool tests with strict validation
- `tests/stress/` - Concurrent access, large projects

**CHECKPOINT:** `cargo test --workspace` passes 300+ tests

---

## PHASE 11: DOCS + CI + SCRIPTS

Create all canonical artifacts:

**12 Doc Pages (docs/public/):**
quickstart.md, concepts.md, integration-guide.md, faq.md, benchmarks.md, api-reference.md, architecture.md, cli-reference.md, configuration.md, ffi-reference.md, mcp-tools.md, troubleshooting.md

**4 SVGs (docs/public/)