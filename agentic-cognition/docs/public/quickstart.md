---
status: stable
---

# Quickstart

Get started with AgenticCognition in under five minutes. This guide walks through installation, model creation, and your first belief graph.

## Install

```bash
curl -fsSL https://agentralabs.tech/install/cognition | bash
```

## Create your first living user model

```bash
acog model create
acog belief add $MODEL_ID "I value honesty above all" --domain values --confidence 0.9
acog model soul $MODEL_ID
```

## Verify with MCP

Once installed, the `acog-mcp` binary is available as a Model Context Protocol server. Any MCP-compatible client (Claude Desktop, Cursor, Windsurf, VS Code) can use cognition tools immediately.

## Next steps

- Read the [Concepts](concepts.md) guide for belief physics, shadow psychology, and drift tracking
- Explore the [API Reference](api-reference.md) for the full Rust SDK
- See [Integration Guide](integration-guide.md) for connecting with other Agentra sisters
