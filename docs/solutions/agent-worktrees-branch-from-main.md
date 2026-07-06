# agent-worktrees-branch-from-main

## Symptom

A builder or judge dispatched via the harness's Agent-tool spawn mechanism
landed in a worktree branched from `main`'s head, not from the checked-out
factory branch (`factory/<run>`) the orchestrator was working on. The
dispatch instructions assumed the fresh worktree would already sit on the
run's current factory-branch head; it did not.

Downstream, this produced a postflight false positive during the
skill-library run (job skill-library/s8-orchestrator): auditing a
fast-forwarded worktree's touch-set against the run's original freeze SHA
read prior waves' already-merged commits as out-of-boundary violations —
`POSTFLIGHT: ERROR exit:2` on a job that had touched nothing outside its
boundary.

## Root Cause

The harness's worktree-spawn path for Agent-tool subagents forks from
`main` regardless of which branch the orchestrator's own session is
checked out on. The orchestrator has no built-in signal that the spawned
worktree diverged from the intended base until a manual `git worktree list`
/ `git log` check is run inside it.

Compounding this: postflight's touch-set audit needs a stable base commit
to diff against. Using the run's original freeze SHA as that base is
correct only for a worktree that was never fast-forwarded past it — once a
worktree is FF'd to a later dispatch-time head (to pick up merged prior
waves), diffing against the stale freeze SHA makes every already-integrated
prior-wave commit look like a violation introduced by the current job.

## What Did Not Work

- Assuming a freshly spawned Agent-tool worktree already sat on the
  dispatch-time factory-branch head without checking.
- Running postflight's touch-set audit against the run's original freeze
  SHA for a worktree that had been fast-forwarded past it — this produced
  the exit-2 false positive.
- Treating the exit-2 result as a real boundary violation and trying to
  re-scope the job, instead of checking whether the audit base itself was
  wrong.

## Route Around

- Treat every dispatch as a FIRST-ACTION step: run
  `git log --oneline -1` in the new worktree, then
  `git merge-base --is-ancestor HEAD <dispatch-head>` to confirm the
  worktree is an ancestor of the intended factory-branch head, then
  `git merge --ff-only <dispatch-head>` to land it there before any edits.
  Verify with `git worktree list` after spawn, not by assumption.
- For a worktree that was fast-forwarded this way, the postflight audit
  base must be the **dispatch-time factory head** (the SHA the worktree was
  FF'd to), not the run's original freeze SHA — otherwise wave-N-1 merges
  already on that head read as this job's violations.
- If postflight reports `exit:2` immediately after a fast-forward step,
  check the audit base before assuming the job actually touched
  out-of-boundary files.
