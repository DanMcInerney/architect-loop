# Rulings: hardening-dispatch (orchestrator-owned, append-only)

- 2026-07-03 PHASE-0 blocker ACCEPTED (builder was right; check defect):
  DB2's required marker `architect-monitor-fallback-template` contained
  DB3's forbidden search string `architect-monitor` — the two checks were
  mutually unsatisfiable as frozen. Ruling: DB3 (and the docs issue's DD2)
  pattern amended to `architect-monitor\.md`, matching the actual intent —
  no references to the DELETED definition file `.claude/agents/architect-monitor.md`.
  The fallback template's marker name is not such a reference. No results
  existed at amendment time; builder had stopped in PHASE 0 with a clean
  tree. Fresh builder respawned with this answer.
