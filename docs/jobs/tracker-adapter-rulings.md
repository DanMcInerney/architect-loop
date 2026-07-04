# Rulings: tracker-adapter (orchestrator-owned, append-only)

- 2026-07-04 PHASE-level concern ACCEPTED (builder right; check-authoring
  defect): TA1's `git grep` commands cannot see the NEW untracked
  tracker.md before the orchestrator's commit, and builders may not
  `git add`. Ruling: TA1's commands are evaluated at judgment time (the
  orchestrator commits the job before judge dispatch, making the file
  tracked); the builder's Select-String-equivalent evidence in the report
  stands as the pre-commit record. Lesson for future check authoring:
  content checks on NEW files use Select-String, not git grep.
  The builder's self-cleanup of its transient tests/__pycache__ artifact
  (workspace-bounded delete, recorded verbatim) is sanctioned bookkeeping,
  not a boundary violation.
