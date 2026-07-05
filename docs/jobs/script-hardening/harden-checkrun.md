# Checkrun: harden-checkrun
generated: 2026-07-05T19:07:36.8961844Z  runner: ps1  config: C:\Users\danhm\tools\architect-loop\.architect\checkrun-harden.json
check_file: docs/checks/script-hardening/harden.md  freeze_sha: 10a73c755d0a9ef2dfca3b748bd34dc18c89eb94
Executor: PowerShell (primary; Windows codex sandbox kills Git Bash with
executor_config: powershell
executor_resolved: powershell
integrity: check_file_matches_freeze=true head=10a73c755d0a9ef2dfca3b748bd34dc18c89eb94
changed_files: 0 listed below; docs_checks_touched=false

## (root) line 23
$ uv run python tests/validate_skills.py
exit: 1  ms: 2312  bytes: 1333
Traceback (most recent call last):
  File "C:\Users\danhm\tools\architect-loop\.architect\wt\script-hardening\harden-01\tests\validate_skills.py", line 920, in <module>
    sys.exit(main())
             ^^^^^^
  File "C:\Users\danhm\tools\architect-loop\.architect\wt\script-hardening\harden-01\tests\validate_skills.py", line 901, in main
    check_postflight_lane_fixture()
  File "C:\Users\danhm\tools\architect-loop\.architect\wt\script-hardening\harden-01\tests\validate_skills.py", line 724, in check_postflight_lane_fixture
    shutil.rmtree(base)
  File "C:\Users\danhm\AppData\Roaming\uv\python\cpython-3.12.4-windows-x86_64-none\Lib\shutil.py", line 781, in rmtree
    return _rmtree_unsafe(path, onexc)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "C:\Users\danhm\AppData\Roaming\uv\python\cpython-3.12.4-windows-x86_64-none\Lib\shutil.py", line 635, in _rmtree_unsafe
    onexc(os.unlink, fullname, err)
  File "C:\Users\danhm\AppData\Roaming\uv\python\cpython-3.12.4-windows-x86_64-none\Lib\shutil.py", line 633, in _rmtree_unsafe
    os.unlink(fullname)
PermissionError: [WinError 5] Access is denied: 'C:\\Users\\danhm\\tools\\architect-loop\\.architect\\wt\\script-hardening\\harden-01\\.architect\\tmp\\postflight-lane-fixture\\lane\\repo\\.git\\objects\\06\\694fcf71ec9569e412d98748f4e9a53e0faf28'

## (root) line 24
$ git grep -F -c "check_postflight_lane_fixture" -- tests/validate_skills.py
exit: 0  ms: 442  bytes: 27
tests/validate_skills.py:2

## (root) line 25
$ git grep -F -c "cleanup=deferred" -- skills/architect/postflight.ps1
exit: 0  ms: 370  bytes: 34
skills/architect/postflight.ps1:1

## (root) line 26
$ git grep -F -c "cleanup=deferred" -- skills/architect/postflight.sh
exit: 0  ms: 393  bytes: 33
skills/architect/postflight.sh:1

## (root) line 27
$ git grep -F -c "cleanup=deferred" -- skills/architect/dispatch.md
exit: 0  ms: 383  bytes: 31
skills/architect/dispatch.md:1

## (root) line 28
$ git grep -F -c "cleanup=deferred" -- docs/solutions/worktree-cleanup-locks.md
exit: 0  ms: 413  bytes: 43
docs/solutions/worktree-cleanup-locks.md:1

## (root) line 29
$ git grep -F -c "no commits beyond freeze" -- skills/architect/postflight.ps1 skills/architect/postflight.sh
exit: 0  ms: 387  bytes: 67
skills/architect/postflight.ps1:1
skills/architect/postflight.sh:1
