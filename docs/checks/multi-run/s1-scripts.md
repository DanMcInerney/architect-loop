# Frozen check: multi-run S1 - run-pinned status scripts

Purpose: prove tracker selection is pinned per run from the committed run
manifest (never a max over the whole tracker), foreign issues and foreign
authors are excluded from SUB rows, and the run-scoping filter is testable
offline.

Spec pointer: docs/spec/multi-run.md (D1, D2). Interface contract: issue body
of the S1 sub-issue under tracking issue #89.

Fix contract: FAIL evidence routes to the orchestrator, who fixes the input
and respawns; the builder never edits this file. Report path:
docs/jobs/multi-run/s1-scripts-01.md.

Executor: PowerShell (primary; Windows codex sandbox kills Git Bash with
Win32 error 5). Recorded same-pattern substitution is permitted per check.
Sanctioned if the default uv cache is denied: PowerShell
`$env:UV_CACHE_DIR='.architect/tmp/uv-cache'` (POSIX form
`UV_CACHE_DIR=.architect/tmp/uv-cache`). Judges in a no-network sandbox pick
network-free RUN items to re-run and record the substitution.

- RUN: `uv run python tests/validate_skills.py` -> exit 0, output contains "OK". Duration hint ~2m (first run may resolve a venv).
- RUN: `git grep -F -n "map(.number) | max" -- skills/architect/status.ps1 skills/architect/status.sh` -> no matches, exit 1 (global-max tracking-issue selection deleted from both scripts).
- RUN: `git grep -c "docs/runs" -- skills/architect/status.ps1` -> matches >= 1 (manifest resolution present in the PowerShell script).
- RUN: `git grep -c "docs/runs" -- skills/architect/status.sh` -> matches >= 1 (manifest resolution present in the POSIX script).
- RUN: `git grep -ci "author" -- skills/architect/status.ps1` -> matches >= 1 (author filter present; substance verified by the judge-only items below).
- RUN: `git grep -ci "author" -- skills/architect/status.sh` -> matches >= 1.
- Judge-only: tests/validate_skills.py contains a fixture-driven test proving all of: (a) github-mode stub data is pre-filter (raw issue records, not post-selection TSV) so the run-scoping filter itself executes under test; (b) a foreign OPEN parent issue with a HIGHER number than the pinned tracking issue does not become TRACK for the run; (c) a sub-issue whose parent edge matches the pinned tracking issue but whose author does not match the expected account is excluded from SUB rows; (d) markdown mode reads only docs/issues/<run>/ for the run. Cite the test function name(s) and fixture path(s).
- Judge-only: both scripts accept a run-slug argument, resolve docs/runs/<slug>/manifest.md, and emit TRACK from the manifest's tracking-issue value; NOOPENRUN is emitted only for manifest missing or pinned issue closed. Cite file:line in both scripts.
- Judge-only: with no slug argument and exactly one ACTIVE manifest, the scripts select that run; with multiple ACTIVE manifests they list runs and exit 0. Cite file:line.
- Judge-only: display logic resolves job worktrees under `.architect/wt/<run>/<slug>-01` and job reports under `docs/jobs/<run>/<slug>-01.md` (run-namespaced, per the interface contract), in BOTH scripts. Cite file:line in each.
- Judge-only: argument disambiguation is pinned: the first positional argument is ALWAYS a run slug, never a path; repo root is passed only via `-RepoRoot` (status.ps1) / `--repo-root` (status.sh). Cite file:line in each.
