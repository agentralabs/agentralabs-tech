#!/usr/bin/env bash
# check-canonical-consistency.sh — Cross-sister consistency validator
#
# Run from the agentralabs-tech workspace root. Validates that ALL sisters
# are structurally identical where they must be. If anything drifts, it fails.
#
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
SISTERS=(agentic-memory agentic-vision agentic-codebase agentic-identity agentic-time)
ERRORS=0

fail() {
  echo "FAIL: $*" >&2
  ERRORS=$((ERRORS + 1))
}

pass() {
  echo "  ok: $*"
}

section() {
  echo ""
  echo "── $* ──"
}

# ── 0. Cross-validate SISTERS array against web navigation contract ────────

section "Cross-validate SISTERS against navigation-contract.json"

NAV_CONTRACT_FILE="${WORKSPACE}/agentralabs-tech-web/docs/ecosystem/navigation-contract.json"
if [ -f "$NAV_CONTRACT_FILE" ] && command -v python3 >/dev/null 2>&1; then
  CONTRACT_KEYS="$(python3 -c "
import json, sys
data = json.load(open('${NAV_CONTRACT_FILE}'))
keys = sorted('agentic-' + s['key'] for s in data.get('sisters',[]) if s.get('enabled', True))
print(' '.join(keys))
")"
  SCRIPT_KEYS="$(printf '%s\n' "${SISTERS[@]}" | sort | tr '\n' ' ' | sed 's/ $//')"
  if [ "$CONTRACT_KEYS" = "$SCRIPT_KEYS" ]; then
    pass "SISTERS array matches navigation-contract.json enabled sisters"
  else
    fail "SISTERS array does not match navigation-contract.json. Script: [${SCRIPT_KEYS}] Contract: [${CONTRACT_KEYS}]. A new sister may have been added to the web contract but not to this script."
  fi
else
  pass "Skipping navigation-contract cross-check (file or python3 not available)"
fi

# ── 1. CANONICAL_SISTER_KIT.md byte-identity ────────────────────────────────

section "CANONICAL_SISTER_KIT.md byte-identity"

REFERENCE="${WORKSPACE}/agentic-memory/docs/ecosystem/CANONICAL_SISTER_KIT.md"
if [ ! -f "$REFERENCE" ]; then
  fail "Reference file missing: ${REFERENCE}"
else
  for sister in "${SISTERS[@]}"; do
    target="${WORKSPACE}/${sister}/docs/ecosystem/CANONICAL_SISTER_KIT.md"
    if [ ! -f "$target" ]; then
      fail "${sister}: missing docs/ecosystem/CANONICAL_SISTER_KIT.md"
    elif ! diff -q "$REFERENCE" "$target" >/dev/null 2>&1; then
      fail "${sister}: docs/ecosystem/CANONICAL_SISTER_KIT.md differs from memory's"
      diff --brief "$REFERENCE" "$target" 2>&1 | head -3
    else
      pass "${sister}: canonical kit matches"
    fi
  done
fi

# ── 2. Check script body-identity ───────────────────────────────────────────

section "Check script body-identity (assertion body must match)"

extract_body() {
  # Strip everything before "# ── Shared helpers" and the header vars section
  sed -n '/^# ── Shared helpers/,$p' "$1"
}

REFERENCE_BODY="$(extract_body "${WORKSPACE}/agentic-memory/scripts/check-canonical-sister.sh")"
for sister in "${SISTERS[@]}"; do
  target="${WORKSPACE}/${sister}/scripts/check-canonical-sister.sh"
  if [ ! -f "$target" ]; then
    fail "${sister}: missing scripts/check-canonical-sister.sh"
  else
    body="$(extract_body "$target")"
    if [ "$REFERENCE_BODY" != "$body" ]; then
      fail "${sister}: check script assertion body differs from memory's"
    else
      pass "${sister}: check script body matches"
    fi
  fi
done

# ── 3. Sister manifest presence and structure ───────────────────────────────

section "Sister manifest validation"

EXPECTED_KEYS=(memory vision codebase identity time)
EXPECTED_NAMES=(AgenticMemory AgenticVision AgenticCodebase AgenticIdentity AgenticTime)

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  key="${EXPECTED_KEYS[$i]}"
  name="${EXPECTED_NAMES[$i]}"
  manifest="${WORKSPACE}/${sister}/docs/public/sister.manifest.json"

  if [ ! -f "$manifest" ]; then
    fail "${sister}: missing docs/public/sister.manifest.json"
    continue
  fi

  if ! grep -qF "\"key\": \"${key}\"" "$manifest"; then
    fail "${sister}: manifest missing key \"${key}\""
  else
    pass "${sister}: manifest key=${key}"
  fi

  if ! grep -qF "\"name\": \"${name}\"" "$manifest"; then
    fail "${sister}: manifest missing name \"${name}\""
  else
    pass "${sister}: manifest name=${name}"
  fi

  if ! grep -qF '"page_ids": [' "$manifest"; then
    fail "${sister}: manifest missing page_ids array"
  else
    pass "${sister}: manifest has page_ids"
  fi
done

# ── 4. Install script canonical strings ─────────────────────────────────────

