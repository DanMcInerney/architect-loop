# Checkrun: s7-cohesion-review-checkrun
generated: 2026-07-06T01:53:12Z  runner: sh  config: .architect/checkrun-sl-s7.json
check_file: docs/checks/skill-library/s7-cohesion-review.md  freeze_sha: 3f56e7c4428d963365b3f04dd5561f5dbe33cf01
executor_config: bash

## (root) line 10
$ test -f skills/cohesion-review/SKILL.md
exit: 0  ms: 187  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 11
$ grep -F -q "name: cohesion-review" skills/cohesion-review/SKILL.md
exit: 0  ms: 217  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 12
$ bash -c 'grep -qF "## Cohesion" skills/cohesion-review/SKILL.md && grep -qF "## Spec" skills/cohesion-review/SKILL.md && echo AXES_OK'
exit: 0  ms: 314  bytes: 8
expected: exit:0 match:"AXES_OK"
verdict: PASS
AXES_OK

## (root) line 13
$ bash -c 'for t in "duplicated" "interface drift" "glossary" "shared-surface" "green-or-discard"; do grep -qi "$t" skills/cohesion-review/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo CHECKLIST_OK'
exit: 0  ms: 621  bytes: 13
expected: exit:0 match:"CHECKLIST_OK"
verdict: PASS
CHECKLIST_OK

## (root) line 14
$ grep -F -q "stated requirements, or documented project invariants" skills/cohesion-review/SKILL.md
exit: 0  ms: 312  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 15
$ bash -c 'n=$(wc -l < skills/cohesion-review/SKILL.md); test "$n" -le 110 && echo "LINES_OK $n"'
exit: 0  ms: 335  bytes: 12
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 73

## (root) line 16
$ bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/cohesion-review/SKILL.md && echo NO_ECHO'
exit: 0  ms: 296  bytes: 8
expected: exit:0 match:"NO_ECHO"
verdict: PASS
NO_ECHO

CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
integrity: check_file_matches_freeze=true head=3f56e7c4428d963365b3f04dd5561f5dbe33cf01
changed_files: 0 listed below; docs_checks_touched=false
