# Lane report: v5-docs-01

Lane identity: v5-docs-01. Issue: #18. Shape: ship.

## PHASE 0 record

Plan:

1. Replace the README v4 diary/slice narrative with the shipped v5 flow:
   intake, spec gate, factory loop, GitHub issue DAG, max 5 brawn lanes plus
   one monitor, and current brain/brawn config.
2. Append `DESIGN.md` section 12 with the D1-D11 summary, 2026-07-02 human
   rulings, research pointers, and dogfood evidence from issues #12-#18.
3. Add four `docs/solutions/*.md` codify documents.
4. Run DC1-DC5 sequentially and record raw output.

Disagreements and constraints:

- The frozen gates are written as Git Bash `grep` commands, but this lane's
  shell is PowerShell and `docs/gates/v5-docs.md` permits recorded
  same-pattern substitution under "Executor." Used PowerShell equivalents.
- DC4's frozen command uses uv's default cache path, but prior v5 evidence in
  `docs/lanes/v5-dispatch-01.md` records AppData cache access denied and the
  `.architect/tmp/uv-cache` route-around. Used the permitted
  `UV_CACHE_DIR=.architect/tmp/uv-cache` redirect.
- README had stale v4 flow content: `README.md:15` linked the v4 flow diagram,
  `README.md:22` and `README.md:76` named the retired coordination file, and
  `README.md:79` described tier-up on failure. Replaced with v5 issue-DAG and
  fixed-tier failure handling.
- README file map was stale: `README.md:168` described `loop.md` as the
  judgment ledger, while v5 records verdicts in issue comments. Updated the
  table.

## Files touched

- `README.md`
- `DESIGN.md`
- `docs/solutions/subagent-shell-strip-codex-fallback.md`
- `docs/solutions/uv-cache-sandbox-redirect.md`
- `docs/solutions/cross-lane-content-dependency.md`
- `docs/solutions/worktree-stale-snapshot.md`
- `docs/lanes/v5-docs-01.md`

## Gate results

### DC1

Frozen command:

```bash
grep -qi "spec gate" README.md && grep -qi "monitor" README.md && grep -qiE "github issues?" README.md
```

Executor: PowerShell same-pattern substitution.

Executed command:

```powershell
$ok = (Select-String -Path README.md -Pattern 'spec gate' -Quiet) -and (Select-String -Path README.md -Pattern 'monitor' -Quiet) -and (Select-String -Path README.md -Pattern 'github issues?' -Quiet); if (-not $ok) { Write-Output 'DC1 pattern check failed'; exit 1 }
```

Output:

```text
```

Exit code: 0

### DC2

Frozen command:

```bash
grep -q "brawn = codex/best:xhigh" README.md
```

Executor: PowerShell same-pattern substitution.

Executed command:

```powershell
if (-not (Select-String -Path README.md -Pattern 'brawn = codex/best:xhigh' -SimpleMatch -Quiet)) { Write-Output 'DC2 literal check failed'; exit 1 }
```

Output:

```text
```

Exit code: 0

### DC3

Frozen command:

```bash
grep -q "architect-v5" DESIGN.md && grep -qi "factory" DESIGN.md
```

Executor: PowerShell same-pattern substitution.

Executed command:

```powershell
$ok = (Select-String -Path DESIGN.md -Pattern 'architect-v5' -SimpleMatch -Quiet) -and (Select-String -Path DESIGN.md -Pattern 'factory' -Quiet); if (-not $ok) { Write-Output 'DC3 pattern check failed'; exit 1 }
```

Output:

```text
```

Exit code: 0

### DC4

Frozen command:

```bash
uv run --no-project python tests/validate_skills.py
```

Executor: PowerShell with permitted `UV_CACHE_DIR=.architect/tmp/uv-cache`
same-pattern substitution.

Executed command:

```powershell
New-Item -ItemType Directory -Force .architect/tmp/uv-cache | Out-Null; $env:UV_CACHE_DIR = (Resolve-Path .architect/tmp/uv-cache).Path; uv run --no-project python tests/validate_skills.py; exit $LASTEXITCODE
```

Output:

```text
OK - 2 skills validated, v4 contracts clean
```

Exit code: 0

### DC5

Frozen command:

```bash
! grep -qi "HANDOFF.md" README.md
```

Executor: PowerShell same-pattern substitution.

Executed command:

