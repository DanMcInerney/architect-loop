# tracker-status-01

## Phase 0

| Item | Record |
|---|---|
| Plan | Verify freeze commit and check file; read `docs/checks/tracker-status.md`, `docs/spec/tracker-markdown.md`, `skills/architect/status.ps1`, `skills/architect/status.sh`, `docs/jobs/status-scripts-rulings.md`; add repo-root `.architect/config` tracker mode read; add markdown TSV emitter from first frontmatter block; preserve gh `STATUS_GH_STUB` path and renderer; run TS1-TS6 sequentially. |
| Disagreements with issue/spec | None. |
| Checked before sound | `docs/checks/tracker-status.md`; `docs/spec/tracker-markdown.md`; `skills/architect/status.ps1`; `skills/architect/status.sh`; `docs/jobs/status-scripts-rulings.md`. |
| Mirror | MIRROR: ORCHESTRATOR |

### First Action: `git log -1 --oneline`

```text
5aa8422 re-freeze: stress-test amendments (TS3 pinned, TK4 decoupled, TA2 operation-level, TA3 behavioral)
```

### First Action: `Test-Path -LiteralPath 'docs/checks/tracker-status.md'; if (Test-Path -LiteralPath 'docs/checks/tracker-status.md') { Get-Item -LiteralPath 'docs/checks/tracker-status.md' | Select-Object -ExpandProperty FullName }`

```text
True
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\docs\checks\tracker-status.md
```

## TS1

### Command

```powershell
$base = Join-Path (Get-Location).Path '.architect/tmp/tmfix'
foreach ($r in 'root1','root2','root3') {
  New-Item -ItemType Directory -Force -Path (Join-Path $base "$r/.architect") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "$r/docs/issues") | Out-Null
  Set-Content -LiteralPath (Join-Path $base "$r/.architect/config") -Value 'tracker = markdown' -Encoding UTF8
}
New-Item -ItemType Directory -Force -Path (Join-Path $base 'root1/docs/spec') | Out-Null
Set-Content -LiteralPath (Join-Path $base 'root1/docs/spec/demo.md') -Value 'demo' -Encoding UTF8
function Write-Issue($root, $file, $issue, $title, $state, $parent, $blocked) {
  $content = @("---", "issue: $issue", "title: $title", "state: $state", "parent: $parent", "blocked-by: $blocked", "---", "", "body", "", "## Comments")
  Set-Content -LiteralPath (Join-Path $root "docs/issues/$file") -Value $content -Encoding UTF8
}
$root1 = Join-Path $base 'root1'
Write-Issue $root1 '003-old-run.md' 3 'old run' 'OPEN' 'none' 'none'
Write-Issue $root1 '004-old-child.md' 4 'old child' 'CLOSED' '3' 'none'
Write-Issue $root1 '007-current-run.md' 7 'current run' 'OPEN' 'none' 'none'
Write-Issue $root1 '008-done-job.md' 8 'done job' 'CLOSED' '7' 'none'
Write-Issue $root1 '009-blocked-job.md' 9 'blocked job' 'OPEN' '7' '8, 10'
Write-Issue $root1 '010-ready-job.md' 10 'ready job' 'OPEN' '7' 'none'
$root3 = Join-Path $base 'root3'
Write-Issue $root3 '007-current-run.md' 7 'current run' 'CLOSED' 'none' 'none'
Write-Issue $root3 '008-done-job.md' 8 'done job' 'CLOSED' '7' 'none'
Get-ChildItem -LiteralPath $base -Recurse -File | ForEach-Object { $_.FullName.Substring($base.Length + 1).Replace('\','/') } | Sort-Object
```

### Output

```text
root1/.architect/config
root1/docs/issues/003-old-run.md
root1/docs/issues/004-old-child.md
root1/docs/issues/007-current-run.md
root1/docs/issues/008-done-job.md
root1/docs/issues/009-blocked-job.md
root1/docs/issues/010-ready-job.md
root1/docs/spec/demo.md
root2/.architect/config
root3/.architect/config
root3/docs/issues/007-current-run.md
root3/docs/issues/008-done-job.md
```

## TS2

### Command

```powershell
.\skills\architect\status.ps1 -RepoRoot .architect/tmp/tmfix/root1
```

### Output

```text
STATUS TREE spec: demo.md branch: unknown
tracker: #7
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
✓ #8 done job .architect/wt/done-job-01
⊘ #9 blocked job .architect/wt/blocked-job-01 blocked-by: 10
○ #10 ready job .architect/wt/ready-job-01
```

