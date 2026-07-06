# Checkrun: s3-wiring-checkrun
generated: 2026-07-06T14:10:33Z  runner: sh  config: .architect/checkrun-gs-s3.json
check_file: docs/checks/ground-scripts/s3-wiring.md  freeze_sha: 44d3ce9f507e8537db316eb4c9a2ed339f65c6d7
executor_config: bash

## (root) line 10
$ bash -c 'grep -q "ground.ps1\|ground.sh" skills/architect/SKILL.md && echo SKILL_WIRED'
exit: 0  ms: 76  bytes: 12
expected: exit:0 match:"SKILL_WIRED"
verdict: PASS
SKILL_WIRED

## (root) line 11
$ bash -c 'grep -qi "ffcheck" skills/architect/dispatch.md && echo DISPATCH_WIRED'
exit: 0  ms: 75  bytes: 15
expected: exit:0 match:"DISPATCH_WIRED"
verdict: PASS
DISPATCH_WIRED

## (root) line 12
$ bash -c 'grep -qi "ground" skills/architect/loop.md && echo LOOP_WIRED'
exit: 0  ms: 75  bytes: 11
expected: exit:0 match:"LOOP_WIRED"
verdict: PASS
LOOP_WIRED

## (root) line 13
$ bash -c 'grep -q "check_ground_contract\|ground.ps1" tests/validate_skills.py && grep -qi "ffcheck" tests/validate_skills.py && echo VALIDATOR_WIRED'
exit: 0  ms: 86  bytes: 16
expected: exit:0 match:"VALIDATOR_WIRED"
verdict: PASS
VALIDATOR_WIRED

## (root) line 14
$ bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'
exit: 0  ms: 9937  bytes: 45
expected: exit:0 match:"OK"
verdict: PASS
OK - 9 skills validated, v4 contracts clean

## (root) line 15
$ bash -c 'n=$(wc -l < skills/architect/SKILL.md); test "$n" -le 220 && echo "LINES_OK $n"'
exit: 0  ms: 87  bytes: 13
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 214

CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
integrity: check_file_matches_freeze=true head=fa9f5474b546984dae13eed530cb18a86f40d8e0
changed_files: 9 listed below; docs_checks_touched=false
docs/jobs/ground-scripts/s1-ground-01.md
docs/jobs/ground-scripts/s1-ground-checkrun.md
docs/jobs/ground-scripts/s1-ground-rulings.md
docs/jobs/ground-scripts/s2-ffcheck-01.md
docs/jobs/ground-scripts/s2-ffcheck-checkrun.md
skills/architect/ffcheck.ps1
skills/architect/ffcheck.sh
skills/architect/ground.ps1
skills/architect/ground.sh
