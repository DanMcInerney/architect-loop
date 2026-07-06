# Checkrun: s1-runner-checkrun
generated: 2026-07-05T20:52:30.5353347Z  runner: ps1  config: .architect/tmp/runner-s1.json
check_file: docs/checks/judge-scout/s1-runner.md  freeze_sha: 8965e40c6ccc657266b6a5ac5e5f36fabbe2b6fe
Executor: powershell
executor_config: powershell
executor_resolved: powershell
integrity: check_file_matches_freeze=true head=8965e40c6ccc657266b6a5ac5e5f36fabbe2b6fe
changed_files: 0 listed below; docs_checks_touched=false

## (root) line 27
$ $env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py
exit: 0  ms: 7822  bytes: 45
OK - 2 skills validated, v4 contracts clean

## (root) line 28
$ git grep -F -c "CHECKRUN SUMMARY:" -- skills/architect/check-runner.ps1
exit: 0  ms: 413  bytes: 36
skills/architect/check-runner.ps1:1

## (root) line 29
$ git grep -F -c "CHECKRUN SUMMARY:" -- skills/architect/check-runner.sh
exit: 0  ms: 351  bytes: 35
skills/architect/check-runner.sh:1

## (root) line 30
$ git grep -F -c "verdict: " -- skills/architect/check-runner.ps1
exit: 0  ms: 356  bytes: 36
skills/architect/check-runner.ps1:1

## (root) line 31
$ git grep -F -c "verdict: " -- skills/architect/check-runner.sh
exit: 0  ms: 362  bytes: 35
skills/architect/check-runner.sh:1

## (root) line 32
$ git grep -F -l -e "-> exit:" -- tests/fixtures/checkrun
exit: 0  ms: 379  bytes: 198
tests/fixtures/checkrun/fixture-checks-bash.md
tests/fixtures/checkrun/fixture-checks-ps.md
tests/fixtures/checkrun/fixture-checks-quoted-bash.md
tests/fixtures/checkrun/fixture-checks-quoted-ps.md
