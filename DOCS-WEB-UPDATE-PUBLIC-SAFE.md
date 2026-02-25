# DOCS & WEB UPDATE — PUBLIC SAFE VERSION

> **STEALTH RULE:** Only show what's RELEASED. No roadmap. No future sisters. Each appears as standalone breakthrough.

---

## WHAT'S PUBLIC

```
SHOW:
─────
.amem    Memory      ✅ Released
.avis    Vision      ✅ Released
.acb     Codebase    ✅ Released
.aid     Identity    ✅ Released

DON'T SHOW:
───────────
.atime, .acon, .acomm, .aplan, .acog, .areal (Foundation coming)
.aatt, .aaff, .amot, .alrn (Cognitive)
.ameta, .awonder, .abond (Relational)
.amenng, .adream, .acons, .adur (Depth)
Hydra, AgenticOS, ring architecture, 25 sisters plan
```

---

## 1. HOMEPAGE UPDATE (PUBLIC SAFE)

### Hero Section

```
REMEMBER. SEE. UNDERSTAND. PROVE.

Your AI forgets you exist. Ours remembers for 20 years.

Four open-source systems. Four file formats. Forever yours.
.amem · .avis · .acb · .aid
```

---

### NEW SECTION: "The .a* Files"

```html
<section id="the-files">
  <h2>Your Agent's Mind. One Folder. Forever Yours.</h2>
  
  <p class="subhead">
    Twenty years from now, you'll open a new AI tool. 
    You'll drag in a folder. Your agent will know you.
  </p>

  <div class="file-ecosystem">
    
    <div class="file-card">
      <span class="ext">.amem</span>
      <span class="name">AgenticMemory</span>
      <span class="desc">Every conversation. Every decision. Every preference.</span>
      <span class="size">~1-2 GB over 20 years</span>
    </div>
    
    <div class="file-card">
      <span class="ext">.avis</span>
      <span class="name">AgenticVision</span>
      <span class="desc">Every page you saw. Every change. Visual evidence.</span>
      <span class="size">~5-8 GB over 20 years</span>
    </div>
    
    <div class="file-card">
      <span class="ext">.acb</span>
      <span class="name">AgenticCodebase</span>
      <span class="desc">Every project. Semantic graphs. Zero hallucination.</span>
      <span class="size">~2-3 GB over 20 years</span>
    </div>
    
    <div class="file-card">
      <span class="ext">.aid</span>
      <span class="name">AgenticIdentity</span>
      <span class="desc">Signed receipts. Earned trust. Unbroken continuity.</span>
      <span class="size">~0.5-1 GB over 20 years</span>
    </div>

  </div>
  
  <div class="value-prop">
    <h3>Two Purposes. One Standard.</h3>
    
    <div class="purpose">
      <h4>RETENTION</h4>
      <p>20 years of your agent's cognitive history. 
         Portable. Encrypted. User-owned. Works offline forever.</p>
    </div>
    
    <div class="purpose">
      <h4>ENRICHMENT</h4>
      <p>Load these files into ANY model — Claude, GPT, Llama, local. 
         The files make any model YOUR intelligent agent.</p>
    </div>
    
    <p class="tagline">
      <strong>The model is commodity. The files are value.</strong>
    </p>
  </div>
  
  <div class="size-promise">
    <code>~10-15 GB</code>
    <p>20 years of memory, vision, code, and identity.<br>
       Fits on your phone. Backs up like photos.</p>
  </div>

</section>
```

**NOTE:** No "coming soon" section. No hints at future. Just the 4 currently available.

---

### UPDATE: Module Cards

Add V2 capabilities (grounding + multi-context):

**Memory Card — Add:**
```
NEW IN v0.3:
• GROUNDING: Claims verified against stored memories
• MULTI-CONTEXT: Query across multiple memory files
```

**Vision Card — Add:**
```
NEW IN v0.2:
• GROUNDING: Visual claims backed by captures
• MULTI-CONTEXT: Compare across sites and time
```

**Codebase Card — Add:**
```
NEW IN v0.2:
• GROUNDING: Code claims verified against graph — zero hallucination
• WORKSPACES: Load source + target codebases simultaneously
• TRANSLATION: Track migration progress across sessions
```

**Identity Card — Add:**
```
NEW IN v0.2:
• GROUNDING: Authority claims backed by trust grants
• MULTI-CONTEXT: Compare permissions across agents
```

---

### UPDATE: Benchmarks Table

Add new rows:

```
| Operation | Latency |
|-----------|---------|
| Grounding: verify claim | < 10 ms |
| Workspace: cross-context query | < 50 ms |
```

---

## 2. DOCS SITE UPDATE (PUBLIC SAFE)

