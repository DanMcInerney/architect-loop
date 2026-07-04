# Checkrun: os-scripts-checkrun
generated: 2026-07-04T21:18:10.8008060Z  runner: ps1  config: C:/Users/danhm/tools/architect-loop/.architect/checkrun-os-scripts.json
check_file: docs/checks/os-scripts.md  freeze_sha: 4ebe337a65e0fe616eb4d3310a307c8eba3c8179
Executor: powershell (single executor; bash-variant commands invoke `bash`
executor_config: powershell
integrity: check_file_matches_freeze=true head=a58b58be7bc96a6178863d184da3ee4f768dafe0
changed_files: 8 listed below; docs_checks_touched=false
docs/jobs/os-scripts-01.md
docs/jobs/os-scripts-rulings.md
skills/architect/postflight.ps1
skills/architect/postflight.sh
skills/architect/preflight.ps1
skills/architect/preflight.sh
tests/fixtures/orchscripts/make-fixture.ps1
tests/fixtures/orchscripts/make-fixture.sh

## OS1 — scripts exist, lean, non-grading line 18
$ @('skills/architect/preflight.ps1','skills/architect/preflight.sh','skills/architect/postflight.ps1','skills/architect/postflight.sh') | ForEach-Object { Test-Path $_ }
exit: 0  ms: 638  bytes: 24
True
True
True
True

## OS1 — scripts exist, lean, non-grading line 19
$ (Get-Content skills/architect/postflight.ps1 | Where-Object { $_.Trim() }).Count
exit: 0  ms: 434  bytes: 5
120

## OS1 — scripts exist, lean, non-grading line 20
$ git grep -cE "PASS|FAIL|INVALID" -- skills/architect/postflight.ps1 skills/architect/postflight.sh
exit: 1  ms: 455  bytes: 0

## OS1 — scripts exist, lean, non-grading line 21
$ git grep -c "PREFLIGHT: FAIL" -- skills/architect/preflight.ps1
exit: 0  ms: 402  bytes: 33
skills/architect/preflight.ps1:2

## OS1 — scripts exist, lean, non-grading line 22
$ git grep -c "PREFLIGHT: FAIL" -- skills/architect/preflight.sh
exit: 0  ms: 449  bytes: 32
skills/architect/preflight.sh:1

## OS2 — fixture builds line 26
$ powershell -NoProfile -File tests/fixtures/orchscripts/make-fixture.ps1; $LASTEXITCODE
exit: 0  ms: 1638  bytes: 3
0

## OS2 — fixture builds line 27
$ git -C .architect/tmp/orchfix log --oneline --all | Measure-Object -Line | Select-Object -ExpandProperty Lines
exit: 0  ms: 515  bytes: 3
6

## OS3 — preflight happy path and typed FAIL line 31
$ powershell -NoProfile -File skills/architect/preflight.ps1 -Config .architect/tmp/orchcfg/pre-ok.json; $LASTEXITCODE
exit: 0  ms: 870  bytes: 166
PREFLIGHT: OK worktree=C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\.architect\tmp\orchfix-wt-ok head=fe626e355663f7f2adb6e4761f2ee248cdadbfe4
0

## OS3 — preflight happy path and typed FAIL line 32
$ powershell -NoProfile -File skills/architect/preflight.ps1 -Config .architect/tmp/orchcfg/pre-badsha.json; $LASTEXITCODE
exit: 5  ms: 1116  bytes: 41
PREFLIGHT: FAIL freeze_sha not found
5

## OS3 — preflight happy path and typed FAIL line 33
$ Test-Path .architect/tmp/orchfix-wt-bad
exit: 0  ms: 446  bytes: 7
False

## OS4 — postflight audit, merge, conflict (ps1) line 37
$ powershell -NoProfile -File skills/architect/postflight.ps1 -Config .architect/tmp/orchcfg/post-clean.json; $LASTEXITCODE
exit: 0  ms: 925  bytes: 76
POSTFLIGHT: OK merge=7abd1c77f74b5551104394d8d5d0c13b1551f7a5 changed=1
0

## OS4 — postflight audit, merge, conflict (ps1) line 38
$ powershell -NoProfile -File skills/architect/postflight.ps1 -Config .architect/tmp/orchcfg/post-violation.json; $LASTEXITCODE
exit: 2  ms: 843  bytes: 48
POSTFLIGHT: VIOLATION docs/checks/frozen.md
2

## OS4 — postflight audit, merge, conflict (ps1) line 39
$ powershell -NoProfile -File skills/architect/postflight.ps1 -Config .architect/tmp/orchcfg/post-conflict.json; $LASTEXITCODE
exit: 3  ms: 1061  bytes: 39
POSTFLIGHT: CONFLICT
conflict.txt
3

## OS4 — postflight audit, merge, conflict (ps1) line 40
$ git -C .architect/tmp/orchfix status --porcelain
exit: 0  ms: 510  bytes: 0

## OS5 — bash variants and bash fixture builder, same contract line 44
$ bash tests/fixtures/orchscripts/make-fixture.sh; bash skills/architect/preflight.sh .architect/tmp/orchcfg/pre-ok.json; $LASTEXITCODE
exit: 0  ms: 2490  bytes: 165
PREFLIGHT: OK worktree=/c/Users/danhm/tools/architect-loop/.architect/wt/os-scripts-01/.architect/tmp/orchfix-wt-ok head=4d73d22a14bd6119e475ce8f437a05437ba8db6d
0

## OS5 — bash variants and bash fixture builder, same contract line 45
$ bash skills/architect/postflight.sh .architect/tmp/orchcfg/post-clean.json; $LASTEXITCODE
exit: 0  ms: 1575  bytes: 75
POSTFLIGHT: OK merge=fca08a1ac8d46ed9761903ca663557b773853a5d changed=1
0

## OS5 — bash variants and bash fixture builder, same contract line 46
$ bash skills/architect/postflight.sh .architect/tmp/orchcfg/post-violation.json; $LASTEXITCODE
exit: 2  ms: 1448  bytes: 47
POSTFLIGHT: VIOLATION docs/checks/frozen.md
2

## OS5 — bash variants and bash fixture builder, same contract line 47
$ bash skills/architect/postflight.sh .architect/tmp/orchcfg/post-conflict.json; $LASTEXITCODE
exit: 3  ms: 1672  bytes: 37
POSTFLIGHT: CONFLICT
conflict.txt
3
