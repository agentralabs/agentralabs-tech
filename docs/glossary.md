---
status: stable
title: Glossary
description: Key terms used across Agentra Labs documentation and sister projects.
---

# Glossary

Key terms used across Agentra Labs projects.

## General

**MCP (Model Context Protocol)** — An open standard that lets AI applications discover and call tools exposed by external servers. All Agentra sisters expose their capabilities as MCP tools.

**Sister** — One of the four Agentra runtime components: AgenticMemory, AgenticVision, AgenticCodebase, and AgenticIdentity. Each sister runs as an independent MCP server and produces its own artifact.

**Artifact** — A portable binary file produced by a sister. Artifacts store all state and can be moved between machines. Formats: `.amem` (memory), `.avis` (vision), `.acb` (codebase), `.aid` (identity).

**Workspace** — The parent directory containing the web repo and all sister repos. The docs sync script reads from this workspace to build the documentation site.

**Runtime mode** — How a sister is deployed: `local` (single machine), `desktop` (MCP client like Claude Desktop), or `server` (remote host with auth and artifact sync).

**Budget policy** — Automatic storage management that prunes low-value data from completed sessions when the artifact approaches a size limit.

## AgenticMemory

**Brain** — The `.amem` artifact file. Contains all cognitive events, edges, embeddings, sessions, and episode summaries for one agent.

**Cognitive event** — The atomic unit of memory. Each event has a type (`fact`, `decision`, `inference`, `correction`, `skill`, `episode`), content, confidence score, and timestamp.

**Edge type** — A typed relationship between two memory nodes: `caused_by`, `derived_from`, `supports`, `contradicts`, `supersedes`, `related_to`, `part_of`, `temporal_next`.

**Supersedes chain** — When a correction replaces a prior belief, the old node is linked via a `supersedes` edge. Resolving a node follows this chain to the latest version.

**Session** — A bounded interaction period. Sessions group cognitive events and can be summarized into episode nodes on close.

**Auto-capture** — Automatic recording of prompts and feedback into memory nodes. Modes: `safe` (templates and explicit feedback), `full` (broader tool input), `off`.

## AgenticVision

**Capture** — A single image stored in visual memory with its CLIP embedding, metadata, quality score, and optional OCR text.

**CLIP embedding** — A 512-dimensional vector (ViT-B/32) computed for each captured image. Used for similarity search and visual comparison.

**Quality score** — A 0.0-1.0 rating computed from resolution, embedding confidence, metadata completeness, and OCR yield.

**.avis** — The AgenticVision artifact file. Stores captures, embeddings, sessions, and tracking configuration in LZ4-compressed binary format.

**Vision link** — A typed connection between a visual capture and an AgenticMemory node. Relationship types: `observed_during`, `evidence_for`, `screenshot_of`.

**Region tracking** — Monitoring a defined screen area for visual changes. Captures are stored when the similarity score drops below a threshold.

**Visual diff** — Pixel-level comparison between two captures. Returns changed pixel count, change percentage, and bounding boxes of changed regions.

## AgenticCodebase

**Code unit** — The atomic element in a code graph: a module, function, type, import, test, parameter, or other structural element.

**Code edge** — A typed relationship between code units: `calls`, `imports`, `inherits`, `implements`, `depends_on`, `tests`, `contains`.

**.acb** — The AgenticCodebase artifact file. A compiled code graph with symbols, edges, embeddings, and structural metadata.

**Impact analysis** — Traversing the code graph from a changed unit outward to find all affected callers, tests, and downstream dependencies.

**Stability score** — A measure of how likely a code unit is to change based on coupling, fan-out, and historical patterns.

**Hidden coupling** — Indirect dependencies between code units that are not visible from direct imports or calls but emerge from graph traversal.

**Gate check** — A pre-merge safety check that evaluates risk score, test coverage, and coupling for a proposed change.

**Collective intelligence** — Ecosystem-level pattern knowledge attached to dependencies, including common failure signatures and mitigation strategies.

## AgenticIdentity

**Identity anchor** — An Ed25519 key pair that serves as the permanent cryptographic root of an agent's identity. The public key is the identity; the identity ID is derived from it via `aid_` + base58(SHA-256(public_key)[0..16]).

**Action receipt** — A signed, timestamped proof that a specific agent took a specific action. Includes the actor's identity, action type, content hash, and Ed25519 signature. Receipts are non-repudiable.

**Receipt chain** — A linked sequence of action receipts where each receipt references the previous receipt's ID. Chain verification checks every signature and every link.

**Trust grant** — A cryptographic statement where one identity delegates specific capabilities to another, with constraints on time, use count, and delegation depth.

**Capability URI** — A colon-delimited string describing a permitted action, with wildcard support. Examples: `read:calendar`, `execute:deploy:*`, `*` (root trust).

**Delegation chain** — A sequence of trust grants where each grantee re-delegates trust to the next party. Verification walks the full chain and checks every signature and delegation permission.

**Revocation** — A signed record that permanently invalidates a trust grant. Revoking any link in a delegation chain invalidates the entire chain downstream.

**Key rotation** — Replacing an identity's signing key with a new Ed25519 key pair. The old key signs an authorization proving the rotation was intentional. Rotation history is preserved for chain-of-custody verification.

**Derived key** — A child signing key generated from the root key using HKDF-SHA256 with a context-specific path. Types: session keys, capability keys, device keys. Compromising a derived key does not expose the root key.

**.aid** — The AgenticIdentity artifact file. A JSON document containing encrypted private key material (ChaCha20-Poly1305) and plaintext public identity metadata. The public document can be read without the passphrase.
