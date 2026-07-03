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

## Re-architecture session

FIRST-ACTION

Command:
```powershell
Select-String -Path docs/checks/status-tracker.md -Pattern 'ST6|ST7|ST8'
Select-String -Path docs/spec/status-tree.md -Pattern 'STATUS_GH_STUB'
```
Output:
```text
docs\checks\status-tracker.md:42:## ST6-ST8 — third-judgment re-architecture addendum (pinned jq, stub seam)
docs\checks\status-tracker.md:47:### ST6 — the pinned jq expression appears VERBATIM in both scripts
docs\checks\status-tracker.md:52:### ST7 — stub-seam render matches the live-verified sample
docs\checks\status-tracker.md:63:### ST8 — stray-file guard
docs\spec\status-tree.md:67:Testing seam: if env var `STATUS_GH_STUB` names a readable file, both
```

Implementation summary:
```text
Replaced duplicated tracker JSON graph logic in both scripts with the pinned gh --jq expression.
Added STATUS_GH_STUB in both scripts.
Changed artifact row discovery to require an actual .architect/wt/<slug>-01 directory.
Updated the validator to require STATUS_GH_STUB, --jq, tracker: no open run, and blockedBy.nodes markers.
```

SS1

Command:
```powershell
Test-Path skills/architect/status.ps1
Test-Path skills/architect/status.sh
(Select-String -Path skills/architect/status.sh -Pattern 'NO ACTIVE FACTORY RUN').Count
(Select-String -Path skills/architect/status.ps1 -Pattern 'NO ACTIVE FACTORY RUN').Count
(Get-Content skills/architect/status.sh -TotalCount 1)
```
Output:
```text
True
True
1
1
#!/usr/bin/env bash
```

SS2

Command:
```powershell
$e = $null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path 'skills/architect/status.ps1').Path, [ref]$null, [ref]$e) | Out-Null
if ($e.Count -eq 0) { 'SS2_OK' } else { $e }
```
Output:
```text
SS2_OK
```

SS3

Command:
```powershell
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root2
```
Output:
```text
STATUS TREE spec: demo.md branch: unknown
tracker: unavailable (local view)
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
! demo-blocked .architect/wt/demo-blocked-01
● demo-build .architect/wt/demo-build-01
    last: pytest -q age: unknown
◐ demo-judge .architect/wt/demo-judge-01
▣ demo-rep .architect/wt/demo-rep-01

NO ACTIVE FACTORY RUN
spec: unknown
```

SS4

Command:
```powershell
$out = & powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1 | Out-String
([Text.Encoding]::UTF8.GetBytes($out) -contains 27)
```
Output:
```text
False
```

SS5

Command:
```powershell
(Select-String -Path tests/validate_skills.py -Pattern '"status.ps1"').Count
(Select-String -Path tests/validate_skills.py -Pattern '"status.sh"').Count
(Select-String -Path tests/validate_skills.py -Pattern 'check_status_contract').Count
$env:UV_CACHE_DIR='.architect/tmp/uv-cache-st'; uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('SS5_OK')"
```
Output:
```text
2
4
2
SS5_OK
```

SS6

Command:
```powershell
Select-String -Path skills/architect/status.ps1,skills/architect/status.sh -Pattern 'Stop-Process|taskkill|Remove-Item|rm -|git (add|commit|push)'
```
Output:
```text
```

ST1-ST3

Command:
```powershell
(Select-String -Path skills/architect/status.ps1 -Pattern '--state all').Count
(Select-String -Path skills/architect/status.sh -Pattern '--state all').Count
(Select-String -Path skills/architect/status.ps1,skills/architect/status.sh -Pattern 'blockedBy').Count
(Select-String -Path skills/architect/status.ps1 -Pattern 'parent').Count
(Select-String -Path skills/architect/status.sh -Pattern 'parent').Count
(Select-String -Path skills/architect/status.ps1 -Pattern 'tracker: no open run').Count
(Select-String -Path skills/architect/status.sh -Pattern 'tracker: no open run').Count
```
Output:
```text
1
1
4
2
2
1
1
```

