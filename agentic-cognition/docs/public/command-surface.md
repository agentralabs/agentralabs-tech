---
status: stable
---

# Command Surface

### Compact Facade Tools

AgenticCognition uses operation-based routing for compact MCP tools. Each compact facade takes an `operation` plus optional `params`.

- `cognition_model_create`
- `cognition_model_heartbeat`
- `cognition_model_vitals`
- `cognition_model_portrait`
- `cognition_belief_add`
- `cognition_belief_query`
- `cognition_belief_graph`
- `cognition_soul_reflect`
- `cognition_self_topology`
- `cognition_pattern_fingerprint`
- `cognition_shadow_map`
- `cognition_drift_track`
- `cognition_predict`
- `cognition_simulate`

### CLI Commands

AgenticCognition provides 40+ CLI commands through the `acog` binary, organized into eight groups.

## model (9 commands)

`create`, `show`, `vitals`, `heartbeat`, `portrait`, `soul`, `consciousness`, `list`, `delete`

## belief (12 commands)

`add`, `show`, `list`, `strengthen`, `weaken`, `connect`, `graph`, `keystones`, `contradictions`, `crystallize`, `collapse`, `search`

## self (6 commands)

`topology`, `peaks`, `valleys`, `blindspots`, `defended`, `edges`

## pattern (3 commands)

`fingerprint`, `fossils`, `strata`

## shadow (3 commands)

`map`, `projections`, `blindspots`

## bias (2 commands)

`field`, `triggers`

## drift (2 commands)

`timeline`, `tectonics`

## predict (3 commands)

`preference`, `decision`, `future`

## Global Options

All commands support `--format json|table|text`, `--storage <path>`, and `--verbose` flags.
