# Checkrun: s4-ship-checkrun
generated: 2026-07-06T14:08:36Z  runner: sh  config: .architect/checkrun-gs-s4.json
check_file: docs/checks/ground-scripts/s4-ship.md  freeze_sha: 2c9efb8
executor_config: bash

## (root) line 11
$ test -f skills/ship/SKILL.md
exit: 0  ms: 57  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 12
$ grep -F -q "name: ship" skills/ship/SKILL.md
exit: 0  ms: 57  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 13
$ bash -c 'for t in "final review" "conflict" "Closes #" "digest" "postflight"; do grep -qi "$t" skills/ship/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo RULES_OK'
exit: 0  ms: 128  bytes: 9
expected: exit:0 match:"RULES_OK"
verdict: PASS
RULES_OK

## (root) line 14
$ bash -c 'grep -qi "ship time" skills/ship/SKILL.md && echo SHIPTIME_OK'
exit: 0  ms: 77  bytes: 12
expected: exit:0 match:"SHIPTIME_OK"
verdict: PASS
SHIPTIME_OK

## (root) line 15
$ bash -c 'n=$(wc -l < skills/ship/SKILL.md); test "$n" -le 90 && echo "LINES_OK $n"'
exit: 0  ms: 88  bytes: 12
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 89

## (root) line 16
$ bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/ship/SKILL.md && echo NO_ECHO'
exit: 0  ms: 74  bytes: 8
expected: exit:0 match:"NO_ECHO"
verdict: PASS
NO_ECHO

CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
integrity: check_file_matches_freeze=true head=2c9efb875c694a5197bd10f28b64fcb7ee3a7e29
changed_files: 0 listed below; docs_checks_touched=false
