# Checkrun: s4-frozen-checks-checkrun
generated: 2026-07-06T01:52:43Z  runner: sh  config: .architect/checkrun-sl-s4.json
check_file: docs/checks/skill-library/s4-frozen-checks.md  freeze_sha: 3f56e7c4428d963365b3f04dd5561f5dbe33cf01
executor_config: bash

## (root) line 10
$ test -f skills/frozen-checks/SKILL.md
exit: 0  ms: 216  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 11
$ grep -F -q "name: frozen-checks" skills/frozen-checks/SKILL.md
exit: 0  ms: 248  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 12
$ grep -F -q "check-runner.ps1" skills/frozen-checks/SKILL.md
exit: 0  ms: 228  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 13
$ bash -c 'grep -qF -- "-> exit:" skills/frozen-checks/SKILL.md && grep -qF "match:" skills/frozen-checks/SKILL.md && echo GRAMMAR_OK'
exit: 0  ms: 362  bytes: 11
expected: exit:0 match:"GRAMMAR_OK"
verdict: PASS
GRAMMAR_OK

## (root) line 14
$ bash -c 'for t in "freeze" "read-only" "automatic FAIL" "docs/checks/" "falsifiable"; do grep -qi "$t" skills/frozen-checks/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo ALL_RULES'
exit: 0  ms: 757  bytes: 10
expected: exit:0 match:"ALL_RULES"
verdict: PASS
ALL_RULES

## (root) line 15
$ bash -c 'n=$(wc -l < skills/frozen-checks/SKILL.md); test "$n" -le 100 && echo "LINES_OK $n"'
exit: 0  ms: 372  bytes: 12
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 60

## (root) line 16
$ bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/frozen-checks/SKILL.md && echo NO_ECHO'
exit: 0  ms: 408  bytes: 8
expected: exit:0 match:"NO_ECHO"
verdict: PASS
NO_ECHO

CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
integrity: check_file_matches_freeze=true head=3f56e7c4428d963365b3f04dd5561f5dbe33cf01
changed_files: 0 listed below; docs_checks_touched=false