ST2/ST3 shell quote

Command:
```powershell
Select-String -Path skills/architect/status.sh -Pattern 'jq_expr=|gh issue list|TRACK|SUB|NO ACTIVE FACTORY RUN|tracker: no open run' | ForEach-Object { "skills/architect/status.sh:$($_.LineNumber):$($_.Line)" }
```
Output:
```text
skills/architect/status.sh:64:  jq_expr='. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
skills/architect/status.sh:70:  gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq "$jq_expr"
skills/architect/status.sh:82:    [ "$kind" = TRACK ] && tracking=$num
skills/architect/status.sh:87:  printf 'NO ACTIVE FACTORY RUN\nspec: %s\n' "$(newest_spec)"
skills/architect/status.sh:94:  printf 'tracker: no open run\n'
skills/architect/status.sh:104:    [ "$kind" = SUB ] || continue
```

ST4

PowerShell tracker section:
```text
skills/architect/status.ps1:69:function TrackerLines() {
skills/architect/status.ps1:70:    $PinnedJq = '. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
skills/architect/status.ps1:71:    if ($env:STATUS_GH_STUB -and (Test-Path -LiteralPath $env:STATUS_GH_STUB -PathType Leaf)) {
skills/architect/status.ps1:72:        return @{ Reachable = $true; Lines = @(Get-Content -LiteralPath $env:STATUS_GH_STUB) }
skills/architect/status.ps1:76:        $out = & gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq $PinnedJq 2>$null
skills/architect/status.ps1:93:    foreach ($line in $trackerData.Lines) {
skills/architect/status.ps1:95:        $parts = $line -split "`t", 5
skills/architect/status.ps1:96:        if ($parts[0] -eq "TRACK" -and $parts.Count -ge 2) { $tracking = $parts[1]; continue }
skills/architect/status.ps1:97:        if ($parts[0] -eq "SUB" -and $parts.Count -ge 5) {
```

Shell tracker section:
```text
skills/architect/status.sh:63:tracker_lines(){
skills/architect/status.sh:64:  jq_expr='. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
skills/architect/status.sh:65:  if [ -n "${STATUS_GH_STUB:-}" ] && [ -r "$STATUS_GH_STUB" ]; then
skills/architect/status.sh:70:  gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq "$jq_expr"
skills/architect/status.sh:78:if tracker_tsv=$(tracker_lines 2>/dev/null); then tracker=1; fi
skills/architect/status.sh:81:  while IFS="$(printf '\t')" read -r kind num state blockers title; do
skills/architect/status.sh:82:    [ "$kind" = TRACK ] && tracking=$num
skills/architect/status.sh:103:  while IFS="$(printf '\t')" read -r kind num state blockers title; do
skills/architect/status.sh:104:    [ "$kind" = SUB ] || continue
```

Parity statement:
```text
Behavioral difference found: none in tracker-mode graph logic. Both scripts delegate the entire graph decision to the same pinned gh --jq expression, use STATUS_GH_STUB when readable, and only parse TRACK/SUB/NOOPENRUN TSV lines.
```

ST5

Output:
```text
SS1-SS6 re-run above: PASS.
```

ST6

Command:
```powershell
$spec = '. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
$ps = (Select-String -Path skills/architect/status.ps1 -Pattern '\$PinnedJq = ''(.*)''' | Select-Object -First 1).Matches[0].Groups[1].Value
$sh = (Select-String -Path skills/architect/status.sh -Pattern "jq_expr='(.*)'" | Select-Object -First 1).Matches[0].Groups[1].Value
"ps1 IDENTICAL: $($ps -ceq $spec)"
"sh IDENTICAL: $($sh -ceq $spec)"
```
Output:
```text
ps1 IDENTICAL: True
sh IDENTICAL: True
```

ST7

Command:
```powershell
$env:STATUS_GH_STUB = (Resolve-Path '.architect/tmp/stfix/stub.tsv').Path
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1
Remove-Item Env:STATUS_GH_STUB
$env:STATUS_GH_STUB = (Resolve-Path '.architect/tmp/stfix/noopen.tsv').Path
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root2
Remove-Item Env:STATUS_GH_STUB
```
Output:
```text
STATUS TREE spec: demo.md branch: unknown
tracker: #43
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
⊘ #46 status: docs closure .architect/wt/status-docs-closure-01 blocked-by: 44
✓ #45 status: skill wiring (10-line cap) .architect/wt/status-skill-wiring-10-line-cap-01
○ #44 status: scripts + validator contract .architect/wt/status-scripts-validator-contract-01

NO ACTIVE FACTORY RUN
spec: unknown
```

NOOPENRUN with artifacts

Command:
```powershell
$env:STATUS_GH_STUB = (Resolve-Path '.architect/tmp/stfix/noopen.tsv').Path
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1
Remove-Item Env:STATUS_GH_STUB
```
Output:
```text
STATUS TREE spec: demo.md branch: unknown
tracker: no open run
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
! demo-blocked .architect/wt/demo-blocked-01
● demo-build .architect/wt/demo-build-01
    last: pytest -q age: unknown
◐ demo-judge .architect/wt/demo-judge-01
▣ demo-rep .architect/wt/demo-rep-01
```

ST8

Command:
```powershell
Set-Content -LiteralPath '.architect/tmp/stfix/root1/.architect/wt/ghost-01.events.jsonl' -Encoding UTF8 -Value '{"command":"ghost"}'
$env:STATUS_GH_STUB = (Resolve-Path '.architect/tmp/stfix/stub.tsv').Path
$out = powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1
$out
"contains ghost: $($out -match 'ghost')"
Remove-Item Env:STATUS_GH_STUB
```
Output:
```text
STATUS TREE spec: demo.md branch: unknown
tracker: #43
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
⊘ #46 status: docs closure .architect/wt/status-docs-closure-01 blocked-by: 44
✓ #45 status: skill wiring (10-line cap) .architect/wt/status-skill-wiring-10-line-cap-01
○ #44 status: scripts + validator contract .architect/wt/status-scripts-validator-contract-01
contains ghost:
```

Validator

Command:
```powershell
$env:UV_CACHE_DIR='.architect/tmp/uv-cache-st'; uv run --no-project python tests/validate_skills.py
```
Output:
```text
OK - 2 skills validated, v4 contracts clean
```

Old duplicated graph parser scan

Command:
```powershell
Select-String -Path skills/architect/status.ps1,skills/architect/status.sh -Pattern 'ConvertFrom-Json|parentRefs|json_objects|parent_number|open_blockers|issue_number\('
```
Output:
```text
```

Touch-set and frozen-check guard

Command:
```powershell
git diff --name-only -- docs/checks
git status --short
```
Output:
```text
 M skills/architect/status.ps1
 M skills/architect/status.sh
 M tests/validate_skills.py
```

Bash execution note:
```text
Not run in this session by instruction: PowerShell + native git only. The shell script was statically checked for the identical pinned jq expression, STATUS_GH_STUB seam, TSV-only parsing, no old graph parser helpers, and read-only command guard.
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

## Final fix session

First action ruling anchor:

Command:
```powershell
Select-String -Path docs/jobs/status-scripts-rulings.md -Pattern 'fourth judgment' -SimpleMatch
```
Output:
```text
docs\jobs\status-scripts-rulings.md:39:- 2026-07-03 fourth judgment FAIL fired the self-imposed rail; factory
```

Changes made:
- `skills/architect/status.ps1`: phase glyphs are ANSI-colored only when `[Console]::IsOutputRedirected` is false and `NO_COLOR` is unset; the `gh issue list` call is wrapped in `Push-Location -LiteralPath $root` / `Pop-Location`.
- `skills/architect/status.sh`: phase glyphs are ANSI-colored only when `[ -t 1 ]` and `NO_COLOR` is unset; the `gh issue list` call runs in `(cd "$root" && ...)`.
- The pinned `--jq` expression was not changed.

Fixture refresh:

Command:
```powershell
New-Item -ItemType Directory -Force -Path @(
  '.architect/tmp/stfix/root1/.architect/wt/demo-build-01',
  '.architect/tmp/stfix/root1/.architect/wt/demo-blocked-01/docs/jobs',
  '.architect/tmp/stfix/root1/.architect/wt/demo-judge-01/docs/jobs',
  '.architect/tmp/stfix/root1/.architect/wt/demo-rep-01/docs/jobs',
  '.architect/tmp/stfix/root1/docs/spec',
  '.architect/tmp/stfix/root2'
) | Out-Null
Set-Content -LiteralPath '.architect/tmp/stfix/root1/.architect/wt/demo-build-01.events.jsonl' -Value '{"command":"pytest -q"}' -Encoding UTF8
Set-Content -LiteralPath '.architect/tmp/stfix/root1/.architect/wt/demo-blocked-01/docs/jobs/demo-blocked-01.md' -Value "x`nSTATUS: BLOCKED (x)" -Encoding UTF8
Set-Content -LiteralPath '.architect/tmp/stfix/root1/.architect/wt/demo-judge-01/docs/jobs/demo-judge-01.md' -Value "x`nSTATUS: COMPLETE" -Encoding UTF8
Set-Content -LiteralPath '.architect/tmp/stfix/root1/.architect/wt/demo-judge-01.judge.md' -Value 'judge' -Encoding UTF8
Set-Content -LiteralPath '.architect/tmp/stfix/root1/.architect/wt/demo-rep-01/docs/jobs/demo-rep-01.md' -Value "x`nSTATUS: COMPLETE" -Encoding UTF8
Set-Content -LiteralPath '.architect/tmp/stfix/root1/docs/spec/demo.md' -Value 'demo' -Encoding UTF8
'FIXTURE_OK'
```
Output:
```text
FIXTURE_OK
```

SS1:

Command:
```powershell
Test-Path skills/architect/status.ps1
Test-Path skills/architect/status.sh
(Select-String -Path skills/architect/status.sh -Pattern 'NO ACTIVE FACTORY RUN').Count
(Select-String -Path skills/architect/status.ps1 -Pattern 'NO ACTIVE FACTORY RUN').Count
(Get-Content skills/architect/status.sh -TotalCount 1)
```
Output:
```text
True
True
1
1
#!/usr/bin/env bash
```

SS2:

Command:
```powershell
$e = $null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path 'skills/architect/status.ps1').Path, [ref]$null, [ref]$e) | Out-Null
if ($e.Count -eq 0) { 'SS2_OK' } else { $e }
```
Output:
```text
SS2_OK
```

SS3:

Command:
```powershell
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root2
```
Output:
```text
STATUS TREE spec: demo.md branch: unknown
tracker: unavailable (local view)
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
! demo-blocked .architect/wt/demo-blocked-01
● demo-build .architect/wt/demo-build-01
    last: pytest -q age: unknown