### NEW PAGE: /docs/en/file-formats

```markdown
# The .a* File Ecosystem

Your agent's mind, stored in files you own.

## The Formats

| Extension | System | Purpose | 20-Year Size |
|-----------|--------|---------|--------------|
| .amem | AgenticMemory | Conversations, decisions, preferences | 1-2 GB |
| .avis | AgenticVision | Visual captures, diffs, evidence | 5-8 GB |
| .acb | AgenticCodebase | Semantic code graphs | 2-3 GB |
| .aid | AgenticIdentity | Receipts, trust, continuity | 0.5-1 GB |

**Total: ~10-15 GB for 20 years of cognitive history**

## Two Purposes

### 1. Retention
Store decades of interaction history:
- Every conversation (.amem)
- Every page seen (.avis)
- Every codebase understood (.acb)
- Every action signed (.aid)

Portable. Works offline. Forever yours.

### 2. Capability Enrichment
Load these files into ANY model:
- Local Llama + your .amem = personalized agent
- New Claude + your .acb = grounded code knowledge
- Any model + your .aid = earned trust

**The model is commodity. The files are value.**

## File Location

```
~/.agentic/
├── memory.amem
├── vision.avis
├── codebase.acb
└── identity.aid
```

## Portability

Every .a* file is:
- **Self-contained**: Single file, no dependencies
- **Portable**: Copy to new machine, works immediately
- **Model-agnostic**: Works with any AI model
- **Versioned**: Format evolves, never breaks old files
```

**NOTE:** No "coming soon" formats. Just the 4 currently available.

---

### NEW PAGE: /docs/en/grounding

```markdown
# Grounding (Anti-Hallucination)

Your agent cannot claim what it cannot prove.

## The Problem

AI models hallucinate:
- "Function validate_token exists" (it doesn't)
- "You said you prefer Python" (no memory of that)
- "The page shows a checkout button" (no capture exists)

## The Solution

Every claim must be grounded in stored data.

| System | Grounding Rule |
|--------|----------------|
| Memory | Can't claim "you said X" without memory node |
| Vision | Can't claim "page shows X" without capture |
| Codebase | Can't claim "function exists" without graph node |
| Identity | Can't claim "has permission" without trust grant |

## MCP Tools

```
memory_ground      Verify memory claim
vision_ground      Verify visual claim  
codebase_ground    Verify code claim
identity_ground    Verify authority claim
```

## Example

```
User: "Does the authenticate() function exist?"

WITHOUT GROUNDING:
Agent: "Yes, authenticate() is in src/auth.rs"
       (may be hallucinated)

WITH GROUNDING:
Agent: [calls codebase_ground("authenticate function")]
       → Verified: src/auth.rs:142
       
Agent: "Yes, authenticate() exists at line 142."
       (proven — cannot be hallucination)
```
```

---

### NEW PAGE: /docs/en/multi-context

```markdown
# Multi-Context Workspaces

Load and query multiple data sources simultaneously.

## Use Cases

| System | Multi-Context Example |
|--------|----------------------|
| Memory | Query across multiple projects |
| Vision | Compare competitor sites |
| Codebase | Load source + target for migration |
| Identity | Compare agent permissions |

## Codebase Example: Migration

```bash
# Create workspace
acb workspace create cpp-to-rust

# Add source and target
acb workspace add cpp-to-rust ./legacy-cpp --role source
acb workspace add cpp-to-rust ./new-rust --role target

# Query across both
acb workspace query cpp-to-rust "AuthManager"

# Track progress
acb translation progress cpp-to-rust
# Output: 15/23 modules ported (65%)
```

## MCP Tools

Each system provides:
- `{system}_workspace_create`
- `{system}_workspace_add`
- `{system}_workspace_list`
- `{system}_workspace_query`
- `{system}_workspace_compare`
- `{system}_workspace_xref`
```

---

### UPDATE: Command Surface Pages

Add V2 tools to each sister's command surface doc.

**Memory — Add:**
```
## Grounding Tools (v0.3)
| Tool | Purpose |
|------|---------|
| memory_ground | Verify claim has memory backing |
| memory_evidence | Get evidence for claim |
| memory_suggest | Find similar memories |

## Workspace Tools (v0.3)
| Tool | Purpose |
|------|---------|
| memory_workspace_create | Create multi-memory workspace |
| memory_workspace_add | Add .amem file |
| memory_workspace_list | List loaded memories |
| memory_workspace_query | Query across all |
| memory_workspace_compare | Compare across contexts |
| memory_workspace_xref | Find topic distribution |
```

**(Similar sections for Vision, Codebase, Identity)**

---

### UPDATE: Nav Structure

