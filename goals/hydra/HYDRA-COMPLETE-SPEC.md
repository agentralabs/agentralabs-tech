# HYDRA COMPLETE SPECIFICATION

> **Status:** Canonical
> **Version:** 1.0
> **Date:** February 2026

---

## Executive Summary

Hydra is a **proof-carrying, compile-to-action agent runtime** that serves as the orchestration layer for the AgenticOS ecosystem. It consumes the 4 sister libraries (Memory, Vision, Codebase, Identity) and provides a unified interface for agent control, safety, and observability.

### Core Principles

```
1. LOWEST TOKEN COST      → Compile actions, don't prompt for them
2. PROOF-CARRYING         → Every action must prove it's safe + intended
3. LOCAL-FIRST            → Zero API cost by default
4. SISTER-INTEGRATED      → .amem, .avis, .acb, .aid are the storage layer
5. UNIVERSAL SKILL LAYER  → Run any skill (OpenClaw, MCP, custom)
6. FULL OBSERVABILITY     → Receipt for every action, replay any run
7. SECURITY-FIRST         → Capability-based, sandboxed, auditable
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              HYDRA PLATFORM                                  │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                        PRODUCT SURFACES                                 │ │
│  │                                                                         │ │
│  │   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │ │
│  │   │   CLI   │  │ VSCode  │  │ Console │  │  Voice  │  │  Remote │    │ │
│  │   │         │  │  Ext    │  │   UI    │  │ Console │  │ Control │    │ │
│  │   └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
│                                      ▼                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                          HYDRA CORE                                     │ │
│  │                                                                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │ │
│  │  │ Run Manager  │  │  Scheduler   │  │ Model Router │                 │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                 │ │
│  │                                                                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │ │
│  │  │  Capability  │  │   Policy     │  │  Execution   │                 │ │
│  │  │   Engine     │  │   Engine     │  │    Gate      │                 │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                 │ │
│  │                                                                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │ │
│  │  │   Receipt    │  │   Replay     │  │    Kill      │                 │ │
│  │  │   Ledger     │  │   Engine     │  │   Switch     │                 │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                 │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
│                                      ▼                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         SKILL FABRIC                                    │ │
│  │                                                                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │ │
│  │  │   Compiler   │  │   Router     │  │   Grader     │                 │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                 │ │
│  │                                                                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │ │
│  │  │   Adapters   │  │  Enhancers   │  │  Executors   │                 │ │
│  │  │ (OpenClaw,   │  │  (Safety,    │  │  (Sandbox,   │                 │ │
│  │  │  MCP, etc)   │  │   Cache)     │  │   Evidence)  │                 │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                 │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
│                                      ▼                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                        SAFETY LAYER                                     │ │
│  │                                                                         │ │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐         │ │
│  │  │  Risk   │ │Injection│ │ Command │ │ Network │ │ Anomaly │         │ │
│  │  │ Scorer  │ │  Guard  │ │  Guard  │ │  Guard  │ │Detector │         │ │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘         │ │
│  │                                                                         │ │
│  │  ┌─────────────────────┐  ┌─────────────────────┐                      │ │
│  │  │  Shadow Simulator   │  │ Containment Manager │                      │ │
│  │  └─────────────────────┘  └─────────────────────┘                      │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
│                                      ▼                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                      SISTER INTEGRATION                                 │ │
│  │                                                                         │ │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │ │
│  │  │   Memory    │ │   Vision    │ │  Codebase   │ │  Identity   │      │ │
│  │  │   Bridge    │ │   Bridge    │ │   Bridge    │ │   Bridge    │      │ │
│  │  │   (.amem)   │ │   (.avis)   │ │   (.acb)    │ │   (.aid)    │      │ │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘      │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. HYDRA CORE

### 1.1 Run Manager

The central state machine for all agent runs.

```
hydra_core/
├── run_manager/
│   ├── run_state_machine/
│   │   ├── states/
│   │   │   ├── pending         # Run created, not started
│   │   │   ├── planning        # Generating plan
│   │   │   ├── executing       # Running steps
│   │   │   ├── awaiting_approval # Paused for human
│   │   │   ├── completed       # Successfully finished
│   │   │   ├── failed          # Error occurred
│   │   │   ├── frozen          # User paused
│   │   │   └── killed          # Emergency stopped
│   │   │
│   │   ├── transitions/
│   │   │   ├── start()         # pending → planning
│   │   │   ├── plan_ready()    # planning → executing
│   │   │   ├── need_approval() # executing → awaiting_approval
│   │   │   ├── approve()       # awaiting_approval → executing
│   │   │   ├── deny()          # awaiting_approval → failed
│   │   │   ├── complete()      # executing → completed
│   │   │   ├── error()         # any → failed
│   │   │   ├── freeze()        # any → frozen
│   │   │   ├── resume()        # frozen → previous state
│   │   │   └── kill()          # any → killed
│   │   │
│   │   └── guards/
│   │       ├── can_transition()
│   │       └── validate_state()
│   │
│   ├── checkpoints/
│   │   ├── checkpoint_writer/    # Save state at key points
│   │   ├── checkpoint_loader/    # Resume from checkpoint
│   │   └── checkpoint_pruner/    # Clean old checkpoints
│   │
│   └── run_metadata/
│       ├── run_id              # Unique identifier
│       ├── created_at          # Timestamp
│       ├── intent              # Original user request
│       ├── plan                # Generated plan
│       ├── current_step        # Progress
│       ├── total_tokens        # Cost tracking
│       └── receipts            # Action receipts
```

### 1.2 Scheduler

Manages step execution with retries and timeouts.

```
hydra_core/
├── scheduler/
│   ├── step_queue/
│   │   ├── priority_queue/       # High priority first
│   │   ├── dependency_graph/     # Step dependencies
│   │   └── deduplicator/         # No duplicate steps
│   │
│   ├── retry_policy/
│   │   ├── max_retries: 3        # Per step
│   │   ├── backoff: exponential  # 1s, 2s, 4s
│   │   ├── retry_conditions/     # When to retry
│   │   └── give_up_action/       # What to do when exhausted
│   │
│   ├── timeout_policy/
│   │   ├── step_timeout: 60s     # Per step max
│   │   ├── run_timeout: 30m      # Total run max
│   │   └── timeout_action/       # Fail or escalate
│   │
│   └── concurrency_limits/
│       ├── max_parallel_steps: 3
│       ├── max_parallel_runs: 5
│       └── resource_locks/       # Prevent conflicts
```

### 1.3 Model Router

Routes LLM requests to minimize cost.

```
hydra_core/
├── model_router/
│   ├── provider_selection/
│   │   ├── local_models/
│   │   │   ├── llama_7b          # Simple tasks
│   │   │   ├── mistral_7b        # Code tasks
│   │   │   └── phi_3             # Tiny tasks
│   │   │
│   │   ├── api_models/
│   │   │   ├── claude_haiku      # Cheap, fast
│   │   │   ├── claude_sonnet     # Balanced
│   │   │   └── claude_opus       # Complex only
│   │   │
│   │   └── selection_rules/
│   │       ├── task_classifier/  # What kind of task?
│   │       ├── complexity_scorer/# How hard?
│   │       └── model_matcher/    # Pick best fit
│   │
│   ├── token_budgeting/
│   │   ├── per_step_budget/      # Max tokens per step
│   │   ├── per_run_budget/       # Max tokens per run
│   │   └── budget_enforcer/      # Block if over budget
│   │
│   ├── context_packager/
│   │   ├── context_selector/     # What to include
│   │   ├── context_compressor/   # Minimize tokens
│   │   └── context_cacher/       # Reuse contexts
│   │
│   └── cost_accounting/
│       ├── token_counter/        # Track usage
│       ├── cost_calculator/      # Tokens → dollars
│       ├── savings_tracker/      # What we avoided
│       └── cost_reporter/        # Generate reports
```

### 1.4 Capability Engine

Least-privilege permission system.

```
hydra_core/
├── capability_engine/
│   ├── capability_tokens/
│   │   ├── token_generator/      # Create capability tokens
│   │   ├── token_validator/      # Check validity
│   │   └── token_revocation/     # Invalidate tokens
│   │
│   ├── scope_definitions/
│   │   ├── file_read            # Read specific paths
│   │   ├── file_write           # Write specific paths
│   │   ├── network_access       # Access specific domains
│   │   ├── browser_control      # Browser automation
│   │   ├── terminal_exec        # Run commands
│   │   ├── send_message         # External communication
│   │   └── custom_scopes        # User-defined
│   │
│   ├── ttl_grants/
│   │   ├── grant_creator/        # Create time-limited grants
│   │   ├── expiration_checker/   # Check if expired
│   │   └── renewal_handler/      # Extend if needed
│   │
│   └── auto_grant_rules/
│       ├── basic_mode_rules/     # Auto-grant low risk
│       ├── advanced_mode_rules/  # Require explicit
│       └── policy_overrides/     # Custom rules
```

### 1.5 Policy Engine

Risk-based approval rules.

```
hydra_core/
├── policy_engine/
│   ├── risk_based_prompts/
│   │   ├── risk_levels/
│   │   │   ├── low (0.0-0.3)     # Auto-execute
│   │   │   ├── medium (0.3-0.6)  # Soft confirm
│   │   │   ├── high (0.6-0.8)    # Hard confirm
│   │   │   └── critical (0.8-1.0)# Challenge phrase
│   │   │
│   │   └── prompt_templates/
│   │       ├── action_summary/
│   │       ├── risk_explanation/
│   │       └── approval_options/
│   │
│   ├── approval_rules/
│   │   ├── always_approve/       # Allowlist
│   │   ├── always_deny/          # Blocklist
│   │   ├── conditional/          # Context-dependent
│   │   └── escalation/           # To human
│   │
│   ├── policy_profiles/
│   │   ├── cautious/             # Maximum safety
│   │   ├── balanced/             # Default
│   │   ├── permissive/           # Minimal prompts
│   │   └── custom/               # User-defined
│   │
│   └── policy_versioning/
│       ├── policy_per_run/       # Pin policy to run
│       └── policy_audit/         # Track changes
```

### 1.6 Execution Gate

The central checkpoint for all actions.

```
hydra_core/
├── execution_gate/
│   ├── preflight_validator/
│   │   ├── capability_check/     # Has permission?
│   │   ├── policy_check/         # Allowed by policy?
│   │   ├── proof_check/          # Evidence provided?
│   │   └── risk_check/           # Within risk tolerance?
│   │
│   ├── tool_dispatch/
│   │   ├── skill_router/         # Route to skill
│   │   ├── sandbox_wrapper/      # Execute in sandbox
│   │   └── result_validator/     # Check output
│   │
│   └── escalation_flow/
│       ├── approval_requester/   # Ask human
│       ├── timeout_handler/      # If no response
│       └── denial_handler/       # If denied
```

### 1.7 Isolation Runtime

Sandboxed execution environments.

```
hydra_core/
├── isolation_runtime/
│   ├── sandbox_profiles/
│   │   ├── minimal/              # Most restricted
│   │   ├── standard/             # Default
│   │   ├── extended/             # More access
│   │   └── custom/               # User-defined
│   │
│   ├── browser_sandbox/
│   │   ├── isolated_profile/     # Separate browser profile
│   │   ├── network_filter/       # Allowed domains only
│   │   ├── storage_isolation/    # No cookie leakage
│   │   └── resource_limits/      # CPU/memory caps
│   │
│   ├── terminal_sandbox/
│   │   ├── command_filter/       # Block dangerous commands
│   │   ├── env_isolation/        # Clean environment
│   │   ├── path_restrictions/    # Limited filesystem
│   │   └── output_limits/        # Max output size
│   │
│   └── filesystem_sandbox/
│       ├── allowed_paths/        # Whitelist
│       ├── denied_paths/         # Blacklist
│       ├── read_only_paths/      # Can read, not write
│       └── temp_workspace/       # Isolated temp dir
```

### 1.8 Receipt Ledger

Immutable action history.

```
hydra_core/
├── receipt_ledger/
│   ├── hash_chain/
│   │   ├── genesis_receipt/      # First receipt
│   │   ├── chain_appender/       # Add to chain
│   │   ├── chain_validator/      # Verify integrity
│   │   └── chain_repairer/       # Fix broken chain
│   │
│   ├── receipt_schema/
│   │   ├── receipt_id            # Unique ID
│   │   ├── previous_hash         # Chain link
│   │   ├── timestamp             # When
│   │   ├── run_id                # Which run
│   │   ├── step_id               # Which step
│   │   ├── action_type           # What kind
│   │   ├── inputs                # What went in
│   │   ├── outputs               # What came out
│   │   ├── evidence_refs         # Proof pointers
│   │   ├── capability_used       # Permission used
│   │   ├── risk_score            # Risk at time
│   │   ├── approval_id           # If approved
│   │   └── signature             # Cryptographic sig
│   │
│   ├── receipt_writer/
│   │   ├── atomic_append/        # Write atomically
│   │   ├── sync_to_identity/     # Sign with .aid
│   │   └── replication/          # Backup copies
│   │
│   └── receipt_query/
│       ├── by_run/               # Receipts for run
│       ├── by_action_type/       # Receipts by type
│       ├── by_time_range/        # Receipts in period
│       └── full_text_search/     # Search contents
```

### 1.9 Replay Engine

Reproduce past runs.

```
hydra_core/
├── replay_engine/
│   ├── decision_replay/
│   │   ├── load_run/             # Load run data
│   │   ├── step_through/         # Go step by step
│   │   ├── decision_points/      # Show choices made
│   │   └── alternative_paths/    # What could have happened
│   │
│   ├── action_replay_best_effort/
│   │   ├── reversible_actions/   # Can actually redo
│   │   ├── simulated_actions/    # Show what would happen
│   │   └── blocked_actions/      # Won't redo (irreversible)
│   │
│   ├── replay_safety_rules/
│   │   ├── require_approval/     # Even in replay
│   │   ├── dry_run_default/      # Don't execute by default
│   │   └── scope_limits/         # Can't expand permissions
│   │
│   └── replay_ui_hooks/
│       ├── timeline_sync/        # UI follows replay
│       ├── evidence_display/     # Show evidence at each point
│       └── comparison_mode/      # Compare original vs replay
```

### 1.10 Kill Switch

Emergency stop mechanisms.

```
hydra_core/
├── kill_switch/
│   ├── freeze_run/
│   │   ├── immediate_pause/      # Stop current action
│   │   ├── state_snapshot/       # Save current state
│   │   └── resumable/            # Can continue later
│   │
│   ├── revoke_all_capabilities/
│   │   ├── global_revoke/        # All capabilities
│   │   ├── per_run_revoke/       # Specific run
│   │   └── per_scope_revoke/     # Specific scope
│   │
│   └── emergency_stop_hooks/
│       ├── cli_trigger/          # hydra kill
│       ├── voice_trigger/        # "Hydra stop"
│       ├── ui_trigger/           # Red button
│       ├── api_trigger/          # Remote kill
│       └── watchdog_trigger/     # Automatic if hung
```

### 1.11 Consolidation Daemon

Background maintenance.

```
hydra_core/
├── consolidation_daemon/
│   ├── memory_consolidation/
│   │   ├── strengthen_frequently_accessed/
│   │   ├── decay_unused_memories/
│   │   └── merge_related_memories/
│   │
│   ├── index_reorganization/
│   │   ├── defragment_graphs/
│   │   ├── optimize_query_paths/
│   │   └── prune_dead_references/
│   │
│   ├── self_diagnostics/
│   │   ├── sister_health_checks/
│   │   ├── storage_metrics/
│   │   └── consistency_validation/
│   │
│   └── garbage_collection/
│       ├── orphan_evidence_cleanup/
│       ├── stale_session_removal/
│       └── receipt_archival/
```

---

## 2. SAFETY LAYER

### 2.1 Risk Scoring

Multi-factor risk assessment.

```
safety/
├── risk_scoring/
│   ├── risk_model/
│   │   ├── base_risk/            # Action type inherent risk
│   │   ├── context_risk/         # Current situation
│   │   ├── history_risk/         # Past patterns
│   │   └── combination_risk/     # Multiple factors
│   │
│   ├── signal_fusion/
│   │   ├── weighted_combination/
│   │   ├── anomaly_boost/        # Increase if anomalous
│   │   └── trust_discount/       # Decrease if trusted
│   │
│   └── thresholds/
│       ├── auto_execute: 0.3
│       ├── soft_confirm: 0.6
│       ├── hard_confirm: 0.8
│       └── block: 0.95
```

### 2.2 Guards

Pre-execution safety checks.

```
safety/
├── injection_guard/
│   ├── untrusted_content_rules/
│   │   ├── detect_prompt_injection/
│   │   ├── detect_hidden_text/
│   │   └── detect_instruction_override/
│   │
│   ├── prompt_injection_signals/
│   │   ├── "ignore previous"
│   │   ├── "new instructions"
│   │   ├── "paste secrets"
│   │   └── base64_encoded_commands
│   │
│   └── reader_decider_boundary/
│       ├── separate_reading_context/
│       └── no_execute_from_read/

