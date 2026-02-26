# MCP TOOL STANDARDS

> **Status:** MANDATORY
> **Version:** 1.0
> **Date:** February 2026
> **Compliance:** All sister MCP servers MUST comply.

---

## Executive Summary

This document defines the **MCP tool naming conventions, schemas, and behaviors** for all sisters. Any MCP client (Claude Code, Cursor, Windsurf, Hydra, etc.) can interact with any sister using these standards.

### The Promise

```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ANY MCP client can use ANY sister.                          ║
║   Tool names are predictable.                                 ║
║   Schemas are consistent.                                     ║
║   Errors are uniform.                                         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

### Relationship to Native Contract

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  SISTER-HYDRA-INTEGRATION-CONTRACT.md    MCP-TOOL-STANDARDS.md │
│  ─────────────────────────────────────   ──────────────────────│
│                                                                 │
│  For: Native Rust integration            For: MCP protocol      │
│  Path: Direct function calls             Path: JSON-RPC         │
│  Speed: Sub-millisecond                  Speed: ~10-50ms        │
│  Use: Local, embedded                    Use: Universal, remote │
│                                                                 │
│  BOTH ARE VALID. BOTH ARE NEEDED.                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1. TOOL NAMING CONVENTION

### 1.1 The Pattern

```
TOOL NAME FORMAT:
─────────────────

{sister}_{action}

EXAMPLES:
─────────
memory_add
memory_query
memory_ground
vision_capture
vision_compare
codebase_impact
identity_sign
```

### 1.2 Sister Prefixes

```
┌─────────────────────────────────────────────────────────────────┐
│                    SISTER PREFIXES                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  SISTER              PREFIX         FILE EXTENSION              │
│  ──────────────────────────────────────────────────────────    │
│  AgenticMemory       memory_        .amem                       │
│  AgenticVision       vision_        .avis                       │
│  AgenticCodebase     codebase_      .acb                        │
│  AgenticIdentity     identity_      .aid                        │
│  AgenticTime         time_          .atime                      │
│  AgenticContract     contract_      .acon                       │
│  AgenticComm         comm_          .acomm                      │
│  AgenticPlanning     planning_      .aplan                      │
│  AgenticCognition    cognition_     .acog                       │
│  AgenticReality      reality_       .areal                      │
│                                                                 │
│  HYDRA (when acting as MCP server):                            │
│  Hydra               hydra_         N/A                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Action Naming Rules

```
ACTION NAMING:
──────────────

• Use lowercase
• Use underscores for multi-word
• Use verbs for actions: add, create, delete, query, get
• Use nouns for retrievals: list, info, status

GOOD:
─────
memory_add
memory_session_resume
vision_capture_url
codebase_impact_analysis

BAD:
────
memoryAdd              (camelCase)
memory-add             (hyphens)
Memory_Add             (uppercase)
addMemory              (wrong order)
```

---

## 2. REQUIRED TOOLS (ALL SISTERS)

### 2.1 Universal Tools

Every sister MCP server MUST expose these tools:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       REQUIRED TOOLS (ALL SISTERS)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  TOOL NAME                    PURPOSE                                       │
│  ─────────────────────────────────────────────────────────────────────────  │
│                                                                             │
│  LIFECYCLE:                                                                 │
│  {sister}_health              Health check, status                          │
│  {sister}_info                Version, capabilities                         │
│                                                                             │
│  CONTEXT MANAGEMENT:                                                        │
│  {sister}_context_create      Create new context                            │
│  {sister}_context_switch      Switch to context                             │
│  {sister}_context_current     Get current context                           │
│  {sister}_context_list        List all contexts                             │
│  {sister}_context_delete      Delete a context                              │
│                                                                             │
│  GROUNDING (V2):                                                            │
│  {sister}_ground              Ground a claim against evidence               │
│                                                                             │
│  QUERY:                                                                     │
│  {sister}_query               Flexible query interface                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. TOOL SCHEMAS

### 3.1 Lifecycle Tools

#### {sister}_health

