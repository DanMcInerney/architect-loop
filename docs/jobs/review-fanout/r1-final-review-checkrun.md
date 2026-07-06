# Checkrun: r1-final-review-checkrun
generated: 2026-07-06T15:47:26.5700548Z  runner: ps1  config: C:\Users\danhm\tools\architect-loop\.architect\checkrun-rf-r1.json
check_file: docs/checks/review-fanout/r1-final-review.md  freeze_sha: b700b6ae24b97c539659b8aeecbe7c0ea8610df2
executor_config: bash
executor_resolved: C:\Program Files\Git\bin\bash.exe

## (root) line 12
$ bash -c 'grep -q "REVIEW: GREEN" skills/final-review/SKILL.md && grep -q "REVIEW: FINDINGS n=" skills/final-review/SKILL.md && echo VERDICT_CONTRACT'
exit: 0  ms: 74  bytes: 17
expected: exit:0 match:"VERDICT_CONTRACT"
verdict: PASS
VERDICT_CONTRACT

## (root) line 13
$ bash -c 'grep -qi "review spec" skills/final-review/SKILL.md && grep -qi "draft" skills/final-review/SKILL.md && echo DECOMPOSE_PRESENT'
exit: 0  ms: 73  bytes: 18
expected: exit:0 match:"DECOMPOSE_PRESENT"
verdict: PASS
DECOMPOSE_PRESENT

## (root) line 14
$ bash -c '! grep -q "directly in the review worktree" skills/final-review/SKILL.md && ! grep -q "## Edit discipline" skills/final-review/SKILL.md && echo DIRECT_EDIT_GONE'
exit: 0  ms: 70  bytes: 17
expected: exit:0 match:"DIRECT_EDIT_GONE"
verdict: PASS
DIRECT_EDIT_GONE

## (root) line 15
$ bash -c '! grep -qi "green-or-discard" skills/final-review/SKILL.md && echo DISCARD_RULE_GONE'
exit: 0  ms: 61  bytes: 18
expected: exit:0 match:"DISCARD_RULE_GONE"
verdict: PASS
DISCARD_RULE_GONE

## (root) line 16
$ bash -c '! grep -qi "intent judge" skills/final-review/SKILL.md && ! grep -qi "intent judge" skills/final-review/TEST-STEWARDSHIP.md && echo JUDGE_VOCAB_GONE'
exit: 0  ms: 68  bytes: 17
expected: exit:0 match:"JUDGE_VOCAB_GONE"
verdict: PASS
JUDGE_VOCAB_GONE

## (root) line 17
$ bash -c 'grep -qiE "fix[- ]issue" skills/final-review/TEST-STEWARDSHIP.md && echo STEWARDSHIP_DIAGNOSIS'
exit: 0  ms: 58  bytes: 22
expected: exit:0 match:"STEWARDSHIP_DIAGNOSIS"
verdict: PASS
STEWARDSHIP_DIAGNOSIS

## (root) line 18
$ uv run python tests/validate_skills.py
exit: 0  ms: 9217  bytes: 46
expected: exit:0 match:"OK - "
verdict: PASS
OK - 10 skills validated, v4 contracts clean

CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
integrity: check_file_matches_freeze=true head=b700b6ae24b97c539659b8aeecbe7c0ea8610df2
changed_files: 0 listed below; docs_checks_touched=false
