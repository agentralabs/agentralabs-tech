# SKILL FABRIC SPECIFICATION

> **Status:** Canonical
> **Version:** 1.0
> **Date:** February 2026

---

## Executive Summary

Skill Fabric is the **universal skill runtime layer** for Hydra. It consumes skills from any source (OpenClaw, MCP, LangChain, custom), enhances them with safety/caching/learning, and compiles repeated patterns into zero-LLM execution.

### Core Principles

```
1. UNIVERSAL CONSUMER    → Run any skill format
2. ENHANCEMENT LAYER     → Make every skill safer, faster, smarter
3. COMPILE TO ACTION     → Repeated patterns need no LLM
4. LEARN FROM EXECUTION  → Skills improve over time
5. PROOF-CARRYING        → Every skill must prove its actions
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            SKILL FABRIC                                      │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                    SKILL DEFINITION LAYER                               │ │
│  │                                                                         │ │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │ │
│  │  │   Schema     │ │   Contract   │ │    Proofs    │ │   Metadata   │  │ │
│  │  │  (inputs/    │ │ (pre/post    │ │ (capability  │ │  (version/   │  │ │
│  │  │   outputs)   │ │  conditions) │ │   evidence)  │ │   grade)     │  │ │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
│                                      ▼                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                    SKILL INTELLIGENCE LAYER                             │ │
│  │                                                                         │ │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │ │
│  │  │   Compiler   │ │   Fusioner   │ │    Router    │ │    Grader    │  │ │
│  │  │  (pattern→   │ │  (combine    │ │  (pick best  │ │  (A/B/C/D/F  │  │ │
│  │  │   compiled)  │ │   skills)    │ │   skill)     │ │   scoring)   │  │ │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
│                                      ▼                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                    SKILL ENHANCEMENT LAYER                              │ │
│  │                                                                         │ │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │ │
│  │  │    Safety    │ │   Receipt    │ │   Grounding  │ │    Cache     │  │ │
│  │  │   Wrapper    │ │   Wrapper    │ │   Wrapper    │ │   Wrapper    │  │ │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
│                                      ▼                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                    SKILL EXECUTION LAYER                                │ │
│  │                                                                         │ │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │ │
│  │  │   Executor   │ │   Sandbox    │ │   Evidence   │ │   Rollback   │  │ │
│  │  │              │ │   Runtime    │ │   Capture    │ │   Engine     │  │ │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
│                                      ▼                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                    SKILL ADAPTERS                                       │ │
│  │                                                                         │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐    │ │
│  │  │ OpenClaw │ │   MCP    │ │LangChain │ │ Browser  │ │  Custom  │    │ │
│  │  │ Adapter  │ │ Adapter  │ │ Adapter  │ │   Use    │ │ Adapter  │    │ │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘    │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. THE .askill FORMAT

### 1.1 Overview

The `.askill` format is a rich skill definition that includes:
- **Schema:** Typed inputs and outputs
- **Contract:** Pre/post conditions, side effects, reversibility
- **Proofs:** Required capabilities, provided evidence, risk factors
- **Implementation:** Multiple execution variants (API, browser, desktop)
- **Metadata:** Version, grade, stats, relationships

### 1.2 Full Specification

```yaml
# ═══════════════════════════════════════════════════════════════════════════
# .askill FORMAT SPECIFICATION v1.0
# ═══════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────
# SCHEMA: What the skill does
# ───────────────────────────────────────────────────────────────────────────

schema:
  # Unique identifier
  name: string                    # Required. e.g., "send_tweet"
  
  # Semantic version
  version: semver                 # Required. e.g., "1.2.0"
  
  # Human-readable description
  description: string             # Required. Shown to LLM for selection
  
  # Domain classification
  domain: string                  # Required. e.g., "social_media.twitter"
  
  # Input parameters
  inputs:
    <param_name>:
      type: <type>                # string, number, boolean, array[T], object
      required: boolean           # Default: true
      default: <value>            # Optional default value
      description: string         # Optional description
      
      # Type constraints
      min_length: number          # For strings
      max_length: number          # For strings
      pattern: regex              # For strings
      min: number                 # For numbers
      max: number                 # For numbers
      enum: [values]              # Allowed values
      min_items: number           # For arrays
      max_items: number           # For arrays
      
      # Security classification
      sensitivity: enum           # public, internal, confidential, secret
      
  # Output values
  outputs:
    <output_name>:
      type: <type>
      format: string              # Optional format hint (e.g., "url", "timestamp")
      description: string

# ───────────────────────────────────────────────────────────────────────────
# CONTRACT: Guarantees and effects
# ───────────────────────────────────────────────────────────────────────────