```json
{
  "name": "{sister}_health",
  "description": "Check health status of the sister",
  "inputSchema": {
    "type": "object",
    "properties": {},
    "required": []
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "healthy": {
        "type": "boolean",
        "description": "Is the sister operational?"
      },
      "status": {
        "type": "string",
        "enum": ["starting", "ready", "busy", "degraded", "error"],
        "description": "Current status"
      },
      "uptime_seconds": {
        "type": "number",
        "description": "Seconds since initialization"
      },
      "memory_bytes": {
        "type": "number",
        "description": "Current memory usage"
      },
      "warnings": {
        "type": "array",
        "items": { "type": "string" },
        "description": "Non-fatal warnings"
      }
    },
    "required": ["healthy", "status"]
  }
}
```

#### {sister}_info

```json
{
  "name": "{sister}_info",
  "description": "Get sister information and capabilities",
  "inputSchema": {
    "type": "object",
    "properties": {},
    "required": []
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "sister_type": {
        "type": "string",
        "description": "Sister identifier (memory, vision, etc.)"
      },
      "version": {
        "type": "string",
        "description": "Semantic version (e.g., 0.3.2)"
      },
      "file_extension": {
        "type": "string",
        "description": "File format extension (e.g., amem)"
      },
      "capabilities": {
        "type": "array",
        "items": { "type": "string" },
        "description": "List of capabilities"
      },
      "tools": {
        "type": "array",
        "items": { "type": "string" },
        "description": "List of available MCP tools"
      }
    },
    "required": ["sister_type", "version", "capabilities", "tools"]
  }
}
```

### 3.2 Context Management Tools

#### {sister}_context_create

```json
{
  "name": "{sister}_context_create",
  "description": "Create a new context (session/workspace/archive)",
  "inputSchema": {
    "type": "object",
    "properties": {
      "name": {
        "type": "string",
        "description": "Human-readable context name"
      },
      "metadata": {
        "type": "object",
        "description": "Optional metadata for the context"
      }
    },
    "required": ["name"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "context_id": {
        "type": "string",
        "description": "Unique context identifier (UUID)"
      },
      "name": {
        "type": "string",
        "description": "Context name"
      },
      "created_at": {
        "type": "string",
        "format": "date-time",
        "description": "Creation timestamp (ISO 8601)"
      }
    },
    "required": ["context_id", "name", "created_at"]
  }
}
```

#### {sister}_context_switch

```json
{
  "name": "{sister}_context_switch",
  "description": "Switch to a different context",
  "inputSchema": {
    "type": "object",
    "properties": {
      "context_id": {
        "type": "string",
        "description": "Context ID to switch to"
      }
    },
    "required": ["context_id"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "success": {
        "type": "boolean"
      },
      "previous_context_id": {
        "type": "string",
        "description": "Context ID we switched from"
      },
      "current_context_id": {
        "type": "string",
        "description": "Context ID we switched to"
      }
    },
    "required": ["success", "current_context_id"]
  }
}
```

#### {sister}_context_current

```json
{
  "name": "{sister}_context_current",
  "description": "Get current context information",
  "inputSchema": {
    "type": "object",
    "properties": {},
    "required": []
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "context_id": {
        "type": "string"
      },
      "name": {
        "type": "string"
      },
      "created_at": {
        "type": "string",
        "format": "date-time"
      },
      "updated_at": {
        "type": "string",
        "format": "date-time"
      },
      "item_count": {
        "type": "number"
      },
      "size_bytes": {
        "type": "number"
      }
    },
    "required": ["context_id", "name"]
  }
}
```

#### {sister}_context_list

```json
{
  "name": "{sister}_context_list",
  "description": "List all available contexts",
  "inputSchema": {
    "type": "object",
    "properties": {
      "limit": {
        "type": "number",
        "description": "Maximum number to return"
      },
      "offset": {
        "type": "number",
        "description": "Offset for pagination"
      }
    },
    "required": []
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "contexts": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "context_id": { "type": "string" },
            "name": { "type": "string" },
            "created_at": { "type": "string", "format": "date-time" },
            "updated_at": { "type": "string", "format": "date-time" },
            "item_count": { "type": "number" }
          }
        }
      },
      "total_count": {
        "type": "number"
      }
    },
    "required": ["contexts"]
  }
}
```

#### {sister}_context_delete

```json
{
  "name": "{sister}_context_delete",
  "description": "Delete a context",
  "inputSchema": {
    "type": "object",
    "properties": {
      "context_id": {
        "type": "string",
        "description": "Context ID to delete"
      },
      "confirm": {
        "type": "boolean",
        "description": "Must be true to confirm deletion"
      }
    },
    "required": ["context_id", "confirm"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "success": { "type": "boolean" },
      "deleted_context_id": { "type": "string" },
      "items_deleted": { "type": "number" }
    },
    "required": ["success"]
  }
}
```

