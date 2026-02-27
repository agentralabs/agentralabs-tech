# New Sister Playbook

**Status:** Canonical (normative)
**Audience:** Claude Code, human developers
**Purpose:** Step-by-step guide to add a new Agentra sister from scratch

Adding a new sister requires changes across two repos (monorepo + web) and one new repo. This playbook covers every file that must be created or updated. Follow it in order.

---

## Prerequisites

- The sister's `key` (e.g., `time`), `name` (e.g., `AgenticTime`), `repo` name (e.g., `agentic-time`), file extension (e.g., `.atime`), CLI binary name (e.g., `atime`)
- A GitHub repo created at `github.com/agentralabs/<repo>`
- `jq` installed locally

---

## Phase 1: Register the Sister (monorepo)

### 1.1 Add entry to `docs/sisters-registry.json`

This is the **only file** that defines the sister list for all automation. Add a new entry to the `sisters` array following the exact schema of existing entries:

```json
{
  "key": "<key>",
  "name": "Agentic<Name>",
  "repo": "agentic-<key>",
  "shortName": "<KEY>",
  "enabled": true,
  "order": <next_multiple_of_10>,
  "fileExtension": ".<ext>",
  "cliBinary": "<ext>",
  "packages": {
    "npm": "@agenticamem/<key>",
    "pypi": "agentic-<key>",
    "coreCrate": "agentic-<key>",
    "ffiCrate": "agentic-<key>-ffi",
    "mcpCrate": "agentic-<key>-mcp",
    "cliCrate": "agentic-<key>-cli"
  },
  "paths": {
    "mcpToolSource": "crates/agentic-<key>-mcp/src/tools/registry.rs"
  },
  "mcp": {
    "binary": "agentic-<key>-mcp",
    "args": [],
    "cratePath": "crates/agentic-<key>-mcp"
  },
  "docs": {
    "landingSlug": "<key>-docs",
    "includeLanding": true
  }
}
```

**Fields to customize per sister:**
- `paths.mcpToolSource` — depends on where MCP tool dispatch lives in the Rust code. Common patterns: `crates/agentic-<key>-mcp/src/tools/registry.rs` (modular) or `crates/agentic-<key>-mcp/src/main.rs` (monolithic) or `src/mcp/server.rs` (flat)
- `mcp.args` — most sisters use `[]`, some use `["serve"]` or log-level flags
- `mcp.cratePath` — usually `crates/agentic-<key>-mcp` but verify against actual crate location

### 1.2 Add to `Cargo.toml` exclude list

```toml
exclude = ["agentic-codebase", "agentic-memory", "agentic-vision", "agentic-identity", "agentic-time", "agentic-<key>"]
```

### 1.3 Verify automation picks it up

After the registry entry, these scripts automatically include the new sister with **zero edits**:

| Script | What it does |
|--------|-------------|
| `scripts/check-canonical-consistency.sh` | All 41 cross-sister checks |
| `scripts/check-command-surface.sh` | MCP tool documentation validation |
| `scripts/install-mcp-servers.sh` | Build + install MCP binary, generate `~/.claude/mcp.json` |
| `install_all.sh` | Install CLI + MCP from local paths |
| `sync_artifacts.sh` | Sync artifact files to server |
| `.github/workflows/canonical-consistency.yml` | CI: clone + validate |
| `agentralabs-tech-web/.github/workflows/docs-sync-guardrails.yml` | Web CI: clone + validate docs |

---

## Phase 2: Create the Sister Repository

### 2.1 Crate structure

Follow the exact crate layout used by existing sisters:

```
agentic-<key>/
├── Cargo.toml              # workspace with members
├── Cargo.lock
├── crates/
│   ├── agentic-<key>/          # core library crate
│   │   ├── Cargo.toml
│   │   └── src/
│   │       └── lib.rs
│   ├── agentic-<key>-cli/      # CLI binary crate
│   │   ├── Cargo.toml
│   │   └── src/
│   │       └── main.rs
│   ├── agentic-<key>-mcp/      # MCP server crate
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── main.rs
│   │       └── tools/
│   │           ├── mod.rs
│   │           └── registry.rs   # MCP tool dispatch
│   └── agentic-<key>-ffi/      # FFI crate (for npm/python bindings)
│       ├── Cargo.toml
│       └── src/
│           └── lib.rs
```

### 2.2 Root governance files (required)

These files are **mandatory** and checked by Section 34 of the canonical consistency guardrail:

```
LICENSE              # MIT
CONTRIBUTING.md      # copy from agentic-memory, update sister name
SECURITY.md          # copy from agentic-memory, update sister name
Makefile             # copy from agentic-memory, update crate names
CHANGELOG.md         # start with initial entry
```

### 2.3 Required docs (checked by guardrails)

