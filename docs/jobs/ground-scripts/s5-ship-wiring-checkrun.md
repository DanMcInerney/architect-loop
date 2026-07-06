# Checkrun: s5-ship-wiring-checkrun
generated: 2026-07-06T14:17:46Z  runner: sh  config: .architect/checkrun-gs-s5.json
check_file: docs/checks/ground-scripts/s5-ship-wiring.md  freeze_sha: f859061
executor_config: bash

## (root) line 10
$ bash -c 'grep -qF "ship" skills/architect/SKILL.md && grep -qi "ship subagent\|ship stage skill" skills/architect/SKILL.md && echo FINISH_WIRED'
exit: 0  ms: 88  bytes: 13
expected: exit:0 match:"FINISH_WIRED"
verdict: PASS
FINISH_WIRED

## (root) line 11
$ bash -c 'grep -qi "isolation\|architect-run" tests/validate_skills.py && grep -qi "ship" tests/validate_skills.py && echo TESTS_WIRED'
exit: 0  ms: 88  bytes: 12
expected: exit:0 match:"TESTS_WIRED"
verdict: PASS
TESTS_WIRED

## (root) line 12
$ bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'
exit: 0  ms: 8157  bytes: 46
expected: exit:0 match:"OK"
verdict: PASS
OK - 10 skills validated, v4 contracts clean

## (root) line 13
$ bash -c 'n=$(wc -l < skills/architect/SKILL.md); test "$n" -le 220 && echo "LINES_OK $n"'
exit: 0  ms: 86  bytes: 13
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 217

CHECKRUN SUMMARY: run_items=4 pass=4 fail=0
integrity: check_file_matches_freeze=true head=f8590610439caaebd97af28ec3d2f0b8d73864e5
changed_files: 0 listed below; docs_checks_touched=false
