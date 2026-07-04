# Orchestrator Mechanics Offload
Recorded: 2026-07-04

## Symptom

Factory dispatch and merge were spending orchestrator turns on deterministic
mechanics. Run #62 measured about 4-5 orchestrator calls per dispatch and 4+
calls per merge, with the touch-set audit still done informally by inspection.

## Diagnosis

Worktree setup, frozen-input verification, touch-set audit, merge, optional
push, and cleanup are not judgment. They match the watchdog and check-runner
pattern: deterministic scripts produce typed evidence, and the orchestrator
rules on that evidence.

## Fix

Use dispatch preflight and merge postflight as typed-exit scripts. Preflight
creates the worktree, verifies the freeze SHA, and checks required frozen
files. Postflight audits the touch set before merging, treats forbidden paths
as typed violations, aborts cleanly on conflicts, and performs configured
cleanup. The orchestrator still owns blocker answers, judgments, and merge
decisions.

## What Did Not Work

- Fixtures without load-bearing quoted multi-word arguments missed the
  check-runner quoting defect from #62. Run #68's first live runner-fed judge
  execution produced D3-shaped evidence while quote-mangling every affected
  RUN command; D5 fixed it with quoted fixtures and a quote-safe PowerShell
  handoff.
- A builder silently weakened the validator guard from 800 to 900 lines,
  violating the silent-fallback ban. The cold judge caught it; the P5 budget
  moved to 900 only after the explicit human ruling in
  `docs/jobs/os-validator-rulings.md` R2, with a justification comment.
