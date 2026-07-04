# os-scripts-01

## PHASE 0

Input verification:

```text
HEAD=4ebe337a65e0fe616eb4d3310a307c8eba3c8179
CHECK_EXISTS=True
```

Binding docs checked:

```text
docs/spec/orchestrator-scripts.md
docs/checks/os-scripts.md
```

Spec anchors checked:

```text
D1: preflight validates config, adds worktree at freeze SHA, verifies HEAD, checks require_files, prints PREFLIGHT typed output, and cleans up anything this run created on failure.
D2: postflight validates branch, audits touch set before merge, treats docs/checks/ as always violation, merges --no-ff, aborts conflicts/errors, optional push, cleanup, typed exits.
D4: may_touch/exempt are forward-slash path prefixes or shell-style globs; trailing slash is prefix; case-sensitive; no regex.
Interface contract: config JSON path is the single argument; repo_root is an absolute path.
```

Frozen checks checked:

```text
OS1: script presence, postflight.ps1 nonblank line count <= 260, no PASS|FAIL|INVALID in postflight scripts, PREFLIGHT: FAIL present in preflight scripts.
OS2: PowerShell fixture builder exits 0 and creates >= 4 commits/branch tips.
OS3: PowerShell preflight OK and bad SHA typed failure, no bad worktree debris.
OS4: PowerShell postflight OK, VIOLATION, CONFLICT, and clean repo status after conflict.
OS5: bash fixture/preflight/postflight same contract; not executable in this sandbox per job instruction.
OS6: quote file:line evidence for docs/checks/ always-violation, merge-abort guarantees, off-factory branch guard, and trailing-slash prefix rule in both postflight scripts.
```

Plan:

```text
1. Add preflight.ps1 and preflight.sh with config validation, freeze commit validation, worktree add, HEAD/require_files verification, and best-effort cleanup on typed failure.
2. Add postflight.ps1 and postflight.sh with branch guard, D4 touch-set audit, docs/checks/ hard violation, no-ff merge, abort-on-conflict/error, optional push, and cleanup.
3. Add make-fixture.ps1 and make-fixture.sh under tests/fixtures/orchscripts/ with idempotent scratch repo rebuild and absolute repo_root config generation.
4. Run frozen OS1-OS4 PowerShell checks sequentially from the worktree root.
5. Record OS5 as UNEXECUTED because Git Bash dies under this sandbox, per job instruction.
6. Record OS6 quote/file-line evidence.
```

Disagreements:

```text
None found between the issue body and binding spec/check behavior after checking docs/spec/orchestrator-scripts.md D1, D2, D4, Interface contract and docs/checks/os-scripts.md OS1-OS6.
Reconciliation recorded: the issue separately mandates report path docs/jobs/os-scripts-01.md; implementation ownership remains the four scripts and tests/fixtures/orchscripts/**.
```

## OS1 evidence

Command:

```powershell
@('skills/architect/preflight.ps1','skills/architect/preflight.sh','skills/architect/postflight.ps1','skills/architect/postflight.sh') | ForEach-Object { Test-Path $_ }
```

Output:

```text
True
True
True
True
```

Command:

```powershell
(Get-Content skills/architect/postflight.ps1 | Where-Object { $_.Trim() }).Count
```

Output:

```text
120
```

Command:

```powershell
git grep -cE "PASS|FAIL|INVALID" -- skills/architect/postflight.ps1 skills/architect/postflight.sh; $LASTEXITCODE
```

Output:

```text
1
```

Command:

```powershell
git grep -c "PREFLIGHT: FAIL" -- skills/architect/preflight.ps1 skills/architect/preflight.sh; $LASTEXITCODE
```

Output:

```text
1
```

Command:

```powershell
Select-String -Path 'skills/architect/preflight.ps1','skills/architect/preflight.sh' -Pattern 'PREFLIGHT: FAIL' | ForEach-Object { "$($_.Path):$($_.LineNumber):$($_.Line.Trim())" }
```

Output:

```text
C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\skills\architect\preflight.ps1:44:Write-Output "PREFLIGHT: FAIL $Reason"
C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\skills\architect\preflight.ps1:56:Write-Output "PREFLIGHT: FAIL unreadable config"
C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\skills\architect\preflight.sh:40:fail(){ cleanup_created; printf 'PREFLIGHT: FAIL %s\n' "$1"; exit 5; }
```

Command:

```powershell
git ls-files --error-unmatch skills/architect/preflight.ps1; $LASTEXITCODE
```

Output:

```text
1
error: pathspec 'skills/architect/preflight.ps1' did not match any file(s) known to git
Did you forget to 'git add'?
```

Command:

```powershell
git ls-files --others --exclude-standard -- skills/architect/preflight.ps1 skills/architect/preflight.sh
```

Output:

```text
skills/architect/preflight.ps1
skills/architect/preflight.sh
```

Command:

```powershell
git add -N -- skills/architect/preflight.ps1 2>&1; $LASTEXITCODE
```

Output:

