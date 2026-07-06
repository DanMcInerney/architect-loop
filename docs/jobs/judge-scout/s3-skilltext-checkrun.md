# Checkrun: s3-skilltext-checkrun
generated: 2026-07-05T20:48:28.0453369Z  runner: ps1  config: .architect/tmp/runner-s3.json
check_file: docs/checks/judge-scout/s3-skilltext.md  freeze_sha: 8965e40c6ccc657266b6a5ac5e5f36fabbe2b6fe
Executor: powershell
executor_config: powershell
executor_resolved: powershell
integrity: check_file_matches_freeze=true head=8965e40c6ccc657266b6a5ac5e5f36fabbe2b6fe
changed_files: 0 listed below; docs_checks_touched=false

## (root) line 13
$ $env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py
exit: 0  ms: 4289  bytes: 45
OK - 2 skills validated, v4 contracts clean

## (root) line 14
$ git grep -F -c "docs/runs/<run>/map.md" -- skills/architect/SKILL.md
exit: 0  ms: 354  bytes: 28
skills/architect/SKILL.md:3

## (root) line 15
$ git grep -F -c "change-skeleton" -- skills/architect/SKILL.md
exit: 0  ms: 414  bytes: 28
skills/architect/SKILL.md:3

## (root) line 16
$ git grep -F -c "closing review" -- skills/architect/SKILL.md
exit: 0  ms: 381  bytes: 28
skills/architect/SKILL.md:1

## (root) line 17
$ git grep -F -c "without judge dispatch" -- skills/architect/loop.md
exit: 0  ms: 364  bytes: 27
skills/architect/loop.md:1

## (root) line 18
$ if (((Get-Content skills/architect/SKILL.md | Where-Object { $_.Trim() -ne "" }).Count + (Get-Content skills/architect/loop.md | Where-Object { $_.Trim() -ne "" }).Count) -le 411) { "BUDGET_OK" } else { "BUDGET_FAIL"; exit 1 }
exit: 0  ms: 353  bytes: 11
BUDGET_OK
