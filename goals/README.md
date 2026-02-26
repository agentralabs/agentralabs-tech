# Goals

> Organized reference documents for the Agentra ecosystem roadmap.

---

## validation/

Documents needed NOW for verifying existing sisters comply with contracts.

| Document | Purpose |
|----------|---------|
| `SISTER-HYDRA-INTEGRATION-CONTRACT.md` | Binding contract: traits, file format, 20-year compatibility |
| `MCP-TOOL-STANDARDS.md` | Mandatory MCP tool naming, schemas, error responses |
| `EDGE-CASE-HANDLERS-SPEC.md` | Production edge-case handling (crashes, auth, approvals) |

**Related crate:** `agentic-contracts/` (single source of truth for Rust traits)

---

## new-sisters/

Documents for planning and building future sisters.

| Document | Purpose |
|----------|---------|
| `ASTRAL-MISSING-SISTERS.md` | Gap analysis: which sister capabilities are still needed |
| `SISTER-V2-PATTERNS.md` | V2 upgrade patterns (grounding, context, events) |
| `SISTER-V2-PLANNED-PRE-PHILIP.md` | Pre-planned V2 implementations + runtime hardening |

**Template:** New sisters follow `agentic-contracts/` traits from day one.

---

## hydra/

Hydra orchestrator specs and design documents (build LATER).

| Document | Purpose |
|----------|---------|
| `HYDRA-COMPLETE-SPEC.md` | Full canonical spec: proof-carrying, compile-to-action runtime |
| `HYDRA-INVENTIONS.md` | 10 novel capabilities (Action Compilation, Intention Anchor, etc.) |
| `SKILL-FABRIC-SPEC.md` | Universal skill runtime layer |
| `RESOURCE-OPTIMIZATION-SPEC.md` | Constrained-hardware operation |
| `HYDRA-UX-SPEC.md` | UX spec: zero learning curve, universal accessibility |
| `HYDRA-ARCHITECTURE-FEEDBACK.md` | Architecture review + gap analysis |
| `HYDRA-ARCHITECTURE-FEEDBACK V2 Openclaw.md` | OpenClaw pattern analysis |
| `HYDRA-SKILL-ECOSYSTEMS.md` | Skill enhancer positioning |
| `HYDRA-PHONECOMM.md` | Phone communication automation |
| `HydraMail.md` | Email automation patterns |
| `HydraPhilosophy.md` | LLM philosophy + token minimization |
| `MOREOFHYDRA.md` | System requirements comparison |
| `UIUX-minset.md` | UX design mindset (grandmother-proof principle) |

---

## vision/

Long-term 20-year roadmaps.

| Document | Purpose |
|----------|---------|
| `SISTER-VISION-20-YEAR.md` | Lifelong agent companionship via persistent sister files |
| `VISION-AMEM-20-YEAR-ROADMAP.md` | 5-phase .amem evolution plan |