├── command_guard/
│   ├── classifier/
│   │   ├── destructive/          # rm, drop, delete
│   │   ├── privilege_escalation/ # sudo, chmod
│   │   ├── network_exfil/        # curl, wget to unknown
│   │   └── persistence/          # cron, startup scripts
│   │
│   ├── destructive_patterns/
│   │   ├── "rm -rf"
│   │   ├── ":(){ :|:& };:"       # Fork bomb
│   │   ├── "dd if=/dev"
│   │   └── "mkfs"
│   │
│   └── escalation_rules/
│       ├── block_by_default/
│       └── require_explicit_approval/

├── network_guard/
│   ├── redirect_detector/
│   │   ├── detect_meta_refresh/
│   │   ├── detect_js_redirect/
│   │   └── detect_url_shorteners/
│   │
│   ├── lookalike_domains/
│   │   ├── typosquatting_check/
│   │   ├── homoglyph_check/
│   │   └── domain_reputation/
│   │
│   └── destination_allowlists/
│       ├── user_defined/
│       ├── skill_declared/
│       └── learned_safe/
```

### 2.3 Anomaly Detector

Runtime behavior monitoring.

```
safety/
├── anomaly_detector/
│   ├── behavior_signals/
│   │   ├── action_frequency/     # Too many actions?
│   │   ├── scope_creep/          # Accessing more than needed?
│   │   ├── time_anomaly/         # Unusual timing?
│   │   └── pattern_deviation/    # Different from normal?
│   │
│   ├── burst_detection/
│   │   ├── rate_monitor/
│   │   ├── burst_threshold/
│   │   └── burst_response/       # Slow down or stop
│   │
│   ├── mass_io_detection/
│   │   ├── file_count_monitor/
│   │   ├── byte_count_monitor/
│   │   └── io_rate_limiter/
│   │
│   └── ui_drift_detection/
│       ├── fingerprint_comparison/
│       ├── unexpected_elements/
│       └── missing_elements/
```

### 2.4 Shadow Simulator

Simulate before execute.

```
safety/
├── shadow_simulator/
│   ├── ghost_runner/
│   │   ├── isolated_environment/ # Can't affect real
│   │   ├── action_predictor/     # Predict outcomes
│   │   └── evidence_gatherer/    # Collect proof
│   │
│   ├── confidence_scoring/
│   │   ├── prediction_confidence/
│   │   ├── risk_estimate/
│   │   └── proceed_threshold/
│   │
│   └── simulate_then_execute/
│       ├── simulation_report/
│       ├── user_confirmation/
│       └── real_execution/
```

### 2.5 Containment Manager

Respond to threats.

```
safety/
├── containment_manager/
│   ├── freeze_on_risk/
│   │   ├── risk_threshold_trigger/
│   │   ├── immediate_freeze/
│   │   └── alert_user/
│   │
│   ├── capability_downgrade/
│   │   ├── reduce_permissions/
│   │   ├── restricted_mode/
│   │   └── recovery_path/
│   │
│   ├── quarantine_module/
│   │   ├── isolate_run/
│   │   ├── prevent_spread/
│   │   └── forensic_capture/
│   │
│   └── incident_receipts/
│       ├── incident_record/
│       ├── evidence_bundle/
│       └── report_generator/
```

---

## 3. INTELLIGENCE LAYER

### 3.1 Action Compiler

Compile repeated patterns to zero-LLM execution.

```
intelligence/
├── action_compiler/
│   ├── pattern_detector/
│   │   ├── sequence_hasher/      # Normalize sequences
│   │   ├── similarity_scorer/    # Compare sequences
│   │   ├── frequency_counter/    # How often?
│   │   └── stability_checker/    # Consistent pattern?
│   │
│   ├── compiler/
│   │   ├── ast_generator/        # Sequence → AST
│   │   ├── variable_extractor/   # Find dynamic parts
│   │   ├── template_generator/   # Parameterized template
│   │   └── code_emitter/         # Generate executable
│   │
│   ├── compiled_store/
│   │   ├── action_index/         # Lookup by intent
│   │   ├── versioning/           # Track changes
│   │   └── invalidation/         # When to recompile
│   │
│   └── execution_router/
│       ├── compiled_check/       # Can use compiled?
│       ├── confidence_gate/      # Sure enough?
│       └── fallback_to_llm/      # If not confident
```

### 3.2 Intention Anchor

Prevent goal drift.

```
intelligence/
├── intention_anchor/
│   ├── intent_extractor/
│   │   ├── goal_parser/          # NL → structured goal
│   │   ├── success_criteria/     # What is "done"?
│   │   └── scope_boundaries/     # What's out of scope?
│   │
│   ├── trajectory_tracker/
│   │   ├── step_analyzer/        # What did step do?
│   │   ├── cumulative_direction/ # Overall trajectory
│   │   └── drift_calculator/     # Distance from anchor
│   │
│   └── realignment/
│       ├── drift_alert/          # Warn user
│       ├── refocus_prompt/       # Guide back
│       └── goal_updater/         # If user wants to change
```

### 3.3 Context Gravity

Pre-load related context.

```
intelligence/
├── context_gravity/
│   ├── topic_extractor/
│   │   ├── keyword_extraction/
│   │   ├── entity_recognition/
│   │   └── domain_detection/
│   │
│   ├── gravity_map/
│   │   ├── co_occurrence_graph/  # What appears together
│   │   ├── user_associations/    # User's patterns
│   │   └── decay_weights/        # Recent > old
│   │
│   └── preloader/
│       ├── background_fetch/     # Non-blocking
│       ├── cache_manager/        # Store preloaded
│       └── relevance_ranker/     # Prioritize
```

### 3.4 Skill Intelligence

Learn from skill execution.

```
intelligence/
├── skill_intelligence/
│   ├── grader/
│   │   ├── success_rate/         # % successful
│   │   ├── latency_stats/        # p50, p95, p99
│   │   ├── token_cost/           # Average cost
│   │   └── grade_calculator/     # A/B/C/D/F
│   │
│   ├── fusioner/
│   │   ├── co_occurrence_tracker/
│   │   ├── compound_generator/
│   │   └── fusion_validator/
│   │
│   ├── failure_genealogy/
│   │   ├── failure_capture/
│   │   ├── fix_tracker/
│   │   └── lineage_tree/
│   │
│   └── router/
│       ├── intent_matcher/
│       ├── grade_ranker/
│       └── fallback_chain/
```

---

## 4. SISTER INTEGRATION

```
sister_bindings/
├── memory_bridge/
│   ├── session_to_run/           # Map runs to sessions
│   ├── artifact_to_memory/       # Store artifacts as memories
│   ├── context_loader/           # Load relevant memories
│   └── memory_methods/
│       ├── memory_add()
│       ├── memory_query()
│       ├── memory_ground()
│       └── memory_session_resume()