◐ demo-judge .architect/wt/demo-judge-01
▣ demo-rep .architect/wt/demo-rep-01
NO ACTIVE FACTORY RUN
spec: unknown
```

SS4:

Command:
```powershell
$out = & powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1 | Out-String
([Text.Encoding]::UTF8.GetBytes($out) -contains 27)
```
Output:
```text
False
```

status.sh piped no-ESC remains composite-side under the PowerShell/native-git-only boundary here; static evidence is the `[ -t 1 ]` guard in `color_glyph`.

SS5:

Command:
```powershell
(Select-String -Path tests/validate_skills.py -Pattern '"status.ps1"').Count
(Select-String -Path tests/validate_skills.py -Pattern '"status.sh"').Count
(Select-String -Path tests/validate_skills.py -Pattern 'check_status_contract').Count
$env:UV_CACHE_DIR='.architect/tmp/uv-cache-st'; uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('SS5_OK')"
```
Output:
```text
2
4
2
SS5_OK
```

SS6:

Command:
```powershell
Select-String -Path skills/architect/status.ps1,skills/architect/status.sh -Pattern 'Stop-Process|taskkill|Remove-Item|rm -|git (add|commit|push)'
```
Output:
```text
```

ST1:

Command:
```powershell
(Select-String -Path skills/architect/status.ps1 -Pattern '--state all').Count
(Select-String -Path skills/architect/status.sh -Pattern '--state all').Count
(Select-String -Path skills/architect/status.ps1,skills/architect/status.sh -Pattern 'blockedBy').Count
```
Output:
```text
1
1
4
```

ST2:

Command:
```powershell
(Select-String -Path skills/architect/status.ps1 -Pattern 'parent').Count
(Select-String -Path skills/architect/status.sh -Pattern 'parent').Count
Select-String -Path skills/architect/status.sh -Pattern 'parent|TRACK|SUB|tracking' | ForEach-Object { "$($_.Path):$($_.LineNumber):$($_.Line)" }
```
Output:
```text
2
2
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:32:  tail_text "$1" | sed 's/^\xEF\xBB\xBF//' | awk '/^STATUS:/{sub(/^STATUS:[[:space:]]*/,""); s=$0} END{print s}'
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:64:tracker_lines(){
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:65:  jq_expr='. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:71:  (cd "$root" && gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq "$jq_expr")
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:77:tracker=0
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:78:tracker_tsv=
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:79:if tracker_tsv=$(tracker_lines 2>/dev/null); then tracker=1; fi
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:80:tracking=
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:81:if [ "$tracker" -eq 1 ]; then
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:83:    [ "$kind" = TRACK ] && tracking=$num
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:84:  done <<< "$tracker_tsv"
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:87:if { [ "$tracker" -eq 0 ] || [ -z "$tracking" ]; } && [ -z "$slugs" ]; then
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:92:if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:93:  printf 'tracker: #%s\n' "$tracking"
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:94:elif [ "$tracker" -eq 1 ]; then
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:95:  printf 'tracker: no open run\n'
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:97:  printf 'tracker: unavailable (local view)\n'
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:103:if [ "$tracker" -eq 1 ] && [ -n "$tracking" ]; then
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:105:    [ "$kind" = SUB ] || continue
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:110:  done <<< "$tracker_tsv"
```

ST3:

Command:
```powershell
(Select-String -Path skills/architect/status.ps1 -Pattern 'tracker: no open run').Count
(Select-String -Path skills/architect/status.sh -Pattern 'tracker: no open run').Count
Select-String -Path skills/architect/status.sh -Pattern 'NOOPENRUN|NO ACTIVE FACTORY RUN|tracker: no open run|\[ -z "\$tracking" \]' | ForEach-Object { "$($_.Path):$($_.LineNumber):$($_.Line)" }
```
Output:
```text
1
1
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:65:  jq_expr='. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:87:if { [ "$tracker" -eq 0 ] || [ -z "$tracking" ]; } && [ -z "$slugs" ]; then
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:88:  printf 'NO ACTIVE FACTORY RUN\nspec: %s\n' "$(newest_spec)"
C:\Users\danhm\architect-loop\.architect\wt\status-scripts-01\skills\architect\status.sh:95:  printf 'tracker: no open run\n'
```

ST4:

Command:
```powershell
$i=0; Get-Content skills/architect/status.ps1 | ForEach-Object { $i++; if ($i -ge 69 -and $i -le 99) { 'skills/architect/status.ps1:{0}:{1}' -f $i, $_ } }
$i=0; Get-Content skills/architect/status.sh | ForEach-Object { $i++; if ($i -ge 64 -and $i -le 84) { 'skills/architect/status.sh:{0}:{1}' -f $i, $_ } }
```
Output:
```text
skills/architect/status.ps1:69:function TrackerLines() {
skills/architect/status.ps1:70:    $PinnedJq = '. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
skills/architect/status.ps1:71:    if ($env:STATUS_GH_STUB -and (Test-Path -LiteralPath $env:STATUS_GH_STUB -PathType Leaf)) {
skills/architect/status.ps1:72:        return @{ Reachable = $true; Lines = @(Get-Content -LiteralPath $env:STATUS_GH_STUB) }
skills/architect/status.ps1:73:    }
skills/architect/status.ps1:74:    if (-not (Get-Command gh)) { return @{ Reachable = $false; Lines = @() } }
skills/architect/status.ps1:75:    try {
skills/architect/status.ps1:76:        Push-Location -LiteralPath $root
skills/architect/status.ps1:77:        try { $out = & gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq $PinnedJq 2>$null }
skills/architect/status.ps1:78:        finally { Pop-Location }
skills/architect/status.ps1:79:        return @{ Reachable = ($LASTEXITCODE -eq 0); Lines = @($out) }
skills/architect/status.ps1:80:    } catch {
skills/architect/status.ps1:81:        return @{ Reachable = $false; Lines = @() }
skills/architect/status.ps1:82:    }
skills/architect/status.ps1:83:}
skills/architect/status.ps1:84:
skills/architect/status.ps1:85:$root = [System.IO.Path]::GetFullPath($RepoRoot)
skills/architect/status.ps1:86:if (-not (Test-Path -LiteralPath $root -PathType Container)) { Write-Output "unreadable repo: $RepoRoot"; exit 1 }
skills/architect/status.ps1:87:$useColor = (-not [Console]::IsOutputRedirected) -and (-not $env:NO_COLOR)
skills/architect/status.ps1:88:function ColorGlyph($Glyph, $Code) {
skills/architect/status.ps1:89:    if (-not $useColor) { return $Glyph }
skills/architect/status.ps1:90:    $esc = [char]27
skills/architect/status.ps1:91:    return "$esc[$Code" + "m$Glyph$esc[0m"
skills/architect/status.ps1:92:}
skills/architect/status.ps1:93:$G = @{
skills/architect/status.ps1:94:    Merged = ColorGlyph ([char]0x2713) "32"
skills/architect/status.ps1:95:    Judging = ColorGlyph ([char]0x25D0) "36"
skills/architect/status.ps1:96:    Blocked = ColorGlyph "!" "31"
skills/architect/status.ps1:97:    Reported = ColorGlyph ([char]0x25A3) "35"
skills/architect/status.ps1:98:    Building = ColorGlyph ([char]0x25CF) "34"
skills/architect/status.ps1:99:    Queued = ColorGlyph ([char]0x2298) "33"
skills/architect/status.sh:64:tracker_lines(){
skills/architect/status.sh:65:  jq_expr='. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
skills/architect/status.sh:66:  if [ -n "${STATUS_GH_STUB:-}" ] && [ -r "$STATUS_GH_STUB" ]; then
skills/architect/status.sh:67:    cat "$STATUS_GH_STUB"
skills/architect/status.sh:68:    return 0
skills/architect/status.sh:69:  fi
skills/architect/status.sh:70:  command -v gh >/dev/null 2>&1 || return 1
skills/architect/status.sh:71:  (cd "$root" && gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq "$jq_expr")
skills/architect/status.sh:72:}
skills/architect/status.sh:73:
skills/architect/status.sh:74:branch=
skills/architect/status.sh:75:[ -e "$root/.git" ] && branch=$(git -C "$root" branch --show-current 2>/dev/null || true)
skills/architect/status.sh:76:[ -n "$branch" ] || branch=unknown
skills/architect/status.sh:77:tracker=0
skills/architect/status.sh:78:tracker_tsv=
skills/architect/status.sh:79:if tracker_tsv=$(tracker_lines 2>/dev/null); then tracker=1; fi
skills/architect/status.sh:80:tracking=
skills/architect/status.sh:81:if [ "$tracker" -eq 1 ]; then
skills/architect/status.sh:82:  while IFS="$(printf '\t')" read -r kind num state blockers title; do
skills/architect/status.sh:83:    [ "$kind" = TRACK ] && tracking=$num
skills/architect/status.sh:84:  done <<< "$tracker_tsv"
```

Behavioral difference found: none in tracker-mode graph logic. Both scripts still delegate the graph decision to the same pinned `gh --jq` expression and parse only TSV lines; both now run real `gh` from the target repo root.

ST5:

SS1-SS6 re-run above: PASS.

ST6:

Command:
```powershell
$spec = (Select-String -Path docs/spec/status-tree.md -Pattern "gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq '(.*)'" | Select-Object -First 1).Matches[0].Groups[1].Value
$ps = (Select-String -Path skills/architect/status.ps1 -Pattern '\$PinnedJq = ''(.*)''' | Select-Object -First 1).Matches[0].Groups[1].Value
$sh = (Select-String -Path skills/architect/status.sh -Pattern "jq_expr='(.*)'" | Select-Object -First 1).Matches[0].Groups[1].Value
'SPEC:'
$spec
'PS1:'
$ps
'SH:'
$sh
if ($spec -eq $ps -and $ps -eq $sh) { 'IDENTICAL' } else { 'DIFF' }
```
Output:
```text
SPEC:
. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end
PS1:
. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end
SH:
. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end
IDENTICAL
```

ST7:

Command:
```powershell
Set-Content -LiteralPath '.architect/tmp/stfix/stub.tsv' -Value @(
  "TRACK`t43",
  "SUB`t46`tOPEN`t44`tstatus: docs closure",
  "SUB`t45`tCLOSED`t`tstatus: skill wiring (10-line cap)",
  "SUB`t44`tOPEN`t`tstatus: scripts + validator contract"
) -Encoding UTF8
Set-Content -LiteralPath '.architect/tmp/stfix/noopen.tsv' -Value 'NOOPENRUN' -Encoding UTF8
$env:STATUS_GH_STUB = (Resolve-Path '.architect/tmp/stfix/stub.tsv').Path
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1
$env:STATUS_GH_STUB = (Resolve-Path '.architect/tmp/stfix/noopen.tsv').Path
powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root2
$env:STATUS_GH_STUB = $null
```
Output:
```text
STATUS TREE spec: demo.md branch: unknown
tracker: #43
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
⊘ #46 status: docs closure .architect/wt/status-docs-closure-01 blocked-by: 44
✓ #45 status: skill wiring (10-line cap) .architect/wt/status-skill-wiring-10-line-cap-01
○ #44 status: scripts + validator contract .architect/wt/status-scripts-validator-contract-01
NO ACTIVE FACTORY RUN
spec: unknown
```

ST8:

Command:
```powershell
Set-Content -LiteralPath '.architect/tmp/stfix/root1/.architect/wt/ghost-01.events.jsonl' -Value '{"command":"ghost"}' -Encoding UTF8
$env:STATUS_GH_STUB = (Resolve-Path '.architect/tmp/stfix/stub.tsv').Path
$out = powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1
$out
'contains ghost: ' + (($out | Out-String) -match 'ghost')
$env:STATUS_GH_STUB = $null
```
Output:
```text
STATUS TREE spec: demo.md branch: unknown
tracker: #43
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
⊘ #46 status: docs closure .architect/wt/status-docs-closure-01 blocked-by: 44
✓ #45 status: skill wiring (10-line cap) .architect/wt/status-skill-wiring-10-line-cap-01
○ #44 status: scripts + validator contract .architect/wt/status-scripts-validator-contract-01
contains ghost: False
```

Full validator:

Command:
```powershell
$env:UV_CACHE_DIR='.architect/tmp/uv-cache-st'; uv run --no-project python tests/validate_skills.py
```
Output:
```text
OK - 2 skills validated, v4 contracts clean
```

Final diff/status:

Command:
```powershell
git status --short
```
Output:
```text
 M docs/jobs/status-scripts-01.md
 M skills/architect/status.ps1
 M skills/architect/status.sh
```

STATUS: COMPLETE