```
Overview▾
├── Documentation
├── Glossary
├── The .a* File Ecosystem      ← NEW

AgenticMemory▾
├── ...existing...
├── Grounding                   ← NEW
├── Multi-Context               ← NEW

AgenticVision▾
├── ...existing...
├── Grounding                   ← NEW
├── Multi-Context               ← NEW

AgenticCodebase▾
├── ...existing...
├── Grounding                   ← NEW
├── Workspaces & Migration      ← NEW

AgenticIdentity▾
├── ...existing...
├── Grounding                   ← NEW
├── Multi-Context               ← NEW

Use-Case Playbooks▾
├── AI Agent Integration
├── Codebase Migration          ← NEW
```

---

## 3. GITHUB README UPDATES (PUBLIC SAFE)

### Add to Each Sister's README

**Memory:**
```markdown
## The .amem File

Your agent's memory. One file. Forever yours.

| | |
|-|-|
| Size | ~1-2 GB over 20 years |
| Format | Binary graph, portable |
| Works with | Claude, GPT, Llama, any model |

**Two purposes:**
1. **Retention**: 20 years of conversations, decisions, preferences
2. **Enrichment**: Load into ANY model — suddenly it knows you

The model is commodity. Your .amem is value.

## v0.3: Grounding & Workspaces

**Grounding**: Agent cannot claim "you said X" without memory evidence.

**Workspaces**: Query across multiple .amem files simultaneously.
```

**Vision:**
```markdown
## The .avis File

Your agent's visual memory. Everything it's seen.

| | |
|-|-|
| Size | ~5-8 GB over 20 years |
| Format | Binary captures with embeddings |
| Works with | Any vision-capable model |

## v0.2: Grounding & Workspaces

**Grounding**: Agent cannot claim "page shows X" without capture evidence.

**Workspaces**: Compare across sites and time periods.
```

**Codebase:**
```markdown
## The .acb File

Your agent's code knowledge. Semantic understanding.

| | |
|-|-|
| Size | ~2-3 GB over 20 years |
| Format | Binary semantic graph |
| Works with | Any coding model |

## v0.2: Grounding, Workspaces & Translation

**Grounding**: Agent cannot claim code exists without graph evidence.

**Workspaces**: Load source + target codebases for migration.

**Translation**: Track what's ported, what remains.

```bash
acb workspace create cpp-to-rust
acb workspace add cpp-to-rust ./legacy --role source
acb workspace add cpp-to-rust ./new --role target
acb translation progress cpp-to-rust
# 65% complete
```
```

**Identity:**
```markdown
## The .aid File

Your agent's identity. Continuous. Verifiable.

| | |
|-|-|
| Size | ~0.5-1 GB over 20 years |
| Format | Cryptographic chain |
| Works with | Any model needing accountability |

## v0.2: Grounding & Workspaces

**Grounding**: Agent cannot claim permission without trust grant evidence.

**Workspaces**: Compare permissions across agents.
```

---

## 4. SOCIAL ANNOUNCEMENT (PUBLIC SAFE)

```
V2 is now available across all four Agentra systems.

NEW:
• Grounding — agent cannot claim what it cannot prove
• Workspaces — load multiple sources, query across all
• Translation tracking — for code migrations

The real insight:

Your .amem file has 20 years of YOUR conversations.
Your .acb file has YOUR codebases mapped.
Your .aid file has YOUR agent's earned trust.

Load these into ANY model — Claude, GPT, Llama, local.
The "dumb" model becomes YOUR intelligent agent.

The model is commodity. The files are value.

.amem · .avis · .acb · .aid

Open source. MIT license.
www.agentralabs.tech
```

**NOTE:** No mention of future sisters, Hydra, or roadmap. Use professional tone — no "shipped!"

---

## STEALTH CHECKLIST

```
✅ Only show 4 released sisters
✅ No "coming soon" file formats
✅ No Hydra mention
✅ No AgenticOS mention
✅ No roadmap hints
✅ No cognitive/relational/depth layer mention
✅ Each sister presented as standalone system
✅ Competitors see 4 products, not 25-sister architecture
```

---

## SUMMARY

```
CURRENTLY AVAILABLE:
────────────────────
.amem   Memory      v0.3.0
.avis   Vision      v0.2.0
.acb    Codebase    v0.2.0
.aid    Identity    v0.2.0

V2 features (grounding + workspaces)
.a* file value proposition
"Model is commodity, files are value"

PUBLIC HIDES:
─────────────
6 more foundation sisters
4 cognitive sisters
3 relational sisters
4 depth sisters
4 hardware sisters
Hydra
Safety architecture
25-sister plan
Post-Hydra roadmap
```

Competitors see innovative memory tools.
We see the 80s internet before anyone else.