## TS3

### Command

```powershell
.\skills\architect\status.ps1 -RepoRoot .architect/tmp/tmfix/root2
```

### Output

```text
NO ACTIVE FACTORY RUN
spec: unknown
```

### Command

```powershell
.\skills\architect\status.ps1 -RepoRoot .architect/tmp/tmfix/root3
```

### Output

```text
NO ACTIVE FACTORY RUN
spec: unknown
```

## TS4

### Command

```powershell
$root4 = Join-Path (Get-Location).Path '.architect/tmp/tmfix/root4'
New-Item -ItemType Directory -Force -Path (Join-Path $root4 'docs/spec') | Out-Null
Set-Content -LiteralPath (Join-Path $root4 'docs/spec/demo.md') -Value 'demo' -Encoding UTF8
$stub = Join-Path (Get-Location).Path '.architect/tmp/tmfix/gh-stub.tsv'
Set-Content -LiteralPath $stub -Value @("TRACK`t43", "SUB`t44`tCLOSED`t`tstatus done", "SUB`t45`tOPEN`t44`tstatus queued", "SUB`t46`tOPEN`t`tstatus ready") -Encoding UTF8
Get-Content -LiteralPath $stub
```

### Output

```text
TRACK	43
SUB	44	CLOSED		status done
SUB	45	OPEN	44	status queued
SUB	46	OPEN		status ready
```

### Command

```powershell
$env:STATUS_GH_STUB = (Resolve-Path '.architect/tmp/tmfix/gh-stub.tsv').Path
.\skills\architect\status.ps1 -RepoRoot .architect/tmp/tmfix/root4
Remove-Item Env:STATUS_GH_STUB
```

### Output

```text
STATUS TREE spec: demo.md branch: unknown
tracker: #43
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
✓ #44 status done .architect/wt/status-done-01
⊘ #45 status queued .architect/wt/status-queued-01 blocked-by: 44
○ #46 status ready .architect/wt/status-ready-01
```

## TS5

### Command

```powershell
$out = Join-Path (Get-Location).Path '.architect/tmp/tmfix/piped-root1.txt'
.\skills\architect\status.ps1 -RepoRoot .architect/tmp/tmfix/root1 > $out
[System.IO.File]::ReadAllBytes($out) -contains 27
```

### Output

```text
False
```

### Command

```powershell
$errors=$null
[System.Management.Automation.PSParser]::Tokenize((Get-Content -LiteralPath 'skills/architect/status.ps1' -Raw), [ref]$errors) > $null
if ($errors) { $errors | ForEach-Object { $_.Message } } else { 'OK' }
```

### Output

```text
OK
```

### Command

```powershell
$ps1 = (Get-Content -LiteralPath 'skills/architect/status.ps1' | Where-Object { $_.Trim() -ne '' }).Count
$sh = (Get-Content -LiteralPath 'skills/architect/status.sh' | Where-Object { $_.Trim() -ne '' }).Count
"skills/architect/status.ps1:$ps1"
"skills/architect/status.sh:$sh"
```

### Output

```text
skills/architect/status.ps1:113
skills/architect/status.sh:78
```

## TS6

### Command

```powershell
Select-String -Path 'skills/architect/status.sh' -Pattern 'tracker_mode|tracker\[\[:space:\]\]|fm\(\)|issue|title|state|parent|blocked-by|037|tr ''\\t''' | ForEach-Object { "$($_.Path):$($_.LineNumber):$($_.Line)" }
```

### Output

```text
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:19:phase(){ slug=$1; state=${2:-}; blockers=${3:-}; [ "$state" = CLOSED ] && { printf '%s MERGED' "$g_merged"; return; }; [ "$state" = OPEN ] && [ -n "$blockers" ] && { printf '%s QUEUED' "$g_queued"; return; }; rep=$(report_path "$slug"); judge=$(find "$root/.architect/wt" -maxdepth 1 -type f -name "$slug-01.judge*.md" 2>/dev/null | head -n 1); [ -f "$rep" ] && [ -n "$judge" ] && { printf '%s JUDGING' "$g_judging"; return; }; st=$(status_line "$rep"); case "$st" in BLOCKED*) printf '%s BLOCKED' "$g_blocked"; return;; esac; [ -f "$rep" ] && { printf '%s REPORTED' "$g_reported"; return; }; [ -d "$root/.architect/wt/$slug-01" ] && { printf '%s BUILDING' "$g_building"; return; }; printf '%s READY' "$g_ready"; }
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:20:tracker_mode(){ cfg="$root/.architect/config"; [ -f "$cfg" ] || { printf github; return; }; v=$(awk -F= '/^[[:space:]]*tracker[[:space:]]*=/{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2); print $2; exit}' "$cfg"); [ "$v" = markdown ] && printf markdown || printf github; }
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:21:fm(){ awk -v key="$2" 'NR==1{sub(/^\357\273\277/,""); if($0!="---") exit} NR>1{if($0=="---") exit; if(index($0,key":")==1){sub(/^[^:]*:[[:space:]]*/,""); print; exit}}' "$1"; }
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:25:  dir="$root/docs/issues"; us=$(printf '\037'); rows=; parents=; open_nums=
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:29:      num=$(fm "$f" issue); title=$(fm "$f" title); state=$(fm "$f" state); parent=$(fm "$f" parent); blocked=$(fm "$f" blocked-by)
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:31:      [ -n "$title" ] && [ -n "$state" ] && [ -n "$parent" ] && [ -n "$blocked" ] || continue
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:32:      rows="${rows}${num}${us}${state}${us}${parent}${us}${blocked}${us}${title}
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:34:      [ "$state" = OPEN ] && open_nums="${open_nums}${num}
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:36:      case "$parent" in *[!0-9]*|'') ;; *) parents="${parents}${parent}
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:41:  while IFS="$(printf '\037')" read -r num state parent blocked title; do
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:43:    if [ "$state" = OPEN ] && has_num "$parents" "$num" && [ "$num" -gt "$track" ]; then track=$num; fi
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:47:  while IFS="$(printf '\037')" read -r num state parent blocked title; do
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:48:    [ "$parent" = "$track" ] || continue
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:51:    printf 'SUB\t%s\t%s\t%s\t%s\n' "$num" "$state" "$out" "$title"
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:55:  if [ "$(tracker_mode)" = markdown ]; then markdown_lines; return 0; fi
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:56:  jq_expr='. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:59:  (cd "$root" && gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq "$jq_expr")
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:67:  while IFS="$(printf '\037')" read -r kind num state blockers title; do [ "$kind" = TRACK ] && tracking=$num; done <<< "$(printf '%s\n' "$tracker_tsv" | tr '\t' '\037')"
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:78:  while IFS="$(printf '\037')" read -r kind num state blockers title; do [ "$kind" = SUB ] || continue; slug=$(slugify "$title"); set -- $(phase "$slug" "$state" "$blockers"); extra=; [ "$2" = QUEUED ] && extra=" blocked-by: $blockers"; printf '%s #%s %s .architect/wt/%s-01%s\n' "$1" "$num" "$title" "$slug" "$extra"; [ "$2" = BUILDING ] && last_command "$slug"; done <<< "$(printf '%s\n' "$tracker_tsv" | tr '\t' '\037')"
```

### Bash Static

```text
bash -n equivalent is composite (orchestrator).
```

## Extra

### Command

```powershell
git diff --check -- skills/architect/status.ps1 skills/architect/status.sh
```

### Output

```text
warning: in the working copy of 'skills/architect/status.ps1', LF will be replaced by CRLF the next time Git touches it
```

### Command

```powershell
git status --short
```

### Output

```text
 M skills/architect/status.ps1
 M skills/architect/status.sh
