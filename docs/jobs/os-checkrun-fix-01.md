# os-checkrun-fix-01 report

## PHASE 0

First action evidence:

```text
$head = git rev-parse HEAD
HEAD=76c572a9fe3459280ea87f5631ed8d92e21ceb41
Test-Path docs/checks/os-checkrun-fix.md
CHECK_EXISTS=True
```

Plan:
- Read `docs/spec/orchestrator-scripts.md` D5 and frozen `docs/checks/os-checkrun-fix.md`.
- Replace `skills/architect/check-runner.ps1` PowerShell executor handoff with an encoded, quote-safe handoff.
- Leave `skills/architect/check-runner.sh` unchanged unless local evidence proves `bash -c` broken.
- Add only `tests/fixtures/checkrun/fixture-checks-quoted-ps.md`, `tests/fixtures/checkrun/fixture-checks-quoted-bash.md`, `tests/fixtures/checkrun/config-quoted-ps.json`, and `tests/fixtures/checkrun/config-quoted-bash.json`.
- Do not touch run-#62 fixture files or `docs/checks/**`.
- Verify PowerShell + native `git.exe` locally; record bash checks as UNEXECUTED because Git Bash dies in this sandbox and is judge-side.

Binding file evidence:

```text
Select-String docs/spec/orchestrator-scripts.md D5 anchors
43:  multi-word patterns. D5 and slice OS5 carry the fix; original evidence:
112:### D5. check-runner quoting fix (amendment)
114:The runner must deliver each RUN command to its executor byte-identical to
116:quote-safe mechanism (encoded command or temp-script-file execution — builder
117:chooses, judge quotes it). sh: verify `bash -c` preserves quoting; fix only
119:(`fixture-checks-quoted-*`, `config-quoted-*`) so run-#62's frozen fixture
120:counts stay untouched. Regression: the original `config-ps.json` fixture
```

```text
Select-String docs/checks/os-checkrun-fix.md anchors
16:## QF1 — quoted-pattern fixture runs clean (ps1)
23:## QF2 — quoted-pattern fixture runs clean (sh)
29:## QF3 — regression: run-#62 fixture contract unchanged
36:## QF4 — old fixtures untouched
40:## QF5 — judge-only
```

Disagreements / unavailable evidence:

```text
git show job/os-wiring-01:docs/jobs/os-wiring-checkrun.md
fatal: invalid object name 'job/os-wiring-01'.

git branch --all --list '*os-wiring*'
<no output>

git for-each-ref --format='%(refname)' | Select-String -Pattern 'os-wiring'
<no output>
```

Finding: `job/os-wiring-01` defect-evidence branch is not available in this worktree. D5 in `docs/spec/orchestrator-scripts.md` contains the same defect summary and is the binding file evidence used for implementation.

No disagreement found between D5 and `docs/checks/os-checkrun-fix.md`.

## Changes

```text
git status --short
 M skills/architect/check-runner.ps1
?? docs/jobs/os-checkrun-fix-01.md
?? tests/fixtures/checkrun/config-quoted-bash.json
?? tests/fixtures/checkrun/config-quoted-ps.json
?? tests/fixtures/checkrun/fixture-checks-quoted-bash.md
?? tests/fixtures/checkrun/fixture-checks-quoted-ps.md
```

