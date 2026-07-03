# Checks: status-tracker (addendum to status-scripts, second-FAIL re-spec)

Purpose: statically verify the tracker-mode algorithm in BOTH scripts —
the gh path cannot execute in this sandbox, so these checks pin the
algorithm's load-bearing features; the orchestrator proves behavior with a
live render at composite.
Spec (fix contract): `docs/spec/status-tree.md` — the amended tracker-mode
algorithm in the Interface contract.
Files owned: unchanged from `docs/checks/status-scripts.md`.

## ST1 — one gh call with the full-state shape, in both scripts

- `(Select-String -Path skills/architect/status.ps1 -Pattern '--state all').Count` → ≥1
- `(Select-String -Path skills/architect/status.sh -Pattern '--state all').Count` → ≥1
- `(Select-String -Path skills/architect/status.ps1,skills/architect/status.sh -Pattern 'blockedBy').Count` → ≥2

## ST2 — parent filtering exists in both scripts

- `(Select-String -Path skills/architect/status.ps1 -Pattern 'parent').Count` → ≥1
- `(Select-String -Path skills/architect/status.sh -Pattern 'parent').Count` → ≥1
- Quote the sh lines that (a) select the tracking-issue candidate from
  `parent.number` references and (b) filter sub-issues by that parent —
  file:line, verbatim.

## ST3 — successful-empty and no-candidate handling

- Both scripts contain the literal `tracker: no open run` → Select-String
  count ≥1 each.
- Quote the sh branch showing `[]`/no-candidate leads to
  `NO ACTIVE FACTORY RUN` when no artifacts exist — file:line, verbatim.

## ST4 — parity statement

- The report quotes both scripts' tracker-mode sections side by side and
  states any behavioral difference found (target: none).

## ST5 — regression: SS1-SS6 all still pass

- Re-run every check in `docs/checks/status-scripts.md` and record
  verbatim output (the fixtures and degraded mode must be unaffected).
