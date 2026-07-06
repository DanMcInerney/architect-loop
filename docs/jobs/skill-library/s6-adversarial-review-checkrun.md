# Checkrun: s6-adversarial-review-checkrun
generated: 2026-07-06T01:47:58Z  runner: sh  config: .architect/checkrun-sl-s6.json
check_file: docs/checks/skill-library/s6-adversarial-review.md  freeze_sha: 3f56e7c4428d963365b3f04dd5561f5dbe33cf01
executor_config: bash

## (root) line 11
$ test -f skills/adversarial-review/SKILL.md
exit: 0  ms: 491  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 12
$ grep -F -q "name: adversarial-review" skills/adversarial-review/SKILL.md
exit: 0  ms: 504  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 13
$ bash -c 'grep -qF "FALSIFIED" skills/adversarial-review/SKILL.md && grep -qF "HOLDS" skills/adversarial-review/SKILL.md && echo VERDICTS_OK'
exit: 0  ms: 957  bytes: 12
expected: exit:0 match:"VERDICTS_OK"
verdict: PASS
VERDICTS_OK

## (root) line 14
$ bash -c 'for t in "check-ignore" "non-falsifiable" "grep collision" "RUN:"; do grep -qi "$t" skills/adversarial-review/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo STRESS_OK'
exit: 0  ms: 1199  bytes: 10
expected: exit:0 match:"STRESS_OK"
verdict: PASS
STRESS_OK

## (root) line 15
$ grep -F -q "stated requirements, or documented project invariants" skills/adversarial-review/SKILL.md
exit: 0  ms: 608  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 16
$ bash -c 'n=$(wc -l < skills/adversarial-review/SKILL.md); test "$n" -le 110 && echo "LINES_OK $n"'
exit: 0  ms: 1230  bytes: 12
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 78

## (root) line 17
$ bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/adversarial-review/SKILL.md && echo NO_ECHO'
exit: 0  ms: 891  bytes: 8
expected: exit:0 match:"NO_ECHO"
verdict: PASS
NO_ECHO

CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
integrity: check_file_matches_freeze=true head=3f56e7c4428d963365b3f04dd5561f5dbe33cf01
changed_files: 0 listed below; docs_checks_touched=false
