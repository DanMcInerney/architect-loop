# Checkrun: s14-cohesion-upgrade-checkrun
generated: 2026-07-06T04:32:38Z  runner: sh  config: .architect/checkrun-sl-s14.json
check_file: docs/checks/skill-library/s14-cohesion-upgrade.md  freeze_sha: 5342125661fbbb177c9dfa42b00eb7a4aaea62c4
executor_config: bash

## (root) line 12
$ bash -c 'grep -qi "reproduce" skills/cohesion-review/SKILL.md && grep -qi "not certain" skills/cohesion-review/SKILL.md && echo VERIFY_GATE_OK'
exit: 0  ms: 112  bytes: 15
expected: exit:0 match:"VERIFY_GATE_OK"
verdict: PASS
VERIFY_GATE_OK

## (root) line 13
$ bash -c 'grep -q "P0" skills/cohesion-review/SKILL.md && grep -q "P2" skills/cohesion-review/SKILL.md && grep -qi "pre-existing" skills/cohesion-review/SKILL.md && echo SEV_OK'
exit: 0  ms: 100  bytes: 7
expected: exit:0 match:"SEV_OK"
verdict: PASS
SEV_OK

## (root) line 14
$ test -f skills/cohesion-review/TEST-STEWARDSHIP.md
exit: 0  ms: 53  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 15
$ bash -c 'for t in "integration" "mutant\|revert" "tautological" "redundant" "seam"; do grep -Eqi "$t" skills/cohesion-review/TEST-STEWARDSHIP.md || { echo "MISSING: $t"; exit 3; }; done; echo STEWARD_OK'
exit: 0  ms: 131  bytes: 11
expected: exit:0 match:"STEWARD_OK"
verdict: PASS
STEWARD_OK

## (root) line 16
$ bash -c 'grep -qF "## Cohesion" skills/cohesion-review/SKILL.md && grep -qF "## Spec" skills/cohesion-review/SKILL.md && grep -qi "green-or-discard" skills/cohesion-review/SKILL.md && grep -qF "stated requirements, or documented project invariants" skills/cohesion-review/SKILL.md && grep -qF "Adapted from mattpocock/skills (MIT)" skills/cohesion-review/SKILL.md && echo ANCHORS_OK'
exit: 0  ms: 130  bytes: 11
expected: exit:0 match:"ANCHORS_OK"
verdict: PASS
ANCHORS_OK

## (root) line 17
$ bash -c 'a=$(wc -l < skills/cohesion-review/SKILL.md); b=$(wc -l < skills/cohesion-review/TEST-STEWARDSHIP.md); test "$a" -le 110 -a "$b" -le 70 && echo "LINES_OK $a $b"'
exit: 0  ms: 106  bytes: 16
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 105 48

## (root) line 18
$ bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/cohesion-review/*.md && echo NO_ECHO'
exit: 0  ms: 84  bytes: 8
expected: exit:0 match:"NO_ECHO"
verdict: PASS
NO_ECHO

## (root) line 19
$ bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'
exit: 0  ms: 6624  bytes: 45
expected: exit:0 match:"OK"
verdict: PASS
OK - 9 skills validated, v4 contracts clean

CHECKRUN SUMMARY: run_items=8 pass=8 fail=0
integrity: check_file_matches_freeze=true head=5342125661fbbb177c9dfa42b00eb7a4aaea62c4
changed_files: 0 listed below; docs_checks_touched=false