```
docs/
├── ecosystem/
│   └── CANONICAL_SISTER_KIT.md   # byte-identical copy from agentic-memory (Section 1)
├── public/
│   ├── command-surface.md         # every MCP tool must be documented here (Section 22)
│   ├── SCENARIOS-AGENTIC-<KEY>.md # scenario document (Section 17)
│   ├── overview.md
│   ├── quickstart.md
│   ├── concepts.md
│   ├── installation.md
│   ├── guide.md
│   ├── api-reference.md
│   ├── benchmarks.md
│   ├── faq.md
│   ├── file-format.md
│   ├── integration-guide.md
│   └── experience-with-vs-without.md
```

**Critical:** `docs/ecosystem/CANONICAL_SISTER_KIT.md` must be a **byte-identical copy** of the one in agentic-memory. The guardrail (Section 1) compares SHA256 hashes.

### 2.4 Required assets (checked by Sections 21 + 29)

```
assets/
├── github-hero-pane.svg           # Agentra design system
├── github-hero-pane-agentra.svg   # workspace variant
├── github-terminal-pane.svg
└── github-terminal-pane-agentra.svg
```

**SVG design system rules** (Section 29):
- Background: `#f2f1ea` (light parchment)
- Ink: `#111111`
- Accent: `#ea580c` (orange)
- Font: `JetBrains Mono`
- **Forbidden:** `linearGradient` (no dark themes), `system-ui` (no system fonts)

### 2.5 Required paper directory (Section 28)

```
paper/
└── paper-i-<topic>/
    ├── paper.tex         # or any .tex file
    └── references.bib
```

### 2.6 Required installer (Section 33 + Canonical Sister Kit)

```
installer/
└── <ext>_installer/    # e.g., atime_installer/
scripts/
├── install.sh
├── check-install-commands.sh
├── check-canonical-sister.sh
```

The installer must support 3 profiles: `desktop`, `terminal`, `server`.

### 2.7 Required CI workflows

```
.github/workflows/
├── install-command-guardrails.yml
├── canonical-sister-guardrails.yml
└── ci.yml                           # standard cargo test + clippy
```

### 2.8 README structure (Sections 5, 30-33)

The README must follow the canonical layout and include all required sections:

```markdown
<!-- hero image -->
<!-- badges: pip_install, cargo_install, MCP_Server, License-MIT, Research-Paper_I, format-.<ext> -->
<!-- nav links -->

## Problems Solved
## MCP
## Benchmarks
## Why
## Install
## Quickstart
## How It Works
## Common Workflows
## Validation
## Repository Structure
## Contributing
## Privacy and Security
## Deployment Model
## MCP Server
  <!-- must include: claude_desktop_config.json, .vscode/settings.json, Standalone -->

Built by [Agentra Labs](https://agentralab-tech-web.vercel.app)
```

Install section must include all 3 profile URLs:
```
install/<key>/desktop
install/<key>/terminal
install/<key>/server
```

### 2.9 MCP context-capture tool (20-Year Clock pattern)

Every sister must have a context-capture tool that records **why** operations happen:

| Sister | Tool name |
|--------|-----------|
| memory | `conversation_log` |
| vision | `observation_log` |
| codebase | `analysis_log` |
| identity | `action_context` |
| time | *(follow the pattern: `<domain>_log` or `<domain>_context`)* |

The tool takes an `intent` field (why the action is happening) and optionally a `topic` and domain-specific result field.

---

## Phase 2.10: Update Hydra Gradual Planning (private, gitignored)

If `goals/hydra/HYDRA-GRADUAL-PLANNING.md` exists locally, add a new section for the sister:

```markdown
### From <Name> (The <Ordinal>)

**Patterns Hydra Should Inherit:**
- [x] <pattern 1 — what the sister does that Hydra needs>
- [x] <pattern 2>

**Edge Cases Discovered:**
- [x] <edge case 1 — what went wrong and how it was solved>

**Hydra Implications:**
- <which Hydra component benefits and how>
```

This section should grow over time as work continues on the sister. The guardrail will softly warn if any sister is missing from this doc. See `CLAUDE.md` for the standing instruction that makes this happen naturally.

---

## Phase 3: Update the Monorepo README

### 3.1 Add badge

Add a badge line in the badge row at the top of `README.md`:

```html
<a href="https://github.com/agentralabs/agentic-<key>"><img src="https://img.shields.io/badge/<Name>-0.1.0-ea580c?style=for-the-badge" alt="<Name>"></a>
```

Use `ea580c` (orange) for new/alpha sisters, `111111` (dark) for stable ones.

### 3.2 Add to sisters table

```markdown
| [**Agentic<Name>**](https://github.com/agentralabs/agentic-<key>) | `.<ext>` | <one-line description> |
```

### 3.3 Add to quick start

```bash
cargo install agentic-<key>-cli    # <ext>
```

