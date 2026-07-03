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

## Re-spec session

PRECONDITION

Command:
```
git cat-file -e HEAD:docs/checks/status-tracker.md
git show HEAD:docs/spec/status-tree.md | Select-String -Pattern 'tracker: no open run'
```
Output:
```
check_exit=0
spec_has_tracker_no_open_run=True
```

ST1

Command:
```
(Select-String -Path skills/architect/status.ps1 -Pattern '--state all').Count
(Select-String -Path skills/architect/status.sh -Pattern '--state all').Count
(Select-String -Path skills/architect/status.ps1,skills/architect/status.sh -Pattern 'blockedBy').Count
```
Output:
```
1
1
4
```

ST2

Command:
```
(Select-String -Path skills/architect/status.ps1 -Pattern 'parent').Count
(Select-String -Path skills/architect/status.sh -Pattern 'parent').Count
Select-String -Path skills/architect/status.sh -Pattern 'parent_refs|parent_number|tracking' | ForEach-Object { "$($_.Path):$($_.LineNumber):$($_.Line)" }
```
Output:
```
4
7
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:39:parent_number(){ printf '%s' "$1" | sed -n 's/.*"parent"[[:space:]]*:[[:space:]]*{[^}]*"number"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n 1; }
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:93:tracking=
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:96:  parent_refs=' '
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:98:    p=$(parent_number "$obj")
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:99:    [ -n "$p" ] && parent_refs="$parent_refs$p "
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:107:    case "$parent_refs" in *" $num "*)
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:108:      if [ "$num" -gt "$highest" ]; then highest=$num; tracking=$num; fi
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:114:if { [ "$tracker" -eq 0 ] || [ -z "$tracking" ]; } && [ -z "$slugs" ]; then
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:119:if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:120:  printf 'tracker: #%s\n' "$tracking"
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:130:if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:132:    [ "$(parent_number "$obj")" = "$tracking" ] || continue
```

ST3

Command:
```
(Select-String -Path skills/architect/status.ps1 -Pattern 'tracker: no open run').Count
(Select-String -Path skills/architect/status.sh -Pattern 'tracker: no open run').Count
Show-Lines 'skills/architect/status.sh' 112 123
```
Output:
```
1
1
skills/architect/status.sh:112:fi
skills/architect/status.sh:113:slugs=$(artifact_slugs)
skills/architect/status.sh:114:if { [ "$tracker" -eq 0 ] || [ -z "$tracking" ]; } && [ -z "$slugs" ]; then
skills/architect/status.sh:115:  printf 'NO ACTIVE FACTORY RUN\nspec: %s\n' "$(newest_spec)"
skills/architect/status.sh:116:  exit 0
skills/architect/status.sh:117:fi
skills/architect/status.sh:118:printf 'STATUS TREE spec: %s branch: %s\n' "$(newest_spec)" "$branch"
skills/architect/status.sh:119:if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then
skills/architect/status.sh:120:  printf 'tracker: #%s\n' "$tracking"
skills/architect/status.sh:121:elif [ "$tracker" -eq 1 ]; then
skills/architect/status.sh:122:  printf 'tracker: no open run\n'
skills/architect/status.sh:123:else
```

ST4

