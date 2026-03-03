---
status: stable
---

# Frequently Asked Questions

## What is a .acog file?

A `.acog` file is a custom binary format with BLAKE3 integrity protection that holds the entire living user model. One file contains beliefs, shadows, drift history, decision fingerprints, and archaeological layers.

## Does AgenticCognition require a cloud connection?

No. Everything runs locally. No telemetry, no cloud sync by default. The user owns their data completely.

## Which MCP clients are supported?

Any MCP-compatible client works: Claude Desktop, Cursor, Windsurf, VS Code, Cody, Claude Code, and any future client supporting the Model Context Protocol.

## Can I use AgenticCognition without the MCP server?

Yes. The CLI (`acog`) and the Rust library provide full access to all 24 inventions. The MCP server is one of several access surfaces.

## How does shadow detection work?

Shadow beliefs are inferred from behavioral patterns that contradict stated beliefs. The system detects projections (attributes ascribed to others that belong to self), blindspots (gaps between self-assessment and observed behavior), and defended regions.

## Is my data private?

Absolutely. See the Privacy and Ethics section in the README. The five privacy principles guarantee consent, transparency, humility, growth orientation, and data sacredness.
