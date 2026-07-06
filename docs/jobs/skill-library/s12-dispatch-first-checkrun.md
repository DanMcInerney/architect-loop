# Checkrun: s12-dispatch-first-checkrun
generated: 2026-07-06T04:10:07Z  runner: sh  config: .architect/checkrun-sl-s12.json
check_file: docs/checks/skill-library/s12-dispatch-first.md  freeze_sha: b630e3dc46077ccd1a85f67f54ad85ec72cc2c53
executor_config: bash

## (root) line 12
$ bash -c 'grep -qi "dispatch event" skills/architect/loop.md && grep -qi "before grading" skills/architect/loop.md && echo CADENCE_OK'
exit: 0  ms: 99  bytes: 11
expected: exit:0 match:"CADENCE_OK"
verdict: PASS
CADENCE_OK

## (root) line 13
$ bash -c 'grep -qi "beyond the" skills/architect/loop.md && grep -qi "multiple builders" skills/architect/loop.md && echo FRONTIER_OK'
exit: 0  ms: 89  bytes: 12
expected: exit:0 match:"FRONTIER_OK"
verdict: PASS
FRONTIER_OK

## (root) line 14
$ bash -c 'grep -Eqi "job end|every job end" skills/architect/SKILL.md && echo SKILLMD_OK'
exit: 0  ms: 82  bytes: 11
expected: exit:0 match:"SKILLMD_OK"
verdict: PASS
SKILLMD_OK

## (root) line 15
$ bash -c 'grep -qi "release" skills/architect/loop.md && grep -Eqi "idle session|lingering" skills/architect/loop.md && echo CLEANUP_OK'
exit: 0  ms: 87  bytes: 11
expected: exit:0 match:"CLEANUP_OK"
verdict: PASS
CLEANUP_OK

## (root) line 16
$ bash -c 'grep -qi "one poke" skills/architect/loop.md && echo POKE_OK'
exit: 0  ms: 76  bytes: 8
expected: exit:0 match:"POKE_OK"
verdict: PASS
POKE_OK

## (root) line 17
$ bash -c 'awk "/architect-judge-template:start/,/architect-judge-template:end/" skills/architect/dispatch.md | grep -qi "deliver it via SendMessage" && echo TEMPLATE_OK'
exit: 0  ms: 84  bytes: 12
expected: exit:0 match:"TEMPLATE_OK"
verdict: PASS
TEMPLATE_OK

## (root) line 18
$ bash -c 'n=$(wc -l < skills/architect/SKILL.md); test "$n" -le 220 && echo "LINES_OK $n"'
exit: 0  ms: 87  bytes: 13
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 220

## (root) line 19
$ bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'
exit: 0  ms: 6648  bytes: 45
expected: exit:0 match:"OK"
verdict: PASS
OK - 9 skills validated, v4 contracts clean

CHECKRUN SUMMARY: run_items=8 pass=8 fail=0
integrity: check_file_matches_freeze=true head=b630e3dc46077ccd1a85f67f54ad85ec72cc2c53
changed_files: 0 listed below; docs_checks_touched=false
