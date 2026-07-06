# Checkrun: s1-skill-checkrun
generated: 2026-07-06T16:37:52Z  runner: sh  config: C:/Users/danhm/tools/architect-loop/.architect/runs/architect-fast/.architect/tmp/runner-s1.json
check_file: docs/checks/architect-fast/s1-skill.md  freeze_sha: e8a4abfa7dd6c387d3a74d03205704a15502a39f
executor_config: bash

## Graded items line 20
$ test -f skills/architect-fast/SKILL.md
exit: 0  ms: 54  bytes: 0
expected: exit:0
verdict: PASS

## Graded items line 21
$ grep -c '^name: architect-fast$' skills/architect-fast/SKILL.md
exit: 0  ms: 62  bytes: 2
expected: exit:0 match:"1"
verdict: PASS
1

## Graded items line 22
$ grep -c '^effort: high$' skills/architect-fast/SKILL.md
exit: 0  ms: 62  bytes: 2
expected: exit:0 match:"1"
verdict: PASS
1

## Graded items line 23
$ grep -F -c 'light factory lane' skills/architect-fast/SKILL.md
exit: 0  ms: 62  bytes: 2
expected: exit:0
verdict: PASS
1

## Graded items line 24
$ grep -F -c 'size ceiling' skills/architect-fast/SKILL.md
exit: 0  ms: 59  bytes: 2
expected: exit:0
verdict: PASS
3

## Graded items line 25
$ grep -F -c 'Hard Rules 3 and 4' skills/architect-fast/SKILL.md
exit: 0  ms: 68  bytes: 2
expected: exit:0
verdict: PASS
1

## Graded items line 26
$ grep -F -c 'docs job' skills/architect-fast/SKILL.md
exit: 0  ms: 62  bytes: 2
expected: exit:0
verdict: PASS
2

## Graded items line 27
$ grep -F -c 'no frozen check files, no check-runner' skills/architect-fast/SKILL.md
exit: 0  ms: 59  bytes: 2
expected: exit:0
verdict: PASS
1

## Graded items line 28
$ grep -F -c '## Substitutions' skills/architect-fast/SKILL.md
exit: 0  ms: 69  bytes: 2
expected: exit:0 match:"1"
verdict: PASS
1

## Graded items line 29
$ grep -F -c 'dispatch-head SHA' skills/architect-fast/SKILL.md
exit: 0  ms: 60  bytes: 2
expected: exit:0
verdict: PASS
2

## Graded items line 30
$ grep -F -c 'recorded final-review substitute' skills/architect-fast/SKILL.md
exit: 0  ms: 55  bytes: 2
expected: exit:0
verdict: PASS
1

## Graded items line 31
$ grep -c -w 'component' skills/architect-fast/SKILL.md
exit: 1  ms: 55  bytes: 2
expected: exit:1 match:"0"
verdict: PASS
0

## Graded items line 32
$ grep -c -w 'ticket' skills/architect-fast/SKILL.md
exit: 1  ms: 60  bytes: 2
expected: exit:1 match:"0"
verdict: PASS
0

## Graded items line 33
$ grep -c -i 'boundar' skills/architect-fast/SKILL.md
exit: 1  ms: 56  bytes: 2
expected: exit:1 match:"0"
verdict: PASS
0

## Graded items line 34
$ grep -c -i 'sentinel' skills/architect-fast/SKILL.md
exit: 1  ms: 61  bytes: 2
expected: exit:1 match:"0"
verdict: PASS
0

## Graded items line 35
$ grep -c '^LOOP:' skills/architect-fast/SKILL.md
exit: 1  ms: 60  bytes: 2
expected: exit:1 match:"0"
verdict: PASS
0

## Graded items line 36
$ test $(grep -c . skills/architect-fast/SKILL.md) -le 160
exit: 0  ms: 82  bytes: 0
expected: exit:0
verdict: PASS

## Graded items line 37
$ uv run python tests/validate_skills.py
exit: 0  ms: 11471  bytes: 46
expected: exit:0 match:"OK - 11 skills validated"
verdict: PASS
OK - 11 skills validated, v4 contracts clean

CHECKRUN SUMMARY: run_items=18 pass=18 fail=0
integrity: check_file_matches_freeze=true head=e8a4abfa7dd6c387d3a74d03205704a15502a39f
changed_files: 0 listed below; docs_checks_touched=false