PowerShell tracker section:
```
skills/architect/status.ps1:83:$ghJson = ""
skills/architect/status.ps1:84:$trackerReachable = $false
skills/architect/status.ps1:85:if (Get-Command gh) {
skills/architect/status.ps1:86:    try { $ghJson = (& gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy 2>$null); $trackerReachable = ($LASTEXITCODE -eq 0) }
skills/architect/status.ps1:87:    catch { $ghJson = ""; $trackerReachable = $false }
skills/architect/status.ps1:88:}
skills/architect/status.ps1:89:$issues = @()
skills/architect/status.ps1:90:if ($trackerReachable -and $ghJson) { try { $issues = @($ghJson | ConvertFrom-Json) } catch { $issues = @() } }
skills/architect/status.ps1:91:$parentRefs = @($issues | Where-Object { $_.parent } | ForEach-Object { $_.parent.number } | Select-Object -Unique)
skills/architect/status.ps1:92:$trackingIssue = @($issues | Where-Object { $_.state -eq "OPEN" -and $parentRefs -contains $_.number } | Sort-Object number -Descending | Select-Object -First 1)
skills/architect/status.ps1:93:$tracking = ""
skills/architect/status.ps1:94:$subIssues = @()
skills/architect/status.ps1:95:if ($trackingIssue.Count -gt 0) {
skills/architect/status.ps1:96:    $tracking = $trackingIssue[0].number
skills/architect/status.ps1:97:    $subIssues = @($issues | Where-Object { $_.parent -and $_.parent.number -eq $tracking })
skills/architect/status.ps1:98:}
skills/architect/status.ps1:99:$slugs = ArtifactSlugs
skills/architect/status.ps1:100:if (((-not $trackerReachable) -or ($trackerReachable -and -not $tracking)) -and $slugs.Count -eq 0) {
skills/architect/status.ps1:101:    Write-Output "NO ACTIVE FACTORY RUN"
skills/architect/status.ps1:102:    Write-Output "spec: $(NewestSpec)"
skills/architect/status.ps1:103:    exit 0
skills/architect/status.ps1:104:}
skills/architect/status.ps1:105:Write-Output "STATUS TREE spec: $(NewestSpec) branch: $branch"
skills/architect/status.ps1:106:if ($trackerReachable -and $tracking) { Write-Output "tracker: #$tracking" } elseif ($trackerReachable) { Write-Output "tracker: no open run" } else { Write-Output "tracker: unavailable (local view)" }
skills/architect/status.ps1:107:Write-Output "ORCHESTRATOR: local view"
skills/architect/status.ps1:108:$wdCfg = @(Get-ChildItem -LiteralPath (J $root ".architect/tmp") -Filter "wd-*.json")
skills/architect/status.ps1:109:$wdProc = @(Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -match 'watchdog\.(ps1|sh)' })
skills/architect/status.ps1:110:Write-Output "WATCHDOG: process=$($wdProc.Count -gt 0) config=$($wdCfg.Count)"
skills/architect/status.ps1:111:if ($trackerReachable -and $tracking) {
skills/architect/status.ps1:112:    foreach ($issue in $subIssues) {
skills/architect/status.ps1:113:        $slug = Slugify $issue.title
skills/architect/status.ps1:114:        $p = Phase $slug $issue
skills/architect/status.ps1:115:        $extra = ""
skills/architect/status.ps1:116:        if ($p[1] -eq "QUEUED") { $extra = " blocked-by: " + ((OpenBlockerNumbers $issue) -join ",") }
skills/architect/status.ps1:117:        Write-Output "$($p[0]) #$($issue.number) $($issue.title) .architect/wt/$slug-01$extra"
skills/architect/status.ps1:118:        if ($p[1] -eq "BUILDING") { $last = LastCommand $slug; if ($last) { Write-Output $last } }
skills/architect/status.ps1:119:    }
skills/architect/status.ps1:120:} else {
skills/architect/status.ps1:121:    foreach ($slug in $slugs) {
skills/architect/status.ps1:122:        $p = Phase $slug $null
skills/architect/status.ps1:123:        if ($p[1] -in @("BUILDING", "BLOCKED", "JUDGING", "REPORTED")) {
skills/architect/status.ps1:124:            Write-Output "$($p[0]) $slug .architect/wt/$slug-01"
skills/architect/status.ps1:125:            if ($p[1] -eq "BUILDING") { $last = LastCommand $slug; if ($last) { Write-Output $last } }
skills/architect/status.ps1:126:        }
```

