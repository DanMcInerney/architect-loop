# Checkrun: docs-finish-checkrun
generated: 2026-07-05T21:55:12.4960926Z  runner: ps1  config: .architect/tmp/runner-docs3.json
check_file: docs/checks/judge-scout/docs-finish3.md  freeze_sha: 8a5c352c7aa16ac6d9fe77b008965dfe9b081769
Executor: powershell
executor_config: powershell
executor_resolved: powershell

## (root) line 15
$ $env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py
exit: 0  ms: 6950  bytes: 45
expected: exit:0 match:"OK"
verdict: PASS
OK - 2 skills validated, v4 contracts clean

## (root) line 16
$ git grep -F -c "closing review" -- DESIGN.md
exit: 0  ms: 320  bytes: 12
expected: exit:0
verdict: PASS
DESIGN.md:4

## (root) line 17
$ git grep -F -c "graded" -- DESIGN.md
exit: 0  ms: 350  bytes: 13
expected: exit:0
verdict: PASS
DESIGN.md:11

## (root) line 18
$ git grep -F -c "scout" -- DESIGN.md
exit: 0  ms: 333  bytes: 13
expected: exit:0
verdict: PASS
DESIGN.md:10

## (root) line 19
$ if (Select-String -Path docs/solutions/*.md -Pattern "judge-scout" -SimpleMatch -Quiet) { "PROVENANCE_OK" } else { "PROVENANCE_MISSING"; exit 1 }
exit: 0  ms: 396  bytes: 15
expected: exit:0 match:"PROVENANCE_OK"
verdict: PASS
PROVENANCE_OK

## (root) line 20
$ git grep -F -c "orchestrator-tier judge" -- DESIGN.md README.md
exit: 1  ms: 311  bytes: 0
expected: exit:1
verdict: PASS

CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
integrity: check_file_matches_freeze=true head=a0eb90ec9c6cfd4536994ca2e05f675722c75648
changed_files: 2 listed below; docs_checks_touched=true
docs/checks/judge-scout/docs-finish2.md
docs/checks/judge-scout/docs-finish3.md