contract:
  # Must be true before execution
  preconditions:
    - <condition_id>              # e.g., "auth_valid", "input_not_empty"
    
  # Must be true after execution
  postconditions:
    - <condition_id>              # e.g., "resource_created", "state_changed"
    
  # Must always be true
  invariants:
    - <condition_id>              # e.g., "account_not_suspended"
    
  # What this skill affects
  side_effects:
    - type: enum                  # external_state_change, local_state_change,
                                  # network_request, file_system, public_visibility,
                                  # financial_transaction, communication
      target: string              # What is affected
      description: string         # Human-readable
      
  # Can this be undone?
  reversibility:
    reversible: boolean           # Can we undo?
    method: string                # Skill to call for undo (optional)
    time_limit: duration          # How long until irreversible (optional)
    partial: boolean              # Only partially reversible (optional)
    
  # Estimated execution time
  timeout:
    expected: duration            # e.g., "5s"
    maximum: duration             # e.g., "60s"

# ───────────────────────────────────────────────────────────────────────────
# PROOFS: What skill requires and provides
# ───────────────────────────────────────────────────────────────────────────

proofs:
  # What this skill needs to run
  requires:
    - type: capability            # Permission type
      name: string                # e.g., "twitter_post"
      scope: string               # Optional scope limiter
      
    - type: auth                  # Authentication type
      provider: string            # e.g., "twitter_oauth"
      scopes: [string]            # OAuth scopes needed
      
    - type: resource              # Resource type
      name: string                # e.g., "network_access"
      target: string              # e.g., "api.twitter.com"
      
  # What evidence this skill produces
  provides:
    - type: evidence
      name: string                # e.g., "tweet_posted"
      format: string              # e.g., "screenshot+api_response"
      
  # Risk assessment
  risk_level: enum                # low, medium, high, critical
  
  risk_factors:
    - string                      # e.g., "public_visibility", "irreversible"

# ───────────────────────────────────────────────────────────────────────────
# IMPLEMENTATION: How to execute
# ───────────────────────────────────────────────────────────────────────────

implementation:
  # Single implementation or multiple variants
  type: enum                      # single, multi
  
  # For type: single
  runtime: enum                   # rest_api, graphql, browser_automation,
                                  # desktop_app, terminal, custom
  
  # For type: multi (multiple implementations)
  variants:
    - name: string                # Variant identifier
      runtime: enum               # Execution runtime
      priority: number            # Lower = preferred
      
      # For rest_api runtime
      endpoint: url
      method: enum                # GET, POST, PUT, DELETE, PATCH
      headers: object
      body_template: string       # With {{input}} placeholders
      response_parser: string     # JSONPath or custom
      
      # For browser_automation runtime
      steps:
        - action: enum            # navigate, click, fill, wait, assert, screenshot
          target: string          # Selector, URL, or value
          value: string           # Optional value
          timeout: duration       # Optional timeout
          
      # For desktop_app runtime
      target: string              # Application name or path
      commands:
        - action: enum            # launch, menu, shortcut, type, click
          params: object
          
      # For terminal runtime
      command: string             # Command template
      shell: enum                 # bash, zsh, powershell, cmd
      working_dir: string         # Optional
      env: object                 # Environment variables
      
      # Fallback behavior
      fallback_to: string         # Next variant name if this fails
      
  # Retry configuration
  retry:
    max_attempts: number          # Default: 3
    backoff: enum                 # constant, linear, exponential
    backoff_base: duration        # e.g., "1s"
    retry_on: [string]            # Error types to retry

# ───────────────────────────────────────────────────────────────────────────
# METADATA: About the skill
# ───────────────────────────────────────────────────────────────────────────

metadata:
  # Authorship
  author: string                  # Creator
  maintainer: string              # Current maintainer
  license: string                 # e.g., "MIT"
  repository: url                 # Source repository
  
  # Timestamps
  created: datetime
  updated: datetime
  
  # Classification
  tags: [string]                  # Searchable tags
  category: string                # Primary category
  
  # Relationships
  alternatives: [string]          # Other skills that do similar things
  composable_with: [string]       # Skills commonly used together
  depends_on: [string]            # Required skills
  supersedes: string              # Skill this replaces
  
  # Quality metrics (auto-populated by Skill Fabric)
  grade: enum                     # A, B, C, D, F (calculated)
  success_rate: number            # 0.0 - 1.0
  avg_latency_ms: number
  total_executions: number
  last_executed: datetime
  last_failed: datetime
  failure_modes: [string]         # Known failure patterns
  
  # Documentation
  examples:
    - name: string
      description: string
      inputs: object
      expected_outputs: object
      
  changelog:
    - version: semver
      date: datetime
      changes: [string]