?? docs/jobs/tracker-status-01.md
```

## Respawn session

### Change

Restored the seven literal UTF-8 phase glyphs in `skills/architect/status.sh`:
`✓`, `◐`, `!`, `▣`, `●`, `⊘`, `○`. No logic changes were made.

### SS1 UTF8 RERUN Output

```text
SS1 UTF8 RERUN
True
True
status.sh MERGED literal=True
status.ps1 MERGED marker=True
status.sh JUDGING literal=True
status.ps1 JUDGING marker=True
status.sh BLOCKED literal=True
status.ps1 BLOCKED marker=True
status.sh REPORTED literal=True
status.ps1 REPORTED marker=True
status.sh BUILDING literal=True
status.ps1 BUILDING marker=True
status.sh QUEUED literal=True
status.ps1 QUEUED marker=True
status.sh READY literal=True
status.ps1 READY marker=True
1
1
#!/usr/bin/env bash
```

### SS2-SS5 Output

```text
SS2
SS2_OK
SS3 FIXTURE CREATE
root1/.architect/wt/demo-blocked-01/docs/jobs/demo-blocked-01.md
root1/.architect/wt/demo-build-01.events.jsonl
root1/.architect/wt/demo-judge-01.judge.md
root1/.architect/wt/demo-judge-01/docs/jobs/demo-judge-01.md
root1/.architect/wt/demo-rep-01/docs/jobs/demo-rep-01.md
root1/docs/spec/demo.md
SS3 ROOT1
STATUS TREE spec: demo.md branch: unknown
tracker: unavailable (local view)
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
! demo-blocked .architect/wt/demo-blocked-01
● demo-build .architect/wt/demo-build-01
    last: pytest -q age: unknown