Shell tracker section:
```
skills/architect/status.sh:85:gh_json=
skills/architect/status.sh:86:tracker=0
skills/architect/status.sh:87:if command -v gh >/dev/null 2>&1; then
skills/architect/status.sh:88:  if gh_json=$(gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy 2>/dev/null); then
skills/architect/status.sh:89:    tracker=1
skills/architect/status.sh:90:  fi
skills/architect/status.sh:91:fi
skills/architect/status.sh:92:issue_objs=
skills/architect/status.sh:93:tracking=
skills/architect/status.sh:94:if [ "$tracker" -eq 1 ]; then
skills/architect/status.sh:95:  issue_objs=$(printf '%s\n' "$gh_json" | json_objects)
skills/architect/status.sh:96:  parent_refs=' '
skills/architect/status.sh:97:  while IFS= read -r obj; do
skills/architect/status.sh:98:    p=$(parent_number "$obj")
skills/architect/status.sh:99:    [ -n "$p" ] && parent_refs="$parent_refs$p "
skills/architect/status.sh:100:  done <<< "$issue_objs"
skills/architect/status.sh:101:  highest=0
skills/architect/status.sh:102:  while IFS= read -r obj; do
skills/architect/status.sh:103:    num=$(issue_number "$obj")
skills/architect/status.sh:104:    state=$(issue_state "$obj")
skills/architect/status.sh:105:    [ -n "$num" ] || continue
skills/architect/status.sh:106:    [ "$state" = OPEN ] || continue
skills/architect/status.sh:107:    case "$parent_refs" in *" $num "*)
skills/architect/status.sh:108:      if [ "$num" -gt "$highest" ]; then highest=$num; tracking=$num; fi
skills/architect/status.sh:109:      ;;
skills/architect/status.sh:110:    esac
skills/architect/status.sh:111:  done <<< "$issue_objs"
skills/architect/status.sh:112:fi
skills/architect/status.sh:113:slugs=$(artifact_slugs)
skills/architect/status.sh:114:if { [ "$tracker" -eq 0 ] || [ -z "$tracking" ]; } && [ -z "$slugs" ]; then
skills/architect/status.sh:115:  printf 'NO ACTIVE FACTORY RUN\nspec: %s\n' "$(newest_spec)"
skills/architect/status.sh:116:  exit 0
skills/architect/status.sh:117:fi
skills/architect/status.sh:118:printf 'STATUS TREE spec: %s branch: %s\n' "$(newest_spec)" "$branch"
skills/architect/status.sh:119:if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then
skills/architect/status.sh:120:  printf 'tracker: #%s\n' "$tracking"
skills/architect/status.sh:121:elif [ "$tracker" -eq 1 ]; then
skills/architect/status.sh:122:  printf 'tracker: no open run\n'
skills/architect/status.sh:123:else
skills/architect/status.sh:124:  printf 'tracker: unavailable (local view)\n'
skills/architect/status.sh:125:fi
skills/architect/status.sh:126:printf 'ORCHESTRATOR: local view\n'
skills/architect/status.sh:127:cfg=$(find "$root/.architect/tmp" -maxdepth 1 -type f -name 'wd-*.json' 2>/dev/null | wc -l | tr -d ' ')
skills/architect/status.sh:128:ps -eo args= 2>/dev/null | grep 'watchdog\.\(ps1\|sh\)' >/dev/null && proc=True || proc=False
skills/architect/status.sh:129:printf 'WATCHDOG: process=%s config=%s\n' "$proc" "$cfg"
skills/architect/status.sh:130:if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then
skills/architect/status.sh:131:  while IFS= read -r obj; do
skills/architect/status.sh:132:    [ "$(parent_number "$obj")" = "$tracking" ] || continue
skills/architect/status.sh:133:    num=$(issue_number "$obj")
skills/architect/status.sh:134:    title=$(issue_title "$obj")
skills/architect/status.sh:135:    state=$(issue_state "$obj")
skills/architect/status.sh:136:    blockers=$(open_blockers "$obj")
skills/architect/status.sh:137:    [ -n "$num" ] || continue
skills/architect/status.sh:138:    slug=$(slugify "$title"); set -- $(phase "$slug" "$state" "$blockers")
skills/architect/status.sh:139:    extra=; [ "$2" = QUEUED ] && extra=" blocked-by: $blockers"
skills/architect/status.sh:140:    printf '%s #%s %s .architect/wt/%s-01%s\n' "$1" "$num" "$title" "$slug" "$extra"
skills/architect/status.sh:141:    [ "$2" = BUILDING ] && last_command "$slug"
skills/architect/status.sh:142:  done <<< "$issue_objs"
skills/architect/status.sh:143:else
skills/architect/status.sh:144:  for slug in $slugs; do
```

Parity statement:
```
Behavioral difference found: none. Both scripts make one all-state gh call, compute open tracking candidates from referenced parent numbers, choose the highest-numbered candidate, render only sub-issues for that parent, filter QUEUED blockers to OPEN blockers, and use tracker: no open run for reachable-empty/no-candidate local views.
```

ST5 / SS1

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

ST5 / SS2

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

ST5 / SS3 fixture create

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
'FIXTURE_READY'
```
Output:
```
FIXTURE_READY
```

ST5 / SS3 root1

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

ST5 / SS3 root2

Command:
```
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root2
```
Output:
```
NO ACTIVE FACTORY RUN
spec: unknown
```

ST5 / SS4

Command:
```
$out = & powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1 | Out-String
([Text.Encoding]::UTF8.GetBytes($out) -contains 27)
```
Output:
```
False
```

ST5 / SS5

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
4
2
SS5_OK
```

ST5 / SS6

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

TOUCH SET

Command:
```
git status --short
```
Output:
```
 M docs/jobs/status-scripts-01.md
 M skills/architect/status.ps1
 M skills/architect/status.sh
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
