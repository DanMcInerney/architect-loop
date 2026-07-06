# Checkrun: s10-trigger-allowlist-checkrun
generated: 2026-07-06T03:11:23Z  runner: sh  config: .architect/checkrun-sl-s10.json
check_file: docs/checks/skill-library/s10-trigger-allowlist.md  freeze_sha: c7f38b9b65567e1ab22f5d8bf489373a9a962e48
executor_config: bash

## (root) line 11
$ bash -c 'for s in codebase-design to-spec to-issues frozen-checks tdd adversarial-review cohesion-review; do grep -qF "$s" skills/architect/trigger-eval.sh || { echo "SH_MISSING: $s"; exit 3; }; done; echo SH_ALLOWLIST_OK'
exit: 0  ms: 614  bytes: 16
expected: exit:0 match:"SH_ALLOWLIST_OK"
verdict: PASS
SH_ALLOWLIST_OK

## (root) line 12
$ bash -c 'for s in codebase-design to-spec to-issues frozen-checks tdd adversarial-review cohesion-review; do grep -qF "$s" skills/architect/trigger-eval.ps1 || { echo "PS_MISSING: $s"; exit 3; }; done; echo PS_ALLOWLIST_OK'
exit: 0  ms: 610  bytes: 16
expected: exit:0 match:"PS_ALLOWLIST_OK"
verdict: PASS
PS_ALLOWLIST_OK

## (root) line 13
$ bash -c 'grep -qF "architect-research" skills/architect/trigger-eval.sh && grep -qF "architect-research" skills/architect/trigger-eval.ps1 && echo EXISTING_KEPT'
exit: 0  ms: 302  bytes: 14
expected: exit:0 match:"EXISTING_KEPT"
verdict: PASS
EXISTING_KEPT

## (root) line 14
$ bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'
exit: 0  ms: 9732  bytes: 45
expected: exit:0 match:"OK"
verdict: PASS
OK - 9 skills validated, v4 contracts clean

CHECKRUN SUMMARY: run_items=4 pass=4 fail=0
integrity: check_file_matches_freeze=true head=29808074675a04704e1160ce2d9cc75097242259
changed_files: 3 listed below; docs_checks_touched=false
docs/evals/trigger-prompts.md
docs/jobs/skill-library/s9-validator-evals-01.md
tests/validate_skills.py
