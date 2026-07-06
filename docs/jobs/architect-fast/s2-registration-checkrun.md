# Checkrun: s2-registration-checkrun
generated: 2026-07-06T16:43:13Z  runner: sh  config: C:/Users/danhm/tools/architect-loop/.architect/runs/architect-fast/.architect/tmp/runner-s2.json
check_file: docs/checks/architect-fast/s2-registration.md  freeze_sha: e8a4abfa7dd6c387d3a74d03205704a15502a39f
executor_config: bash

## Graded items line 26
$ grep -F -c '"architect-fast": [],' tests/validate_skills.py
exit: 0  ms: 60  bytes: 2
expected: exit:0 match:"1"
verdict: PASS
1

## Graded items line 27
$ grep -F -c '"architect-fast": (("SKILL.md",), 160),' tests/validate_skills.py
exit: 0  ms: 54  bytes: 2
expected: exit:0 match:"1"
verdict: PASS
1

## Graded items line 28
$ grep -F -c 'ARCHITECT_SKILL_TEXT_MAX_NON_BLANK = 989' tests/validate_skills.py
exit: 0  ms: 58  bytes: 2
expected: exit:0 match:"1"
verdict: PASS
1

## Graded items line 29
$ grep -F -c 'SKILL: architect-fast' docs/evals/trigger-prompts.md
exit: 0  ms: 55  bytes: 2
expected: exit:0 match:"6"
verdict: PASS
6

## Graded items line 30
$ grep -F -c 'architect a new multi-service ingestion pipeline end to end' docs/evals/trigger-prompts.md
exit: 0  ms: 55  bytes: 2
expected: exit:0 match:"1"
verdict: PASS
1

## Graded items line 31
$ grep -F -c 'read docs/spec/architect-fast.md and summarize it' docs/evals/trigger-prompts.md
exit: 0  ms: 52  bytes: 2
expected: exit:0 match:"1"
verdict: PASS
1

## Graded items line 32
$ sed -n '1,8p' docs/evals/trigger-prompts.md | grep -F -c 'architect-fast'
exit: 0  ms: 67  bytes: 2
expected: exit:0
verdict: PASS
1

## Graded items line 33
$ grep -F -c 'architect-fast' skills/architect/trigger-eval.sh
exit: 0  ms: 55  bytes: 2
expected: exit:0
verdict: PASS
1

## Graded items line 34
$ grep -F -c 'architect-fast' skills/architect/trigger-eval.ps1
exit: 0  ms: 54  bytes: 2
expected: exit:0
verdict: PASS
1

## Graded items line 35
$ uv run python tests/validate_skills.py
exit: 0  ms: 9998  bytes: 46
expected: exit:0 match:"OK - 11 skills validated"
verdict: PASS
OK - 11 skills validated, v4 contracts clean

CHECKRUN SUMMARY: run_items=10 pass=10 fail=0
integrity: check_file_matches_freeze=true head=c40efd54644d1489b1dd72d13c9215ba94a9a7a1
changed_files: 10 listed below; docs_checks_touched=false
CONTEXT.md
DESIGN.md
README.md
assets/architect-fast-flow.svg
docs/jobs/architect-fast/s1-skill-01.md
docs/jobs/architect-fast/s1-skill-checkrun.md
docs/jobs/architect-fast/s3-docs-01.md
docs/jobs/architect-fast/s3-docs-checkrun.md
skills/architect-fast/SKILL.md
skills/codebase-design/SKILL.md
