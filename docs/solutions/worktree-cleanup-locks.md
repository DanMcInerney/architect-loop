# worktree-cleanup-locks

## Symptom

Worktree cleanup failed or skipped removal after integration. The live failure
modes were:

- A relative `worktree` config path resolved against the script caller's
  current directory instead of the repo root.
- The orchestrator shell's own current directory was inside the worktree being
  removed.
- Lingering Codex child processes still held files or directories in the
  worktree.

## Root Cause

Cleanup depends on both path resolution and open handles. A relative worktree
path is ambiguous when the orchestrator shell's cwd drifts between events. On
Windows, a directory cannot be removed while a shell or child process still has
it as cwd or holds an open handle under it.

The session-cwd drift cause remains unattributed after code audit:
check-runner uses per-process `WorkingDirectory`, preflight/postflight never
change location, and status.ps1 balances Push/Pop.

## What Did Not Work

- Assuming relative `worktree` paths were repo-root-relative.
- Running removal from a shell currently located inside the target worktree.
- Deleting child paths piecemeal without first finding which process held the
  directory.

## Route Around

- Resolve worktree paths against the repo root before cleanup.
- Move the orchestrator shell cwd outside the worktree before removal.
- Search for lingering child processes by command signature: executable path,
  worktree path, cache/temp path, or another unique fragment from the in-flight
  command.
- Kill the holder, retry worktree removal, and use piecemeal child deletion only
  to isolate which path remains locked.
- Postflight now retries `git worktree remove`, then retries with `--force`,
  then reports `cleanup=deferred <path>` on the OK line instead of failing a
  completed merge for cleanup alone.