```

### 1.3 Example: Twitter Post Skill

```yaml
# twitter_post.askill

schema:
  name: twitter_post
  version: 2.1.0
  description: |
    Posts a tweet to Twitter/X. Supports text content up to 280 characters
    and optional media attachments (up to 4 images or 1 video).
  domain: social_media.twitter
  
  inputs:
    content:
      type: string
      required: true
      max_length: 280
      description: "Tweet text content"
      sensitivity: public
      
    media_urls:
      type: array[url]
      required: false
      max_items: 4
      description: "Optional media URLs to attach"
      
    reply_to:
      type: string
      required: false
      pattern: "^[0-9]+$"
      description: "Tweet ID to reply to"
      
    quote_tweet:
      type: string
      required: false
      pattern: "^[0-9]+$"
      description: "Tweet ID to quote"

  outputs:
    tweet_id:
      type: string
      format: twitter_id
      description: "ID of created tweet"
      
    url:
      type: string
      format: url
      description: "URL to view tweet"
      
    posted_at:
      type: string
      format: iso8601
      description: "Timestamp of posting"

contract:
  preconditions:
    - twitter_auth_valid
    - content_not_empty
    - content_within_limit
    - media_valid_if_present
    
  postconditions:
    - tweet_exists_on_platform
    - tweet_id_returned
    - url_accessible
    
  invariants:
    - account_not_suspended
    - rate_limit_not_exceeded
    
  side_effects:
    - type: external_state_change
      target: twitter.com
      description: "Creates new tweet on Twitter platform"
      
    - type: public_visibility
      target: followers_and_public
      description: "Tweet visible to followers and potentially wider audience"
      
    - type: network_request
      target: api.twitter.com
      description: "Makes authenticated API call to Twitter"
      
  reversibility:
    reversible: true
    method: twitter_delete
    time_limit: null
    partial: false
    
  timeout:
    expected: 2s
    maximum: 30s

proofs:
  requires:
    - type: capability
      name: social_media_post
      scope: twitter
      
    - type: auth
      provider: twitter_oauth2
      scopes:
        - tweet.read
        - tweet.write
        - users.read
        
    - type: resource
      name: network_access
      target: api.twitter.com
      
  provides:
    - type: evidence
      name: tweet_created
      format: api_response+screenshot
      
  risk_level: medium
  
  risk_factors:
    - public_visibility
    - reputation_impact
    - cannot_fully_retract  # Others may have seen/screenshot

