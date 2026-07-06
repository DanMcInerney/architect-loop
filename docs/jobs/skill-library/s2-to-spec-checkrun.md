# Checkrun: s2-to-spec-checkrun
generated: 2026-07-06T02:00:32Z  runner: sh  config: .architect/checkrun-sl-s2.json
check_file: docs/checks/skill-library/s2-to-spec.md  freeze_sha: 3f56e7c4428d963365b3f04dd5561f5dbe33cf01
executor_config: bash

## (root) line 11
$ test -f skills/to-spec/SKILL.md
exit: 0  ms: 176  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 12
$ grep -F -q "name: to-spec" skills/to-spec/SKILL.md
exit: 0  ms: 198  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 13
$ bash -c 'for s in "## Goal" "## Non-goals" "## Assumptions" "## Validation strategy" "## Domain language" "## Approval record"; do grep -qF "$s" skills/to-spec/SKILL.md || { echo "MISSING: $s"; exit 3; }; done; echo ALL_SECTIONS'
exit: 0  ms: 592  bytes: 13
expected: exit:0 match:"ALL_SECTIONS"
verdict: PASS
ALL_SECTIONS

## (root) line 14
$ bash -c 'n=$(wc -l < skills/to-spec/SKILL.md); test "$n" -le 100 && echo "LINES_OK $n"'
exit: 0  ms: 368  bytes: 12
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 70

## (root) line 15
$ bash -c 'grep -qi "do not interview" skills/to-spec/SKILL.md || grep -qi "synthesize" skills/to-spec/SKILL.md; echo RULE_$?'
exit: 0  ms: 261  bytes: 7
expected: exit:0 match:"RULE_0"
verdict: PASS
RULE_0

## (root) line 16
$ bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/to-spec/SKILL.md && echo NO_ECHO'
exit: 0  ms: 237  bytes: 8
expected: exit:0 match:"NO_ECHO"
verdict: PASS
NO_ECHO

CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
integrity: check_file_matches_freeze=true head=3f56e7c4428d963365b3f04dd5561f5dbe33cf01
changed_files: 0 listed below; docs_checks_touched=false
