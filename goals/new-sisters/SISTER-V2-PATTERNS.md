# SISTER-V2-PATTERNS.md

# V2 Upgrade Patterns — Learned from Real Users

> **Origin:** 11philip22's C++ → Rust migration struggle revealed patterns that apply to ALL sisters.

---

## The Core Problem (Universal)

```
USER PAIN POINTS (from 11philip22):
──────────────────────────────────
1. Agent HALLUCINATES (claims things that don't exist)
2. Agent FORGETS (loses task context across sessions)
3. Agent can't COMPARE (needs two sources simultaneously)
4. Agent can't TRACK (what's done vs what remains)

These aren't Codebase problems.
These are EVERY sister problems.
```

---

## The 4 Universal Patterns

### Pattern 1: GROUNDING

> **"If it's not in the data, the agent can't claim it."**

Every sister must prevent hallucination by requiring claims to be backed by stored data.

| Sister | Grounding Rule |
|--------|----------------|
| Memory | Can't claim "you said X" without memory node |
| Vision | Can't claim "the page shows X" without capture |
| Codebase | Can't claim "function X exists" without graph node |
| Identity | Can't claim "agent has permission X" without trust grant |

**Implementation:**
```rust
// Every sister adds:
fn verify_claim(claim: &str) -> GroundingResult {
    match self.find_supporting_evidence(claim) {
        Some(evidence) => GroundingResult::Verified(evidence),
        None => GroundingResult::Ungrounded(claim)
    }
}

// MCP behavior:
// Before agent responds with a claim, it MUST call verify
// Ungrounded claims get flagged or blocked
```

---

### Pattern 2: MULTI-CONTEXT

> **"Work with multiple sources simultaneously."**

Every sister must support loading and querying across multiple instances.

| Sister | Multi-Context Use Case |
|--------|------------------------|
| Memory | "What did I decide in Project A that applies to Project B?" |
| Vision | "Compare competitor A's checkout vs competitor B's" |
| Codebase | "Show me C++ source alongside Rust target" |
| Identity | "Agent A's permissions vs Agent B's permissions" |

**Implementation:**
```rust
// Every sister adds workspace concept:
struct Workspace {
    name: String,
    contexts: Vec<ContextRef>,  // Multiple loaded sources
    active: Option<ContextRef>, // Current focus
    cross_query_enabled: bool,  // Can query across all
}

// MCP tools:
// workspace_create, workspace_add, workspace_query_all
```

---

### Pattern 3: TASK CONTINUITY

> **"Long-running tasks persist across sessions, days, weeks."**

Every sister must integrate with Memory for task state that survives session boundaries.

| Sister | Task Continuity Example |
|--------|-------------------------|
| Memory | "Continue the auth refactor discussion from last week" |
| Vision | "Continue monitoring competitor pricing (started 3 days ago)" |
| Codebase | "Continue the C++ → Rust port (40% complete)" |
| Identity | "Continue the security audit (permissions granted last month)" |

**Implementation:**
```rust
// Every sister stores task state in Memory:
struct TaskState {
    task_id: String,
    description: String,
    started: Timestamp,
    last_touched: Timestamp,
    progress_percent: u8,
    context: SisterSpecificContext,  // Each sister defines this
    checkpoints: Vec<Checkpoint>,
}

// On session start:
// 1. Load active tasks from Memory
// 2. Restore sister-specific context
// 3. Agent knows exactly where we left off
```

---

### Pattern 4: PROGRESS TRACKING

> **"What's done. What remains. Always clear."**

Every sister must track completion state for scoped work.

| Sister | Progress Tracking Example |
|--------|---------------------------|
| Memory | "3 of 5 decisions made for Q2 planning" |
| Vision | "Captured 7 of 12 competitor pages" |
| Codebase | "Ported 15 of 23 modules" |
| Identity | "Verified 8 of 10 required permissions" |

**Implementation:**
```rust
// Every sister adds:
struct ProgressScope {
    scope_id: String,
    scope_name: String,          // "auth module port"
    total_items: usize,
    completed_items: Vec<ItemId>,
    remaining_items: Vec<ItemId>,
    percent_complete: u8,
}

// MCP tools:
// progress_create, progress_update, progress_status, progress_remaining
```

---

## Sister-Specific V2 Upgrades

### Memory v2

```
NEW CAPABILITIES:
─────────────────
1. Task memory (not just facts — track ongoing work)
2. Multi-project queries ("decisions in Project A that affect B")
3. Grounded recall ("I said X" → must have memory node)
4. Progress tracking for decisions/discussions

NEW MCP TOOLS:
──────────────
task_create         Start tracking a long-running task
task_update         Update progress/status
task_complete       Mark task done, store lessons
task_resume         Load task context into session
memory_ground       Verify a claim has memory backing
memory_cross_query  Query across multiple .amem files
```

---

### Vision v2

```
NEW CAPABILITIES:
─────────────────
1. Multi-site workspaces (compare A vs B)
2. Monitoring tasks (track changes over time)
3. Grounded claims ("page shows X" → must have capture)
4. Visual diff progress (N pages tracked, M changed)

NEW MCP TOOLS:
──────────────
workspace_create     Load multiple sites for comparison
workspace_compare    Side-by-side semantic diff
monitor_create       Start tracking a page for changes
monitor_status       What's changed since monitoring started
vision_ground        Verify visual claim has capture backing
capture_for_task     Link capture to ongoing task
```

