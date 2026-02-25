#!/usr/bin/env bash
# check-canonical-consistency.sh — Cross-sister consistency validator
#
# Run from the agentralabs-tech workspace root. Validates that ALL sisters
# are structurally identical where they must be. If anything drifts, it fails.
#
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
SISTERS=(agentic-memory agentic-vision agentic-codebase agentic-identity)
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

EXPECTED_KEYS=(memory vision codebase identity)
EXPECTED_NAMES=(AgenticMemory AgenticVision AgenticCodebase AgenticIdentity)

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

# ── 7. CI workflow trigger alignment ────────────────────────────────────────

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

# ── 8. Asset directory ──────────────────────────────────────────────────────

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

# ── 9. Web install route registration ───────────────────────────────────────

section "Web install route registration"

ROUTE_FILE="${WORKSPACE}/agentralabs-tech-web/app/install/[target]/[profile]/route.ts"
if [ ! -f "$ROUTE_FILE" ]; then
  fail "Web install route file missing: ${ROUTE_FILE}"
else
  for key in memory vision codebase identity; do
    if ! grep -qF "\"${key}\"" "$ROUTE_FILE"; then
      fail "Web route missing target: ${key}"
    else
      pass "Web route has target: ${key}"
    fi
  done
fi

# ── 10. Public docs baseline parity ────────────────────────────────────────

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

# ── 11. Core scripts presence ──────────────────────────────────────────────

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

# ── 12. Web navigation contract — all sister keys present ────────────────────

section "Web navigation contract"

NAV_CONTRACT="${WORKSPACE}/agentralabs-tech-web/docs/ecosystem/navigation-contract.json"
if [ ! -f "$NAV_CONTRACT" ]; then
  fail "Web navigation-contract.json missing"
else
  for key in memory vision codebase identity; do
    if ! grep -qF "\"key\": \"${key}\"" "$NAV_CONTRACT"; then
      fail "navigation-contract.json missing sister key: ${key}"
    else
      pass "navigation-contract.json has sister key: ${key}"
    fi
  done
fi

# ── 13. Manifest page_ids baseline ──────────────────────────────────────────

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

# ── 14. README nav bar links ────────────────────────────────────────────────

section "README nav bar links"

NAV_LINKS=(
  '#quickstart'
  '#problems-solved'
  '#how-it-works'
  '#benchmarks'
  '#install'
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
  if [ "$missing" -eq 0 ]; then
    pass "${sister}: README has all nav bar links"
  fi
done

# ── 15. README architecture SVG width ───────────────────────────────────────

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

# ── 16. Web scenario data files ─────────────────────────────────────────────

section "Web scenario data files"

for key in memory vision codebase identity; do
  datafile="${WORKSPACE}/agentralabs-tech-web/data/scenarios-${key}.ts"
  if [ ! -f "$datafile" ]; then
    fail "Web missing data/scenarios-${key}.ts"
  else
    pass "Web has data/scenarios-${key}.ts"
  fi
done

# ── 17. Workspace README sister mentions ──────────────────────────────────

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

# ── 18. README npm install rows ──────────────────────────────────────────────

section "README npm install rows"

NPM_PACKAGES=(
  "@agenticamem/memory"
  "@agenticamem/vision"
  "@agenticamem/codebase"
  "@agenticamem/identity"
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

# ── 19. Installation doc npm sections ────────────────────────────────────────

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

# ── 20. Required SVG assets per sister ────────────────────────────────────────

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

# ── 21. README references benchmark and architecture SVGs ────────────────────

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

# ── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: ${ERRORS} consistency error(s) found"
  exit 1
else
  echo "Cross-sister consistency checks passed."
fi
