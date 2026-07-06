# Checkrun: s9-validator-evals-checkrun
generated: 2026-07-06T03:02:32Z  runner: sh  config: .architect/checkrun-sl-s9.json
check_file: docs/checks/skill-library/s9-validator-evals.md  freeze_sha: 3f56e7c4428d963365b3f04dd5561f5dbe33cf01
executor_config: bash

## (root) line 11
$ bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'
exit: 0  ms: 9862  bytes: 45
expected: exit:0 match:"OK"
verdict: PASS
OK - 9 skills validated, v4 contracts clean

## (root) line 12
$ bash -c 'for s in codebase-design to-spec to-issues frozen-checks tdd adversarial-review cohesion-review; do grep -qF "$s" tests/validate_skills.py || { echo "MISSING: $s"; exit 3; }; done; echo INVENTORY_OK'
exit: 0  ms: 593  bytes: 13
expected: exit:0 match:"INVENTORY_OK"
verdict: PASS
INVENTORY_OK

## (root) line 13
$ bash -c 'grep -qF "1536" tests/validate_skills.py && echo DESCCAP_OK'
exit: 0  ms: 238  bytes: 11
expected: exit:0 match:"DESCCAP_OK"
verdict: PASS
DESCCAP_OK

## (root) line 14
$ bash -c 'grep -qF "Adapted from mattpocock/skills (MIT)" tests/validate_skills.py && echo ATTRIB_OK'
exit: 0  ms: 242  bytes: 10
expected: exit:0 match:"ATTRIB_OK"
verdict: PASS
ATTRIB_OK

## (root) line 15
$ bash -c 'for s in to-spec to-issues frozen-checks cohesion-review; do grep -qF "$s" docs/evals/trigger-prompts.md || { echo "MISSING: $s"; exit 3; }; done; echo EVALS_OK'
exit: 0  ms: 456  bytes: 9
expected: exit:0 match:"EVALS_OK"
verdict: PASS
EVALS_OK

## (root) line 16
$ bash -c 'grep -qi "glossary\|banned" tests/validate_skills.py && echo LINT_OK'
exit: 0  ms: 232  bytes: 8
expected: exit:0 match:"LINT_OK"
verdict: PASS
LINT_OK

CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
integrity: check_file_matches_freeze=true head=6ea824e163fd4ee897362d0930ac6e393d6550fb
changed_files: 38 listed below; docs_checks_touched=false
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
docs/jobs/skill-library/s8-orchestrator-01.md
docs/jobs/skill-library/s8-orchestrator-checkrun.md
docs/jobs/skill-library/s8-orchestrator-rulings.md
docs/jobs/skill-library/s9-validator-evals-rulings.md
skills/adversarial-review/SKILL.md
skills/architect/SKILL.md
skills/architect/dispatch.md
skills/architect/loop.md
skills/architect/research.md
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
tests/validate_skills.py