### 3.3 Grounding Tool (V2 Pattern)

#### {sister}_ground

```json
{
  "name": "{sister}_ground",
  "description": "Ground a claim against evidence. Returns whether the claim is supported by the evidence.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "claim": {
        "type": "string",
        "description": "The claim being made (natural language)"
      },
      "evidence_id": {
        "type": "string",
        "description": "ID of evidence to ground against"
      },
      "aspect": {
        "type": "string",
        "description": "Optional: specific aspect to check"
      }
    },
    "required": ["claim", "evidence_id"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "grounded": {
        "type": "boolean",
        "description": "Is the claim supported by the evidence?"
      },
      "confidence": {
        "type": "number",
        "minimum": 0,
        "maximum": 1,
        "description": "Confidence level (0.0 = no support, 1.0 = full support)"
      },
      "explanation": {
        "type": "string",
        "description": "Human-readable explanation of grounding decision"
      },
      "grounding_id": {
        "type": "string",
        "description": "Unique ID for this grounding (for receipts)"
      },
      "evidence": {
        "type": "object",
        "description": "The evidence used",
        "properties": {
          "id": { "type": "string" },
          "type": { "type": "string" },
          "captured_at": { "type": "string", "format": "date-time" },
          "summary": { "type": "string" }
        }
      },
      "timestamp": {
        "type": "string",
        "format": "date-time"
      }
    },
    "required": ["grounded", "confidence", "grounding_id", "timestamp"]
  }
}
```

### 3.4 Query Tool

#### {sister}_query

```json
{
  "name": "{sister}_query",
  "description": "Flexible query interface for the sister",
  "inputSchema": {
    "type": "object",
    "properties": {
      "query_type": {
        "type": "string",
        "description": "Type of query (list, search, recent, related, temporal)"
      },
      "params": {
        "type": "object",
        "description": "Query-specific parameters"
      },
      "limit": {
        "type": "number",
        "description": "Maximum results"
      },
      "offset": {
        "type": "number",
        "description": "Offset for pagination"
      },
      "context_id": {
        "type": "string",
        "description": "Optional: query in specific context"
      }
    },
    "required": ["query_type"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "results": {
        "type": "array",
        "description": "Query results (structure depends on sister)"
      },
      "total_count": {
        "type": "number",
        "description": "Total matching items (if known)"
      },
      "has_more": {
        "type": "boolean",
        "description": "Whether there are more results"
      },
      "query_time_ms": {
        "type": "number",
        "description": "Query execution time in milliseconds"
      }
    },
    "required": ["results"]
  }
}
```

---

## 4. SISTER-SPECIFIC TOOLS

### 4.1 Memory Tools

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          MEMORY-SPECIFIC TOOLS                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  TOOL                        PURPOSE                                        │
│  ─────────────────────────────────────────────────────────────────────────  │
│  memory_add                  Add a memory node                              │
│  memory_relate               Create relationship between nodes              │
│  memory_similar              Find similar memories (embedding search)       │
│  memory_temporal             Query by time range                            │
│  memory_traverse             Walk the graph from a starting node            │
│  memory_session_resume       Resume previous session with context           │
│  memory_summarize            Get summary of memory graph                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### memory_add

```json
{
  "name": "memory_add",
  "description": "Add a memory node to the graph",
  "inputSchema": {
    "type": "object",
    "properties": {
      "content": {
        "type": "string",
        "description": "Memory content"
      },
      "node_type": {
        "type": "string",
        "enum": ["episode", "fact", "concept", "procedure", "preference", "reflection"],
        "description": "Type of memory"
      },
      "importance": {
        "type": "number",
        "minimum": 0,
        "maximum": 1,
        "description": "Importance score (0.0-1.0)"
      },
      "tags": {
        "type": "array",
        "items": { "type": "string" },
        "description": "Optional tags"
      },
      "caused_by": {
        "type": "string",
        "description": "Optional: ID of memory that caused this"
      },
      "metadata": {
        "type": "object",
        "description": "Optional metadata"
      }
    },
    "required": ["content", "node_type"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "node_id": { "type": "string" },
      "created_at": { "type": "string", "format": "date-time" }
    },
    "required": ["node_id", "created_at"]
  }
}
```

