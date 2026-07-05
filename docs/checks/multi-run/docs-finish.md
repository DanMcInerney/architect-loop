# Frozen check: multi-run docs-finish

Purpose: product docs reflect the shipped multi-run isolation feature and the
run's docs debt is consumed; README voice/structure preserved.

Spec pointer: docs/spec/multi-run.md. Fix contract: FAIL evidence routes to
the orchestrator; the builder never edits this file. Report path:
docs/jobs/multi-run/docs-finish-01.md. This job has no cold judge
(human-ruled exception): the orchestrator grades the checkrun evidence
directly.

Executor: PowerShell (primary; Windows codex sandbox kills Git Bash with
Win32 error 5). Recorded same-pattern substitution is permitted per check.
Sanctioned if the default uv cache is denied: PowerShell
`$env:UV_CACHE_DIR='.architect/tmp/uv-cache'`.

- RUN: `git grep -F -c "docs/runs/" -- README.md` -> matches >= 1 (run manifest/per-run layout documented for users).
- RUN: `git grep -F -c "run marker" -- DESIGN.md` -> matches >= 1 (run-identity design and evidence recorded).
- RUN: `git grep -F -c "## Config" -- README.md` -> exactly 1 (Config section preserved; it holds the repo's only ini example).
- RUN: `git grep -F -c "assets/" -- README.md` -> matches >= 1 (hand-written SVG diagrams still referenced).
- RUN: `Test-Path docs/solutions/postflight-lane-commit.md` -> True (lesson: orchestrator commits the lane onto the job branch BEFORE postflight; symptom of skipping = exit 5 with no-op merge).
- RUN: `Test-Path docs/solutions/worktree-cleanup-locks.md` -> True (lesson: worktree removal fails on cwd drift - relative config paths, orchestrator shell cwd inside the worktree, lingering codex children).
- RUN: `uv run python tests/validate_skills.py` -> exit 0, output contains "OK". Duration hint ~2m.
- Orchestrator-graded: README's multi-run coverage names the status run-slug argument and the per-run stop file; DESIGN.md records this run's evidence (grill catches incl. validator-retired term, postflight lessons); no invented content beyond the change-context digest.
