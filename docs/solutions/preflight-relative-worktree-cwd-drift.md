# preflight-relative-worktree-cwd-drift

## Symptom

A preflight config used a relative `worktree` path. The PowerShell shell had a
persisted current directory from a previous job, so preflight resolved the path
there and created a nested worktree:

```text
.architect/wt/skill-text-01/.architect/wt/skill-guards-01
```

The intended location was the run's repo-level `.architect/wt/skill-guards-01`.

Related observations from the same run:

- The check-runner resolves `evidence_out` relative to its own current
  directory or repo root, not relative to the config's `workdir`.
- Postflight can exit 5 on `worktree remove failed` after a successful merge and
  push.

## Root Cause

The factory scripts run in shells whose current directory can persist across
events. Relative paths in configs are therefore ambiguous unless the script
explicitly resolves them against the repo root. In this case, the relative
`worktree` value followed the calling shell's current directory instead of the
intended repo root.

The postflight cleanup failure is a separate late-stage condition: integration
may already have succeeded before worktree removal fails.

## What Did Not Work

- Relying on the config example's relative `worktree` path form.
- Treating an exit 5 cleanup failure as proof that merge or push failed.
- Treating `evidence_out` as config-workdir-relative.

## Route Around

- Write absolute worktree paths in preflight configs.
- Treat check-runner evidence paths as repo-root-relative unless the runner
  explicitly records otherwise.
- If postflight reports `worktree remove failed`, verify merge and push state
  before rerunning any integration step.

