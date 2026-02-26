Hydra's LLM Philosophy
NOT THIS:
─────────
"Never use Claude API"

THIS:
─────
"Use Claude API when needed, but be the MOST EFFICIENT consumer possible"

The Token Minimization Stack
LAYER 1: AVOID (Don't call LLM at all)
──────────────────────────────────────
- Action Compilation     → Repeated tasks need no LLM
- Compiled Skills        → Known patterns run directly
- Sister Queries         → Memory/Vision/Codebase answer without LLM
- Cached Responses       → Same question = same answer

LAYER 2: REDUCE (When LLM needed, minimize tokens)
──────────────────────────────────────────────────
- Context Gravity        → Only load relevant context
- Local Summarizer       → Compress DOM/logs before sending
- Sister Context         → .amem summary instead of full history
- Smart Truncation       → Send minimum viable context

LAYER 3: ROUTE (Use cheapest model that works)
──────────────────────────────────────────────
- Local First           → Llama/Mistral for simple tasks
- Haiku for Triage      → Cheap model decides if expensive needed
- Sonnet for Work       → Standard tasks
- Opus for Complex      → Only when truly needed

LAYER 4: OPTIMIZE (When using Claude, be surgical)
──────────────────────────────────────────────────
- Structured Prompts    → Less tokens to explain format
- Tool-First            → Let tools do work, not text
- Incremental Context   → Don't resend what Claude knows
- Response Budgets      → "Answer in <100 tokens"

When Hydra MUST Use Claude API
NECESSARY LLM USE:
──────────────────
- Natural language understanding (user intent)
- Complex reasoning (multi-step planning)
- Novel situations (never seen before)
- Creative tasks (writing, synthesis)
- Ambiguity resolution (unclear requests)

UNNECESSARY LLM USE (eliminate):
────────────────────────────────
- Repeated identical tasks
- Simple lookups (use sisters)
- Known patterns (use compiled actions)
- Format conversion (deterministic)
- Status checks (direct queries)

The Efficiency Metrics
TRACK AND DISPLAY:
──────────────────
- Tokens used this run
- Tokens saved (vs naive approach)
- Cache hit rate
- Local model percentage
- Compiled action percentage

EXAMPLE OUTPUT:
───────────────
Run complete.
Tokens: 3,240 (Claude API)
Saved:  12,800 tokens (80%)
  ├── Compiled actions:  4,200 (33%)
  ├── Cache hits:        3,100 (24%)
  ├── Local model:       2,500 (20%)
  └── Context compression: 3,000 (23%)

The Cost Engine (Updated)
hydra_core/
├── cost_engine/
│   ├── token_minimizer/
│   │   ├── can_avoid_llm/         # Check compiled actions, cache
│   │   ├── can_use_local/         # Check if local model works
│   │   ├── context_compressor/    # Minimize what's sent
│   │   └── response_budgeter/     # Limit response size
│   │
│   ├── model_router/
│   │   ├── task_classifier/       # What kind of task?
│   │   ├── model_selector/        # Cheapest that works
│   │   ├── local_pool/            # Llama, Mistral, etc.
│   │   └── api_pool/              # Haiku → Sonnet → Opus
│   │
│   ├── efficiency_tracker/
│   │   ├── tokens_used/           # What we spent
│   │   ├── tokens_saved/          # What we avoided
│   │   ├── savings_breakdown/     # By method
│   │   └── trend_analysis/        # Getting more efficient?
│   │
│   └── billing_optimizer/
│       ├── batch_requests/        # Combine when possible
│       ├── prompt_caching/        # Reuse prompt prefixes
│       └── off_peak_scheduling/   # If not urgent, wait

The Principle
"Every token to Claude API should EARN its place."

Before sending ANY token:
1. Can we avoid this call entirely?
2. Can a local model handle it?
3. Can we compress the context?
4. Can we limit the response?
5. Are we using the cheapest model that works?

Only after all 5: Send to Claude API.

Real Example
USER: "What did I decide about the database last week?"

NAIVE APPROACH:
───────────────
Send to Claude: "User asks about database decision from last week.
Here's their full conversation history: [50,000 tokens of context]
What did they decide?"

Cost: ~50,000 tokens

HYDRA APPROACH:
───────────────
1. Query Memory sister: memory_query("database decision", time_range="last_week")
2. Memory returns: "Decision: PostgreSQL for ACID compliance (Feb 20)"
3. No LLM needed at all

Cost: 0 tokens

OR if LLM needed for synthesis:
1. Query Memory → Get 3 relevant memories (200 tokens)
2. Send to Claude: "Summarize these database decisions: [200 tokens]"
3. Response: 50 tokens

Cost: 250 tokens (vs 50,000)

Summary
HYDRA + CLAUDE API:
───────────────────
✓ Uses Claude when genuinely needed
✓ Minimizes tokens through every layer
✓ Routes to cheapest effective model
✓ Tracks and displays savings
✓ Makes efficiency visible to user

THE GOAL:
─────────
Not "never use Claude"
But "use Claude 10x more efficiently than anyone else"