section "Install script canonical output strings"

CANONICAL_STRINGS=(
  "MCP client summary:"
  "Universal MCP entry (works in any MCP client):"
  "Quick terminal check:"
  'echo "  args: ${SERVER_ARGS_TEXT}"'
  "After restart, confirm"
  "Optional feedback:"
  "AGENTIC_TOKEN"
)

for sister in "${SISTERS[@]}"; do
  script="${WORKSPACE}/${sister}/scripts/install.sh"
  if [ ! -f "$script" ]; then
    fail "${sister}: missing scripts/install.sh"
    continue
  fi
  missing=0
  for str in "${CANONICAL_STRINGS[@]}"; do
    if ! grep -qF "$str" "$script"; then
      fail "${sister}: install.sh missing canonical string: ${str}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: install.sh has all canonical strings"
  fi
done

# ── 5. README section consistency ───────────────────────────────────────────

section "README canonical sections"

README_SECTIONS=(
  '## Install'
  '## Quickstart'
  '## How It Works'
  '<img src="assets/github-hero-pane.svg"'
  '<img src="assets/github-terminal-pane.svg"'
)

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    fail "${sister}: missing README.md"
    continue
  fi
  missing=0
  for sec in "${README_SECTIONS[@]}"; do
    if ! grep -qF "$sec" "$readme"; then
      fail "${sister}: README.md missing: ${sec}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: README has all canonical sections"
  fi
done

# ── 6. CI workflow presence ─────────────────────────────────────────────────

section "CI workflow presence"

REQUIRED_WORKFLOWS=(
  ci.yml
  release.yml
  canonical-sister-guardrails.yml
  install-command-guardrails.yml
)

for sister in "${SISTERS[@]}"; do
  missing=0
  for wf in "${REQUIRED_WORKFLOWS[@]}"; do
    if [ ! -f "${WORKSPACE}/${sister}/.github/workflows/${wf}" ]; then
      fail "${sister}: missing .github/workflows/${wf}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: all required workflows present"
  fi
done

# ── 7. Release workflow publish parity ───────────────────────────────────────

section "Release workflow publish parity (core + ffi + mcp + cli)"

CORE_CRATES=(
  "agentic-memory"
  "agentic-vision"
  "agentic-codebase"
  "agentic-identity"
  "agentic-time"
)

FFI_CRATES=(
  "agentic-memory-ffi"
  "agentic-vision-ffi"
  "agentic-codebase-ffi"
  "agentic-identity-ffi"
  "agentic-time-ffi"
)

MCP_CRATES=(
  "agentic-memory-mcp"
  "agentic-vision-mcp"
  "agentic-codebase-mcp"
  "agentic-identity-mcp"
  "agentic-time-mcp"
)

CLI_CRATES=(
  "agentic-memory-cli"
  "agentic-vision-cli"
  "agentic-codebase-cli"
  "agentic-identity-cli"
  "agentic-time-cli"
)

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  release_wf="${WORKSPACE}/${sister}/.github/workflows/release.yml"

  if [ ! -f "$release_wf" ]; then
    fail "${sister}: missing .github/workflows/release.yml"
    continue
  fi

  missing=0
  for pkg in "${CORE_CRATES[$i]}" "${FFI_CRATES[$i]}" "${MCP_CRATES[$i]}" "${CLI_CRATES[$i]}"; do
    if ! grep -qF "$pkg" "$release_wf"; then
      fail "${sister}: release workflow missing publish target ${pkg}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: release workflow references core+ffi+mcp+cli crates"
  fi

  if grep -Eq 'cargo publish[^#\n]*\|\|[[:space:]]*true' "$release_wf"; then
    fail "${sister}: release workflow has non-blocking cargo publish (|| true)"
  fi
  if grep -qF 'continue-on-error: true' "$release_wf"; then
    fail "${sister}: release workflow has continue-on-error: true (publish must fail fast)"
  fi
done

# ── 8. CI workflow trigger alignment ────────────────────────────────────────

section "CI workflow trigger alignment (canonical-sister-guardrails.yml)"

for sister in "${SISTERS[@]}"; do
  wf="${WORKSPACE}/${sister}/.github/workflows/canonical-sister-guardrails.yml"
  if [ ! -f "$wf" ]; then
    continue  # already flagged above
  fi
  if ! grep -qF 'push:' "$wf"; then
    fail "${sister}: canonical-sister-guardrails.yml missing push trigger"
  elif ! grep -qF 'pull_request:' "$wf"; then
    fail "${sister}: canonical-sister-guardrails.yml missing pull_request trigger"
  else
    pass "${sister}: CI triggers aligned (push + pull_request)"
  fi
done

# ── 9. Asset directory ──────────────────────────────────────────────────────

section "Design asset presence"

for sister in "${SISTERS[@]}"; do
  hero="${WORKSPACE}/${sister}/assets/github-hero-pane.svg"
  term="${WORKSPACE}/${sister}/assets/github-terminal-pane.svg"
  if [ ! -f "$hero" ] || [ ! -f "$term" ]; then
    fail "${sister}: missing SVG assets"
  else
    pass "${sister}: SVG assets present"
  fi