implementation:
  type: multi
  
  variants:
    - name: api_v2
      runtime: rest_api
      priority: 1
      endpoint: https://api.twitter.com/2/tweets
      method: POST
      headers:
        Authorization: "Bearer {{auth_token}}"
        Content-Type: "application/json"
      body_template: |
        {
          "text": "{{content}}",
          {{#if reply_to}}"reply": {"in_reply_to_tweet_id": "{{reply_to}}"},{{/if}}
          {{#if quote_tweet}}"quote_tweet_id": "{{quote_tweet}}",{{/if}}
          {{#if media_urls}}"media": {"media_ids": {{media_ids}}}{{/if}}
        }
      response_parser: "$.data.id"
      fallback_to: browser
      
    - name: browser
      runtime: browser_automation
      priority: 2
      steps:
        - action: navigate
          target: https://twitter.com/compose/tweet
          timeout: 10s
          
        - action: wait
          target: "[data-testid='tweetTextarea_0']"
          timeout: 5s
          
        - action: fill
          target: "[data-testid='tweetTextarea_0']"
          value: "{{content}}"
          
        - action: wait
          target: 500ms
          
        - action: click
          target: "[data-testid='tweetButton']"
          timeout: 5s
          
        - action: wait
          target: "[data-testid='toast']"
          timeout: 10s
          
        - action: screenshot
          target: viewport
          
      fallback_to: null
      
  retry:
    max_attempts: 3
    backoff: exponential
    backoff_base: 2s
    retry_on:
      - rate_limit
      - network_timeout
      - server_error

metadata:
  author: skill_fabric_core
  maintainer: agentralabs
  license: MIT
  repository: https://github.com/agentralabs/skill-fabric
  
  created: 2026-01-15T00:00:00Z
  updated: 2026-02-20T00:00:00Z
  
  tags:
    - social
    - twitter
    - x
    - post
    - content
    - public
    
  category: social_media
  
  alternatives:
    - buffer_post
    - hootsuite_post
    - tweetdeck_post
    
  composable_with:
    - content_generator
    - image_generator
    - url_shortener
    - sentiment_analyzer
    
  depends_on: []
  
  supersedes: twitter_post_v1
  
  # Auto-populated by Skill Fabric
  grade: A-
  success_rate: 0.97
  avg_latency_ms: 1847
  total_executions: 12453
  last_executed: 2026-02-25T10:30:00Z
  last_failed: 2026-02-24T08:15:00Z
  failure_modes:
    - rate_limit_exceeded
    - auth_token_expired
    - content_policy_violation
    
  examples:
    - name: simple_tweet
      description: "Post a simple text tweet"
      inputs:
        content: "Hello, world! This is my first tweet via Skill Fabric."
      expected_outputs:
        tweet_id: "1234567890"
        url: "https://twitter.com/user/status/1234567890"
        
    - name: reply_tweet
      description: "Reply to an existing tweet"
      inputs:
        content: "Great point! I totally agree."
        reply_to: "9876543210"
      expected_outputs:
        tweet_id: "1234567891"
        url: "https://twitter.com/user/status/1234567891"
        
  changelog:
    - version: 2.1.0
      date: 2026-02-20
      changes:
        - Added quote tweet support
        - Improved error handling for rate limits
        - Added browser fallback
        
    - version: 2.0.0
      date: 2026-01-15
      changes:
        - Migrated to Twitter API v2
        - Added media upload support
        - Breaking: Changed input parameter names
```

---

## 2. SKILL ADAPTERS

### 2.1 OpenClaw Adapter

```rust
// openclaw_adapter.rs

/// Converts OpenClaw skill definitions to .askill format
pub struct OpenClawAdapter;

impl OpenClawAdapter {
    /// Import OpenClaw skill JSON
    pub fn import(openclaw_json: &str) -> Result<ASkill> {
        let oc: OpenClawSkill = serde_json::from_str(openclaw_json)?;
        
        Ok(ASkill {
            schema: Schema {
                name: oc.name,
                version: "1.0.0".into(),  // Default version
                description: oc.description,
                domain: infer_domain(&oc.name),
                inputs: convert_inputs(&oc.inputs),
                outputs: convert_outputs(&oc.outputs),
            },
            contract: Contract {
                preconditions: infer_preconditions(&oc),
                postconditions: infer_postconditions(&oc),
                invariants: vec![],
                side_effects: infer_side_effects(&oc),
                reversibility: Reversibility::unknown(),
                timeout: Timeout::default(),
            },
            proofs: Proofs {
                requires: infer_requirements(&oc),
                provides: vec![],  // Enhanced after first execution
                risk_level: infer_risk_level(&oc),
                risk_factors: infer_risk_factors(&oc),
            },
            implementation: Implementation::Single {
                runtime: Runtime::Custom,
                function: oc.function,
            },
            metadata: Metadata::default_for_import(),
        })
    }
}
```

### 2.2 MCP Adapter

```rust
// mcp_adapter.rs

/// Converts MCP tool definitions to .askill format
pub struct McpAdapter;

impl McpAdapter {
    /// Import MCP tool
    pub fn import(mcp_tool: &McpTool) -> Result<ASkill> {
        Ok(ASkill {
            schema: Schema {
                name: mcp_tool.name.clone(),
                version: "1.0.0".into(),
                description: mcp_tool.description.clone(),
                domain: infer_domain(&mcp_tool.name),
                inputs: convert_mcp_schema(&mcp_tool.input_schema),
                outputs: OutputSchema::dynamic(),  // MCP doesn't define outputs
            },
            contract: Contract::inferred(),  // Learn from execution
            proofs: Proofs::minimal(),
            implementation: Implementation::Mcp {
                server: mcp_tool.server_uri.clone(),
                tool_name: mcp_tool.name.clone(),
            },
            metadata: Metadata::default_for_import(),
        })
    }
}
```

### 2.3 Adapter Registry

```rust
// adapter_registry.rs

pub struct AdapterRegistry {
    adapters: HashMap<SkillFormat, Box<dyn SkillAdapter>>,
}

impl AdapterRegistry {
    pub fn new() -> Self {
        let mut adapters = HashMap::new();
        adapters.insert(SkillFormat::OpenClaw, Box::new(OpenClawAdapter));
        adapters.insert(SkillFormat::Mcp, Box::new(McpAdapter));
        adapters.insert(SkillFormat::LangChain, Box::new(LangChainAdapter));
        adapters.insert(SkillFormat::BrowserUse, Box::new(BrowserUseAdapter));
        adapters.insert(SkillFormat::AutoGpt, Box::new(AutoGptAdapter));
        Self { adapters }
    }
    
    pub fn import(&self, source: &str, format: SkillFormat) -> Result<ASkill> {
        self.adapters
            .get(&format)
            .ok_or(Error::UnsupportedFormat)?
            .import(source)
    }
}
```

---

## 3. SKILL INTELLIGENCE

### 3.1 Action Compiler

```rust
// action_compiler.rs

pub struct ActionCompiler {
    pattern_store: PatternStore,
    compiled_store: CompiledStore,
}

impl ActionCompiler {
    /// Detect patterns in execution history
    pub fn detect_patterns(&self, history: &[Execution]) -> Vec<Pattern> {
        let mut patterns = vec![];
        
        // Group by skill sequence
        let sequences = self.extract_sequences(history);
        
        for (sequence_hash, occurrences) in sequences {
            if occurrences.len() >= 3 {  // Minimum for pattern
                let stability = self.calculate_stability(&occurrences);
                
                if stability > 0.8 {  // 80% stability threshold
                    patterns.push(Pattern {
                        hash: sequence_hash,
                        sequence: occurrences[0].sequence.clone(),
                        occurrences: occurrences.len(),
                        stability,
                        variables: self.extract_variables(&occurrences),
                    });
                }
            }
        }
        
        patterns
    }
    
    /// Compile pattern into executable action
    pub fn compile(&self, pattern: &Pattern) -> Result<CompiledAction> {
        // Generate AST
        let ast = self.generate_ast(&pattern.sequence, &pattern.variables)?;
        
        // Validate AST
        self.validate_ast(&ast)?;
        
        // Generate executable
        let executable = self.emit_code(&ast)?;
        
        // Test executable
        self.test_compiled(&executable, &pattern)?;
        
        Ok(CompiledAction {
            id: CompiledId::new(),
            pattern_hash: pattern.hash,
            ast,
            executable,
            created: Utc::now(),
            success_rate: 1.0,  // Will be updated
        })
    }
    
    /// Check if we can use compiled action for this intent
    pub fn find_compiled(&self, intent: &Intent) -> Option<CompiledAction> {
        let candidates = self.compiled_store.find_by_intent(intent);
        
        candidates
            .into_iter()
            .filter(|c| c.success_rate > 0.9)  // 90% success minimum
            .max_by_key(|c| c.success_rate)
    }
}
```

### 3.2 Skill Grader

```rust
// skill_grader.rs

pub struct SkillGrader;

impl SkillGrader {
    /// Calculate grade for a skill based on metrics
    pub fn calculate_grade(metrics: &SkillMetrics) -> Grade {
        let success_score = metrics.success_rate * 40.0;  // 40% weight
        let latency_score = self.latency_score(metrics.avg_latency_ms) * 25.0;  // 25%
        let reliability_score = self.reliability_score(metrics) * 20.0;  // 20%
        let cost_score = self.cost_score(metrics.avg_token_cost) * 15.0;  // 15%
        
        let total = success_score + latency_score + reliability_score + cost_score;
        
        match total {
            t if t >= 90.0 => Grade::A,
            t if t >= 80.0 => Grade::B,
            t if t >= 70.0 => Grade::C,
            t if t >= 60.0 => Grade::D,
            _ => Grade::F,
        }
    }
    
    fn latency_score(&self, latency_ms: f64) -> f64 {
        match latency_ms {
            l if l < 500.0 => 1.0,
            l if l < 1000.0 => 0.9,
            l if l < 2000.0 => 0.7,
            l if l < 5000.0 => 0.5,
            _ => 0.3,
        }
    }
}
```

### 3.3 Skill Fusioner

```rust
// skill_fusioner.rs

pub struct SkillFusioner {
    co_occurrence_tracker: CoOccurrenceTracker,
}

impl SkillFusioner {
    /// Track skill co-occurrence
    pub fn track_execution(&mut self, run: &Run) {
        let skills = run.steps.iter()
            .map(|s| s.skill_name.clone())
            .collect::<Vec<_>>();
            
        for window in skills.windows(2) {
            self.co_occurrence_tracker.record(
                &window[0],
                &window[1],
                run.id,
            );
        }
    }
    
    /// Detect fusion candidates
    pub fn detect_fusion_candidates(&self) -> Vec<FusionCandidate> {
        self.co_occurrence_tracker
            .pairs()
            .filter(|(_, count)| *count >= 10)  // Used together 10+ times
            .map(|((a, b), count)| {
                let success_rate = self.calculate_pair_success_rate(a, b);
                FusionCandidate {
                    skills: vec![a.clone(), b.clone()],
                    co_occurrences: count,
                    success_rate,
                }
            })
            .filter(|c| c.success_rate > 0.85)
            .collect()
    }
    
    /// Generate compound skill from fusion candidate
    pub fn fuse(&self, candidate: &FusionCandidate) -> Result<ASkill> {
        let skills = candidate.skills.iter()
            .map(|name| self.skill_store.get(name))
            .collect::<Result<Vec<_>>>()?;
            
        Ok(ASkill {
            schema: Schema {
                name: format!("compound_{}_{}", skills[0].name, skills[1].name),
                version: "1.0.0".into(),
                description: format!(
                    "Compound skill: {} then {}",
                    skills[0].description,
                    skills[1].description
                ),
                inputs: merge_inputs(&skills),
                outputs: skills.last().unwrap().outputs.clone(),
                ..Default::default()
            },
            implementation: Implementation::Compound {
                steps: skills.iter().map(|s| s.name.clone()).collect(),
            },
            metadata: Metadata {
                tags: vec!["compound".into(), "auto-generated".into()],
                ..Default::default()
            },
            ..Default::default()
        })
    }
}
```

### 3.4 Skill Router

```rust
// skill_router.rs

pub struct SkillRouter {
    skill_store: SkillStore,
    compiled_store: CompiledStore,
    grader: SkillGrader,
}

impl SkillRouter {
    /// Route intent to best skill
    pub fn route(&self, intent: &Intent) -> Result<RoutingDecision> {
        // 1. Check for compiled action first (fastest, cheapest)
        if let Some(compiled) = self.compiled_store.find_by_intent(intent) {
            if compiled.confidence > 0.9 {
                return Ok(RoutingDecision::Compiled(compiled));
            }
        }
        
        // 2. Find matching skills
        let candidates = self.skill_store.find_by_intent(intent);
        
        if candidates.is_empty() {
            return Err(Error::NoMatchingSkill);
        }
        
        // 3. Rank by grade
        let mut ranked: Vec<_> = candidates
            .into_iter()
            .map(|skill| {
                let grade = self.grader.get_grade(&skill.name);
                (skill, grade)
            })
            .collect();
            
        ranked.sort_by(|a, b| b.1.cmp(&a.1));  // Best grade first
        
        // 4. Return best with fallback chain
        let (best, _) = ranked.remove(0);
        let fallbacks = ranked.into_iter().map(|(s, _)| s).collect();
        
        Ok(RoutingDecision::Skill {
            primary: best,
            fallbacks,
        })
    }
}
```

---

## 4. SKILL ENHANCEMENT

### 4.1 Enhancement Pipeline

```rust
// enhancement_pipeline.rs

pub struct EnhancementPipeline {
    safety_wrapper: SafetyWrapper,
    receipt_wrapper: ReceiptWrapper,
    grounding_wrapper: GroundingWrapper,
    cache_wrapper: CacheWrapper,
}

impl EnhancementPipeline {
    /// Wrap skill execution with enhancements
    pub async fn execute(&self, skill: &ASkill, inputs: Value) -> Result<ExecutionResult> {
        // 1. Check cache first
        if let Some(cached) = self.cache_wrapper.get(skill, &inputs).await? {
            return Ok(cached);
        }
        
        // 2. Safety checks
        self.safety_wrapper.pre_check(skill, &inputs).await?;
        
        // 3. Grounding: capture pre-state
        let pre_evidence = self.grounding_wrapper.capture_pre_state(skill, &inputs).await?;
        
        // 4. Execute skill
        let raw_result = skill.execute(inputs.clone()).await?;
        
        // 5. Grounding: capture post-state and verify
        let post_evidence = self.grounding_wrapper.capture_post_state(skill, &raw_result).await?;
        self.grounding_wrapper.verify_postconditions(skill, &raw_result).await?;
        
        // 6. Generate receipt
        let receipt = self.receipt_wrapper.generate(
            skill,
            &inputs,
            &raw_result,
            &pre_evidence,
            &post_evidence,
        ).await?;
        
        // 7. Cache result
        self.cache_wrapper.set(skill, &inputs, &raw_result).await?;
        
        Ok(ExecutionResult {
            outputs: raw_result,
            receipt,
            evidence: Evidence {
                pre: pre_evidence,
                post: post_evidence,
            },
        })
    }
}
```

### 4.2 Safety Wrapper

```rust
// safety_wrapper.rs

pub struct SafetyWrapper {
    risk_scorer: RiskScorer,
    policy_engine: PolicyEngine,
    approval_gate: ApprovalGate,
}

impl SafetyWrapper {
    pub async fn pre_check(&self, skill: &ASkill, inputs: &Value) -> Result<()> {
        // 1. Score risk
        let risk = self.risk_scorer.score(skill, inputs);
        
        // 2. Check policy
        let policy_result = self.policy_engine.check(skill, inputs, risk);
        
        match policy_result {
            PolicyResult::Allow => Ok(()),
            PolicyResult::Deny(reason) => Err(Error::PolicyDenied(reason)),
            PolicyResult::RequireApproval => {
                let approved = self.approval_gate.request(skill, inputs, risk).await?;
                if approved {
                    Ok(())
                } else {
                    Err(Error::ApprovalDenied)
                }
            }
        }
    }
}
```

### 4.3 Cache Wrapper

```rust
// cache_wrapper.rs

pub struct CacheWrapper {
    result_cache: ResultCache,
    ttl_config: TtlConfig,
}

impl CacheWrapper {
    /// Generate cache key
    fn cache_key(&self, skill: &ASkill, inputs: &Value) -> CacheKey {
        CacheKey {
            skill_name: skill.name.clone(),
            skill_version: skill.version.clone(),
            inputs_hash: hash(inputs),
            context_hash: hash(&self.current_context()),
        }
    }
    
    /// Check if result is cacheable
    fn is_cacheable(&self, skill: &ASkill) -> bool {
        // Don't cache skills with external side effects
        !skill.contract.side_effects.iter().any(|e| {
            matches!(e.effect_type, 
                EffectType::ExternalStateChange | 
                EffectType::Communication |
                EffectType::FinancialTransaction
            )
        })
    }
    
    /// Get cached result
    pub async fn get(&self, skill: &ASkill, inputs: &Value) -> Result<Option<ExecutionResult>> {
        if !self.is_cacheable(skill) {
            return Ok(None);
        }
        
        let key = self.cache_key(skill, inputs);
        self.result_cache.get(&key).await
    }
}
```

---

## 5. SKILL EXECUTION

### 5.1 Executor

```rust
// executor.rs

pub struct SkillExecutor {
    sandbox_manager: SandboxManager,
    evidence_capturer: EvidenceCapturer,
    retry_handler: RetryHandler,
}

impl SkillExecutor {
    pub async fn execute(&self, skill: &ASkill, inputs: Value) -> Result<ExecutionResult> {
        let sandbox = self.sandbox_manager.create_for_skill(skill)?;
        
        let result = self.retry_handler.with_retry(skill.retry_config(), || async {
            match &skill.implementation {
                Implementation::Single { runtime, .. } => {
                    self.execute_single(runtime, skill, &inputs, &sandbox).await
                }
                Implementation::Multi { variants } => {
                    self.execute_with_fallback(variants, skill, &inputs, &sandbox).await
                }
                Implementation::Compound { steps } => {
                    self.execute_compound(steps, skill, &inputs, &sandbox).await
                }
                Implementation::Compiled { executable } => {
                    self.execute_compiled(executable, &inputs, &sandbox).await
                }
            }
        }).await?;
        
        Ok(result)
    }
    
    async fn execute_with_fallback(
        &self,
        variants: &[Variant],
        skill: &ASkill,
        inputs: &Value,
        sandbox: &Sandbox,
    ) -> Result<Value> {
        let mut last_error = None;
        
        for variant in variants.iter().sorted_by_key(|v| v.priority) {
            match self.execute_variant(variant, inputs, sandbox).await {
                Ok(result) => return Ok(result),
                Err(e) => {
                    log::warn!("Variant {} failed: {}", variant.name, e);
                    last_error = Some(e);
                    
                    if variant.fallback_to.is_none() {
                        break;
                    }
                }
            }
        }
        
        Err(last_error.unwrap_or(Error::AllVariantsFailed))
    }
}
```

### 5.2 Sandbox Runtime

```rust
// sandbox_runtime.rs

pub struct SandboxManager {
    profiles: HashMap<String, SandboxProfile>,
}

impl SandboxManager {
    pub fn create_for_skill(&self, skill: &ASkill) -> Result<Sandbox> {
        let profile = self.select_profile(skill);
        
        Sandbox::new(SandboxConfig {
            // Network restrictions
            allowed_domains: self.allowed_domains(skill),
            blocked_domains: self.blocked_domains(),
            
            // Filesystem restrictions
            allowed_paths: self.allowed_paths(skill),
            read_only_paths: self.read_only_paths(),
            temp_dir: self.create_temp_dir()?,
            
            // Resource limits
            max_memory_mb: profile.max_memory_mb,
            max_cpu_percent: profile.max_cpu_percent,
            timeout: skill.contract.timeout.maximum,
            
            // Capabilities
            capabilities: self.required_capabilities(skill),
        })
    }
    
    fn allowed_domains(&self, skill: &ASkill) -> Vec<String> {
        skill.proofs.requires
            .iter()
            .filter_map(|r| {
                if let Requirement::Resource { target, .. } = r {
                    extract_domain(target)
                } else {
                    None
                }
            })
            .collect()
    }
}
```

---

## 6. SKILL REGISTRY

### 6.1 Unified Registry

```rust
// skill_registry.rs

pub struct SkillRegistry {
    store: SkillStore,
    adapter_registry: AdapterRegistry,
    indexer: SkillIndexer,
}

impl SkillRegistry {
    /// Register a skill
    pub async fn register(&self, skill: ASkill) -> Result<()> {
        // Validate skill
        self.validate(&skill)?;
        
        // Store skill
        self.store.insert(&skill).await?;
        
        // Update index
        self.indexer.index(&skill).await?;
        
        Ok(())
    }
    
    /// Import from external format
    pub async fn import(&self, source: &str, format: SkillFormat) -> Result<ASkill> {
        let skill = self.adapter_registry.import(source, format)?;
        self.register(skill.clone()).await?;
        Ok(skill)
    }
    
    /// Search skills
    pub async fn search(&self, query: &str) -> Vec<SkillSummary> {
        self.indexer.search(query).await
    }
    
    /// Get skill by name
    pub async fn get(&self, name: &str) -> Result<ASkill> {
        self.store.get(name).await
    }
    
    /// List all skills
    pub async fn list(&self) -> Vec<SkillSummary> {
        self.store.list().await
    }
    
    /// Get skill stats
    pub async fn stats(&self, name: &str) -> Result<SkillStats> {
        self.store.get_stats(name).await
    }
}
```

---

## 7. COMPARISON: OPENCLAW vs SKILL FABRIC

| Feature | OpenClaw | Skill Fabric |
|---------|----------|--------------|
| Skill definition | JSON | .askill (rich contract) |
| Input validation | Basic | Full type system + constraints |
| Output validation | None | Postconditions + verification |
| Side effects | Implicit | Explicitly declared |
| Reversibility | Unknown | Declared with method |
| Risk scoring | None | Built-in |
| Approval gates | None | Multi-level |
| Execution sandbox | None | Yes (configurable) |
| Evidence capture | None | Automatic |
| Receipt generation | None | Automatic |
| Caching | None | Multi-level intelligent |
| Skill grading | None | Automatic A-F |
| Pattern compilation | None | Auto-compile repeated patterns |
| Skill fusion | None | Auto-fuse co-occurring |
| Multiple implementations | None | Yes (API, browser, desktop) |
| Versioning | None | Semantic versioning |
| Learning | None | Continuous improvement |

---

## 8. DIRECTORY STRUCTURE

```
skill_fabric/
├── core/
│   ├── schema/
│   │   ├── askill_parser.rs
│   │   ├── contract_validator.rs
│   │   ├── type_system.rs
│   │   └── version_resolver.rs
│   │
│   ├── registry/
│   │   ├── skill_store.rs
│   │   ├── discovery.rs
│   │   ├── indexer.rs
│   │   └── grade_tracker.rs
│   │
│   └── execution/
│       ├── executor.rs
│       ├── sandbox.rs
│       ├── cache.rs
│       └── evidence.rs
│
├── intelligence/
│   ├── compiler/
│   │   ├── pattern_detector.rs
│   │   ├── action_compiler.rs
│   │   └── compiled_store.rs
│   │
│   ├── fusioner/
│   │   ├── co_occurrence.rs
│   │   ├── compound_generator.rs
│   │   └── fusion_validator.rs
│   │
│   ├── router/
│   │   ├── intent_matcher.rs
│   │   ├── grade_ranker.rs
│   │   └── fallback_chain.rs
│   │
│   └── grader/
│       ├── metrics_collector.rs
│       ├── grade_calculator.rs
│       └── trend_analyzer.rs
│
├── enhancement/
│   ├── pipeline.rs
│   ├── safety_wrapper.rs
│   ├── receipt_wrapper.rs
│   ├── grounding_wrapper.rs
│   └── cache_wrapper.rs
│
├── adapters/
│   ├── openclaw_adapter.rs
│   ├── mcp_adapter.rs
│   ├── langchain_adapter.rs
│   ├── browseruse_adapter.rs
│   └── custom_adapter.rs
│
├── skills/
│   ├── social/
│   │   ├── twitter_post.askill
│   │   ├── twitter_delete.askill
│   │   └── ...
│   ├── productivity/
│   ├── development/
│   └── ...
│
└── cli/
    ├── skill_import.rs
    ├── skill_test.rs
    ├── skill_publish.rs
    └── skill_search.rs
```

---

*Document Version: 1.0*
*Status: Canonical*
