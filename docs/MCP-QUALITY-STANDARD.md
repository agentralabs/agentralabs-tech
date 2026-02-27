# MCP Quality Standard (Agentra)

**Status:** Canonical (normative)
**Scope:** All current and future Agentra sister MCP servers
**Enforced by:** `scripts/check-canonical-consistency.sh` sections 42-43

This document defines the quality standard for all Agentra MCP server implementations. Every sister must conform to these rules. New sisters inherit them by default via `docs/NEW-SISTER-PLAYBOOK.md`.

---

## 1. Tool Descriptions

### Format
- **Verb-first** (imperative mood): Start with Add, Get, Search, Verify, Create, List, etc.
- **1-2 sentences max**, 10-50 words
- **No trailing period** on single-sentence descriptions
- State what data comes back when relevant
- Do NOT put parameter details in the tool description — those belong in schema descriptions

### Examples

```
Good:  "Add a new cognitive event to the memory graph"
Good:  "Verify a claim has memory backing. Returns verified/partial/ungrounded status"
Good:  "Search for memories matching conditions using pattern queries"
Bad:   "This tool adds a memory."          (passive, period)
Bad:   "memory_add"                        (just repeats the name)
Bad:   "Adds a memory event with type, content, confidence, and optional edges"  (lists params)
```

### Description Template
```
{Verb} {what} {from/for/in what}
```
Or for tools that return structured data:
```
{Verb} {what}. Returns {output description}
```

---

## 2. Parameter Schemas

### Required Practices
- Every parameter MUST have a `"description"` field
- `"required"` array MUST be present (even if empty `[]`)
- Use `"enum"` for constrained string choices — never open strings for known value sets
- Use `"minimum"`, `"maximum"` for numeric bounds
- Use `"default"` for optional parameters with sensible defaults
- Use `"format": "date-time"` for ISO 8601 timestamps
- Flatten arguments — prefer top-level primitives over nested objects

### Behavioral Hints in Descriptions
Add LLM instructions directly in parameter descriptions where they improve tool usage:

```json
{
  "depth": {
    "type": "number",
    "default": 5,
    "description": "Maximum traversal depth. Only increase if explicitly requested"
  },
  "graph": {
    "type": "string",
    "description": "Graph name. Omit to use the auto-detected project graph"
  },
  "min_confidence": {
    "type": "number",
    "minimum": 0.0,
    "maximum": 1.0,
    "description": "Minimum confidence threshold (0.0 to 1.0). Default 0.0 includes all results"
  }
}
```

### Anti-patterns
- `"description": "The name"` — too vague, restate the field name
- No description at all — forces the LLM to guess
- Nested objects for what could be flat params — confuses LLMs
- `"type": "string"` with no enum for a known set like `["exact", "prefix", "contains", "fuzzy"]`

---

## 3. Error Handling (MCP Spec Compliance)

### Two-Tier Error Model

**Tier 1: Protocol Errors** — JSON-RPC error response

For failures in the protocol layer (before a tool executes):

```json
{"jsonrpc": "2.0", "id": 1, "error": {"code": -32700, "message": "Parse error"}}
```

| Code | Name | When to use |
|------|------|------------|
| -32700 | Parse error | Malformed JSON |
| -32600 | Invalid request | Missing jsonrpc/method fields |
| -32601 | Method not found | Unknown JSON-RPC method |
| -32602 | Invalid params | Malformed params structure |
| -32603 | Internal error | Unexpected server failure |
| -32803 | Tool not found | Unknown tool name in tools/call |

**Tier 2: Tool Execution Errors** — Successful response with `isError: true`

