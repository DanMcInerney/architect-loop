# Checkrun: s8-orchestrator-checkrun
generated: 2026-07-06T02:30:15Z  runner: sh  config: .architect/checkrun-sl-s8.json
check_file: docs/checks/skill-library/s8-orchestrator.md  freeze_sha: 3f56e7c4428d963365b3f04dd5561f5dbe33cf01
executor_config: bash

## (root) line 11
$ bash -c 'for s in codebase-design to-spec to-issues frozen-checks tdd adversarial-review cohesion-review; do grep -qF "$s" skills/architect/SKILL.md || { echo "MISSING: $s"; exit 3; }; done; echo STAGES_OK'
exit: 0  ms: 741  bytes: 10
expected: exit:0 match:"STAGES_OK"
verdict: PASS
STAGES_OK

## (root) line 12
$ bash -c 'n=$(wc -l < skills/architect/SKILL.md); test "$n" -le 220 && echo "LINES_OK $n"'
exit: 0  ms: 334  bytes: 13
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 220

## (root) line 13
$ bash -c 'grep -qF "third strike" skills/architect/loop.md && echo LADDER_OK'
exit: 0  ms: 283  bytes: 10
expected: exit:0 match:"LADDER_OK"
verdict: PASS
LADDER_OK

## (root) line 14
$ bash -c 'grep -qF "architect-judge-template:start" skills/architect/dispatch.md && grep -qF "architect-codex-judge-template:start" skills/architect/dispatch.md && echo TEMPLATES_OK'
exit: 0  ms: 428  bytes: 13
expected: exit:0 match:"TEMPLATES_OK"
verdict: PASS
TEMPLATES_OK

## (root) line 15
$ bash -c '! grep -qF "Stress-test delegation template" skills/architect/dispatch.md && echo STRESS_MOVED'
exit: 0  ms: 274  bytes: 13
expected: exit:0 match:"STRESS_MOVED"
verdict: PASS
STRESS_MOVED

## (root) line 16
$ bash -c '! grep -qF "architect-stress-test-template" tests/validate_skills.py && echo STRESSREF_GONE'
exit: 0  ms: 289  bytes: 15
expected: exit:0 match:"STRESSREF_GONE"
verdict: PASS
STRESSREF_GONE

## (root) line 17
$ bash -c 'for t in "docs/STOP" "timed-ruling" "APPROVE" "freeze" "check-runner"; do grep -qri "$t" skills/architect/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo INVARIANTS_OK'
exit: 0  ms: 603  bytes: 14
expected: exit:0 match:"INVARIANTS_OK"
verdict: PASS
INVARIANTS_OK

## (root) line 18
$ bash -c 'grep -qi "expires" skills/architect/dispatch.md && echo MAP_EXPIRY_OK'
exit: 0  ms: 290  bytes: 14
expected: exit:0 match:"MAP_EXPIRY_OK"
verdict: PASS
MAP_EXPIRY_OK

## (root) line 19
$ bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'
exit: 0  ms: 15109  bytes: 45
expected: exit:0 match:"OK"
verdict: PASS
OK - 9 skills validated, v4 contracts clean

CHECKRUN SUMMARY: run_items=9 pass=9 fail=0
integrity: check_file_matches_freeze=true head=de7ec47e4b7a66d6133e1f95d8162934bbfe1471
changed_files: 30 listed below; docs_checks_touched=false
.claude/agents/architect-builder.md
.claude/agents/architect-judge.md
docs/jobs/skill-library/s1-codebase-design-01.md
docs/jobs/skill-library/s1-codebase-design-checkrun.md
docs/jobs/skill-library/s2-to-spec-01.md
docs/jobs/skill-library/s2-to-spec-checkrun.md
docs/jobs/skill-library/s2-to-spec-rulings.md
docs/jobs/skill-library/s3-to-issues-01.md
docs/jobs/skill-library/s3-to-issues-checkrun.md
docs/jobs/skill-library/s4-frozen-checks-01.md
docs/jobs/skill-library/s4-frozen-checks-checkrun.md
docs/jobs/skill-library/s5-tdd-agents-01.md
docs/jobs/skill-library/s5-tdd-agents-checkrun.md
docs/jobs/skill-library/s6-adversarial-review-01.md
docs/jobs/skill-library/s6-adversarial-review-checkrun.md
docs/jobs/skill-library/s7-cohesion-review-01.md
docs/jobs/skill-library/s7-cohesion-review-checkrun.md
docs/jobs/skill-library/s7-cohesion-review-rulings.md
docs/jobs/skill-library/s9-validator-evals-rulings.md
skills/adversarial-review/SKILL.md
skills/codebase-design/DEEPENING.md
skills/codebase-design/DESIGN-IT-TWICE.md
skills/codebase-design/SKILL.md
skills/cohesion-review/SKILL.md
skills/frozen-checks/SKILL.md
skills/tdd/SKILL.md
skills/tdd/mocking.md
skills/tdd/tests.md
skills/to-issues/SKILL.md
skills/to-spec/SKILL.md
