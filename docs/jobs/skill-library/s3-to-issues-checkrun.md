# Checkrun: s3-to-issues-checkrun
generated: 2026-07-06T01:48:01Z  runner: sh  config: .architect/checkrun-sl-s3.json
check_file: docs/checks/skill-library/s3-to-issues.md  freeze_sha: 3f56e7c4428d963365b3f04dd5561f5dbe33cf01
executor_config: bash

## (root) line 11
$ test -f skills/to-issues/SKILL.md
exit: 0  ms: 462  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 12
$ grep -F -q "name: to-issues" skills/to-issues/SKILL.md
exit: 0  ms: 614  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 13
$ bash -c 'for t in "vertical slice" "tracer" "change-skeleton" "interface contract" "MAY TOUCH" "MUST NOT TOUCH" "blocked-by" "architect-run:"; do grep -qi "$t" skills/to-issues/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo ALL_RULES'
exit: 0  ms: 1780  bytes: 10
expected: exit:0 match:"ALL_RULES"
verdict: PASS
ALL_RULES

## (root) line 14
$ bash -c 'n=$(wc -l < skills/to-issues/SKILL.md); test "$n" -le 110 && echo "LINES_OK $n"'
exit: 0  ms: 1110  bytes: 12
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 89

## (root) line 15
$ bash -c 'grep -qi "structural" skills/to-issues/SKILL.md && grep -qi "frontier" skills/to-issues/SKILL.md && echo STRUCT_OK'
exit: 0  ms: 1242  bytes: 10
expected: exit:0 match:"STRUCT_OK"
verdict: PASS
STRUCT_OK

## (root) line 16
$ bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/to-issues/SKILL.md && echo NO_ECHO'
exit: 0  ms: 1014  bytes: 8
expected: exit:0 match:"NO_ECHO"
verdict: PASS
NO_ECHO

CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
integrity: check_file_matches_freeze=true head=3f56e7c4428d963365b3f04dd5561f5dbe33cf01
changed_files: 0 listed below; docs_checks_touched=false
