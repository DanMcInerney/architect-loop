# Checkrun: docs-finish-checkrun
generated: 2026-07-05T18:39:20.7200613Z  runner: ps1  config: C:\Users\danhm\tools\architect-loop\.architect\checkrun-docs.json
check_file: docs/checks/multi-run/docs-finish.md  freeze_sha: 608b0a184cd63aedf694b836b7aa3cfd743b8098
Executor: PowerShell (primary; Windows codex sandbox kills Git Bash with
executor_config: powershell
executor_resolved: powershell
integrity: check_file_matches_freeze=true head=608b0a184cd63aedf694b836b7aa3cfd743b8098
changed_files: 0 listed below; docs_checks_touched=false

## (root) line 17
$ git grep -F -c "docs/runs/" -- README.md
exit: 0  ms: 492  bytes: 12
README.md:5

## (root) line 18
$ git grep -F -c "run marker" -- DESIGN.md
exit: 0  ms: 511  bytes: 12
DESIGN.md:4

## (root) line 19
$ git grep -F -c "## Config" -- README.md
exit: 0  ms: 400  bytes: 12
README.md:1

## (root) line 20
$ git grep -F -c "assets/" -- README.md
exit: 0  ms: 350  bytes: 12
README.md:2

## (root) line 21
$ Test-Path docs/solutions/postflight-lane-commit.md
exit: 0  ms: 359  bytes: 6
True

## (root) line 22
$ Test-Path docs/solutions/worktree-cleanup-locks.md
exit: 0  ms: 346  bytes: 6
True

## (root) line 23
$ uv run python tests/validate_skills.py
exit: 0  ms: 1849  bytes: 45
OK - 2 skills validated, v4 contracts clean
