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

# ── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: ${ERRORS} consistency error(s) found"
  exit 1
else
  echo "Cross-sister consistency checks passed."
fi
