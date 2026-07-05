# Frozen check: multi-run S2 - skill-text run conventions

Purpose: the skill text pins runs (committed manifest + issue-body run marker),
namespaces all run artifacts per run, scopes grounding to the pinned run,
adds per-run stop and one-checkout-per-live-run, and deletes the
global-scan selection text.

Spec pointer: docs/spec/multi-run.md (D1-D5). Interface contract: issue body
of the S2 sub-issue under tracking issue #89.

Fix contract: FAIL evidence routes to the orchestrator, who fixes the input
and respawns; the builder never edits this file. Report path:
docs/jobs/multi-run/s2-skilltext-01.md.

Executor: PowerShell (primary; Windows codex sandbox kills Git Bash with
Win32 error 5). Recorded same-pattern substitution is permitted per check.
Sanctioned if the default uv cache is denied: PowerShell
`$env:UV_CACHE_DIR='.architect/tmp/uv-cache'` (POSIX form
`UV_CACHE_DIR=.architect/tmp/uv-cache`). Judges in a no-network sandbox pick
network-free RUN items to re-run and record the substitution.

- RUN: `git grep -F -c "docs/runs/<run>/manifest.md" -- skills/architect/SKILL.md skills/architect/tracker.md` -> matches in BOTH files; `git grep -c` exits 0 when only one file matches, so grade from the per-file output lines, not the exit code (manifest convention named where grounding and tracker mechanics live).
- RUN: `git grep -F -c "architect-run:" -- skills/architect` -> matches >= 2 across skill text (run marker documented in issue conventions and at intake/tracking-issue creation).
- RUN: `git grep -F -c "docs/checks/<run>/" -- skills/architect` -> matches >= 1 (per-run check namespace).
- RUN: `git grep -F -c "docs/jobs/<run>/" -- skills/architect` -> matches >= 1 (per-run job-artifact namespace).
- RUN: `git grep -F -c "docs/issues/<run>/" -- skills/architect/tracker.md` -> matches >= 1 (markdown-mode per-run issue dir with per-run numbering).
- RUN: `git grep -F -c "job/<run>/" -- skills/architect/dispatch.md` -> matches >= 1 (run-namespaced job branches).
- RUN: `git grep -F -c "docs/runs/<run>/STOP" -- skills/architect` -> matches >= 1 (per-run stop documented; global docs/STOP retained).
- RUN: `git grep -F -n "highest such number wins" -- skills/architect` -> no matches, exit 1 (global-scan selection text deleted).
- RUN: `uv run python tests/validate_skills.py` -> exit 0, output contains "OK" (marker, TOC, template-block, and size guards all hold against unmodified tests). Duration hint ~2m.
- Judge-only: SKILL.md step 0 grounding scopes tracker reading to the pinned run - the tracking issue plus its children - and states the wider tracker is out of scope for the loop. Cite line.
- Judge-only: the foreign sub-issue rule is present: a sub-issue under the run parent with wrong author or missing run marker is never dispatched and is escalated on the tracking-issue digest. Cite file:line.
- Judge-only: one-checkout-per-live-run rule present: each concurrently live run operates in its own git worktree on its own factory/<run> branch; never two orchestrator sessions in one checkout. Cite file:line.
- Judge-only: intake ordering present: create the tracking issue first, then write docs/runs/<run>/manifest.md with its number; manifest must be committable (fix ignore rules if docs/runs is ignored). Cite file:line.
- Judge-only: docs/STOP remains the absolute kill-all and the stop check covers both the run checkout and the primary checkout. Cite file:line.