done

# ── 10. Web install route registration ───────────────────────────────────────

section "Web install route registration"

ROUTE_FILE="${WORKSPACE}/agentralabs-tech-web/app/install/[target]/[profile]/route.ts"
if [ ! -f "$ROUTE_FILE" ]; then
  pass "Skipping web install route check (web repo not available)"
else
  for key in memory vision codebase identity time; do
    if ! grep -qF "\"${key}\"" "$ROUTE_FILE"; then
      fail "Web route missing target: ${key}"
    else
      pass "Web route has target: ${key}"
    fi
  done
fi

# ── 11. Public docs baseline parity ────────────────────────────────────────

section "Public docs baseline parity"

BASELINE_DOCS=(
  experience-with-vs-without.md
  quickstart.md
  installation.md
  command-surface.md
  runtime-install-sync.md
  integration-guide.md
  concepts.md
  api-reference.md
  benchmarks.md
  faq.md
)

for sister in "${SISTERS[@]}"; do
  missing=0
  for doc in "${BASELINE_DOCS[@]}"; do
    if [ ! -f "${WORKSPACE}/${sister}/docs/public/${doc}" ]; then
      fail "${sister}: missing docs/public/${doc}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: all baseline public docs present"
  fi
done

# ── 12. Core scripts presence ──────────────────────────────────────────────

section "Core scripts presence"

REQUIRED_SCRIPTS=(
  scripts/install.sh
  scripts/check-install-commands.sh
  scripts/check-canonical-sister.sh
  scripts/check-runtime-hardening.sh
  scripts/test-primary-problems.sh
)

for sister in "${SISTERS[@]}"; do
  missing=0
  for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -f "${WORKSPACE}/${sister}/${script}" ]; then
      fail "${sister}: missing ${script}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: all required scripts present"
  fi
done

# ── 13. Web navigation contract — all sister keys present ────────────────────

section "Web navigation contract"

NAV_CONTRACT="${WORKSPACE}/agentralabs-tech-web/docs/ecosystem/navigation-contract.json"
if [ ! -f "$NAV_CONTRACT" ]; then
  pass "Skipping navigation contract check (web repo not available)"
else
  for key in memory vision codebase identity time; do
    if ! grep -qF "\"key\": \"${key}\"" "$NAV_CONTRACT"; then
      fail "navigation-contract.json missing sister key: ${key}"
    else
      pass "navigation-contract.json has sister key: ${key}"
    fi
  done
fi

# ── 14. Manifest page_ids baseline ──────────────────────────────────────────

section "Manifest page_ids baseline"

BASELINE_PAGE_IDS=(
  experience-with-vs-without
  quickstart
  installation
  command-surface
  runtime-install-sync
)

for sister in "${SISTERS[@]}"; do
  manifest="${WORKSPACE}/${sister}/docs/public/sister.manifest.json"
  if [ ! -f "$manifest" ]; then
    continue  # already flagged above
  fi
  missing=0
  for pid in "${BASELINE_PAGE_IDS[@]}"; do
    if ! grep -qF "\"${pid}\"" "$manifest"; then
      fail "${sister}: manifest missing baseline page_id: ${pid}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: manifest has all baseline page_ids"
  fi
done

# ── 15. README nav bar links ────────────────────────────────────────────────

section "README nav bar links"

NAV_LINKS=(
  '#quickstart'
  '#problems-solved'
  '#how-it-works'
  '#benchmarks'
  '#install'
)
# Additional nav elements checked by text presence (not href)
NAV_TEXT_LINKS=(
  '>Papers</a>'
  '>API</a>'
)

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue  # already flagged above
  fi
  missing=0
  for link in "${NAV_LINKS[@]}"; do
    if ! grep -qF "href=\"${link}\"" "$readme"; then
      fail "${sister}: README nav bar missing link: ${link}"
      missing=1
    fi
  done
  for textlink in "${NAV_TEXT_LINKS[@]}"; do
    if ! grep -qF "$textlink" "$readme"; then
      fail "${sister}: README nav bar missing text link: ${textlink}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: README has all nav bar links"
  fi
done

# ── 16. README architecture SVG width ───────────────────────────────────────

section "README architecture SVG width"

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue  # already flagged above
  fi
  if grep -qF 'architecture-agentra.svg' "$readme"; then
    if grep 'architecture-agentra.svg' "$readme" | grep -qF 'width="980"'; then
      pass "${sister}: architecture SVG width=980"
    else
      fail "${sister}: architecture SVG not using width=\"980\""
    fi
  fi
done

# ── 17. Web scenario data files ─────────────────────────────────────────────

section "Web scenario data files"

WEB_DATA_DIR="${WORKSPACE}/agentralabs-tech-web/data"
if [ ! -d "$WEB_DATA_DIR" ]; then
  pass "Skipping web scenario data check (web repo not available)"
else
  for key in memory vision codebase identity time; do
    datafile="${WEB_DATA_DIR}/scenarios-${key}.ts"
    if [ ! -f "$datafile" ]; then
      fail "Web missing data/scenarios-${key}.ts"
    else
      pass "Web has data/scenarios-${key}.ts"
    fi
  done
