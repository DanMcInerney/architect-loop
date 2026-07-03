MIRROR: ORCHESTRATOR

PHASE 0

FIRST-ACTION input verification:
Command:
```
git log -1 --oneline
Test-Path -LiteralPath docs/checks/status-scripts.md
```
Output:
```
eacc00e re-freeze: stress-test amendments (degraded-mode phase honesty, REPORTED glyph, exact SS3 fixtures, fresh uv cache, PS-native size count)
True
```

Plan:
1. Read `docs/spec/status-tree.md`, `docs/checks/status-scripts.md`, `tests/validate_skills.py`, and existing `skills/architect/watchdog.*`.
2. Add `skills/architect/status.ps1` and `skills/architect/status.sh` as read-only status renderers.
3. Update `tests/validate_skills.py` only to require the two new sibling scripts and enforce the status contract markers.
4. Create SS3 fixtures under `.architect/tmp/stfix/`.
5. Run every check in `docs/checks/status-scripts.md` sequentially with temp/cache paths under `.architect/tmp/`.

Disagreements:
- None.

Checked before concluding the issue is sound:
- `docs/spec/status-tree.md` defines the interface contract, degraded mode, glyph phases, and may-touch split for issue A.
- `docs/checks/status-scripts.md` freezes executable checks for `skills/architect/status.ps1`, `skills/architect/status.sh`, and `tests/validate_skills.py`.
- `tests/validate_skills.py` already has `REQUIRED_SIBLINGS["architect"]` and centralized validator checks, so the requested validator addition fits the existing structure.
- `skills/architect/watchdog.ps1` and `skills/architect/watchdog.sh` are existing sibling scripts and confirm this repo keeps architect helper scripts in `skills/architect/`.

LINE COUNTS

Command:
```
(Get-Content -LiteralPath skills/architect/status.ps1).Count
(Get-Content -LiteralPath skills/architect/status.sh).Count
```
Output:
```
118
97
```

SS1

Command:
```
Test-Path skills/architect/status.ps1
Test-Path skills/architect/status.sh
(Select-String -Path skills/architect/status.sh -Pattern 'NO ACTIVE FACTORY RUN').Count
(Select-String -Path skills/architect/status.ps1 -Pattern 'NO ACTIVE FACTORY RUN').Count
(Get-Content skills/architect/status.sh -TotalCount 1)
```
Output:
```
True
True
1
1
#!/usr/bin/env bash
```

SS2

Command:
```
$e = $null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path 'skills/architect/status.ps1').Path, [ref]$null, [ref]$e) | Out-Null
if ($e.Count -eq 0) { 'SS2_OK' } else { $e }
```
Output:
```
SS2_OK
```

SS3 FIXTURE CREATE

Command:
```
$base = '.architect/tmp/stfix'
New-Item -ItemType Directory -Force -Path "$base/root1/.architect/wt/demo-build-01" | Out-Null
New-Item -ItemType Directory -Force -Path "$base/root1/.architect/wt/demo-blocked-01/docs/jobs" | Out-Null
New-Item -ItemType Directory -Force -Path "$base/root1/.architect/wt/demo-judge-01/docs/jobs" | Out-Null
New-Item -ItemType Directory -Force -Path "$base/root1/.architect/wt/demo-rep-01/docs/jobs" | Out-Null
New-Item -ItemType Directory -Force -Path "$base/root1/docs/spec" | Out-Null
New-Item -ItemType Directory -Force -Path "$base/root2" | Out-Null
Set-Content -LiteralPath "$base/root1/.architect/wt/demo-build-01.events.jsonl" -Encoding UTF8 -Value '{"command":"pytest -q"}'
Set-Content -LiteralPath "$base/root1/.architect/wt/demo-blocked-01/docs/jobs/demo-blocked-01.md" -Encoding UTF8 -Value "STATUS: BLOCKED (x)"
Set-Content -LiteralPath "$base/root1/.architect/wt/demo-judge-01/docs/jobs/demo-judge-01.md" -Encoding UTF8 -Value "STATUS: COMPLETE"
Set-Content -LiteralPath "$base/root1/.architect/wt/demo-judge-01.judge.md" -Encoding UTF8 -Value "judge"
Set-Content -LiteralPath "$base/root1/.architect/wt/demo-rep-01/docs/jobs/demo-rep-01.md" -Encoding UTF8 -Value "STATUS: COMPLETE"
Set-Content -LiteralPath "$base/root1/docs/spec/demo.md" -Encoding UTF8 -Value "demo"
```
Output:
```
```

SS3 ROOT1

Command:
```
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1
```
Output:
```
STATUS TREE spec: demo.md branch: unknown
tracker: unavailable (local view)
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
! demo-blocked .architect/wt/demo-blocked-01
● demo-build .architect/wt/demo-build-01
    last: pytest -q age: unknown
◐ demo-judge .architect/wt/demo-judge-01
▣ demo-rep .architect/wt/demo-rep-01
```

SS3 ROOT2

Command:
```
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root2
```
Output:
```
NO ACTIVE FACTORY RUN
spec: unknown
```

SS4

Command:
```
$out = & powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1 | Out-String
([Text.Encoding]::UTF8.GetBytes($out) -contains 27)
```
Output:
```
False
```

SS5

