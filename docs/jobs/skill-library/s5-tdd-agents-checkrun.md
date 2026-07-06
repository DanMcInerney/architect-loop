# Checkrun: s5-tdd-agents-checkrun
generated: 2026-07-06T01:48:02Z  runner: sh  config: .architect/checkrun-sl-s5.json
check_file: docs/checks/skill-library/s5-tdd-agents.md  freeze_sha: 3f56e7c4428d963365b3f04dd5561f5dbe33cf01
executor_config: bash

## (root) line 11
$ test -f skills/tdd/SKILL.md -a -f skills/tdd/tests.md -a -f skills/tdd/mocking.md
exit: 0  ms: 606  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 12
$ grep -F -q "name: tdd" skills/tdd/SKILL.md
exit: 0  ms: 528  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 13
$ grep -F -q "Adapted from mattpocock/skills (MIT)" skills/tdd/SKILL.md
exit: 0  ms: 556  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 14
$ bash -c 'for t in "red" "green" "seam" "tracer" "vertical"; do grep -qi "$t" skills/tdd/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo ALL_TERMS'
exit: 0  ms: 1800  bytes: 10
expected: exit:0 match:"ALL_TERMS"
verdict: PASS
ALL_TERMS

## (root) line 15
$ bash -c 'for f in skills/tdd/SKILL.md skills/tdd/tests.md skills/tdd/mocking.md; do test -f "$f" || { echo "MISSING: $f"; exit 3; }; done; n=$(cat skills/tdd/SKILL.md skills/tdd/tests.md skills/tdd/mocking.md | wc -l); test "$n" -le 220 && echo "LINES_OK $n"'
exit: 0  ms: 1236  bytes: 13
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 206

## (root) line 16
$ bash -c 'grep -q "skills:" .claude/agents/architect-builder.md && grep -q "tdd" .claude/agents/architect-builder.md && grep -q "codebase-design" .claude/agents/architect-builder.md && echo BUILDER_WIRED'
exit: 0  ms: 1425  bytes: 14
expected: exit:0 match:"BUILDER_WIRED"
verdict: PASS
BUILDER_WIRED

## (root) line 17
$ bash -c 'grep -q "skills:" .claude/agents/architect-judge.md && grep -q "codebase-design" .claude/agents/architect-judge.md && echo JUDGE_WIRED'
exit: 0  ms: 1304  bytes: 12
expected: exit:0 match:"JUDGE_WIRED"
verdict: PASS
JUDGE_WIRED

## (root) line 18
$ bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/tdd/*.md && echo NO_ECHO'
exit: 0  ms: 462  bytes: 8
expected: exit:0 match:"NO_ECHO"
verdict: PASS
NO_ECHO

CHECKRUN SUMMARY: run_items=8 pass=8 fail=0
integrity: check_file_matches_freeze=true head=3f56e7c4428d963365b3f04dd5561f5dbe33cf01
changed_files: 0 listed below; docs_checks_touched=false