fi

# ── 18. Workspace README sister mentions ──────────────────────────────────

section "Workspace README sister mentions"

WORKSPACE_README="${WORKSPACE}/README.md"
if [ ! -f "$WORKSPACE_README" ]; then
  fail "Workspace README.md missing"
else
  for sister in "${SISTERS[@]}"; do
    if grep -qF "$sister" "$WORKSPACE_README"; then
      pass "Workspace README mentions ${sister}"
    else
      fail "Workspace README missing mention of ${sister}"
    fi
  done
fi

# ── 19. README npm install rows ──────────────────────────────────────────────

section "README npm install rows"

NPM_PACKAGES=(
  "@agenticamem/memory"
  "@agenticamem/vision"
  "@agenticamem/codebase"
  "@agenticamem/identity"
  "@agenticamem/time"
)

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  pkg="${NPM_PACKAGES[$i]}"
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue  # already flagged above
  fi
  if grep -qF "npm install ${pkg}" "$readme"; then
    pass "${sister}: README has npm install ${pkg}"
  else
    fail "${sister}: README missing npm install ${pkg}"
  fi
done

# ── 20. Installation doc npm sections ────────────────────────────────────────

section "Installation doc npm sections"

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  pkg="${NPM_PACKAGES[$i]}"
  doc="${WORKSPACE}/${sister}/docs/public/installation.md"
  if [ ! -f "$doc" ]; then
    fail "${sister}: missing docs/public/installation.md"
    continue
  fi
  if grep -qF "npm install ${pkg}" "$doc"; then
    pass "${sister}: installation.md has npm install ${pkg}"
  else
    fail "${sister}: installation.md missing npm install ${pkg}"
  fi
done

# ── 21. Required SVG assets per sister ────────────────────────────────────────

section "Required SVG assets per sister"

REQUIRED_SVGS=(
  "assets/github-hero-pane.svg"
  "assets/github-terminal-pane.svg"
  "assets/benchmark-chart.svg"
  "assets/architecture-agentra.svg"
)

for sister in "${SISTERS[@]}"; do
  missing=0
  for svg in "${REQUIRED_SVGS[@]}"; do
    if [ ! -f "${WORKSPACE}/${sister}/${svg}" ]; then
      fail "${sister}: missing ${svg}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: all required SVGs present"
  fi
done

# ── 22. README references benchmark and architecture SVGs ────────────────────

section "README benchmark + architecture SVG references"

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue
  fi
  if ! grep -qF 'benchmark-chart.svg' "$readme"; then
    fail "${sister}: README missing benchmark-chart.svg reference"
  elif ! grep -qF 'architecture-agentra.svg' "$readme"; then
    fail "${sister}: README missing architecture-agentra.svg reference"
  else
    pass "${sister}: README references both benchmark + architecture SVGs"
  fi
done

# ── 23. MCP command-surface documentation completeness ─────────────────────

section "MCP command-surface documentation completeness"

CMD_SURFACE_SCRIPT="${WORKSPACE}/scripts/check-command-surface.sh"
if [ -f "$CMD_SURFACE_SCRIPT" ]; then
  if bash "$CMD_SURFACE_SCRIPT" >/dev/null 2>&1; then
    pass "All MCP tools documented in command-surface.md (all sisters)"
  else
    # Re-run to capture which tools are missing (|| true prevents set -e exit)
    sub_output="$(bash "$CMD_SURFACE_SCRIPT" 2>&1 || true)"
    sub_errors="$(echo "$sub_output" | grep -c '^FAIL:' || true)"
    echo "$sub_output" | grep '^FAIL:' | while IFS= read -r line; do
      echo "FAIL: $line"
    done || true
    ERRORS=$((ERRORS + sub_errors))
  fi
else
  fail "scripts/check-command-surface.sh not found"
fi

# ── 24. 4-crate structure + language bindings per sister ──────────────────────

section "4-crate structure + language bindings"

SISTER_KEYS=(memory vision codebase identity time)

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  key="${SISTER_KEYS[$i]}"
  missing=0

  for suffix in cli mcp ffi; do
    crate_dir="${WORKSPACE}/${sister}/crates/agentic-${key}-${suffix}"
    if [ ! -d "$crate_dir" ] || [ ! -f "${crate_dir}/Cargo.toml" ]; then
      fail "${sister}: missing crate crates/agentic-${key}-${suffix}"
      missing=1
    fi
  done

  if [ ! -d "${WORKSPACE}/${sister}/python" ] || [ ! -f "${WORKSPACE}/${sister}/python/pyproject.toml" ]; then
    fail "${sister}: missing python/pyproject.toml"
    missing=1
  fi

  if [ ! -d "${WORKSPACE}/${sister}/npm/wasm" ] || [ ! -f "${WORKSPACE}/${sister}/npm/wasm/Cargo.toml" ]; then
    fail "${sister}: missing npm/wasm/Cargo.toml"
    missing=1
  fi

  if [ "$missing" -eq 0 ]; then
    pass "${sister}: 4-crate structure + python + wasm present"
  fi