```powershell
if (Select-String -Path README.md -Pattern 'HANDOFF.md' -Quiet) { Write-Output 'DC5 forbidden README mention found'; exit 1 }
```

Output:

```text
```

Exit code: 0

## Additional raw checks

Command:

```powershell
git diff -- docs/gates/
```

Output:

```text
```

Exit code: 0

Command:

```powershell
git status --short
```

Output before report creation:

```text
 M DESIGN.md
 M README.md
```

Exit code: 0

Command:

```powershell
Get-ChildItem docs/solutions | Select-Object Name,Length
```

Output:

```text
Name                                   Length
----                                   ------
cross-lane-content-dependency.md         1153
subagent-shell-strip-codex-fallback.md   1204
uv-cache-sandbox-redirect.md              809
worktree-stale-snapshot.md                930
```

Exit code: 0

Command:

```powershell
git check-ignore -v docs/solutions/subagent-shell-strip-codex-fallback.md docs/lanes/v5-docs-01.md; exit 0
```

Output:

```text
.gitignore:6:/docs/*	docs/solutions/subagent-shell-strip-codex-fallback.md
```

Exit code: 0

Command:

```powershell
git add -N -f docs/solutions/subagent-shell-strip-codex-fallback.md docs/solutions/uv-cache-sandbox-redirect.md docs/solutions/cross-lane-content-dependency.md docs/solutions/worktree-stale-snapshot.md docs/lanes/v5-docs-01.md
```

Output:

```text
fatal: Unable to create 'C:/Users/danhm/tools/architect-loop/.git/worktrees/v5-docs-01/index.lock': Permission denied
```

Exit code: 1

Command:

```powershell
git status --short --ignored=matching docs/solutions docs/lanes/v5-docs-01.md README.md DESIGN.md
```

Output:

```text
 M DESIGN.md
 M README.md
?? docs/lanes/v5-docs-01.md
!! docs/solutions/
```

Exit code: 0

## RESPAWN PATCH (.gitignore allowlist)

Edit summary:

- Removed dead docs allowlist entry `!/docs/HANDOFF.md`.
- Added docs allowlist entry `!/docs/solutions/` so codified solution docs are visible to git.
- No other `.gitignore` changes were made.

Verification:

Command:

```powershell
git check-ignore docs/solutions/uv-cache-sandbox-redirect.md; $code = $LASTEXITCODE; Write-Output "EXIT:$code"; exit 0
```

Output:

```text
EXIT:1
```

Exit code: 0 for the wrapper; captured git check-ignore exit: 1.

Command:

```powershell
git status --short --untracked-files=all; $code = $LASTEXITCODE; Write-Output "EXIT:$code"; exit 0
```

Output:

```text
 M .gitignore
 M DESIGN.md
 M README.md
?? docs/lanes/v5-docs-01.md
?? docs/solutions/cross-lane-content-dependency.md
?? docs/solutions/subagent-shell-strip-codex-fallback.md
?? docs/solutions/uv-cache-sandbox-redirect.md
?? docs/solutions/worktree-stale-snapshot.md
EXIT:0
```

Exit code: 0.

Command:

```powershell
New-Item -ItemType Directory -Force .architect/tmp/uv-cache | Out-Null; $env:UV_CACHE_DIR = (Resolve-Path .architect/tmp/uv-cache).Path; uv run --no-project python tests/validate_skills.py; $code = $LASTEXITCODE; Write-Output "EXIT:$code"; exit $code
```

Output:

```text
OK - 2 skills validated, v4 contracts clean
EXIT:0
```

Exit code: 0.

Command:

```powershell
git diff -- .gitignore; $code = $LASTEXITCODE; Write-Output "EXIT:$code"; exit 0
```

Output:

```text
diff --git a/.gitignore b/.gitignore
index 074f41e..4743f41 100644
--- a/.gitignore
+++ b/.gitignore
@@ -4,11 +4,11 @@ Thumbs.db
 # Loop memory files are tracked; everything else under docs/ stays local.
 # docs/STOP is the loop kill switch — never commit it.
 /docs/*
-!/docs/HANDOFF.md
 !/docs/gates/
 !/docs/lanes/
 !/docs/spec/
 !/docs/research/
+!/docs/solutions/
 /.architect/
 /research/
 .gstack/
EXIT:0
warning: in the working copy of '.gitignore', LF will be replaced by CRLF the next time Git touches it
```

Exit code: 0.

STATUS: COMPLETE
MIRROR: ORCHESTRATOR