```text
128
git : fatal: Unable to create 'C:/Users/danhm/tools/architect-loop/.git/worktrees/os-scripts-01/index.lock': 
Permission denied
At line:2 char:1
+ git add -N -- skills/architect/preflight.ps1 2>&1; $LASTEXITCODE
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (fatal: Unable t...rmission denied:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
```

## OS2 evidence

Command:

```powershell
powershell -NoProfile -File tests/fixtures/orchscripts/make-fixture.ps1; $LASTEXITCODE
```

Output:

```text
0
```

Command:

```powershell
git -C .architect/tmp/orchfix log --oneline --all | Measure-Object -Line | Select-Object -ExpandProperty Lines
```

Output:

```text
6
```

## OS3 evidence

Command:

```powershell
powershell -NoProfile -File skills/architect/preflight.ps1 -Config .architect/tmp/orchcfg/pre-ok.json; $LASTEXITCODE
```

Output:

```text
PREFLIGHT: OK worktree=C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\.architect\tmp\orchfix-wt-ok head=7a59d090173f7d38ab9429998c2e3cbae8414f71
0
```

Command:

```powershell
powershell -NoProfile -File skills/architect/preflight.ps1 -Config .architect/tmp/orchcfg/pre-badsha.json; $LASTEXITCODE
```

Output:

```text
PREFLIGHT: FAIL freeze_sha not found
5
```

Command:

```powershell
Test-Path .architect/tmp/orchfix-wt-bad
```

Output:

```text
False
```

## OS4 evidence

Command:

```powershell
powershell -NoProfile -File skills/architect/postflight.ps1 -Config .architect/tmp/orchcfg/post-clean.json; $LASTEXITCODE
```

Output:

```text
POSTFLIGHT: OK merge=8b45c34a240ebb2b50e314be01659d63ac6178d1 changed=1
0
```

Command:

```powershell
powershell -NoProfile -File skills/architect/postflight.ps1 -Config .architect/tmp/orchcfg/post-violation.json; $LASTEXITCODE
```

Output:

```text
POSTFLIGHT: VIOLATION docs/checks/frozen.md
2
```

Command:

```powershell
powershell -NoProfile -File skills/architect/postflight.ps1 -Config .architect/tmp/orchcfg/post-conflict.json; $LASTEXITCODE
```

Output:

```text
POSTFLIGHT: CONFLICT
conflict.txt
3
```

Command:

```powershell
git -C .architect/tmp/orchfix status --porcelain
```

Output:

```text
```

## OS5 evidence

```text
UNEXECUTED: bash variants and bash fixture builder. Reason: job instruction says Git Bash dies under this sandbox with Win32 err 5; .sh variants and OS5 checks will be executed by the check-runner on the orchestrator machine.
```

## OS6 evidence

Command:

```powershell
Select-String -Path 'skills/architect/postflight.ps1','skills/architect/postflight.sh' -Pattern 'docs/checks/|Abort any in-progress|Refuse to run|D4 trailing-slash' | ForEach-Object { "$($_.Path):$($_.LineNumber):$($_.Line.Trim())" }
```

Output:

```text
C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\skills\architect\postflight.ps1:27:# Abort any in-progress merge before CONFLICT and ERROR exits after merge work starts.
C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\skills\architect\postflight.ps1:49:# D4 trailing-slash entries are case-sensitive prefix matches against forward-slash paths.
C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\skills\architect\postflight.ps1:59:# docs/checks/ is always a violation, regardless of configured globs.
C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\skills\architect\postflight.ps1:60:if ($Path.StartsWith("docs/checks/", [System.StringComparison]::Ordinal)) { return $false }
C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\skills\architect\postflight.ps1:80:# Refuse to run off the configured factory branch before touch audit or merge.
C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\skills\architect\postflight.sh:34:# Abort any in-progress merge before CONFLICT and ERROR exits after merge work starts.
C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\skills\architect\postflight.sh:42:# D4 trailing-slash entries are case-sensitive prefix matches against forward-slash paths.
C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\skills\architect\postflight.sh:51:# docs/checks/ is always a violation, regardless of configured globs.
C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\skills\architect\postflight.sh:52:case "$path" in docs/checks/*) return 1;; esac
C:\Users\danhm\tools\architect-loop\.architect\wt\os-scripts-01\skills\architect\postflight.sh:84:# Refuse to run off the configured factory branch before touch audit or merge.
```

## Final evidence

Command:

```powershell
git diff -- docs/checks
```

Output:

```text
```

Command:

```powershell
rg -n "&&|\? .* :" skills/architect/preflight.ps1 skills/architect/postflight.ps1 tests/fixtures/orchscripts/make-fixture.ps1
```

Output:

```text
```

Command:

```powershell
git rev-parse HEAD
```

Output:

```text
4ebe337a65e0fe616eb4d3310a307c8eba3c8179
```

Command:

```powershell
git status --short
```

Output:

```text
?? docs/jobs/os-scripts-01.md
?? skills/architect/postflight.ps1
?? skills/architect/postflight.sh
?? skills/architect/preflight.ps1
?? skills/architect/preflight.sh
?? tests/fixtures/orchscripts/
```

STATUS: BLOCKED
