# postflight-lane-commit

## Symptom

Postflight was launched after a builder reported done, but before the
orchestrator committed the builder worktree onto the job branch.

The visible failure shape:

```text
POSTFLIGHT: ERROR
exit 5
```

The factory head was still the freeze SHA, and the merge was a no-op because
the job branch had no committed builder changes.

## Root Cause

Builder worktrees are allowed to contain uncommitted file edits. Postflight
integrates a job branch, not loose working-tree state. If the orchestrator does
not first commit the builder's changes inside the job worktree, the job branch
still points at the freeze commit and postflight has nothing real to merge.

## What Did Not Work

- Treating the builder's DONE report as proof that the job branch contained the
  edits.
- Running postflight directly against a job branch still at the freeze SHA.
- Retrying postflight without first checking whether the builder worktree had
  uncommitted changes.

## Route Around

- Before postflight, the orchestrator must commit the builder worktree changes
  onto the job branch.
- Verify the job branch moved off the freeze SHA before merge postflight.
- If postflight exits 5 with a no-op merge shape, inspect the job worktree for
  uncommitted edits and commit them before retrying integration.