### 3.4 Add to layout tree

```
├── agentic-<key>/     <short description>
```

---

## Phase 4: Update the Web Repo

### 4.1 Update stale count references

Search for the current count word (e.g., "Five") and update to the new count (e.g., "Six") in all web files. The Section 37 guardrail catches stale counts.

### 4.2 Critical web files that must mention the new sister

These files are checked by Sections 35, 38, 39, 40:

| File | What to add |
|------|-------------|
| `app/page.tsx` | Sister display name in content |
| `app/layout.tsx` | Sister display name in metadata |
| `components/footer.tsx` | Sister link |
| `components/pricing-section.tsx` | Sister entry |
| `lib/site.ts` | Sister metadata |
| `app/opengraph-image.tsx` | Sister in OG image |
| `app/projects/page.tsx` | Sister project entry |
| `app/projects/head.tsx` | Sister in head metadata |
| `components/about-section.tsx` | Sister display name |
| `components/scenario-cards-section.tsx` | Sister scenario card |
| `components/scenario-page.tsx` | Sister scenario reference |
| `app/flyers/twitter-post/route.tsx` | Sister short name |
| `app/flyers/linkedin-post/route.tsx` | Sister short name |
| `app/twitter-image.tsx` | Sister short name |

### 4.3 Add install routes

Create install route handlers that redirect to the sister's install script:

- `app/install/[target]/route.ts` — add `"<key>"` and `"agentic-<key>"` entries
- `app/install/[target]/[profile]/route.ts` — same entries

### 4.4 Add scenario page

- `app/projects/scenarios/[sister]/page.tsx` — add to `VALID_SISTERS` array and `META` object

### 4.5 Navigation contract

- `docs/ecosystem/navigation-contract.json` — add sister entry with `key`, `enabled: true`, `landing`, `pages` array

### 4.6 Sync ecosystem docs

Run `pnpm docs:sync` to pull the new sister's docs into the web repo. The sync script reads sisters from the registry automatically.

---

## Phase 5: Verify

Run these commands to confirm everything passes:

```bash
# In monorepo
bash scripts/check-canonical-consistency.sh
bash scripts/check-command-surface.sh

# In web repo
pnpm docs:sync:check
```

All sections should pass. Fix any failures before pushing.

---

## Checklist Summary

```
Registry & Automation (monorepo):
  [ ] docs/sisters-registry.json — new entry
  [ ] Cargo.toml — exclude list

Sister Repo:
  [ ] Crate structure: core, cli, mcp, ffi
  [ ] Root files: LICENSE, CONTRIBUTING.md, SECURITY.md, Makefile, CHANGELOG.md
  [ ] docs/ecosystem/CANONICAL_SISTER_KIT.md (byte-identical)
  [ ] docs/public/command-surface.md (all MCP tools)
  [ ] docs/public/SCENARIOS-AGENTIC-<KEY>.md
  [ ] docs/public/{overview,quickstart,concepts,installation,guide,api-reference,benchmarks,faq,file-format,integration-guide,experience-with-vs-without}.md
  [ ] assets/ — 4 SVGs (Agentra design system)
  [ ] paper/paper-i-<topic>/ — .tex + references.bib
  [ ] installer/ + scripts/install.sh
  [ ] scripts/check-install-commands.sh + check-canonical-sister.sh
  [ ] .github/workflows/ — 2 guardrail workflows + CI
  [ ] README.md — canonical layout with all required sections and badges
  [ ] MCP context-capture tool (intent logging)

Hydra Planning (private, local-only):
  [ ] goals/hydra/HYDRA-GRADUAL-PLANNING.md — new sister section

Monorepo README:
  [ ] Badge row
  [ ] Sisters table
  [ ] Quick start
  [ ] Layout tree

Web Repo:
  [ ] ~14 content files updated with sister name
  [ ] Install routes (2 files)
  [ ] Scenario page entry
  [ ] Navigation contract
  [ ] Stale count words updated
  [ ] pnpm docs:sync passes
```

---

## What's Fully Automated vs Manual

| Layer | Automated? | Details |
|-------|-----------|---------|
| CI clone + validation | Yes | Reads from registry |
| MCP server install | Yes | Reads from registry |
| Artifact sync | Yes | Reads extensions from registry |
| Local install (CLI+MCP) | Yes | Reads from registry |
| Canonical consistency checks | Yes | All 41 sections use registry arrays |
| Command surface checks | Yes | Reads tool source path from registry |
| Docs sync to web | Yes | Copies registry + reads it |
| Sister repo structure | Manual | Crates, docs, assets, paper, installer |
| Monorepo README content | Manual | Badge, table row, quickstart line, layout tree |
| Web repo content | Manual | ~14 files need sister name/description |
| Web install routes | Manual | 2 files need new mapping |
| Web scenario page | Manual | 1 file needs new entry |