done

# ── 25. MCP stdio hardening parity ──────────────────────────────────────────

section "MCP stdio hardening parity (frame limit + Content-Length + JSON-RPC)"

for i in "${!SISTERS[@]}"; do
  sister="${SISTERS[$i]}"
  key="${SISTER_KEYS[$i]}"
  mcp_src="${WORKSPACE}/${sister}/crates/agentic-${key}-mcp/src"

  if [ ! -d "$mcp_src" ]; then
    fail "${sister}: MCP source directory missing (crates/agentic-${key}-mcp/src)"
    continue
  fi

  missing=0

  # 8 MiB frame limit constant
  if ! grep -rqF "MAX_CONTENT_LENGTH_BYTES" "$mcp_src"; then
    fail "${sister}: MCP source missing MAX_CONTENT_LENGTH_BYTES (8 MiB frame limit)"
    missing=1
  fi

  # Content-Length framing support
  if ! grep -rqiF "content-length:" "$mcp_src"; then
    fail "${sister}: MCP source missing Content-Length framing"
    missing=1
  fi

  # JSON-RPC version handling
  if ! grep -rqF "jsonrpc" "$mcp_src"; then
    fail "${sister}: MCP source missing jsonrpc version handling"
    missing=1
  fi

  if [ "$missing" -eq 0 ]; then
    pass "${sister}: MCP hardening patterns present (frame limit + framing + jsonrpc)"
  fi
done

# ── 26. Local goals/ directory structure (gitignored but must exist) ──────────
#
# WHEN YOU NEED CONTRACTS:
#   cat goals/validation/SISTER-HYDRA-INTEGRATION-CONTRACT.md
#   cat goals/validation/MCP-TOOL-STANDARDS.md
#
# WHEN BUILDING A NEW SISTER:
#   cat goals/new-sisters/SISTER-V2-PATTERNS.md
#   cp -r agentic-contracts/ ../new-sister/deps/
#
# WHEN BUILDING HYDRA:
#   ls goals/hydra/   # 13 specification documents
#

section "Local goals/ directory structure"

GOALS_DIR="${WORKSPACE}/goals"
if [ ! -d "$GOALS_DIR" ]; then
  pass "Skipping goals/ check (gitignored, local-only)"
else
  GOALS_GROUPS=(validation new-sisters hydra vision)
  missing=0
  for group in "${GOALS_GROUPS[@]}"; do
    if [ ! -d "${GOALS_DIR}/${group}" ]; then
      fail "goals/${group}/ subdirectory missing"
      missing=1
    fi
  done

  # Validation group — needed NOW for sister compliance
  VALIDATION_DOCS=(
    "SISTER-HYDRA-INTEGRATION-CONTRACT.md"
    "MCP-TOOL-STANDARDS.md"
    "EDGE-CASE-HANDLERS-SPEC.md"
  )
  for doc in "${VALIDATION_DOCS[@]}"; do
    if [ ! -f "${GOALS_DIR}/validation/${doc}" ]; then
      fail "goals/validation/${doc} missing"
      missing=1
    fi
  done

  # New-sisters group — needed when building future sisters
  NEW_SISTER_DOCS=(
    "ASTRAL-MISSING-SISTERS.md"
    "SISTER-V2-PATTERNS.md"
    "SISTER-V2-PLANNED-PRE-PHILIP.md"
  )
  for doc in "${NEW_SISTER_DOCS[@]}"; do
    if [ ! -f "${GOALS_DIR}/new-sisters/${doc}" ]; then
      fail "goals/new-sisters/${doc} missing"
      missing=1
    fi
  done

  # Hydra group — needed LATER when building Hydra orchestrator
  HYDRA_DOCS=(
    "HYDRA-COMPLETE-SPEC.md"
    "HYDRA-INVENTIONS.md"
    "SKILL-FABRIC-SPEC.md"
    "RESOURCE-OPTIMIZATION-SPEC.md"
    "HYDRA-UX-SPEC.md"
    "HYDRA-ARCHITECTURE-FEEDBACK.md"
    "HYDRA-SKILL-ECOSYSTEMS.md"
    "HydraPhilosophy.md"
    "HydraMail.md"
    "HYDRA-PHONECOMM.md"
    "MOREOFHYDRA.md"
    "UIUX-minset.md"
  )
  for doc in "${HYDRA_DOCS[@]}"; do
    if [ ! -f "${GOALS_DIR}/hydra/${doc}" ]; then
      fail "goals/hydra/${doc} missing"
      missing=1
    fi
  done

  # Vision group — 20-year roadmaps
  VISION_DOCS=(
    "SISTER-VISION-20-YEAR.md"
    "VISION-AMEM-20-YEAR-ROADMAP.md"
  )
  for doc in "${VISION_DOCS[@]}"; do
    if [ ! -f "${GOALS_DIR}/vision/${doc}" ]; then
      fail "goals/vision/${doc} missing"
      missing=1
    fi
  done

  if [ "$missing" -eq 0 ]; then
    pass "goals/ has all 4 groups with all required documents"
  fi
fi

