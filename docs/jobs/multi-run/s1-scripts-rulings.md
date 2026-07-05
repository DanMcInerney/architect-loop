# Rulings: multi-run/s1-scripts (issue #90)

Append-only; orchestrator-owned.

- 2026-07-05 RULING on PHASE-0 item 1 (run-marker check vs no body field in
  the raw record contract): correct reading. The run-marker body check is an
  ORCHESTRATOR dispatch-time duty, not the status emitter's. Status scripts
  scope SUB rows by parent edge + author only; the orchestrator verifies the
  `<!-- architect-run: <run> -->` marker when it reads a candidate sub-issue
  before dispatch. No body fetch in the scripts.
- 2026-07-05 RULING on PHASE-0 item 2 (tracker.md still shows flat
  docs/issues paths): expected mid-flight; sibling job s2-skilltext owns
  tracker.md and rewrites it against the same contract.
- 2026-07-05 RULING on PHASE-0 item 3 (gh binary present in sandbox despite
  "no network" note): binary presence != network reachability; offline proof
  via STATUS_GH_STUB was the required path and was used. No change.
- 2026-07-05 RULING on PHASE-0 item 4 (status.sh was bash, target POSIX sh):
  intended by the issue; #!/bin/sh shebang change is in-scope.
