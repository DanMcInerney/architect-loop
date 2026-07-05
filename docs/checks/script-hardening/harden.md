# Frozen check: script-hardening harden

Purpose: postflight commits dirty lanes and refuses no-op merges on EVERY
path (dirty worktree, clean worktree, no worktree); relative config paths
anchor to repo_root; cleanup survives held directories with
`cleanup=deferred` instead of a false exit 5; the solutions note records the
unattributed cwd-drift cause and the new safety net.

Spec pointer: docs/spec/script-hardening.md. Interface contract: issue body
of the harden sub-issue under tracking issue #95.

Fix contract: FAIL evidence routes to the orchestrator, who fixes the input
and respawns; the builder never edits this file. Report path:
docs/jobs/script-hardening/harden-01.md.

Executor: PowerShell (primary; Windows codex sandbox kills Git Bash with
Win32 error 5). Recorded same-pattern substitution is permitted per check.
Sanctioned if the default uv cache is denied: PowerShell
`$env:UV_CACHE_DIR='.architect/tmp/uv-cache'` (POSIX form
`UV_CACHE_DIR=.architect/tmp/uv-cache`). Judges in a no-network sandbox pick
network-free RUN items to re-run and record the substitution.

- RUN: `uv run python tests/validate_skills.py` -> exit 0, output contains "OK". Duration hint ~1m (baseline ~2s; the new fixture builds throwaway git repos).
- RUN: `git grep -F -c "check_postflight_lane_fixture" -- tests/validate_skills.py` -> matches >= 1 (the postflight fixture test exists under its pinned name).
- RUN: `git grep -F -c "cleanup=deferred" -- skills/architect/postflight.ps1` -> matches >= 1.
- RUN: `git grep -F -c "cleanup=deferred" -- skills/architect/postflight.sh` -> matches >= 1.
- RUN: `git grep -F -c "cleanup=deferred" -- skills/architect/dispatch.md` -> matches >= 1 (typed-exit table documents the form).
- RUN: `git grep -F -c "cleanup=deferred" -- docs/solutions/worktree-cleanup-locks.md` -> matches >= 1 (safety net documented for future operators).
- RUN: `git grep -F -c "no commits beyond freeze" -- skills/architect/postflight.ps1 skills/architect/postflight.sh` -> matches in BOTH files; `git grep -c` exits 0 when only one file matches, so grade from the per-file output lines.
- Judge-only: postflight (BOTH languages) commits a dirty configured worktree (`add -A` + commit with the `(lane)` message suffix) BEFORE the touch-set audit, and AFTER that step exits 5 with the no-commits-beyond-freeze error whenever the job tip still equals freeze_sha (covers clean-worktree and no-worktree paths — no silent no-op merge survives). Cite file:line in each.
- Judge-only: `check_postflight_lane_fixture` proves (a) dirty lane -> lane committed, merged, exit 0, factory head advanced; (b) a RELATIVE worktree config path resolves against repo_root and the worktree is removed even when the test process cwd is elsewhere; (c) job tip == freeze_sha -> exit 5 with the pinned message. Cite the assertions by line.
- Judge-only: FullPath (postflight.ps1, preflight.ps1) and abs_path (postflight.sh, preflight.sh) anchor relative paths to the resolved repo_root, not the caller cwd. Cite file:line in all four.
- Judge-only: worktree removal path: retry after a delay, then `--force`, then `cleanup=deferred <path>` on the OK line with exit 0; a completed merge+push never exits 5 for cleanup alone. Cite file:line in both languages.
- Judge-only: docs/solutions/worktree-cleanup-locks.md records the session-cwd drift cause as unattributed (scripts audited clean) and keeps the existing mitigations. Cite line.
- Judge-only: loop.md close-out (or dispatch.md) names killing lingering codex children of a consumed exec before postflight. Cite file:line.
- Judge-only: net non-blank additions across the five capped skill-text files (SKILL.md, tracker.md, dispatch.md, loop.md, research.md) <= 12 (measured 1088/1100 pre-build). Cite before/after counts from the job report.
