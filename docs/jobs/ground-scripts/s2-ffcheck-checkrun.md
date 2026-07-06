# Checkrun: s2-ffcheck-checkrun
generated: 2026-07-06T13:39:54Z  runner: sh  config: .architect/checkrun-gs-s2.json
check_file: docs/checks/ground-scripts/s2-ffcheck.md  freeze_sha: 44d3ce9
executor_config: bash

## (root) line 11
$ test -f skills/architect/ffcheck.ps1 -a -f skills/architect/ffcheck.sh
exit: 0  ms: 48  bytes: 0
expected: exit:0
verdict: PASS

## (root) line 12
$ bash -c 'bash skills/architect/ffcheck.sh $(git rev-parse HEAD) | grep -q "FFCHECK: OK" && echo AT_HEAD_OK'
exit: 0  ms: 207  bytes: 11
expected: exit:0 match:"AT_HEAD_OK"
verdict: PASS
AT_HEAD_OK

## (root) line 13
$ bash -c 'r=.architect/tmp/ffx; rm -rf $r; git init -q $r; cd $r; git commit -qm a --allow-empty; git commit -qm b --allow-empty; s=$(git rev-parse HEAD); git checkout -qb w HEAD~1; bash "$OLDPWD/skills/architect/ffcheck.sh" $s | grep -q "FFCHECK: OK" && test "$(git rev-parse HEAD)" = "$s" && echo FF_APPLIED_OK'
exit: 0  ms: 454  bytes: 14
expected: exit:0 match:"FF_APPLIED_OK"
verdict: PASS
FF_APPLIED_OK

## (root) line 14
$ bash -c 'r=.architect/tmp/ffd; rm -rf $r; git init -q $r; cd $r; git commit -qm a --allow-empty; git checkout -qb w; git commit -qm div --allow-empty; git checkout -q master 2>/dev/null || git checkout -q main; git commit -qm other --allow-empty; s=$(git rev-parse HEAD); git checkout -qw 2>/dev/null; git checkout -q w; bash "$OLDPWD/skills/architect/ffcheck.sh" $s; test $? -eq 2 && echo DIVERGED_OK'
exit: 0  ms: 523  bytes: 60
expected: exit:0 match:"DIVERGED_OK"
verdict: PASS
FFCHECK: DIVERGED head=cc36803 expected=6e84f71
DIVERGED_OK

## (root) line 15
$ bash -c 'bash skills/architect/ffcheck.sh not-a-sha 2>&1; test $? -eq 5 && echo ERROR_OK'
exit: 0  ms: 123  bytes: 51
expected: exit:0 match:"ERROR_OK"
verdict: PASS
FFCHECK: ERROR unresolvable sha not-a-sha
ERROR_OK

## (root) line 16
$ bash -c 'powershell -NoProfile -ExecutionPolicy Bypass -File skills/architect/ffcheck.ps1 $(git rev-parse HEAD) | grep -q "FFCHECK: OK" && echo PS_OK'
exit: 0  ms: 294  bytes: 6
expected: exit:0 match:"PS_OK"
verdict: PASS
PS_OK

CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
integrity: check_file_matches_freeze=true head=44d3ce9f507e8537db316eb4c9a2ed339f65c6d7
changed_files: 0 listed below; docs_checks_touched=false