#### memory_session_resume

```json
{
  "name": "memory_session_resume",
  "description": "Resume a previous session with full context",
  "inputSchema": {
    "type": "object",
    "properties": {
      "session_id": {
        "type": "string",
        "description": "Optional: specific session ID to resume"
      },
      "last_n": {
        "type": "number",
        "description": "Optional: resume last N sessions"
      }
    },
    "required": []
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "session_id": { "type": "string" },
      "summary": { "type": "string" },
      "key_memories": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "node_id": { "type": "string" },
            "content": { "type": "string" },
            "importance": { "type": "number" }
          }
        }
      },
      "context_restored": { "type": "boolean" }
    },
    "required": ["session_id", "context_restored"]
  }
}
```

### 4.2 Vision Tools

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          VISION-SPECIFIC TOOLS                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  TOOL                        PURPOSE                                        │
│  ─────────────────────────────────────────────────────────────────────────  │
│  vision_capture              Capture screenshot of URL or screen            │
│  vision_capture_url          Capture specific URL                           │
│  vision_compare              Compare two captures                           │
│  vision_diff                 Get visual diff between captures               │
│  vision_similar              Find visually similar captures                 │
│  vision_ocr                  Extract text from capture                      │
│  vision_describe             Get AI description of capture                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### vision_capture

```json
{
  "name": "vision_capture",
  "description": "Capture a screenshot",
  "inputSchema": {
    "type": "object",
    "properties": {
      "url": {
        "type": "string",
        "description": "URL to capture (optional if capturing screen)"
      },
      "selector": {
        "type": "string",
        "description": "CSS selector to capture specific element"
      },
      "full_page": {
        "type": "boolean",
        "description": "Capture full scrollable page"
      },
      "label": {
        "type": "string",
        "description": "Human-readable label for this capture"
      }
    },
    "required": []
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "capture_id": { "type": "string" },
      "url": { "type": "string" },
      "timestamp": { "type": "string", "format": "date-time" },
      "dimensions": {
        "type": "object",
        "properties": {
          "width": { "type": "number" },
          "height": { "type": "number" }
        }
      },
      "fingerprint": { "type": "string" }
    },
    "required": ["capture_id", "timestamp"]
  }
}
```

### 4.3 Codebase Tools

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CODEBASE-SPECIFIC TOOLS                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  TOOL                        PURPOSE                                        │
│  ─────────────────────────────────────────────────────────────────────────  │
│  codebase_build              Build/update codebase graph                    │
│  codebase_query              Query the code graph                           │
│  codebase_impact             Analyze impact of changes                      │
│  codebase_prophecy           Predict effects of modifications               │
│  codebase_navigate           Navigate code concepts                         │
│  codebase_workspace          Get/set current workspace                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### codebase_impact

```json
{
  "name": "codebase_impact",
  "description": "Analyze impact of changing a code element",
  "inputSchema": {
    "type": "object",
    "properties": {
      "target": {
        "type": "string",
        "description": "File path or symbol to analyze"
      },
      "change_type": {
        "type": "string",
        "enum": ["modify", "delete", "rename"],
        "description": "Type of change"
      },
      "depth": {
        "type": "number",
        "description": "How deep to trace impact (default: 3)"
      }
    },
    "required": ["target"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "target": { "type": "string" },
      "direct_dependents": {
        "type": "array",
        "items": { "type": "string" }
      },
      "indirect_dependents": {
        "type": "array",
        "items": { "type": "string" }
      },
      "risk_level": {
        "type": "string",
        "enum": ["low", "medium", "high", "critical"]
      },
      "recommendation": { "type": "string" }
    },
    "required": ["target", "direct_dependents", "risk_level"]
  }
}
```

### 4.4 Identity Tools

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         IDENTITY-SPECIFIC TOOLS                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  TOOL                        PURPOSE                                        │
│  ─────────────────────────────────────────────────────────────────────────  │
│  identity_sign               Sign data with identity key                    │
│  identity_verify             Verify a signature                             │
│  identity_receipt            Create action receipt                          │
│  identity_trust_grant        Grant trust to another agent                   │
│  identity_trust_check        Check trust level                              │
│  identity_competence         Record competence proof                        │
│  identity_spawn              Create child identity                          │
│  identity_lineage            Get identity lineage                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### identity_receipt