---

### Codebase v2

```
NEW CAPABILITIES:
─────────────────
1. Multi-graph workspaces (source + target)
2. Translation mapping (what maps to what)
3. Grounded claims (function exists → must be in graph)
4. Migration progress (ported vs remaining)

NEW MCP TOOLS:
──────────────
workspace_create      Load multiple codebases
workspace_query_all   Query across all loaded graphs
translation_map       Record source → target mapping
translation_status    What's mapped, what's not
migration_remaining   What's left to port
migration_verify      Semantic equivalence check
codebase_ground       Verify code claim has graph backing
```

---

### Identity v2

```
NEW CAPABILITIES:
─────────────────
1. Task-scoped permissions (authority for THIS task only)
2. Multi-agent coordination (A's perms vs B's perms)
3. Grounded authority claims (can't claim permission without grant)
4. Audit progress (N checks done, M remaining)

NEW MCP TOOLS:
──────────────
task_scope_create    Create permissions scoped to task
task_scope_verify    Check if action allowed in task scope
multi_agent_compare  Compare permissions across agents
identity_ground      Verify authority claim has trust backing
audit_create         Start permission audit
audit_progress       Audit completion status
```

---

## The Grounding Protocol

Every sister implements the same grounding interface:

```rust
pub trait Grounded {
    /// Verify a natural language claim has data backing
    fn ground_claim(&self, claim: &str) -> GroundingResult;
    
    /// Get evidence for a claim
    fn get_evidence(&self, claim: &str) -> Option<Evidence>;
    
    /// Check if agent should be blocked from making ungrounded claim
    fn should_block_ungrounded(&self) -> bool;
}

pub enum GroundingResult {
    /// Claim is fully supported by data
    Verified { evidence: Vec<Evidence>, confidence: f32 },
    
    /// Claim is partially supported
    Partial { supported: String, unsupported: String },
    
    /// Claim has no data backing — potential hallucination
    Ungrounded { claim: String, suggestion: Option<String> },
}
```

---

## The Task Protocol

Every sister integrates with Memory for task continuity:

```rust
pub trait TaskAware {
    /// Get current active task context
    fn active_task(&self) -> Option<TaskContext>;
    
    /// Link an operation to current task
    fn link_to_task(&mut self, operation_id: &str, task_id: &str);
    
    /// Get task progress from this sister's perspective
    fn task_progress(&self, task_id: &str) -> TaskProgress;
    
    /// Resume task context from Memory
    fn resume_task(&mut self, task: &TaskState);
}
```

---

## The Workspace Protocol

Every sister supports multi-context workspaces:

```rust
pub trait MultiContext {
    /// Create workspace with multiple sources
    fn workspace_create(&mut self, name: &str, sources: Vec<Source>) -> WorkspaceId;
    
    /// Add source to existing workspace
    fn workspace_add(&mut self, workspace: WorkspaceId, source: Source);
    
    /// Query across all sources in workspace
    fn workspace_query(&self, workspace: WorkspaceId, query: &str) -> Vec<Result>;
    
    /// Compare across sources
    fn workspace_compare(&self, workspace: WorkspaceId, item_a: &str, item_b: &str) -> Comparison;
}
```

---

## Priority Implementation Order

```
PHASE 1 — Grounding (Anti-Hallucination)
────────────────────────────────────────
All sisters add ground_claim() and evidence requirements.
This is the #1 pain point from real users.
Effort: ~2-3 days per sister

PHASE 2 — Task Continuity
─────────────────────────
All sisters integrate with Memory for task state.
Long-running work survives sessions.
Effort: ~2-3 days per sister

PHASE 3 — Multi-Context Workspaces
──────────────────────────────────
All sisters support loading multiple sources.
Comparison and cross-querying.
Effort: ~4-5 days per sister

PHASE 4 — Progress Tracking
───────────────────────────
All sisters track completion state.
"What's done, what remains" always available.
Effort: ~1-2 days per sister
```

---

## Success Criteria

After V2, this conversation works:

```
User: Continue the C++ to Rust port

Agent: [loads task from Memory]
       [loads both codebases from Codebase workspace]
       [checks translation map]
       
       "Last session we ported SessionCache. 
        Translation map shows 15 of 23 modules complete (65%).
        
        Remaining in auth module:
        - TokenValidator (blocked — needs SessionCache, now done ✓)
        - AuthConfig (no dependencies, ready to port)
        
        I have both codebases loaded. Ready to continue with TokenValidator?"

User: Yes, port TokenValidator

Agent: [queries C++ graph for TokenValidator — GROUNDED]
       [verifies dependencies exist in Rust — GROUNDED]
       [produces translation]
       [updates translation map]
       [updates task progress: 16/23 = 70%]
       [stores in Memory: checkpoint reached]
       
       "TokenValidator ported. Progress: 70% complete.
        Next suggested: AuthConfig (last item in auth module)."
```

**Zero hallucination. Zero forgetting. Perfect continuity.**

---

## Document Status

```
Created: February 2026
Origin: 11philip22 user feedback
Applies to: ALL sisters
Status: CANONICAL V2 ROADMAP
```
