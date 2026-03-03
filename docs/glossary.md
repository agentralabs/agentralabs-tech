---
status: stable
title: Glossary
description: Key terms used across Agentra Labs documentation and sister projects.
---

# Glossary

Key terms used across Agentra Labs projects.

## General

**MCP (Model Context Protocol)** — An open standard that lets AI applications discover and call tools exposed by external servers. All Agentra sisters expose their capabilities as MCP tools.

**Sister** — One of the ten Agentra runtime components: AgenticMemory, AgenticVision, AgenticCodebase, AgenticIdentity, AgenticTime, AgenticContract, AgenticComm, AgenticPlanning, AgenticCognition, and AgenticReality. Each sister runs as an independent MCP server and produces its own artifact.

**Artifact** — A portable binary file produced by a sister. Artifacts store all state and can be moved between machines. Formats: `.amem` (memory), `.avis` (vision), `.acb` (codebase), `.aid` (identity), `.atime` (time), `.acon` (contract), `.acomm` (communication), `.aplan` (planning), `.acog` (cognition), `.areal` (reality).

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

## AgenticTime

**Temporal event** — The atomic unit in a time artifact. Each event has a type (deadline, schedule, reminder, decay, constraint), timestamp, and associated metadata.

**Deadline** — A temporal constraint with a fixed end time and optional escalation policy. Deadlines can be chained and can trigger actions on expiry.

**Decay model** — A mathematical function that reduces the relevance or priority of an item over time. Common models: linear, exponential, step-function.

**Schedule** — A recurring temporal pattern defined by intervals, cron expressions, or calendar rules. Schedules produce temporal events at each occurrence.

**Temporal constraint** — A rule that bounds when an action can or must occur. Constraints can be absolute (before/after a timestamp) or relative (within N hours of another event).

**Temporal reasoning** — The ability to evaluate deadlines, detect scheduling conflicts, compute time-to-expiry, and prioritize actions based on temporal urgency.

**.atime** — The AgenticTime artifact file. Stores temporal events, schedules, decay models, and constraint graphs in a structured binary format.

## AgenticContract

**Policy** — A named governance rule with an action (allow or deny) and scope (global, session, or task). Policies are checked against incoming actions in microseconds.

**Risk limit** — A quantitative constraint on agent behavior: rate limits, budget caps, or threshold bounds. Limits track current usage and enforce maximums.

**Approval gate** — A workflow rule that routes sensitive actions through a configurable approval process. Gates match action patterns and require explicit approval before proceeding.

**Obligation** — A time-bound compliance requirement with a deadline. Obligations track fulfillment status and can trigger escalation on expiry.

**Violation** — A recorded policy breach with severity level and actor attribution. Violations provide an immutable audit trail of governance failures.

**Condition** — A boolean expression that gates policy activation. Conditions can reference runtime state, time, or external signals.

**.acon** — The AgenticContract artifact file. Stores policies, risk limits, approval rules, obligations, violations, and audit history in a single binary format.

## AgenticComm

**Channel** — A named communication pathway between agents. Channel types include direct (1:1), group, broadcast, and pub/sub.

**Pub/Sub** — Publish-subscribe messaging pattern where agents subscribe to topics and receive messages published to those topics without direct addressing.

**Message routing** — The process of delivering messages to the correct recipients through channels, topics, or direct addressing. Supports priority levels and delivery guarantees.

**.acomm** — The AgenticComm artifact file. Stores channels, messages, subscriptions, encryption keys, and routing configuration.

## AgenticPlanning

**Goal** — A high-level objective with optional decomposition into sub-goals. Goals track status, priority, and progress toward completion.

**Decision** — A structured choice between options with criteria evaluation. Decisions record the options considered, criteria used, and final selection with rationale.

**Commitment** — A time-bound promise to deliver a specific outcome. Commitments track deadlines, progress, and risk status.

**.aplan** — The AgenticPlanning artifact file. Stores goals, decisions, commitments, progress records, and strategic reasoning chains.

## AgenticCognition

**.acog** — Binary file format for living user models. Stores user models, beliefs, reflections, drift history, and prediction records.

**acog** — CLI binary for AgenticCognition. Provides command-line access to user modeling, belief management, and cognitive analysis.

**acog-mcp** — MCP server binary for AgenticCognition. Exposes user modeling and belief graph tools to MCP clients.

**User model** — A living representation of a human user built from longitudinal observations. User models track beliefs, preferences, patterns, and cognitive fingerprints over time.

**Belief** — An inferred fact about a user with confidence, source attribution, and decay. Beliefs are continuously updated as new evidence arrives and can be queried for decision support.

**Belief Graph** — An interconnected web of beliefs with physics properties. Beliefs link to each other through causal, supporting, and contradicting edges, forming a navigable knowledge structure.

**Living User Model** — A breathing model with soul, consciousness, and vitals. Unlike static profiles, a living user model evolves continuously as new observations arrive and old beliefs decay.

**Soul Reflection** — Discovery of the user's essential nature. A synthesized portrait of the user's cognitive patterns, values, and behavioral tendencies derived from accumulated observations.

**Decision Fingerprint** — A unique decision-making signature derived from observed choices. Captures recurring patterns in how a user weighs options, tolerates risk, and prioritizes criteria.

**Shadow Map** — A record of unconscious beliefs, projections, and blindspots in a user model. Highlights contradictions, tensions, and unresolved ambiguities where the model's confidence is low or beliefs conflict.

**Belief Physics** — The dynamics governing belief behavior: crystallization (beliefs hardening with evidence), entanglement (correlated beliefs changing together), gravity (strong beliefs attracting related evidence), and collapse (belief resolution under contradictory pressure).

**Drift Timeline** — Tracking how beliefs change over time. Drift detection identifies when a user's preferences or behaviors shift significantly, enabling proactive adaptation.

**Cognitive drift** — The measured change in a user model's belief landscape over time. Drift tracking detects when a user's preferences or behaviors shift significantly.

## AgenticReality

**.areal** — Binary file format for reality context. Stores deployment state, resource inventories, reality anchors, and hallucination detection records.

**areal** — CLI binary for AgenticReality. Provides command-line access to reality verification, resource discovery, and deployment management.

**areal-mcp** — MCP server binary for AgenticReality. Exposes reality anchoring and hallucination detection tools to MCP clients.

**Deployment Soul** — The persistent identity of an agent deployment. Captures the unique configuration, history, and operational context that define a running agent instance across restarts and migrations.

**Resource Body** — A complete picture of available resources. Inventories compute, storage, network, API quotas, and other operational assets accessible to an agent deployment.

**Reality Anchor** — A ground truth reference for fact verification. Reality anchors provide authoritative data points against which agent-generated statements can be validated.

**Hallucination Detection** — Identifying fabricated vs verified information. Compares agent outputs against reality anchors and known facts to flag ungrounded claims and unsupported assertions.

**Context Fingerprint** — A unique hash of the operational environment. Captures the specific combination of tools, data sources, permissions, and runtime conditions that define an agent's operating context.

**Stakes Perception** — Awareness of consequences and blast radius. Evaluates the potential impact of actions based on affected systems, data sensitivity, reversibility, and downstream dependencies.