# ── 27. Local agentic-contracts/ crate (gitignored but must exist) ──────────
#
# Single source of truth for Rust traits all sisters implement.
# Will be published to crates.io when ready.
#
# WHEN VALIDATING A SISTER:
#   cd agentic-contracts && cargo test
#   cat docs/SISTER-COMPLIANCE-VERIFICATION.md
#
# WHEN BUILDING A NEW SISTER:
#   # Add to new sister's Cargo.toml:
#   # agentic-contracts = { path = "../agentic-contracts" }
#

section "Local agentic-contracts/ crate"

CONTRACTS_DIR="${WORKSPACE}/agentic-contracts"
if [ ! -d "$CONTRACTS_DIR" ]; then
  pass "Skipping agentic-contracts/ check (gitignored, local-only)"
else
  missing=0

  if [ ! -f "${CONTRACTS_DIR}/Cargo.toml" ]; then
    fail "agentic-contracts/Cargo.toml missing"
    missing=1
  fi

  REQUIRED_SOURCES=(
    src/lib.rs
    src/types.rs
    src/sister.rs
    src/context.rs
    src/errors.rs
    src/events.rs
    src/grounding.rs
    src/query.rs
    src/receipts.rs
    src/file_format.rs
  )
  for src in "${REQUIRED_SOURCES[@]}"; do
    if [ ! -f "${CONTRACTS_DIR}/${src}" ]; then
      fail "agentic-contracts/${src} missing"
      missing=1
    fi
  done

  if [ ! -f "${CONTRACTS_DIR}/docs/SISTER-COMPLIANCE-VERIFICATION.md" ]; then
    fail "agentic-contracts/docs/SISTER-COMPLIANCE-VERIFICATION.md missing"
    missing=1
  fi

  if [ "$missing" -eq 0 ]; then
    pass "agentic-contracts/ crate structure complete (10 source files + compliance doc)"
  fi
fi

# ── 28. Research paper directory parity ──────────────────────────────────────

section "Research paper directory parity"