◐ demo-judge .architect/wt/demo-judge-01
▣ demo-rep .architect/wt/demo-rep-01
SS3 ROOT2
NO ACTIVE FACTORY RUN
spec: unknown
SS4
False
SS5
2
4
2
SS5_OK
```

### SS6 And Validator Output

```text
SS6
SS EXTRA VALIDATOR
OK - 2 skills validated, v4 contracts clean
```

### TS1-TS3 Output

```text
TS1
root1/.architect/config
root1/docs/issues/003-old-run.md
root1/docs/issues/004-old-child.md
root1/docs/issues/007-current-run.md
root1/docs/issues/008-done-job.md
root1/docs/issues/009-blocked-job.md
root1/docs/issues/010-ready-job.md
root1/docs/spec/demo.md
root2/.architect/config
root3/.architect/config
root3/docs/issues/007-current-run.md
root3/docs/issues/008-done-job.md
TS2
STATUS TREE spec: demo.md branch: unknown
tracker: #7
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
✓ #8 done job .architect/wt/done-job-01
⊘ #9 blocked job .architect/wt/blocked-job-01 blocked-by: 10
○ #10 ready job .architect/wt/ready-job-01
TS3 ROOT2
NO ACTIVE FACTORY RUN
spec: unknown
TS3 ROOT3
NO ACTIVE FACTORY RUN
spec: unknown
```

### TS4-TS6 Output

```text
TS4 FIXTURE
TRACK	43
SUB	44	CLOSED		status done
SUB	45	OPEN	44	status queued
SUB	46	OPEN		status ready
TS4 OUTPUT
STATUS TREE spec: demo.md branch: unknown
tracker: #43
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
✓ #44 status done .architect/wt/status-done-01
⊘ #45 status queued .architect/wt/status-queued-01 blocked-by: 44
○ #46 status ready .architect/wt/status-ready-01
TS5 ESC
False
TS5 PARSE
OK
TS5 BUDGETS
skills/architect/status.ps1:113
skills/architect/status.sh:78
TS6
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:19:phase(){ slug=$1; state=${2:-}; blockers=${3:-}; [ "$state" = CLOSED ] && { printf '%s MERGED' "$g_merged"; return; }; [ "$state" = OPEN ] && [ -n "$blockers" ] && { printf '%s QUEUED' "$g_queued"; return; }; rep=$(report_path "$slug"); judge=$(find "$root/.architect/wt" -maxdepth 1 -type f -name "$slug-01.judge*.md" 2>/dev/null | head -n 1); [ -f "$rep" ] && [ -n "$judge" ] && { printf '%s JUDGING' "$g_judging"; return; }; st=$(status_line "$rep"); case "$st" in BLOCKED*) printf '%s BLOCKED' "$g_blocked"; return;; esac; [ -f "$rep" ] && { printf '%s REPORTED' "$g_reported"; return; }; [ -d "$root/.architect/wt/$slug-01" ] && { printf '%s BUILDING' "$g_building"; return; }; printf '%s READY' "$g_ready"; }
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:20:tracker_mode(){ cfg="$root/.architect/config"; [ -f "$cfg" ] || { printf github; return; }; v=$(awk -F= '/^[[:space:]]*tracker[[:space:]]*=/{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2); print $2; exit}' "$cfg"); [ "$v" = markdown ] && printf markdown || printf github; }
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:21:fm(){ awk -v key="$2" 'NR==1{sub(/^\357\273\277/,""); if($0!="---") exit} NR>1{if($0=="---") exit; if(index($0,key":")==1){sub(/^[^:]*:[[:space:]]*/,""); print; exit}}' "$1"; }
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:25:  dir="$root/docs/issues"; us=$(printf '\037'); rows=; parents=; open_nums=
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:29:      num=$(fm "$f" issue); title=$(fm "$f" title); state=$(fm "$f" state); parent=$(fm "$f" parent); blocked=$(fm "$f" blocked-by)
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:31:      [ -n "$title" ] && [ -n "$state" ] && [ -n "$parent" ] && [ -n "$blocked" ] || continue
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:32:      rows="${rows}${num}${us}${state}${us}${parent}${us}${blocked}${us}${title}
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:34:      [ "$state" = OPEN ] && open_nums="${open_nums}${num}
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:36:      case "$parent" in *[!0-9]*|'') ;; *) parents="${parents}${parent}
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:41:  while IFS="$(printf '\037')" read -r num state parent blocked title; do
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:43:    if [ "$state" = OPEN ] && has_num "$parents" "$num" && [ "$num" -gt "$track" ]; then track=$num; fi
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:47:  while IFS="$(printf '\037')" read -r num state parent blocked title; do
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:48:    [ "$parent" = "$track" ] || continue
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:51:    printf 'SUB\t%s\t%s\t%s\t%s\n' "$num" "$state" "$out" "$title"
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:55:  if [ "$(tracker_mode)" = markdown ]; then markdown_lines; return 0; fi
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:56:  jq_expr='. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:59:  (cd "$root" && gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq "$jq_expr")
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:67:  while IFS="$(printf '\037')" read -r kind num state blockers title; do [ "$kind" = TRACK ] && tracking=$num; done <<< "$(printf '%s\n' "$tracker_tsv" | tr '\t' '\037')"
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-01\skills\architect\status.sh:78:  while IFS="$(printf '\037')" read -r kind num state blockers title; do [ "$kind" = SUB ] || continue; slug=$(slugify "$title"); set -- $(phase "$slug" "$state" "$blockers"); extra=; [ "$2" = QUEUED ] && extra=" blocked-by: $blockers"; printf '%s #%s %s .architect/wt/%s-01%s\n' "$1" "$num" "$title" "$slug" "$extra"; [ "$2" = BUILDING ] && last_command "$slug"; done <<< "$(printf '%s\n' "$tracker_tsv" | tr '\t' '\037')"
TS6 BASH STATIC
bash -n equivalent is composite (orchestrator).
```

STATUS: COMPLETE

## Reopen session

### Change

Reimplemented `skills/architect/status.sh` `has_num()` without command
substitution:
`case $'\n'"$1" in *$'\n'"$2"$'\n'*) ...`.
This preserves the caller's trailing newline, so the terminal list entry is
matchable at both call sites.

### Reopen Harness And TS1-TS6 Output

```text
REOPEN HARNESS
root1 open_nums=[3,7,9,10] old_has_10=False fixed_has_10=True
root4 parents=[50] old_track_parent_50=False fixed_track_parent_50=True
root5 open_nums=[99,100,101] old_has_101=False fixed_has_101=True
REOPEN ROOT4 STATUS
STATUS TREE spec: demo.md branch: unknown
tracker: #50
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
○ #51 only child .architect/wt/only-child-01
REOPEN ROOT5 STATUS
STATUS TREE spec: demo.md branch: unknown
tracker: #99
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
⊘ #100 highest blocked .architect/wt/highest-blocked-01 blocked-by: 101
○ #101 highest open .architect/wt/highest-open-01
TS1
.architect/config
docs/issues/003-old-run.md
docs/issues/004-old-child.md
docs/issues/007-current-run.md
docs/issues/008-done-job.md
docs/issues/009-blocked-job.md
docs/issues/010-ready-job.md
docs/spec/demo.md
TS2
STATUS TREE spec: demo.md branch: unknown
tracker: #7
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
✓ #8 done job .architect/wt/done-job-01
⊘ #9 blocked job .architect/wt/blocked-job-01 blocked-by: 10
○ #10 ready job .architect/wt/ready-job-01
TS3 ROOT2
NO ACTIVE FACTORY RUN
spec: demo.md
TS3 ROOT3
NO ACTIVE FACTORY RUN
spec: demo.md
TS4 FIXTURE
TRACK	43
SUB	44	CLOSED		status done
SUB	45	OPEN	44	status queued
SUB	46	OPEN		status ready
TS4 OUTPUT
STATUS TREE spec: demo.md branch: unknown
tracker: #43
ORCHESTRATOR: local view
WATCHDOG: process=False config=0
✓ #44 status done .architect/wt/status-done-01
⊘ #45 status queued .architect/wt/status-queued-01 blocked-by: 44
○ #46 status ready .architect/wt/status-ready-01
TS5 ESC
False
TS5 PARSE
OK
TS5 BUDGETS
skills/architect/status.ps1:113
skills/architect/status.sh:78
TS6
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:19:phase(){ slug=$1; state=${2:-}; blockers=${3:-}; [ "$state" = CLOSED ] && { printf '%s MERGED' "$g_merged"; return; }; [ "$state" = OPEN ] && [ -n "$blockers" ] && { printf '%s QUEUED' "$g_queued"; return; }; rep=$(report_path "$slug"); judge=$(find "$root/.architect/wt" -maxdepth 1 -type f -name "$slug-01.judge*.md" 2>/dev/null | head -n 1); [ -f "$rep" ] && [ -n "$judge" ] && { printf '%s JUDGING' "$g_judging"; return; }; st=$(status_line "$rep"); case "$st" in BLOCKED*) printf '%s BLOCKED' "$g_blocked"; return;; esac; [ -f "$rep" ] && { printf '%s REPORTED' "$g_reported"; return; }; [ -d "$root/.architect/wt/$slug-01" ] && { printf '%s BUILDING' "$g_building"; return; }; printf '%s READY' "$g_ready"; }
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:20:tracker_mode(){ cfg="$root/.architect/config"; [ -f "$cfg" ] || { printf github; return; }; v=$(awk -F= '/^[[:space:]]*tracker[[:space:]]*=/{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2); print $2; exit}' "$cfg"); [ "$v" = markdown ] && printf markdown || printf github; }
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:21:fm(){ awk -v key="$2" 'NR==1{sub(/^\357\273\277/,""); if($0!="---") exit} NR>1{if($0=="---") exit; if(index($0,key":")==1){sub(/^[^:]*:[[:space:]]*/,""); print; exit}}' "$1"; }
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:22:has_num(){ case $'\n'"$1" in *$'\n'"$2"$'\n'*) return 0;; *) return 1;; esac; }
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:25:  dir="$root/docs/issues"; us=$(printf '\037'); rows=; parents=; open_nums=
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:29:      num=$(fm "$f" issue); title=$(fm "$f" title); state=$(fm "$f" state); parent=$(fm "$f" parent); blocked=$(fm "$f" blocked-by)
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:31:      [ -n "$title" ] && [ -n "$state" ] && [ -n "$parent" ] && [ -n "$blocked" ] || continue
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:32:      rows="${rows}${num}${us}${state}${us}${parent}${us}${blocked}${us}${title}
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:34:      [ "$state" = OPEN ] && open_nums="${open_nums}${num}
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:36:      case "$parent" in *[!0-9]*|'') ;; *) parents="${parents}${parent}
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:41:  while IFS="$(printf '\037')" read -r num state parent blocked title; do
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:43:    if [ "$state" = OPEN ] && has_num "$parents" "$num" && [ "$num" -gt "$track" ]; then track=$num; fi
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:47:  while IFS="$(printf '\037')" read -r num state parent blocked title; do
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:48:    [ "$parent" = "$track" ] || continue
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:50:    for b do b=$(trim_token "$b"); case "$b" in ''|*[!0-9]*) continue;; esac; has_num "$open_nums" "$b" && { [ -n "$out" ] && out="$out,$b" || out=$b; }; done
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:51:    printf 'SUB\t%s\t%s\t%s\t%s\n' "$num" "$state" "$out" "$title"
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:55:  if [ "$(tracker_mode)" = markdown ]; then markdown_lines; return 0; fi
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:56:  jq_expr='. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:59:  (cd "$root" && gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq "$jq_expr")
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:67:  while IFS="$(printf '\037')" read -r kind num state blockers title; do [ "$kind" = TRACK ] && tracking=$num; done <<< "$(printf '%s\n' "$tracker_tsv" | tr '\t' '\037')"
C:\Users\danhm\architect-loop\.architect\wt\tracker-status-02\skills\architect\status.sh:78:  while IFS="$(printf '\037')" read -r kind num state blockers title; do [ "$kind" = SUB ] || continue; slug=$(slugify "$title"); set -- $(phase "$slug" "$state" "$blockers"); extra=; [ "$2" = QUEUED ] && extra=" blocked-by: $blockers"; printf '%s #%s %s .architect/wt/%s-01%s\n' "$1" "$num" "$title" "$slug" "$extra"; [ "$2" = BUILDING ] && last_command "$slug"; done <<< "$(printf '%s\n' "$tracker_tsv" | tr '\t' '\037')"
TS6 BASH STATIC
bash -n equivalent is composite (orchestrator).
```

STATUS: COMPLETE
