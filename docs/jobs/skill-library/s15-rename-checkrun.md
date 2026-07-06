# Checkrun: s15-rename-checkrun
generated: 2026-07-06T05:00:57Z  runner: sh  config: .architect/checkrun-sl-s15.json
check_file: docs/checks/skill-library/s15-rename.md  freeze_sha: 3a227abaa0de6b6710be6fc800e9f0647c9cb1a4
executor_config: bash

## (root) line 14
$ test -f skills/code-review/SKILL.md -a -f skills/code-review/TEST-STEWARDSHIP.md
exit: 0  ms: 51  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 15
$ bash -c 'grep -qF "name: code-review" skills/code-review/SKILL.md && grep -qF "Adapted from mattpocock/skills (MIT)" skills/code-review/SKILL.md && echo NAME_OK'
exit: 0  ms: 86  bytes: 8
expected: exit:0 match:"NAME_OK"
verdict: PASS
NAME_OK

## (root) line 16
$ bash -c 'grep -qF "## Cohesion" skills/code-review/SKILL.md && grep -qF "## Spec" skills/code-review/SKILL.md && grep -qi "green-or-discard" skills/code-review/SKILL.md && grep -qF "stated requirements, or documented project invariants" skills/code-review/SKILL.md && echo ANCHORS_OK'
exit: 0  ms: 113  bytes: 11
expected: exit:0 match:"ANCHORS_OK"
verdict: PASS
ANCHORS_OK

## (root) line 17
$ bash -c 'grep -qi "reproduce" skills/code-review/SKILL.md && grep -qi "not certain" skills/code-review/SKILL.md && grep -q "P0" skills/code-review/SKILL.md && echo GATES_OK'
exit: 0  ms: 108  bytes: 9
expected: exit:0 match:"GATES_OK"
verdict: PASS
GATES_OK

## (root) line 18
$ bash -c 'for t in "integration" "tautological" "redundant" "seam"; do grep -qi "$t" skills/code-review/TEST-STEWARDSHIP.md || { echo "MISSING: $t"; exit 3; }; done; echo STEWARD_OK'
exit: 0  ms: 114  bytes: 11
expected: exit:0 match:"STEWARD_OK"
verdict: PASS
STEWARD_OK

## (root) line 19
$ bash -c 'a=$(wc -l < skills/code-review/SKILL.md); b=$(wc -l < skills/code-review/TEST-STEWARDSHIP.md); test "$a" -le 110 -a "$b" -le 70 && echo "LINES_OK $a $b"'
exit: 0  ms: 105  bytes: 16
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 107 48

## (root) line 20
$ bash -c 'test ! -d skills/cohesion-review && grep -qF "code-review" skills/architect/SKILL.md && ! grep -qi "cohesion-review" skills/architect/SKILL.md skills/architect/loop.md skills/architect/dispatch.md && echo ARCH_RENAMED'
exit: 0  ms: 85  bytes: 13
expected: exit:0 match:"ARCH_RENAMED"
verdict: PASS
ARCH_RENAMED

## (root) line 21
$ bash -c 'grep -qF "code-review" tests/validate_skills.py && ! grep -qi "cohesion-review" tests/validate_skills.py && echo VALIDATOR_OK'
exit: 0  ms: 86  bytes: 13
expected: exit:0 match:"VALIDATOR_OK"
verdict: PASS
VALIDATOR_OK

## (root) line 22
$ bash -c 'grep -qF "code-review" docs/evals/trigger-prompts.md && ! grep -qi "cohesion-review" docs/evals/trigger-prompts.md README.md && echo FIXTURE_README_OK'
exit: 0  ms: 90  bytes: 18
expected: exit:0 match:"FIXTURE_README_OK"
verdict: PASS
FIXTURE_README_OK

## (root) line 23
$ bash -c 'grep -qF "code-review" skills/architect/trigger-eval.sh && grep -qF "code-review" skills/architect/trigger-eval.ps1 && ! grep -qi "cohesion-review" skills/architect/trigger-eval.sh skills/architect/trigger-eval.ps1 && echo SCRIPTS_OK'
exit: 0  ms: 100  bytes: 11
expected: exit:0 match:"SCRIPTS_OK"
verdict: PASS
SCRIPTS_OK

## (root) line 24
$ bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'
exit: 0  ms: 6865  bytes: 45
expected: exit:0 match:"OK"
verdict: PASS
OK - 9 skills validated, v4 contracts clean

CHECKRUN SUMMARY: run_items=11 pass=11 fail=0
integrity: check_file_matches_freeze=true head=3a227abaa0de6b6710be6fc800e9f0647c9cb1a4
changed_files: 0 listed below; docs_checks_touched=false