Command:
```
(Select-String -Path tests/validate_skills.py -Pattern '"status.ps1"').Count
(Select-String -Path tests/validate_skills.py -Pattern '"status.sh"').Count
(Select-String -Path tests/validate_skills.py -Pattern 'check_status_contract').Count
$env:UV_CACHE_DIR='.architect/tmp/uv-cache-st'; uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('SS5_OK')"
```
Output:
```
2
3
2
SS5_OK
```

SS6

Command:
```
Select-String -Path skills/architect/status.ps1,skills/architect/status.sh -Pattern 'Stop-Process|taskkill|Remove-Item|rm -|git (add|commit|push)'
```
Output:
```
```

VALIDATOR

Command:
```
$env:UV_CACHE_DIR='.architect/tmp/uv-cache-st'; uv run --no-project python tests/validate_skills.py
```
Output:
```
OK - 2 skills validated, v4 contracts clean
```

TOUCH SET

Command:
```
git status --short
```
Output:
```
 M tests/validate_skills.py
?? docs/jobs/status-scripts-01.md
?? skills/architect/status.ps1
?? skills/architect/status.sh
```

DOCS CHECKS DIFF

Command:
```
git diff --name-only -- docs/checks
```
Output:
```
```

STATUS: COMPLETE

## Respawn session

Ruling addressed: `skills/architect/status.sh` no longer selects the lexically last `docs/spec/*.md`; it scans spec files and chooses the newest numeric mtime using `stat -c %Y` with `stat -f %m` fallback.

MTIME FIXTURE

Command:
```
$base = '.architect/tmp/stfix'
New-Item -ItemType Directory -Force -Path "$base/root1/docs/spec" | Out-Null
Set-Content -LiteralPath "$base/root1/docs/spec/zzz-old.md" -Encoding UTF8 -Value 'old lexical winner'
Start-Sleep -Milliseconds 25
Set-Content -LiteralPath "$base/root1/docs/spec/aaa-new.md" -Encoding UTF8 -Value 'new mtime winner'
Set-Content -LiteralPath "$base/root1/docs/spec/demo.md" -Encoding UTF8 -Value 'demo older than both'
(Get-Item -LiteralPath "$base/root1/docs/spec/demo.md").LastWriteTimeUtc = [datetime]'2024-01-01T00:00:00Z'
(Get-Item -LiteralPath "$base/root1/docs/spec/zzz-old.md").LastWriteTimeUtc = [datetime]'2025-01-01T00:00:00Z'
(Get-Item -LiteralPath "$base/root1/docs/spec/aaa-new.md").LastWriteTimeUtc = [datetime]'2026-01-01T00:00:00Z'
Get-ChildItem -LiteralPath "$base/root1/docs/spec" -Filter '*.md' | Sort-Object Name | ForEach-Object { "$($_.Name) $($_.LastWriteTimeUtc.ToString('o'))" }
```
Output:
```
aaa-new.md 2026-01-01T00:00:00.0000000Z
demo.md 2024-01-01T00:00:00.0000000Z
zzz-old.md 2025-01-01T00:00:00.0000000Z
```

STATUS.SH MTIME STATIC PROOF

Command:
```
Select-String -Path skills/architect/status.sh -Pattern 'stat -c %Y|stat -f %m|find "\$root/docs/spec".*\|\s*sort'
```
Output:
```

skills\architect\status.sh:20:    mtime=$(stat -c %Y "$spec" 2>/dev/null || stat -f %m "$spec" 2>/dev/null || printf 0)

```

Shell functional note: per respawn instruction, MSYS binaries die in this sandbox and `skills/architect/status.sh` cannot be executed here. I did not run Bash. The shell script is validated statically here; the orchestrator composite runner must execute the shell functional pass.

SS1

Command:
```
Test-Path skills/architect/status.ps1
Test-Path skills/architect/status.sh
(Select-String -Path skills/architect/status.sh -Pattern 'NO ACTIVE FACTORY RUN').Count
(Select-String -Path skills/architect/status.ps1 -Pattern 'NO ACTIVE FACTORY RUN').Count
(Get-Content skills/architect/status.sh -TotalCount 1)
```
Output:
```
True
True
1
1
#!/usr/bin/env bash
```

SS3 ROOT1

Command:
```
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1
```
Output:
```
STATUS TREE spec: aaa-new.md branch: unknown
tracker: unavailable (local view)
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
! demo-blocked .architect/wt/demo-blocked-01
● demo-build .architect/wt/demo-build-01
    last: pytest -q age: unknown
◐ demo-judge .architect/wt/demo-judge-01
▣ demo-rep .architect/wt/demo-rep-01
```

SS3 ROOT2

Command:
```
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root2
```
Output:
```
NO ACTIVE FACTORY RUN
spec: unknown
```

SS6

Command:
```
Select-String -Path skills/architect/status.ps1,skills/architect/status.sh -Pattern 'Stop-Process|taskkill|Remove-Item|rm -|git (add|commit|push)'
```
Output:
```
```

VALIDATOR

Command:
```
$env:UV_CACHE_DIR='.architect/tmp/uv-cache-st'; uv run --no-project python tests/validate_skills.py
```
Output:
```
OK - 2 skills validated, v4 contracts clean
```

DOCS CHECKS DIFF

Command:
```
git diff --name-only -- docs/checks
```
Output:
```
```

STATUS: COMPLETE
