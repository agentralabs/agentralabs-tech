<p align="center">
  <img src="assets/github-hero-pane.svg" alt="Agentra workspace hero pane" width="980">
</p>

<p align="center">
  <a href="https://github.com/agentralabs/agentic-memory"><img src="https://img.shields.io/badge/Memory-0.3.2-111111?style=for-the-badge" alt="Memory"></a>
  <a href="https://github.com/agentralabs/agentic-vision"><img src="https://img.shields.io/badge/Vision-0.2.2-111111?style=for-the-badge" alt="Vision"></a>
  <a href="https://github.com/agentralabs/agentic-codebase"><img src="https://img.shields.io/badge/Codebase-0.2.2-111111?style=for-the-badge" alt="Codebase"></a>
  <a href="https://github.com/agentralabs/agentic-identity"><img src="https://img.shields.io/badge/Identity-0.2.3-111111?style=for-the-badge" alt="Identity"></a>
  <a href="https://github.com/agentralabs/agentic-time"><img src="https://img.shields.io/badge/Time-0.1.0-ea580c?style=for-the-badge" alt="Time"></a>
  <a href="https://github.com/agentralabs/agentic-contract"><img src="https://img.shields.io/badge/Contract-0.1.0-ea580c?style=for-the-badge" alt="Contract"></a>
  <a href="https://github.com/agentralabs/agentic-comm"><img src="https://img.shields.io/badge/Comm-0.1.0-ea580c?style=for-the-badge" alt="Comm"></a>
  <a href="https://github.com/agentralabs/agentic-planning"><img src="https://img.shields.io/badge/Planning-0.1.0-ea580c?style=for-the-badge" alt="Planning"></a>
  <a href="https://github.com/agentralabs/agentic-cognition"><img src="https://img.shields.io/badge/Cognition-0.1.0-ea580c?style=for-the-badge" alt="Cognition"></a>
  <a href="https://github.com/agentralabs/agentic-reality"><img src="https://img.shields.io/badge/Reality-0.1.0-ea580c?style=for-the-badge" alt="Reality"></a>
  <a href="https://github.com/agentralabs/agentic-forge"><img src="https://img.shields.io/badge/Forge-0.1.0-ea580c?style=for-the-badge" alt="Forge"></a>
  <a href="https://github.com/agentralabs/agentic-aegis"><img src="https://img.shields.io/badge/Aegis-0.1.0-ea580c?style=for-the-badge" alt="Aegis"></a>
  <a href="https://github.com/agentralabs/agentic-veritas"><img src="https://img.shields.io/badge/Veritas-0.1.0-ea580c?style=for-the-badge" alt="Veritas"></a>
  <a href="https://github.com/agentralabs/agentic-evolve"><img src="https://img.shields.io/badge/Evolve-0.1.0-ea580c?style=for-the-badge" alt="Evolve"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-22C55E?style=for-the-badge" alt="MIT License"></a>
</p>

<p align="center">
  <strong>Workspace orchestrator for the fourteen Agentra sisters.</strong>
</p>

<p align="center">
  <a href="#sisters">Sisters</a> · <a href="#quick-start">Quick Start</a> · <a href="#install">Install</a> · <a href="#layout">Layout</a> · <a href="https://agentralab-tech-web.vercel.app">Docs</a>
</p>

---

<a name="sisters"></a>

## Sisters

