# Checkrun: os-checkrun-fix-checkrun
generated: 2026-07-04T21:12:54.3018174Z  runner: ps1  config: C:/Users/danhm/tools/architect-loop/.architect/checkrun-os-fix.json
check_file: docs/checks/os-checkrun-fix.md  freeze_sha: 76c572a9fe3459280ea87f5631ed8d92e21ceb41
Executor: powershell; native `git.exe`. Run sequentially from the worktree
executor_config: powershell
integrity: check_file_matches_freeze=true head=26b119f13df8629575354e0b7c0f7d15e7fda1a2
changed_files: 6 listed below; docs_checks_touched=false
docs/jobs/os-checkrun-fix-01.md
skills/architect/check-runner.ps1
tests/fixtures/checkrun/config-quoted-bash.json
tests/fixtures/checkrun/config-quoted-ps.json
tests/fixtures/checkrun/fixture-checks-quoted-bash.md
tests/fixtures/checkrun/fixture-checks-quoted-ps.md

## QF1 — quoted-pattern fixture runs clean (ps1) line 18
$ powershell -NoProfile -File skills/architect/check-runner.ps1 -Config tests/fixtures/checkrun/config-quoted-ps.json; $LASTEXITCODE
exit: 0  ms: 2214  bytes: 3
0

## QF1 — quoted-pattern fixture runs clean (ps1) line 19
$ (Select-String -Path .architect/tmp/checkrun-quoted-ps.md -Pattern 'fatal').Count
exit: 0  ms: 532  bytes: 3
0

## QF1 — quoted-pattern fixture runs clean (ps1) line 20
$ (Select-String -Path .architect/tmp/checkrun-quoted-ps.md -Pattern 'fixture-checks-quoted-ps.md:2').Count
exit: 0  ms: 507  bytes: 3
1

## QF1 — quoted-pattern fixture runs clean (ps1) line 21
$ (Select-String -Path .architect/tmp/checkrun-quoted-ps.md -Pattern '^exit: 0').Count
exit: 0  ms: 531  bytes: 3
2

## QF2 — quoted-pattern fixture runs clean (sh) line 25
$ bash skills/architect/check-runner.sh tests/fixtures/checkrun/config-quoted-bash.json; $LASTEXITCODE
exit: 0  ms: 1684  bytes: 3
0

## QF2 — quoted-pattern fixture runs clean (sh) line 26
$ (Select-String -Path .architect/tmp/checkrun-quoted-bash.md -Pattern 'fatal').Count
exit: 0  ms: 503  bytes: 3
0

## QF2 — quoted-pattern fixture runs clean (sh) line 27
$ (Select-String -Path .architect/tmp/checkrun-quoted-bash.md -Pattern 'fixture-checks-quoted-bash.md:2').Count
exit: 0  ms: 529  bytes: 3
1

## QF3 — regression: run-#62 fixture contract unchanged line 31
$ powershell -NoProfile -File skills/architect/check-runner.ps1 -Config tests/fixtures/checkrun/config-ps.json; $LASTEXITCODE
exit: 0  ms: 2527  bytes: 3
0

## QF3 — regression: run-#62 fixture contract unchanged line 32
$ (Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^exit: ').Count
exit: 0  ms: 496  bytes: 3
3

## QF3 — regression: run-#62 fixture contract unchanged line 33
$ (Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^exit: 3').Count
exit: 0  ms: 712  bytes: 3
1

## QF3 — regression: run-#62 fixture contract unchanged line 34
$ Test-Path tests/fixtures/checkrun/TRAP.txt
exit: 0  ms: 503  bytes: 7
False

## QF4 — old fixtures untouched line 38
$ git diff 4ebe337a65e0fe616eb4d3310a307c8eba3c8179..HEAD --name-only -- tests/fixtures/checkrun/fixture-checks-ps.md tests/fixtures/checkrun/fixture-checks-bash.md tests/fixtures/checkrun/config-ps.json tests/fixtures/checkrun/config-bash.json tests/fixtures/checkrun/config-missing.json
exit: 0  ms: 533  bytes: 0