For failures within a tool's business logic (the tool was found and invoked):

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [{"type": "text", "text": "Node 42 not found. Use memory_query to search for existing nodes"}],
    "isError": true
  }
}
```

### The Rule

> If the tool was found and invoked, all errors go through `isError: true`.
> JSON-RPC errors are ONLY for protocol/routing failures.

This is critical because MCP clients (Claude, Cursor, etc.) treat JSON-RPC errors and `isError` results differently. Tool execution errors with `isError: true` allow the LLM to self-correct. JSON-RPC errors may cause the client to stop trying.

### Error Message Quality
- Human-readable text the LLM can reason about
- Include what went wrong AND what to try instead
- Never return raw error codes or stack traces

```
Good: "Node 42 not found. Use memory_query to search for existing nodes first"
Good: "Invalid event_type 'foo'. Must be one of: fact, decision, inference, correction, skill, episode"
Bad:  "NotFound"
Bad:  "Error code -32850"
Bad:  "thread 'main' panicked at 'index out of bounds'"
```

---

## 4. Unknown Tool Response

Standard across all sisters — use code -32803 (TOOL_NOT_FOUND):

```json
{"jsonrpc": "2.0", "id": 1, "error": {"code": -32803, "message": "Tool not found: foo_bar"}}
```

Never use -32602 (INVALID_PARAMS) for unknown tools. They are different errors:
- -32602: The tool exists but the parameters are wrong
- -32803: The tool does not exist at all

---

## 5. Tool Naming Convention

```
{sister_prefix}_{action}              # Core tools
{sister_prefix}_{category}_{action}   # Extended/invention tools
```

| Sister | Prefix |
|--------|--------|
| Memory | `memory_` |
| Vision | `vision_` |
| Codebase | (various: `symbol_`, `impact_`, `graph_`, etc.) |
| Identity | `identity_`, `action_`, `trust_`, `spawn_`, etc. |
| Time | `time_` |

Context-capture tools follow their own pattern: `conversation_log`, `observation_log`, `analysis_log`, `action_context`.

---

## 6. Tool Count Strategy

- **Core tools**: 5-25 per sister (the essential MCP surface)
- **Extended/Invention tools**: Group via name prefixes for discoverability
- Tool descriptions for extended tools should clearly indicate their category
- Consider lazy-loading invention tools only when explicitly enabled (future optimization)

---

## 7. Rust Implementation Patterns

### Recommended ToolDefinition Type
```rust
pub struct ToolDefinition {
    pub name: String,
    pub description: Option<String>,
    #[serde(rename = "inputSchema")]
    pub input_schema: serde_json::Value,
}
```

### Recommended Tool Error Pattern
```rust
// In the tool handler, return ToolCallResult::error() for business logic failures
pub async fn execute(args: Value, session: &Session) -> McpResult<ToolCallResult> {
    let node_id = args.get("node_id")
        .and_then(|v| v.as_u64())
        .ok_or_else(|| McpError::InvalidParams("node_id is required".into()))?;

    match session.get_node(node_id) {
        Ok(node) => Ok(ToolCallResult::json(&node)),
        Err(e) => Ok(ToolCallResult::error(
            format!("Node {} not found. Use memory_query to search for existing nodes", node_id)
        )),
    }
}
```

### Protocol vs Tool Error Classification
```rust
impl McpError {
    /// Returns true if this is a protocol-level error (should be JSON-RPC error)
    pub fn is_protocol_error(&self) -> bool {
        matches!(self,
            McpError::ParseError(_) |
            McpError::InvalidRequest(_) |
            McpError::MethodNotFound(_) |
            McpError::InvalidParams(_) |
            McpError::ToolNotFound(_)
        )
    }
}
```

In the protocol handler:
```rust
match ToolRegistry::call(name, args, session).await {
    Ok(result) => serialize_success(id, result),
    Err(e) if e.is_protocol_error() => serialize_json_rpc_error(id, e),
    Err(e) => serialize_success(id, ToolCallResult::error(e.to_string())),
}
```

---

## Change Control

Any exception to this standard requires explicit written approval. New sisters must pass sections 42-43 of the canonical consistency check before first release.