```json
{
  "name": "identity_receipt",
  "description": "Create a signed receipt for an action",
  "inputSchema": {
    "type": "object",
    "properties": {
      "action_type": {
        "type": "string",
        "description": "Type of action being receipted"
      },
      "action_data": {
        "type": "object",
        "description": "Action parameters and results"
      },
      "evidence_ids": {
        "type": "array",
        "items": { "type": "string" },
        "description": "IDs of supporting evidence"
      },
      "outcome": {
        "type": "string",
        "enum": ["success", "failure", "partial"],
        "description": "Action outcome"
      }
    },
    "required": ["action_type", "outcome"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "receipt_id": { "type": "string" },
      "signature": { "type": "string" },
      "timestamp": { "type": "string", "format": "date-time" },
      "chain_position": { "type": "number" }
    },
    "required": ["receipt_id", "signature", "timestamp"]
  }
}
```

---

## 5. ERROR RESPONSES

### 5.1 Standard Error Format

All MCP tools MUST return errors in this format:

```json
{
  "error": {
    "code": "string (machine-readable)",
    "message": "string (human-readable)",
    "recoverable": "boolean",
    "suggested_action": "string (optional)",
    "details": "object (optional)"
  }
}
```

### 5.2 Standard Error Codes

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         STANDARD ERROR CODES                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  CODE                    MEANING                    RECOVERABLE             │
│  ─────────────────────────────────────────────────────────────────────────  │
│                                                                             │
│  NOT_FOUND              Resource not found          Yes                     │
│  INVALID_INPUT          Bad input parameters        Yes (fix input)         │
│  PERMISSION_DENIED      Not authorized              Maybe (get permission)  │
│  STORAGE_ERROR          File I/O failed             Yes (retry)             │
│  NETWORK_ERROR          Network request failed      Yes (retry)             │
│  TIMEOUT                Operation timed out         Yes (retry)             │
│  RESOURCE_EXHAUSTED     Limits exceeded             Yes (wait)              │
│  CONTEXT_NOT_FOUND      Context doesn't exist       Yes (create it)         │
│  EVIDENCE_NOT_FOUND     Evidence doesn't exist      No                      │
│  GROUNDING_FAILED       Grounding check failed      No (claim not supported)│
│  VERSION_MISMATCH       Incompatible version        Maybe (upgrade)         │
│  CHECKSUM_MISMATCH      Data corruption             No (data lost)          │
│  ALREADY_EXISTS         Resource exists             Yes (use existing)      │
│  INVALID_STATE          Wrong state for operation   Yes (change state)      │
│  INTERNAL               Bug/unexpected error        No (report bug)         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.3 Error Examples

```json
// Not found
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Memory node abc123 not found",
    "recoverable": true,
    "suggested_action": "Check the node ID or list available nodes"
  }
}

// Invalid input
{
  "error": {
    "code": "INVALID_INPUT",
    "message": "node_type must be one of: episode, fact, concept, procedure, preference, reflection",
    "recoverable": true,
    "suggested_action": "Use a valid node_type value",
    "details": {
      "field": "node_type",
      "provided": "memory",
      "allowed": ["episode", "fact", "concept", "procedure", "preference", "reflection"]
    }
  }
}

// Grounding failed (not an error, but claim not supported)
{
  "grounded": false,
  "confidence": 0.2,
  "explanation": "The evidence shows the meeting was on Tuesday, not Monday as claimed",
  "grounding_id": "grnd_xyz789"
}
```

---

## 6. MULTI-CONTEXT PATTERN

### 6.1 The V2 Enhancement

All sisters support querying across contexts:

```json
// Query in specific context
{
  "name": "memory_query",
  "params": {
    "query_type": "search",
    "params": { "text": "meeting notes" },
    "context_id": "ctx_project_alpha"
  }
}

// Query across multiple contexts (V2 multi-context)
{
  "name": "memory_query",
  "params": {
    "query_type": "search",
    "params": { "text": "meeting notes" },
    "context_ids": ["ctx_project_alpha", "ctx_project_beta"],
    "merge_results": true
  }
}

// Query in current context (default)
{
  "name": "memory_query",
  "params": {
    "query_type": "search",
    "params": { "text": "meeting notes" }
  }
}
```

---

## 7. HYDRA MCP SERVER

### 7.1 Hydra As MCP Server