| Sister | Artifact | What it does |
|--------|----------|-------------|
| [**AgenticMemory**](https://github.com/agentralabs/agentic-memory) | `.amem` | Persistent cognitive graph memory — facts, decisions, corrections, reasoning chains |
| [**AgenticVision**](https://github.com/agentralabs/agentic-vision) | `.avis` | Persistent visual memory — CLIP embeddings, similarity search, visual diff |
| [**AgenticCodebase**](https://github.com/agentralabs/agentic-codebase) | `.acb` | Semantic code intelligence — concept graphs, impact analysis, coupling detection |
| [**AgenticIdentity**](https://github.com/agentralabs/agentic-identity) | `.aid` | Cryptographic agent identity — Ed25519 anchors, signed receipts, trust delegation |
| [**AgenticTime**](https://github.com/agentralabs/agentic-time) | `.atime` | Temporal reasoning — deadlines, schedules, PERT estimation, decay models |
| [**AgenticContract**](https://github.com/agentralabs/agentic-contract) | `.acon` | Policy engine — governance rules, risk limits, approvals, obligations, violations |
| [**AgenticComm**](https://github.com/agentralabs/agentic-comm) | `.acomm` | Structured agent communication — channels, pub/sub, message routing, encryption |
| [**AgenticPlanning**](https://github.com/agentralabs/agentic-planning) | `.aplan` | Persistent goals, decisions, commitments, strategic reasoning |
| [**AgenticCognition**](https://github.com/agentralabs/agentic-cognition) | `.acog` | Longitudinal user modeling — living models of human consciousness |
| [**AgenticReality**](https://github.com/agentralabs/agentic-reality) | `.areal` | Existential grounding — deployment consciousness and reality physics |
| [**AgenticForge**](https://github.com/agentralabs/agentic-forge) | `.forge` | Blueprint engine — complete project architecture before code generation |
| [**AgenticAegis**](https://github.com/agentralabs/agentic-aegis) | `.aegis` | Streaming shield — real-time validation during code generation |
| [**AgenticVeritas**](https://github.com/agentralabs/agentic-veritas) | `.veritas` | Truth engine — intent compilation and uncertainty detection |
| [**AgenticEvolve**](https://github.com/agentralabs/agentic-evolve) | `.evolve` | Pattern library — crystallizing patterns for instant rebuilds |

Each sister is an independent MCP server. Install one or all. Any model. Any client.

<a name="quick-start"></a>

## Quick Start

```bash
cargo install agentic-memory-cli    # amem
cargo install agentic-vision-cli    # avis
cargo install agentic-codebase-cli  # acb
cargo install agentic-identity-cli  # aid
cargo install agentic-time-cli      # atime
cargo install agentic-contract-cli  # acon
cargo install agentic-comm-cli      # acomm
cargo install agentic-planning-cli  # aplan
cargo install agentic-cognition-cli # acog
cargo install agentic-reality-cli  # areal
cargo install agentic-forge-cli   # aforge
cargo install agentic-aegis-cli   # aegis
cargo install agentic-veritas-cli # veritas
cargo install agentic-evolve-cli  # evolve
```

Or use the orchestrator:

```bash
cargo run --bin agentra -- status          # check what's installed
cargo run --bin agentra -- doctor          # health check + repair
cargo run --bin agentra -- doctor --fix    # auto-fix issues
```

<a name="install"></a>

## Install

```bash
./install_all.sh                    # install all sisters locally
./install_all.sh --profile=desktop  # desktop MCP client profile
./install_all.sh --profile=server   # server runtime profile
```

<a name="layout"></a>

## Layout

```
agentralabs-tech/
├── agentra-cli/       orchestrator CLI (agentra)
├── agentic-memory/    persistent graph memory
├── agentic-vision/    visual memory
├── agentic-codebase/  code graph + query engine
├── agentic-identity/  cryptographic agent identity
├── agentic-time/      temporal reasoning
├── agentic-contract/  policy engine + governance
├── agentic-comm/      structured agent communication
├── agentic-planning/  strategic planning + decisions
├── agentic-cognition/ longitudinal user modeling
├── agentic-reality/  existential grounding
├── agentic-forge/    blueprint engine
├── agentic-aegis/    streaming shield
├── agentic-veritas/  truth engine
├── agentic-evolve/   pattern library
├── install_all.sh     install sisters from local paths
├── sync_artifacts.sh  sync artifacts to server paths
└── scripts/           guardrail + consistency checks
```

---

<p align="center">
  Built by <a href="https://agentralab-tech-web.vercel.app">Agentra Labs</a>
</p>
