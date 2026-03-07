# PARALLEL ASTRAL SISTER EXECUTION GUIDE

> **5 Claude Code Terminals → 4 Astral Sisters in Parallel**
> **Repo:** `/Users/omoshola/Documents/agentralabs-tech`

---

## TERMINAL ASSIGNMENT

```
TERMINAL 1: AgenticForge    (MOST CRITICAL)
TERMINAL 2: AgenticAegis
TERMINAL 3: AgenticEvolve
TERMINAL 4: AgenticVeritas
TERMINAL 5: Backup/Monitor (run guardrails, check progress)
```

---

## STEP 1: OPEN ALL TERMINALS

In each terminal:
```bash
cd /Users/omoshola/Documents/agentralabs-tech
```

---

## STEP 2: START CLAUDE CODE IN EACH TERMINAL

### Terminal 1 (Forge):
```bash
claude --dangerously-skip-permissions
```
Then paste:
```
Read /Users/omoshola/Documents/agentralabs-tech/CLAUDE-CODE-INSTRUCTIONS-FORGE.md and implement AgenticForge from Phase 1 to Phase 11. Do not stop until all tests pass. Working directory: /Users/omoshola/Documents/agentralabs-tech/agentic-forge
```

### Terminal 2 (Aegis):
```bash
claude --dangerously-skip-permissions
```
Then paste:
```
Read /Users/omoshola/Documents/agentralabs-tech/CLAUDE-CODE-INSTRUCTIONS-AEGIS.md and implement AgenticAegis from Phase 1 to Phase 11. Do not stop until all tests pass. Working directory: /Users/omoshola/Documents/agentralabs-tech/agentic-aegis
```

### Terminal 3 (Evolve):
```bash
claude --dangerously-skip-permissions
```
Then paste:
```
Read /Users/omoshola/Documents/agentralabs-tech/CLAUDE-CODE-INSTRUCTIONS-EVOLVE.md and implement AgenticEvolve from Phase 1 to Phase 11. Do not stop until all tests pass. Working directory: /Users/omoshola/Documents/agentralabs-tech/agentic-evolve
```

### Terminal 4 (Veritas):
```bash
claude --dangerously-skip-permissions
```
Then paste:
```
Read /Users/omoshola/Documents/agentralabs-tech/CLAUDE-CODE-INSTRUCTIONS-VERITAS.md and implement AgenticVeritas from Phase 1 to Phase 11. Do not stop until all tests pass. Working directory: /Users/omoshola/Documents/agentralabs-tech/agentic-veritas
```

### Terminal 5 (Monitor):
```bash
# Check progress periodically
watch -n 60 'for d in agentic-forge agentic-aegis agentic-evolve agentic-veritas; do echo "=== $d ==="; cd /Users/omoshola/Documents/agentralabs-tech/$d 2>/dev/null && cargo test --workspace 2>&1 | tail -3; cd ..; done'
```

---

## STEP 3: COPY INSTRUCTION FILES

Before running terminals, copy these files to the repo:

```bash
cp /path/to/CLAUDE-CODE-INSTRUCTIONS-FORGE.md /Users/omoshola/Documents/agentralabs-tech/
cp /path/to/CLAUDE-CODE-INSTRUCTIONS-AEGIS.md /Users/omoshola/Documents/agentralabs-tech/
cp /path/to/CLAUDE-CODE-INSTRUCTIONS-EVOLVE.md /Users/omoshola/Documents/agentralabs-tech/
cp /path/to/CLAUDE-CODE-INSTRUCTIONS-VERITAS.md /Users/omoshola/Documents/agentralabs-tech/
```

---

## SUCCESS CRITERIA PER SISTER

| Sister | Tests | MCP Tools | Inventions | CLI Commands |
|--------|-------|-----------|------------|--------------|
| Forge | 300+ | 15 | 32 | 40+ |
| Aegis | 250+ | 12 | 20 | 30+ |
| Evolve | 250+ | 14 | 22 | 35+ |
| Veritas | 200+ | 10 | 20 | 25+ |

---

## IF A SESSION DIES

Restart Claude Code in that terminal and paste:
```
Continue implementing [SisterName]. Check cargo test output to find which phase completed. Resume from the next phase.
```

---

## ESTIMATED TIME

- Per sister: 4-8 hours (depending on complexity)
- Total parallel: ~8 hours
- With 5 terminals: All 4 sisters done simultaneously

---

## POST-COMPLETION

When all 4 are done, run in Terminal 5:
```bash
cd /Users/omoshola/Documents/agentralabs-tech
for d in agentic-forge agentic-aegis agentic-evolve agentic-veritas; do
  echo "=== $d ==="
  cd $d
  cargo test --workspace 2>&1 | tail -5
  ./scripts/check-canonical-sister.sh 2>&1 | tail -3
  cd ..
done
```

All should show:
- Tests: 200+ passed
- Guardrails: All green