Hydra itself exposes MCP tools for AI agents to control it:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           HYDRA MCP TOOLS                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  TOOL                        PURPOSE                                        │
│  ─────────────────────────────────────────────────────────────────────────  │
│                                                                             │
│  RUN MANAGEMENT:                                                            │
│  hydra_run                   Start a new run                                │
│  hydra_run_status            Get run status                                 │
│  hydra_run_list              List runs                                      │
│  hydra_run_freeze            Pause a run                                    │
│  hydra_run_resume            Resume a paused run                            │
│  hydra_run_kill              Stop a run                                     │
│                                                                             │
│  APPROVAL:                                                                  │
│  hydra_approval_list         List pending approvals                         │
│  hydra_approval_approve      Approve an action                              │
│  hydra_approval_deny         Deny an action                                 │
│                                                                             │
│  INSPECTION:                                                                │
│  hydra_inspect               Inspect run details                            │
│  hydra_timeline              Get run timeline                               │
│  hydra_evidence              Get evidence for run                           │
│  hydra_receipts              Get receipts for run                           │
│                                                                             │
│  SISTER ACCESS:                                                             │
│  hydra_sister_status         Status of all sisters                          │
│  hydra_sister_query          Query a sister through Hydra                   │
│                                                                             │
│  CONFIGURATION:                                                             │
│  hydra_config_get            Get configuration                              │
│  hydra_config_set            Set configuration                              │
│  hydra_policy_get            Get current policy                             │
│  hydra_policy_set            Set policy                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Example: AI Agent Controlling Hydra

```json
// Claude Code tells Hydra to do something
{
  "tool": "hydra_run",
  "params": {
    "intent": "Refactor the authentication module",
    "policy": "cautious",
    "auto_approve_low_risk": true
  }
}

// Response
{
  "run_id": "run_abc123",
  "status": "planning",
  "estimated_steps": 12
}

// Check status
{
  "tool": "hydra_run_status",
  "params": { "run_id": "run_abc123" }
}

// Response
{
  "run_id": "run_abc123",
  "status": "awaiting_approval",
  "current_step": 5,
  "pending_approval": {
    "approval_id": "apr_xyz",
    "action": "Delete 3 deprecated files",
    "risk": "medium"
  }
}

// Approve
{
  "tool": "hydra_approval_approve",
  "params": { "approval_id": "apr_xyz" }
}
```

---

## 8. MCP SERVER CONFIGURATION

### 8.1 Standard Server Config

All sister MCP servers use this configuration pattern:

```json
{
  "mcpServers": {
    "agentic-memory": {
      "command": "agentic-memory-mcp",
      "args": ["--data-dir", "~/.agentic/memory"],
      "env": {
        "RUST_LOG": "info"
      }
    },
    "agentic-vision": {
      "command": "agentic-vision-mcp",
      "args": ["--data-dir", "~/.agentic/vision"],
      "env": {}
    },
    "agentic-codebase": {
      "command": "agentic-codebase-mcp",
      "args": ["--data-dir", "~/.agentic/codebase"],
      "env": {}
    },
    "agentic-identity": {
      "command": "agentic-identity-mcp",
      "args": ["--data-dir", "~/.agentic/identity"],
      "env": {}
    },
    "hydra": {
      "command": "hydra-mcp",
      "args": ["--config", "~/.hydra/config.yaml"],
      "env": {}
    }
  }
}
```

### 8.2 Standard Arguments

```
ALL SISTER MCP SERVERS ACCEPT:
──────────────────────────────

--data-dir <path>      Directory for .a* files
--read-only            Open in read-only mode
--port <number>        Port for HTTP transport (optional)
--verbose              Enable verbose logging

EXAMPLE:
────────
agentic-memory-mcp --data-dir ~/.agentic/memory --verbose
```

---

## 9. TOOL DISCOVERY

### 9.1 tools/list Response

Every sister MCP server returns consistent tool listings:

```json
{
  "tools": [
    {
      "name": "memory_health",
      "description": "Check health status of Memory sister",
      "inputSchema": { ... }
    },
    {
      "name": "memory_info",
      "description": "Get Memory sister information",
      "inputSchema": { ... }
    },
    {
      "name": "memory_context_create",
      "description": "Create a new memory session/context",
      "inputSchema": { ... }
    },
    // ... all other tools
  ]
}
```

### 9.2 Capability Flags

Tools can indicate capabilities:

```json
{
  "name": "memory_similar",
  "description": "Find similar memories using embeddings",
  "inputSchema": { ... },
  "capabilities": {
    "requires_embedding": true,
    "fallback_available": true
  }
}
```

---

## 10. VERSIONING

### 10.1 MCP Protocol Version

All sisters report protocol version:

```json
// Response to tools/list
{
  "protocolVersion": "2024-11-05",
  "serverInfo": {
    "name": "agentic-memory-mcp",
    "version": "0.3.2"
  },
  "capabilities": {
    "tools": {},
    "prompts": {},
    "resources": {}
  }
}
```

### 10.2 Tool Versioning

Tool schemas can evolve with backward compatibility:

```
TOOL EVOLUTION RULES:
─────────────────────

• ADD optional parameters: OK
• ADD optional output fields: OK
• REMOVE required parameters: NEVER
• CHANGE parameter types: NEVER
• RENAME parameters: NEVER

Same rules as file format versioning.
```

---

## 11. COMPLIANCE CHECKLIST

### 11.1 MCP Server Checklist

```
EVERY SISTER MCP SERVER MUST:
─────────────────────────────

□ NAMING
  □ Use {sister}_ prefix for all tools
  □ Use lowercase with underscores
  □ Follow action naming conventions

□ REQUIRED TOOLS
  □ {sister}_health
  □ {sister}_info
  □ {sister}_context_create
  □ {sister}_context_switch
  □ {sister}_context_current
  □ {sister}_context_list
  □ {sister}_context_delete
  □ {sister}_ground
  □ {sister}_query

□ ERROR HANDLING
  □ Use standard error codes
  □ Include human-readable messages
  □ Include recoverable flag
  □ Include suggested_action when helpful

□ SCHEMAS
  □ All tools have inputSchema
  □ All tools document outputSchema
  □ Use consistent type definitions

□ CONFIGURATION
  □ Accept --data-dir argument
  □ Accept --read-only argument
  □ Accept --verbose argument

□ DISCOVERY
  □ Return proper tools/list response
  □ Include server version
  □ Include protocol version
```

### 11.2 Current Sister Status

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MCP COMPLIANCE STATUS                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  SISTER          TOOLS    CONTEXT   GROUND   ERRORS   SCHEMAS   STATUS     │
│  ──────────────────────────────────────────────────────────────────────    │
│  Memory          ✅       ⚠️        ✅       ⚠️       ✅        PARTIAL    │
│  Vision          ✅       ⚠️        ✅       ⚠️       ✅        PARTIAL    │
│  Codebase        ✅       ⚠️        ✅       ⚠️       ✅        PARTIAL    │
│  Identity        ✅       ⚠️        ✅       ⚠️       ✅        PARTIAL    │
│                                                                             │
│  ✅ = Compliant                                                             │
│  ⚠️ = Needs update (context tools, standard errors)                         │
│  ❌ = Missing                                                                │
│                                                                             │
│  NEEDED UPDATES:                                                            │
│  • Add context management tools to all sisters                              │
│  • Standardize error responses                                              │
│  • Verify tool naming consistency                                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 12. SUMMARY

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                          MCP TOOL STANDARDS                                ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  This document defines the MCP interface for all sisters.                 ║
║                                                                           ║
║  NAMING:                                                                  ║
║  • Pattern: {sister}_{action}                                             ║
║  • Lowercase with underscores                                             ║
║                                                                           ║
║  REQUIRED TOOLS (ALL SISTERS):                                            ║
║  • Lifecycle: _health, _info                                              ║
║  • Context: _context_create/switch/current/list/delete                    ║
║  • Grounding: _ground                                                     ║
║  • Query: _query                                                          ║
║                                                                           ║
║  ERRORS:                                                                  ║
║  • Standard error codes (NOT_FOUND, INVALID_INPUT, etc.)                  ║
║  • Human-readable messages                                                ║
║  • Recoverable flag                                                       ║
║                                                                           ║
║  HYDRA:                                                                   ║
║  • Is both MCP client (to sisters) and MCP server (to AI agents)         ║
║  • AI agents can control Hydra via MCP                                    ║
║                                                                           ║
║  COMPLIANCE:                                                              ║
║  • All sisters must pass MCP checklist                                    ║
║  • Tool schemas must be consistent                                        ║
║  • Backward compatibility required                                        ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

*Document Version: 1.0*
*Status: MANDATORY*
*Compliance Required: All sister MCP servers*
