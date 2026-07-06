# Checkrun: s1-codebase-design-checkrun
generated: 2026-07-06T01:50:13Z  runner: sh  config: .architect/checkrun-sl-s1.json
check_file: docs/checks/skill-library/s1-codebase-design.md  freeze_sha: 3f56e7c4428d963365b3f04dd5561f5dbe33cf01
executor_config: bash

## (root) line 11
$ test -f skills/codebase-design/SKILL.md -a -f skills/codebase-design/DEEPENING.md -a -f skills/codebase-design/DESIGN-IT-TWICE.md
exit: 0  ms: 230  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 12
$ grep -F -q "name: codebase-design" skills/codebase-design/SKILL.md
exit: 0  ms: 212  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 13
$ grep -F -q "Adapted from mattpocock/skills (MIT)" skills/codebase-design/SKILL.md
exit: 0  ms: 230  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 14
$ grep -F -q "## Glossary" skills/codebase-design/SKILL.md
exit: 0  ms: 231  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 15
$ bash -c 'for t in module interface seam adapter depth leverage locality "frozen check" check-runner "intent judge" orchestrator builder worktree; do grep -qi "$t" skills/codebase-design/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo ALL_TERMS'
exit: 0  ms: 1232  bytes: 10
expected: exit:0 match:"ALL_TERMS"
verdict: PASS
ALL_TERMS

## (root) line 16
$ bash -c 'for f in skills/codebase-design/SKILL.md skills/codebase-design/DEEPENING.md skills/codebase-design/DESIGN-IT-TWICE.md; do test -f "$f" || { echo "MISSING: $f"; exit 3; }; done; n=$(cat skills/codebase-design/SKILL.md skills/codebase-design/DEEPENING.md skills/codebase-design/DESIGN-IT-TWICE.md | wc -l); test "$n" -le 240 && echo "LINES_OK $n"'
exit: 0  ms: 393  bytes: 13
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 162

## (root) line 17
$ bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/codebase-design/*.md && echo NO_ECHO'
exit: 0  ms: 289  bytes: 8
expected: exit:0 match:"NO_ECHO"
verdict: PASS
NO_ECHO

CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
integrity: check_file_matches_freeze=true head=3f56e7c4428d963365b3f04dd5561f5dbe33cf01
changed_files: 0 listed below; docs_checks_touched=false