for sister in "${SISTERS[@]}"; do
  paper_dir="${WORKSPACE}/${sister}/paper"
  if [ ! -d "$paper_dir" ]; then
    fail "${sister}: missing paper/ directory"
    continue
  fi

  paper_i="$(ls -d "${paper_dir}"/paper-i-* 2>/dev/null | head -1)"
  if [ -z "$paper_i" ]; then
    fail "${sister}: missing paper/paper-i-* subdirectory"
    continue
  fi

  if ! ls "$paper_i"/*.tex >/dev/null 2>&1; then
    fail "${sister}: missing .tex file in $(basename "$paper_i")"
  elif [ ! -f "$paper_i/references.bib" ]; then
    fail "${sister}: missing references.bib in $(basename "$paper_i")"
  else
    pass "${sister}: paper/paper-i-* with .tex + references.bib present"
  fi
done

# ── 29. SVG design system conformance ────────────────────────────────────────
#
# All sister SVGs MUST use the canonical Agentra design system:
#   Background: #f2f1ea (light parchment, NOT dark gradients)
#   Grid: dotted pattern with #b8b6ae or #c8c5bb or #c9c6bb dots
#   Text: #111111 primary ink
#   Accent: #ea580c orange
#   Font: JetBrains Mono (or IBM Plex Mono fallback)
#
# This prevents the exact problem that happened with agentic-time's initial
# SVGs (dark gradient theme with system-ui fonts).

section "SVG design system conformance (Agentra canonical)"

SVG_DESIGN_TOKENS=(
  "#f2f1ea"           # canonical background color
  "#111111"           # canonical ink color
  "#ea580c"           # canonical accent color
  "JetBrains Mono"    # canonical font family
)

SVG_DARK_ANTI_TOKENS=(
  "linearGradient"    # dark gradient backgrounds are NOT canonical
  "system-ui"         # system fonts are NOT canonical
)

for sister in "${SISTERS[@]}"; do
  missing=0
  for svg in "${REQUIRED_SVGS[@]}"; do
    svgfile="${WORKSPACE}/${sister}/${svg}"
    if [ ! -f "$svgfile" ]; then
      continue  # already flagged in section 21
    fi

    # Positive check: must contain design tokens
    for token in "${SVG_DESIGN_TOKENS[@]}"; do
      if ! grep -qF "$token" "$svgfile"; then
        fail "${sister}: ${svg} missing design token: ${token}"
        missing=1
      fi
    done

    # Negative check: must NOT contain anti-tokens
    for antitoken in "${SVG_DARK_ANTI_TOKENS[@]}"; do
      if grep -qF "$antitoken" "$svgfile"; then
        fail "${sister}: ${svg} has non-canonical token: ${antitoken} (use Agentra design system)"
        missing=1
      fi
    done
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: all SVGs conform to Agentra design system"
  fi
done

# ── 30. README full canonical structure ──────────────────────────────────────
#
# Beyond basic section presence (section 5), enforce the complete README
# structure that all sisters must have. This catches stripped-down READMEs
# that have Install/Quickstart but miss MCP, Benchmarks, or other sections.

section "README full canonical structure"

README_FULL_SECTIONS=(
  '## Problems Solved'
  '## MCP'                      # MCP Tools or MCP Server
  '## Benchmarks'
  '## Why'
  '## Install'
  '## Quickstart'
  '## How It Works'
  '## Common Workflows'
  '## Validation'
  '## Repository Structure'
  '## Contributing'
  '## Privacy and Security'
  'Built by'                    # footer
)

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue  # already flagged above
  fi
  missing=0
  for sec in "${README_FULL_SECTIONS[@]}"; do
    if ! grep -qF "$sec" "$readme"; then
      fail "${sister}: README missing canonical section/element: ${sec}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: README has all canonical structure elements"
  fi
done

# ── 31. README canonical badges ──────────────────────────────────────────────
#
# All sisters must have the standard badge rows: pip install, cargo install,
# MCP Server, MIT License, and format badge.

section "README canonical badges"

README_BADGES=(
  'pip_install'
  'cargo_install'
  'MCP_Server'
  'License-MIT'
  'Research-Paper_I'        # must link to paper-i
  'format-.'               # .amem, .atime, .acb, .avis, .aid
)

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue
  fi
  missing=0
  for badge in "${README_BADGES[@]}"; do
    if ! grep -qF "$badge" "$readme"; then
      fail "${sister}: README missing canonical badge: ${badge}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: README has all canonical badges"
  fi
done

# ── 32. README deployment model section ──────────────────────────────────────

section "README Deployment Model + MCP Server configuration"

README_DEPLOY_ELEMENTS=(
  '## Deployment Model'
  '## MCP Server'
  'claude_desktop_config.json'
  '.vscode/settings.json'
  'Standalone'
)

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue
  fi
  missing=0
  for elem in "${README_DEPLOY_ELEMENTS[@]}"; do
    if ! grep -qF "$elem" "$readme"; then
      fail "${sister}: README missing deployment element: ${elem}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: README has deployment model + MCP server config"
  fi
done

# ── 33. README install profiles (desktop/terminal/server) ──────────────────

section "README install profiles"

for sister in "${SISTERS[@]}"; do
  readme="${WORKSPACE}/${sister}/README.md"
  if [ ! -f "$readme" ]; then
    continue
  fi
  missing=0
  for profile in desktop terminal server; do
    if ! grep -qF "install/${profile}" "$readme" 2>/dev/null; then
      # Try alternate pattern with sister key
      key="${sister#agentic-}"
      if ! grep -qF "${key}/${profile}" "$readme" 2>/dev/null; then
        fail "${sister}: README missing install profile: ${profile}"
        missing=1
      fi
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: README has all 3 install profiles"
  fi
done

# ── 34. Root governance files ────────────────────────────────────────────────
#
# Every sister MUST have these root files for a professional, complete repo.

section "Root governance files"

ROOT_FILES=(
  LICENSE
  CONTRIBUTING.md
  SECURITY.md
  Makefile
  CHANGELOG.md
)

for sister in "${SISTERS[@]}"; do
  missing=0
  for rf in "${ROOT_FILES[@]}"; do
    if [ ! -f "${WORKSPACE}/${sister}/${rf}" ]; then
      fail "${sister}: missing root file ${rf}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: all root governance files present"
  fi
done

# ── 35. Web content: every sister name must appear in critical web pages ──────

section "Web sister name parity in critical pages"

WEB_ROOT="${WORKSPACE}/agentralabs-tech-web"
SISTER_DISPLAY_NAMES=(AgenticMemory AgenticVision AgenticCodebase AgenticIdentity AgenticTime)

# These files MUST mention ALL sister display names. If a new sister is added
# and these files are not updated, the guardrail will FAIL.
WEB_CRITICAL_FILES=(
  "app/page.tsx"
  "app/layout.tsx"
  "components/footer.tsx"
  "components/pricing-section.tsx"
  "lib/site.ts"
  "app/opengraph-image.tsx"
  "app/projects/page.tsx"
  "app/projects/head.tsx"
)

if [ ! -d "$WEB_ROOT" ]; then
  pass "Skipping web sister name parity (web repo not available)"
else
  for webfile in "${WEB_CRITICAL_FILES[@]}"; do
    filepath="${WEB_ROOT}/${webfile}"
    if [ ! -f "$filepath" ]; then
      fail "Web critical file missing: ${webfile}"
      continue
    fi
    missing_names=()
    for name in "${SISTER_DISPLAY_NAMES[@]}"; do
      if ! grep -qF "$name" "$filepath"; then
        missing_names+=("$name")
      fi
    done
    if [ ${#missing_names[@]} -gt 0 ]; then
      fail "Web ${webfile} missing sister names: ${missing_names[*]}"
    else
      pass "Web ${webfile}: all 5 sister names present"
    fi
  done
fi

# ── 36. Web content: file format strings must appear on home page ─────────────

section "Web home page file format completeness"

HOME_PAGE="${WEB_ROOT}/app/page.tsx"
HERO_SECTION="${WEB_ROOT}/components/hero-section.tsx"
FILE_FORMATS=(.amem .avis .acb .aid .atime)

if [ ! -d "$WEB_ROOT" ]; then
  pass "Skipping web file format check (web repo not available)"
else
  for target in "$HOME_PAGE" "$HERO_SECTION"; do
    if [ ! -f "$target" ]; then
      continue
    fi
    basename="$(basename "$(dirname "$target")")/$(basename "$target")"
    missing_fmt=()
    for fmt in "${FILE_FORMATS[@]}"; do
      if ! grep -qF "$fmt" "$target"; then
        missing_fmt+=("$fmt")
      fi
    done
    if [ ${#missing_fmt[@]} -gt 0 ]; then
      fail "Web ${basename} missing file formats: ${missing_fmt[*]}"
    else
      pass "Web ${basename}: all 5 file formats present"
    fi
  done
fi

# ── 37. Web content: no stale "Four" count (must say "Five") ──────────────────

section "Web stale sister count detection"

# Any file saying "Four open-source" or "Four independent" or "Four file formats"
# is stale and must be updated to "Five".
STALE_COUNT_PATTERNS=(
  "Four open-source"
  "Four file format"
  "Four independent"
  "Four sisters"
)

if [ ! -d "$WEB_ROOT" ]; then
  pass "Skipping stale count detection (web repo not available)"
else
  stale_found=0
  for pattern in "${STALE_COUNT_PATTERNS[@]}"; do
    matches="$(grep -rl "$pattern" "$WEB_ROOT" --include='*.tsx' --include='*.ts' --include='*.md' 2>/dev/null || true)"
    if [ -n "$matches" ]; then
      while IFS= read -r match; do
        relative="${match#"${WEB_ROOT}/"}"
        # Skip node_modules and .next
        case "$relative" in
          node_modules/*|.next/*) continue ;;
        esac
        fail "Web ${relative} contains stale count: '${pattern}' (should be Five)"
        stale_found=1
      done <<< "$matches"
    fi
  done
  if [ "$stale_found" -eq 0 ]; then
    pass "Web: no stale 'Four' sister counts found"
  fi
fi

# ── 38. Web flyer pages: all sisters in social media OG images ────────────────

section "Web social media flyer sister parity"

WEB_FLYER_FILES=(
  "app/flyers/twitter-post/route.tsx"
  "app/flyers/linkedin-post/route.tsx"
  "app/twitter-image.tsx"
)

# These files must reference all sister short names (MEMORY, VISION, etc.)
# OR their full display names (AgenticMemory, etc.)
SISTER_SHORT_NAMES=(MEMORY VISION CODEBASE IDENTITY TIME)

if [ ! -d "$WEB_ROOT" ]; then
  pass "Skipping flyer parity (web repo not available)"
else
  for flyer in "${WEB_FLYER_FILES[@]}"; do
    filepath="${WEB_ROOT}/${flyer}"
    if [ ! -f "$filepath" ]; then
      fail "Web flyer missing: ${flyer}"
      continue
    fi
    missing_short=()
    for sname in "${SISTER_SHORT_NAMES[@]}"; do
      # Check for short name OR full name (case insensitive)
      if ! grep -qi "$sname" "$filepath"; then
        missing_short+=("$sname")
      fi
    done
    if [ ${#missing_short[@]} -gt 0 ]; then
      fail "Web ${flyer} missing sisters: ${missing_short[*]}"
    else
      pass "Web ${flyer}: all 5 sisters present"
    fi
  done
fi

# ── 39. Web about section: all sisters mentioned in description ───────────────

section "Web about section sister completeness"

ABOUT_SECTION="${WEB_ROOT}/components/about-section.tsx"
if [ ! -f "$ABOUT_SECTION" ]; then
  pass "Skipping about section check (file not available)"
else
  missing_about=()
  for name in "${SISTER_DISPLAY_NAMES[@]}"; do
    if ! grep -qF "$name" "$ABOUT_SECTION"; then
      missing_about+=("$name")
    fi
  done
  if [ ${#missing_about[@]} -gt 0 ]; then
    fail "Web about-section.tsx missing sister names: ${missing_about[*]}"
  else
    pass "Web about-section.tsx: all 5 sister names present"
  fi
fi

# ── 40. Web scenario data + component: every sister has scenario integration ──

section "Web scenario integration completeness"

SCENARIO_COMPONENT="${WEB_ROOT}/components/scenario-cards-section.tsx"
SCENARIO_PAGE="${WEB_ROOT}/components/scenario-page.tsx"

if [ ! -d "$WEB_ROOT" ]; then
  pass "Skipping scenario integration check (web repo not available)"
else
  # Already checked data files in section 17, now check components reference all
  for component in "$SCENARIO_COMPONENT" "$SCENARIO_PAGE"; do
    if [ ! -f "$component" ]; then
      continue
    fi
    basename="$(basename "$component")"
    for key in memory vision codebase identity time; do
      if ! grep -qi "$key" "$component"; then
        fail "Web ${basename} missing scenario reference for: ${key}"
      fi
    done
    pass "Web ${basename}: all 5 sister scenarios referenced"
  done
fi

# ── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: ${ERRORS} consistency error(s) found"
  exit 1
else
  echo "Cross-sister consistency checks passed."
fi
