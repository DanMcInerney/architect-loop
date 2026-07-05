# Spec: script-hardening — postflight/preflight integration fixes

Run slug: `script-hardening`. Tracker mode: github. Base: factory/multi-run
(99ac31c); the fixes depend on the multi-run run's .gitignore and solutions
notes. Closing PR stacks onto PR #94.

## Problem (all observed live in run multi-run, 2026-07-05)

1. postflight merges the job BRANCH; when the orchestrator has not committed
   the builder's worktree changes, the merge silently no-ops (job tip ==
   freeze SHA) and the only symptom is a misleading late
   `POSTFLIGHT: ERROR worktree remove failed` (observed: S2 first attempt).
2. `FullPath` in postflight.ps1:37 and preflight.ps1:50 anchors relative
   config paths to the CALLER'S CWD, not `repo_root`; a relative `worktree`
   entry then misses `Test-Path` and cleanup silently skips (violates the
   no-silent-fallback rule). The .sh pair's `abs_path` needs the same audit.
3. `git worktree remove` fails when anything holds the directory (observed:
   lingering codex child processes twice; an unattributed session-cwd drift
   once). No retry, no `--force` fallback; a SUCCESSFUL merge+push then
   exits 5 as if integration failed.
4. The #93 close comment blames check-runner for the session-cwd drift;
   grill code audit exonerates it (per-process WorkingDirectory;
   preflight/postflight never change location; status.ps1 balances
   Push/Pop). Cause is unattributed; the orchestrator corrects the comment
   on the tracker (not builder work). GRILL CORRECTIONS (pre-freeze): a
   suspected `>\dev\null` defect in postflight.sh was falsified byte-level
   (Grep display artifact); docs/solutions/worktree-cleanup-locks.md never
   contained the check-runner attribution.

## Goal

postflight fails loudly and early on an uncommitted lane by committing it
(matching the recorded manual fallback sequence, which includes
`add -A; commit`); relative config paths anchor to `repo_root`; cleanup
survives transient directory holds; the .sh/.ps1 pairs stay in parity; the
solutions note tells the truth.

## Design

- D1 lane commit: when `worktree` is configured and its tree is dirty,
  postflight runs `git add -A` + `git commit` in the worktree (message:
  `<merge_message> (lane)`) BEFORE the touch-set audit, so the audit covers
  the full lane. AFTER that step, if the job tip still equals `freeze_sha`
  (no worktree, or worktree clean), exit 5 `POSTFLIGHT: ERROR job branch has
  no commits beyond freeze` — no silent no-op merge survives on any path.
  Scripts stay mechanical: no grading, no conflict resolution.
- D2 path anchoring: `FullPath`/`abs_path` anchor relative paths to the
  resolved `repo_root` in preflight and postflight, both languages.
- D3 cleanup resilience: worktree remove retries once after ~2s, then falls
  back to `git worktree remove --force`, then (still failing) emits
  `POSTFLIGHT: OK merge=<sha> changed=<n> cleanup=deferred <path>` exit 0 —
  a completed merge+push is OK with recorded deferred cleanup, not exit 5.
  dispatch.md's typed-exit table row for postflight exit 0 gains the
  `cleanup=deferred` form; loop.md/dispatch close-out gains: kill lingering
  codex children of a consumed exec before postflight.
- D4 docs/solutions/worktree-cleanup-locks.md: record the cwd-drift cause as
  unattributed (audit exonerated the scripts) and document the new
  mechanical safety net (retry / --force / cleanup=deferred).

## Non-goals

No changes to check-runner (exonerated), status scripts, watchdog, judge
flow, or tracker conventions. No new typed exit codes.

## Validation strategy

- New fixture test in tests/validate_skills.py: temp git repo + worktree with
  a dirty lane -> postflight commits the lane, merges, exits 0; relative
  `worktree` path in config resolves against repo_root (worktree actually
  removed); job-tip==freeze with no worktree -> exit 5 with the new message.
  Platform-native script; both where available.
- `uv run python tests/validate_skills.py` green; the new fixture test is
  named `check_postflight_lane_fixture` so its presence is grep-provable.
- Grep guards: `cleanup=deferred` present in postflight.ps1, postflight.sh,
  dispatch.md, and the solutions note.

## Domain language

**lane commit** (postflight committing the builder's dirty worktree onto the
job branch), **deferred cleanup** (merge OK, directory removal pending).

## Approval record

In-session approval, 2026-07-05: repo owner, verbatim: "can you just go fix
those \"worth knowing\" issues" — authorizes this run including invocation.
Design choices D1 (commit-the-lane over hard-error; matches the recorded
manual fallback) and D3 (exit-0-with-deferred-cleanup over new exit code)
are orchestrator-ruled; recorded here for after-the-fact veto.
