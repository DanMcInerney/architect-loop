# Checkrun: s1-ground-checkrun
generated: 2026-07-06T13:49:56Z  runner: sh  config: .architect/checkrun-gs-s1.json
check_file: docs/checks/ground-scripts/s1-ground.md  freeze_sha: 44d3ce9f507e8537db316eb4c9a2ed339f65c6d7
executor_config: bash

## (root) line 11
$ test -f skills/architect/ground.ps1 -a -f skills/architect/ground.sh
exit: 0  ms: 53  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 12
$ bash skills/architect/ground.sh ground-scripts
exit: 3  ms: 2765  bytes: 302
expected: exit:0 match:"GROUND: OK"
verdict: FAIL
ISSUE: 129 open blockedBy=none
ISSUE: 130 open blockedBy=none
ISSUE: 131 closed blockedBy=none
ISSUE: 132 open blockedBy=131,130
BRANCH: factory/ground-scripts 074ccd78d55c815634872601d9ffdcc3f3c94797 synced
UNGRADED: s1-ground-01
GROUND: DRIFT ungraded job report(s) present without checkrun evidence

## (root) line 13
$ bash -c 'bash skills/architect/ground.sh ground-scripts | grep -c "FRONTIER:"'
exit: 1  ms: 2705  bytes: 2
expected: exit:0 match:"1"
verdict: FAIL
0

## (root) line 14
$ bash -c 'CLAUDE_CODE_SUBAGENT_MODEL=haiku bash skills/architect/ground.sh ground-scripts; test $? -eq 2 && echo STOP_GATE_OK'
exit: 0  ms: 300  bytes: 45
expected: exit:0 match:"STOP_GATE_OK"
verdict: PASS
GROUND: STOP subagent-model-env
STOP_GATE_OK

## (root) line 15
$ bash -c 'bash skills/architect/ground.sh no-such-run 2>&1; test $? -eq 5 && echo ERROR_RAIL_OK'
exit: 0  ms: 108  bytes: 158
expected: exit:0 match:"ERROR_RAIL_OK"
verdict: PASS
GROUND: ERROR missing manifest: /c/Users/danhm/tools/architect-loop/.claude/worktrees/agent-a5d0e1ae294983e7d/docs/runs/no-such-run/manifest.md
ERROR_RAIL_OK

## (root) line 16
$ bash -c 'powershell -NoProfile -ExecutionPolicy Bypass -File skills/architect/ground.ps1 ground-scripts | grep -q "GROUND: OK" && echo PS_OK'
exit: 1  ms: 2228  bytes: 0
expected: exit:0 match:"PS_OK"
verdict: FAIL

## (root) line 17
$ bash -c 'out=$(bash skills/architect/ground.sh ground-scripts); git status --porcelain | grep -v "^??" | wc -l | grep -qx 0 && echo READONLY_OK'
exit: 0  ms: 2845  bytes: 12
expected: exit:0 match:"READONLY_OK"
verdict: PASS
READONLY_OK

CHECKRUN SUMMARY: run_items=7 pass=4 fail=3
integrity: check_file_matches_freeze=true head=44d3ce9f507e8537db316eb4c9a2ed339f65c6d7
changed_files: 0 listed below; docs_checks_touched=false
