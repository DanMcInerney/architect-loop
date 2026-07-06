# Checkrun: s3-docs-checkrun
generated: 2026-07-06T16:38:10Z  runner: sh  config: C:/Users/danhm/tools/architect-loop/.architect/runs/architect-fast/.architect/tmp/runner-s3.json
check_file: docs/checks/architect-fast/s3-docs.md  freeze_sha: e8a4abfa7dd6c387d3a74d03205704a15502a39f
executor_config: bash

## Graded items line 21
$ grep -F -c '/architect-fast <small change>' README.md
exit: 0  ms: 63  bytes: 2
expected: exit:0 match:"1"
verdict: PASS
1

## Graded items line 22
$ grep -F -c '### /architect-fast' README.md
exit: 0  ms: 60  bytes: 2
expected: exit:0 match:"2"
verdict: PASS
2

## Graded items line 23
$ grep -F -c 'assets/architect-fast-flow.svg' README.md
exit: 0  ms: 61  bytes: 2
expected: exit:0 match:"1"
verdict: PASS
1

## Graded items line 24
$ test -f assets/architect-fast-flow.svg
exit: 0  ms: 54  bytes: 0
expected: exit:0
verdict: PASS

## Graded items line 25
$ grep -F -c '### The fast lane' DESIGN.md
exit: 0  ms: 56  bytes: 2
expected: exit:0 match:"1"
verdict: PASS
1

## Graded items line 26
$ grep -F -c '/architect-fast' DESIGN.md
exit: 0  ms: 57  bytes: 2
expected: exit:0
verdict: PASS
4

## Graded items line 27
$ grep -i -c 'fast lane' CONTEXT.md
exit: 0  ms: 69  bytes: 2
expected: exit:0
verdict: PASS
2

## Graded items line 28
$ grep -F -c 'fast lane (/architect-fast)' skills/codebase-design/SKILL.md
exit: 0  ms: 60  bytes: 2
expected: exit:0 match:"1"
verdict: PASS
1

## Graded items line 29
$ uv run python tests/validate_skills.py
exit: 0  ms: 11848  bytes: 46
expected: exit:0 match:"OK -"
verdict: PASS
OK - 11 skills validated, v4 contracts clean

CHECKRUN SUMMARY: run_items=9 pass=9 fail=0
integrity: check_file_matches_freeze=true head=e8a4abfa7dd6c387d3a74d03205704a15502a39f
changed_files: 0 listed below; docs_checks_touched=false
