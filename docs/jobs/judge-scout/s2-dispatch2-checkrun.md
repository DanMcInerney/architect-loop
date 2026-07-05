# Checkrun: s2-dispatch2-checkrun
generated: 2026-07-05T21:09:22.9547163Z  runner: ps1  config: .architect/tmp/runner-s2b.json
check_file: docs/checks/judge-scout/s2-dispatch2.md  freeze_sha: 567841119507f5138e92ec37b1b461ede1ba9330
Executor: powershell
executor_config: powershell
executor_resolved: powershell

## (root) line 14
$ $env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py
exit: 0  ms: 7549  bytes: 45
expected: exit:0 match:"OK"
verdict: PASS
OK - 2 skills validated, v4 contracts clean

## (root) line 15
$ git grep -F -c "Per check:" -- skills/architect/dispatch.md
exit: 1  ms: 381  bytes: 0
expected: exit:1
verdict: PASS

## (root) line 16
$ git grep -F -c "Per check:" -- tests/validate_skills.py
exit: 1  ms: 482  bytes: 0
expected: exit:1
verdict: PASS

## (root) line 17
$ git grep -F -c -e "-> exit:" -- skills/architect/dispatch.md
exit: 0  ms: 401  bytes: 31
expected: exit:0
verdict: PASS
skills/architect/dispatch.md:2

## (root) line 18
$ git grep -F -c "match:" -- skills/architect/dispatch.md
exit: 0  ms: 402  bytes: 31
expected: exit:0
verdict: PASS
skills/architect/dispatch.md:2

## (root) line 19
$ git grep -F -c "## Scout dispatch" -- skills/architect/dispatch.md
exit: 0  ms: 399  bytes: 31
expected: exit:0
verdict: PASS
skills/architect/dispatch.md:1

## (root) line 20
$ if ((Get-Content skills/architect/dispatch.md | Where-Object { $_.Trim() -ne "" }).Count -le 545) { "BUDGET_OK" } else { "BUDGET_FAIL"; exit 1 }
exit: 0  ms: 415  bytes: 11
expected: exit:0 match:"BUDGET_OK"
verdict: PASS
BUDGET_OK

CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
integrity: check_file_matches_freeze=true head=567841119507f5138e92ec37b1b461ede1ba9330
changed_files: 0 listed below; docs_checks_touched=false