├── vision_bridge/
│   ├── capture_to_evidence/      # Screenshots → evidence
│   ├── diff_to_vision/           # Diffs stored in vision
│   ├── screenshot_store/         # Store in .avis
│   └── vision_methods/
│       ├── vision_capture()
│       ├── vision_compare()
│       ├── vision_ground()
│       └── vision_similar()

├── codebase_bridge/
│   ├── change_to_graph/          # Code changes → graph
│   ├── impact_checker/           # Pre-change impact
│   ├── prophecy_risk/            # Risk from prophecy
│   └── codebase_methods/
│       ├── codebase_query()
│       ├── codebase_impact()
│       ├── codebase_ground()
│       └── codebase_workspace()

└── identity_bridge/
    ├── receipt_signer/           # Sign receipts
    ├── capability_mapper/        # Map to trust grants
    ├── continuity_link/          # Link to identity chain
    └── identity_methods/
        ├── identity_sign()
        ├── identity_verify()
        ├── identity_trust()
        └── identity_ground()
```

---

## 5. PRODUCT SURFACES

### 5.1 CLI

```
product_surfaces/
├── cli/
│   ├── commands/
│   │   ├── run/
│   │   │   ├── hydra "<natural language>"
│   │   │   └── hydra run task.yaml
│   │   │
│   │   ├── control/
│   │   │   ├── hydra approve <run_id>
│   │   │   ├── hydra deny <run_id>
│   │   │   ├── hydra freeze [run_id]
│   │   │   ├── hydra resume <run_id>
│   │   │   └── hydra kill [run_id]
│   │   │
│   │   ├── inspect/
│   │   │   ├── hydra inspect [run_id]
│   │   │   ├── hydra timeline [run_id]
│   │   │   ├── hydra evidence [run_id]
│   │   │   ├── hydra diff <run_id>
│   │   │   └── hydra cost [run_id]
│   │   │
│   │   ├── replay/
│   │   │   └── hydra replay <run_id>
│   │   │
│   │   ├── remote/
│   │   │   ├── hydra remote enable
│   │   │   ├── hydra remote qr
│   │   │   └── hydra remote devices
│   │   │
│   │   └── config/
│   │       ├── hydra policy set <profile>
│   │       ├── hydra voice enable
│   │       └── hydra config show
│   │
│   └── renderers/
│       ├── timeline_view/
│       ├── evidence_view/
│       ├── cost_view/
│       └── approval_card/
```

### 5.2 Console UI

```
product_surfaces/
├── console_ui/
│   ├── layout/
│   │   ├── left_panel/           # Plan
│   │   ├── center_panel/         # Timeline
│   │   └── right_panel/          # Evidence
│   │
│   ├── views/
│   │   ├── runs_list/
│   │   ├── run_detail/
│   │   ├── replay_controls/
│   │   └── evidence_viewer/
│   │
│   └── components/
│       ├── approval_modal/
│       ├── cost_chart/
│       ├── diff_viewer/
│       └── timeline_step/
```

### 5.3 Voice Console

```
product_surfaces/
├── voice_console/
│   ├── asr/
│   │   ├── whisper_local/        # Local STT
│   │   └── wake_word/            # "Hey Hydra"
│   │
│   ├── tts/
│   │   ├── piper_local/          # Local TTS
│   │   └── voice_selection/
│   │
│   ├── voice_commands/
│   │   ├── approve_deny/
│   │   ├── stop_freeze/
│   │   ├── explain/
│   │   └── what_changed/
│   │
│   └── approval_protocol/
│       ├── challenge_phrase/     # High risk
│       └── confirmation/         # Standard
```

---

## 6. RUN CONTRACT

All surfaces render the same data.

```
run_artifacts/
├── run_summary.json              # Metadata + status
├── plan.json                     # Human-readable plan
├── timeline.jsonl                # Append-only events
├── receipts.jsonl                # Action receipts
├── evidence_index.json           # Evidence pointers
├── diff_index.json               # Diff pointers
├── cost_report.json              # Token/cost breakdown
└── approvals.jsonl               # Approval records
```

### Event Types

```
RUN_STARTED
PLAN_GENERATED
STEP_STARTED
OBSERVATION_CAPTURED
ACTION_PROPOSED
APPROVAL_REQUIRED
APPROVED
DENIED
ACTION_EXECUTED
RECEIPT_WRITTEN
EVIDENCE_CAPTURED
STEP_COMPLETED
STEP_FAILED
RUN_COMPLETED
RUN_FAILED
RUN_FROZEN
RUN_KILLED
ANOMALY_DETECTED
CONTAINMENT_TRIGGERED
```

---

## 7. REMOTE ACCESS

```
remote/
├── transports/
│   ├── tailscale/                # Recommended
│   ├── direct_https/             # Port forward
│   ├── ssh_tunnel/               # Classic
│   ├── self_hosted_relay/        # Full control
│   └── tor_hidden/               # Maximum privacy
│
├── auth/
│   ├── token_manager/
│   ├── device_registry/
│   └── identity_link/            # Via .aid
│
└── voice_remote/
    ├── mumble_server/            # Self-hosted voice
    └── sip_bridge/               # VoIP
```

---

## 8. DEPLOYMENT MODES

```
deployment/
├── local_mode/
│   ├── single_process/           # Everything in one
│   ├── minimal_resources/        # Low memory mode
│   └── offline_capable/          # No network needed

├── desktop_mode/
│   ├── system_tray/              # Background daemon
│   ├── auto_start/               # Start with system
│   └── native_integration/       # OS notifications

├── server_mode/
│   ├── headless/                 # No UI
│   ├── multi_user/               # Multiple users
│   └── api_only/                 # HTTP API

└── container_mode/
    ├── docker/                   # Container image
    ├── kubernetes/               # K8s deployment
    └── cloud_functions/          # Serverless
```

---

## 9. METRICS

### Token Efficiency

```
• Tokens used per run
• Tokens saved per run
• Cache hit rate
• Compiled action usage rate
• Local vs API model ratio
```

### Safety

```
• Approvals requested
• Approvals granted/denied
• Risk scores distribution
• Anomalies detected
• Containment events
```

### Performance

```
• Steps per minute
• Latency p50/p95/p99
• Skill success rates
• Skill grades
```

---

*Document Version: 1.0*
*Status: Canonical*
