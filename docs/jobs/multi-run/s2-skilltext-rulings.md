# Rulings: multi-run/s2-skilltext (issue #91)

Append-only; orchestrator-owned.

- 2026-07-05 RULING on PHASE-0 disagreement 1 (report path outside MAY TOUCH):
  `docs/jobs/<run>/` artifacts are exempt bookkeeping - the dispatch block
  itself orders the report there, and postflight exempts `docs/jobs/`. Writing
  the job report and checkrun evidence is NOT a boundary violation. Judges:
  grade the implementation boundary over the four skill files only.
- 2026-07-05 RULING on PHASE-0 disagreement 2 (status scripts in this checkout
  still carry the old selection and signature): expected by design. Sibling job
  multi-run/s1-scripts-01 (issue #90) owns the scripts and builds against the
  same pinned interface contract; S2 documents the contract sight-unseen. The
  skill text describing behavior not yet present in THIS worktree's scripts is
  not a defect of S2.
