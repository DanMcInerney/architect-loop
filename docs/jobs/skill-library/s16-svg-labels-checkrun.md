# Checkrun: s16-svg-labels-checkrun
generated: 2026-07-06T11:43:23Z  runner: sh  config: .architect/checkrun-sl-s16.json
check_file: docs/checks/skill-library/s16-svg-labels.md  freeze_sha: 13beee2d59c58b023263ee8e6a34ac5d525f9b1f
executor_config: bash

## (root) line 12
$ bash -c '! grep -qi "judge" assets/architect-flow.svg && echo NO_JUDGE'
exit: 0  ms: 84  bytes: 9
expected: exit:0 match:"NO_JUDGE"
verdict: PASS
NO_JUDGE

## (root) line 13
$ bash -c 'grep -qi "review" assets/architect-flow.svg && echo REVIEW_PRESENT'
exit: 0  ms: 80  bytes: 15
expected: exit:0 match:"REVIEW_PRESENT"
verdict: PASS
REVIEW_PRESENT

## (root) line 14
$ bash -c 'git diff --name-only HEAD | grep -vE "^(assets/architect-flow.svg|docs/jobs/skill-library/)" | wc -l | grep -qx "0" && echo SCOPE_OK'
exit: 0  ms: 97  bytes: 9
expected: exit:0 match:"SCOPE_OK"
verdict: PASS
SCOPE_OK

## (root) line 15
$ bash -c 'git diff HEAD -- assets/architect-flow.svg | grep "^[+-]" | grep -v "^[+-][+-]" | grep -viE "text|tspan" | wc -l | grep -qx "0" && echo TEXT_ONLY'
exit: 1  ms: 119  bytes: 0
expected: exit:0 match:"TEXT_ONLY"
verdict: FAIL

CHECKRUN SUMMARY: run_items=4 pass=3 fail=1
integrity: check_file_matches_freeze=true head=967746fc35308ef5f743618ae7006d7dea5205c2
changed_files: 1 listed below; docs_checks_touched=false
docs/jobs/skill-library/s16-svg-labels-rulings.md