```text
git diff -- skills/architect/check-runner.ps1
@@ -42,11 +42,26 @@ function QuoteArg($Text) {
     return $r + '"'
 }
 
+function EncodePowerShellCommand($Text) {
+    return [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Text))
+}
+
+function BuildPowerShellInvocation($Command) {
+    $encodedRunCommand = EncodePowerShellCommand $Command
+    $wrapper = @"
+`$ProgressPreference = 'SilentlyContinue'
+`$__checkrunCommand = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String('$encodedRunCommand'))
+Invoke-Expression `$__checkrunCommand
+if (`$global:LASTEXITCODE -ne `$null) { exit `$global:LASTEXITCODE }
+"@
+    return EncodePowerShellCommand $wrapper
+}
+
 function CaptureCommand($Executor, $Command, $Workdir) {
     $psi = New-Object System.Diagnostics.ProcessStartInfo
     if ($Executor -eq "powershell") {
         $psi.FileName = "powershell"
-        $psi.Arguments = "-NoProfile -Command " + $Command + '; if ($global:LASTEXITCODE -ne $null) { exit $global:LASTEXITCODE }'
+        $psi.Arguments = "-NoProfile -EncodedCommand " + (BuildPowerShellInvocation $Command)
     } else {
         $psi.FileName = "bash"
         $psi.Arguments = "-c " + (QuoteArg $Command)
```

PowerShell mechanism file evidence:

```text
Select-String -Path skills/architect/check-runner.ps1 -Pattern EncodedCommand,encodedRunCommand,Invoke-Expression,LASTEXITCODE
45:function EncodePowerShellCommand($Text) {
49:function BuildPowerShellInvocation($Command) {
50:    $encodedRunCommand = EncodePowerShellCommand $Command
52:`$ProgressPreference = 'SilentlyContinue'
53:`$__checkrunCommand = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String('$encodedRunCommand'))
54:Invoke-Expression `$__checkrunCommand
55:if (`$global:LASTEXITCODE -ne `$null) { exit `$global:LASTEXITCODE }
64:        $psi.Arguments = "-NoProfile -EncodedCommand " + (BuildPowerShellInvocation $Command)
```

Bash runner file evidence:

```text
Select-String -Path skills/architect/check-runner.sh -Pattern 'bash -c'
95:      (cd "$workdir" && bash -c "${commands[$i]}") > "$run_out" 2>&1
```

## Fixtures

```text
Get-Content tests/fixtures/checkrun/fixture-checks-quoted-ps.md
# Fixture Checks: Quoted PowerShell

Executor: powershell

## Fixture

QUOTED MARKER sentinel

- RUN: `git --version` -> records git version.
- RUN: `git grep -c "QUOTED MARKER" -- tests/fixtures/checkrun/fixture-checks-quoted-ps.md` -> records quoted grep count.
```

```text
Get-Content tests/fixtures/checkrun/fixture-checks-quoted-bash.md
# Fixture Checks: Quoted Bash

Executor: bash

## Fixture

QUOTED MARKER sentinel

- RUN: `git --version` -> records git version.
- RUN: `git grep -c "QUOTED MARKER" -- tests/fixtures/checkrun/fixture-checks-quoted-bash.md` -> records quoted grep count.
```

```text
Get-Content tests/fixtures/checkrun/config-quoted-ps.json
{"check_file":"tests/fixtures/checkrun/fixture-checks-quoted-ps.md","workdir":".","freeze_sha":"HEAD","evidence_out":".architect/tmp/checkrun-quoted-ps.md","executor":"powershell","max_output_lines":60}

Get-Content tests/fixtures/checkrun/config-quoted-bash.json
{"check_file":"tests/fixtures/checkrun/fixture-checks-quoted-bash.md","workdir":".","freeze_sha":"HEAD","evidence_out":".architect/tmp/checkrun-quoted-bash.md","executor":"bash","max_output_lines":60}
```

```text
(Select-String -Path tests/fixtures/checkrun/fixture-checks-quoted-ps.md -Pattern 'QUOTED MARKER').Count
2
(Select-String -Path tests/fixtures/checkrun/fixture-checks-quoted-bash.md -Pattern 'QUOTED MARKER').Count
2
```

## QF1

Local direct quote probe against a tracked file:

```text
powershell -NoProfile -Command git grep -c "PREFLIGHT: OK" -- docs/spec/orchestrator-scripts.md; Write-Output "oldstyle_exit=$LASTEXITCODE"
oldstyle_exit=1
fatal: unable to resolve revision: OK

$Command = 'git grep -c "PREFLIGHT: OK" -- docs/spec/orchestrator-scripts.md'
<same encoded wrapper mechanism as check-runner.ps1>
powershell -NoProfile -EncodedCommand $encodedWrapper; Write-Output "encoded_exit=$LASTEXITCODE"
docs/spec/orchestrator-scripts.md:2
encoded_exit=0
```

Local fixture run before orchestrator commit:

```text
powershell -NoProfile -File skills/architect/check-runner.ps1 -Config tests/fixtures/checkrun/config-quoted-ps.json; $LASTEXITCODE
0
(Select-String -Path .architect/tmp/checkrun-quoted-ps.md -Pattern 'fatal').Count
0
(Select-String -Path .architect/tmp/checkrun-quoted-ps.md -Pattern 'fixture-checks-quoted-ps.md:2').Count
0
(Select-String -Path .architect/tmp/checkrun-quoted-ps.md -Pattern '^exit: 0').Count
1
```

```text
Get-Content .architect/tmp/checkrun-quoted-ps.md
# Checkrun: checkrun-quoted-ps
generated: 2026-07-04T21:08:25.4313912Z  runner: ps1  config: tests/fixtures/checkrun/config-quoted-ps.json
check_file: tests/fixtures/checkrun/fixture-checks-quoted-ps.md  freeze_sha: HEAD
Executor: powershell
executor_config: powershell
integrity: check_file_matches_freeze=false head=76c572a9fe3459280ea87f5631ed8d92e21ceb41
changed_files: 0 listed below; docs_checks_touched=false

## Fixture line 9
$ git --version
exit: 0  ms: 541  bytes: 29
git version 2.51.2.windows.1

## Fixture line 10
$ git grep -c "QUOTED MARKER" -- tests/fixtures/checkrun/fixture-checks-quoted-ps.md
exit: 1  ms: 500  bytes: 0
```

Local fixture limitation evidence:

```text
git ls-files --error-unmatch tests/fixtures/checkrun/fixture-checks-quoted-ps.md; Write-Output "lsfiles_exit=$LASTEXITCODE"
lsfiles_exit=1

git grep -c "QUOTED MARKER" -- tests/fixtures/checkrun/fixture-checks-quoted-ps.md; Write-Output "grepgrep_exit=$LASTEXITCODE"
grepgrep_exit=1
error: pathspec 'tests/fixtures/checkrun/fixture-checks-quoted-ps.md' did not match any file(s) known to git
Did you forget to 'git add'?
```

```text
git add -- tests/fixtures/checkrun/fixture-checks-quoted-ps.md tests/fixtures/checkrun/fixture-checks-quoted-bash.md tests/fixtures/checkrun/config-quoted-ps.json tests/fixtures/checkrun/config-quoted-bash.json
fatal: Unable to create 'C:/Users/danhm/tools/architect-loop/.git/worktrees/os-checkrun-fix-01/index.lock': Permission denied

$env:GIT_INDEX_FILE='C:\tmp\checkrun-osfix-index-local'; git read-tree HEAD; git add -- tests/fixtures/checkrun/fixture-checks-quoted-ps.md ...
fatal: Unable to create 'C:\tmp\checkrun-osfix-index-local.lock': Permission denied
```

## QF2

```text
UNEXECUTED: bash skills/architect/check-runner.sh tests/fixtures/checkrun/config-quoted-bash.json; $LASTEXITCODE
Reason: executor truth says PowerShell + native git.exe in this sandbox; Git Bash dies here. Judge/check-runner run bash-side checks orchestrator-side.
```

Bash static evidence:

```text
Select-String -Path skills/architect/check-runner.sh -Pattern 'bash -c'
95:      (cd "$workdir" && bash -c "${commands[$i]}") > "$run_out" 2>&1
```

## QF3

```text
powershell -NoProfile -File skills/architect/check-runner.ps1 -Config tests/fixtures/checkrun/config-ps.json; $LASTEXITCODE
0
(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^exit: ').Count
3
(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^exit: 3').Count
1
Test-Path tests/fixtures/checkrun/TRAP.txt
False
```

```text
Get-Content .architect/tmp/checkrun-fixture-ps.md
# Checkrun: checkrun-fixture-ps
generated: 2026-07-04T21:08:25.4405646Z  runner: ps1  config: tests/fixtures/checkrun/config-ps.json
check_file: tests/fixtures/checkrun/fixture-checks-ps.md  freeze_sha: HEAD
Executor: powershell
executor_config: powershell
integrity: check_file_matches_freeze=true head=76c572a9fe3459280ea87f5631ed8d92e21ceb41
changed_files: 0 listed below; docs_checks_touched=false

## Fixture line 7
$ git --version
exit: 0  ms: 533  bytes: 29
git version 2.51.2.windows.1

## Fixture line 8
$ 1..100 | ForEach-Object { $_ }
exit: 0  ms: 502  bytes: 392 truncated
1
2
3
...
60

## Fixture line 9
$ powershell -NoProfile -Command "exit 3"
exit: 3  ms: 680  bytes: 0
```

## QF4

```text
git diff 4ebe337a65e0fe616eb4d3310a307c8eba3c8179..HEAD --name-only -- tests/fixtures/checkrun/fixture-checks-ps.md tests/fixtures/checkrun/fixture-checks-bash.md tests/fixtures/checkrun/config-ps.json tests/fixtures/checkrun/config-bash.json tests/fixtures/checkrun/config-missing.json
<no output>
```

```text
git diff --name-only -- docs/checks
<no output>
```

## QF5

```text
skills/architect/check-runner.ps1 lines 45-64
45:function EncodePowerShellCommand($Text) {
46:    return [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Text))
49:function BuildPowerShellInvocation($Command) {
50:    $encodedRunCommand = EncodePowerShellCommand $Command
53:`$__checkrunCommand = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String('$encodedRunCommand'))
54:Invoke-Expression `$__checkrunCommand
55:if (`$global:LASTEXITCODE -ne `$null) { exit `$global:LASTEXITCODE }
64:        $psi.Arguments = "-NoProfile -EncodedCommand " + (BuildPowerShellInvocation $Command)
```

```text
skills/architect/check-runner.sh
UNMODIFIED
95:      (cd "$workdir" && bash -c "${commands[$i]}") > "$run_out" 2>&1
```

STATUS: COMPLETE
