# loop-hygiene-xplat-01

MIRROR: ORCHESTRATOR

## Phase 0

### Input Verification

| Command | Exit | Output |
|---|---:|---|
| `git rev-parse HEAD` | 0 | `cbfb4734d30557c5ebb72b91239024e6e69a946c` |
| `Get-Content -Raw docs\checks\loop-hygiene-xplat.md` | 0 | `# Frozen checks: loop-hygiene-xplat (#77)` |
| `Test-Path CLAUDE.md` | 0 | `False` |
| `Test-Path AGENTS.md` | 0 | `False` |
| `$PSVersionTable.PSVersion.ToString()` | 0 | `5.1.26100.8655` |
| `uv --version` | 0 | `uv 0.9.10 (44f5a14f4 2025-11-17)` |
| `git --version` | 0 | `git version 2.51.2.windows.1` |
| `git config --get core.autocrlf` | 0 | `true` |

### Plan

| Step | Scope |
|---|---|
| 1 | Audit only `skills/architect/*.ps1`, `skills/architect/*.sh`, `install.ps1`, `install.sh`; write only this report under `docs/jobs/`. |
| 2 | Patch audit-backed portability risks only. |
| 3 | Run sandbox-permitted checks sequentially with temp/cache under `.architect/tmp`. |
| 4 | Record frozen bash RUN items as unexecuted in sandbox with substitute evidence. |

### Disagreements

| Item | File evidence | Ruling |
|---|---|---|
| Skill text platform invocation work is outside this job. | `docs/spec/loop-hygiene.md:32-36`, `docs/spec/loop-hygiene.md:121-122` | No `.md` skill edits. |
| Broad `*.md` ban conflicts with required job report. | `docs/checks/loop-hygiene-xplat.md:33-35`, `docs/spec/loop-hygiene.md:136` | Only `docs/jobs/loop-hygiene-xplat-01.md` written. |
| Frozen executor is bash, but sandbox cannot execute Git Bash. | `docs/checks/loop-hygiene-xplat.md:11`, `docs/checks/loop-hygiene-xplat.md:18-23` | Bash RUN items marked unexecuted in sandbox. |

## Parity Table

| Script | Construct audited | Platform risk found | Fix applied or ALREADY-OK | Verification command + output |
|---|---|---|---|---|
| `skills/architect/status.ps1` | PS 5.1 parse; watchdog process probe | Direct `Get-WmiObject` process probe brittle under newer PowerShell | FIXED: `Win32Processes` helper prefers `Get-CimInstance`, falls back to `Get-WmiObject` | `PS_PARSE`: exit 0, `PS_PARSE_OK`; `INTERFACE_COUNTS`: `WATCHDOG: 10 10` |
| `skills/architect/status.sh` | bash 3.2 syntax, `stat`, `ps args=`, TSV tokens, LF | none | ALREADY-OK | `GNU_SCAN`: `status.sh:12 stat -c ... stat -f`; `status.sh:75 ps -eo args=`; `EOL`: `w/lf attr/text eol=lf` |
| `skills/architect/watchdog.ps1` | PS 5.1 parse; process CPU probe | Direct `Get-WmiObject` process probe brittle under newer PowerShell | FIXED: `Win32Processes` helper prefers `Get-CimInstance`, falls back to `Get-WmiObject` | `PS_PARSE`: exit 0, `PS_PARSE_OK`; `INTERFACE_COUNTS`: `WATCHDOG: 10 10` |
| `skills/architect/watchdog.sh` | bash 3.2 indexed arrays; `/proc` fallback; BSD `ps args=` | `ps -eo time=,args=` less portable than split `-o` form | FIXED: `ps -eo time= -o args=` | `GNU_SCAN`: `watchdog.sh:21 /proc`, `watchdog.sh:30 ps -eo time= -o args=` |
| `skills/architect/check-runner.ps1` | PS 5.1 parse; encoded command runner; typed exit | none | ALREADY-OK | `PS_PARSE`: exit 0, `PS_PARSE_OK`; `git grep -c "CHECKRUN: ERROR"`: `check-runner.ps1:2` |
| `skills/architect/check-runner.sh` | bash 3.2 indexed arrays; temp files; `date` | default `mktemp` used system temp | FIXED: temp templates under `$workdir/.architect/tmp/check-runner` | `NO_BARE_MKTEMP`: exit 1, no output; `MKTEMP_LINES`: `check-runner.sh:19 mktemp "$tmp_base/$1.XXXXXX"` |
| `skills/architect/preflight.ps1` | PS 5.1 parse; repo-root/worktree path handling; typed exit | none | ALREADY-OK | `PS_PARSE`: exit 0, `PS_PARSE_OK`; `git grep -c "PREFLIGHT: OK"`: `preflight.ps1:1` |
| `skills/architect/preflight.sh` | bash 3.2 syntax; repo-root/worktree path handling; typed exit | none | ALREADY-OK | `BASH4_SCAN`: exit 0, `NO_MATCH`; `CASE_SCAN`: exit 0, `NO_MATCH`; `EOL`: `w/lf attr/text eol=lf` |
| `skills/architect/postflight.ps1` | PS 5.1 parse; touch audit; typed exit | none | ALREADY-OK | `PS_PARSE`: exit 0, `PS_PARSE_OK`; `INTERFACE_COUNTS`: `POSTFLIGHT: 20 20` |
| `skills/architect/postflight.sh` | bash 3.2 arrays; temp files; touch audit; typed exit | default `mktemp` used system temp | FIXED: temp templates under `$repo_root/.architect/tmp/postflight` | `NO_BARE_MKTEMP`: exit 1, no output; `MKTEMP_LINES`: `postflight.sh:34 mktemp "$tmp_dir/$1.XXXXXX"` |
| `install.ps1` | PS 5.1 parse; Claude and Codex install roots | none | ALREADY-OK | `PS_PARSE`: exit 0, `PS_PARSE_OK` |
| `install.sh` | bash 3.2 syntax; Claude and Codex install roots; LF | none | ALREADY-OK | `BASH4_SCAN`: exit 0, `NO_MATCH`; `CASE_SCAN`: exit 0, `NO_MATCH`; `EOL`: `w/lf attr/text eol=lf` |

## Verification Results

### Frozen Bash RUN Items

| Frozen RUN | Result |
|---|---|
| `bash -n skills/architect/status.sh` | UNEXECUTED in sandbox (Git Bash Win32 err 5); verified by static read plus `BASH4_SCAN`, `CASE_SCAN`, `GNU_SCAN`, `EOL`. |
| `bash -n skills/architect/watchdog.sh` | UNEXECUTED in sandbox (Git Bash Win32 err 5); verified by static read plus `BASH4_SCAN`, `CASE_SCAN`, `GNU_SCAN`, `EOL`. |
| `bash -n skills/architect/check-runner.sh` | UNEXECUTED in sandbox (Git Bash Win32 err 5); verified by static read plus `BASH4_SCAN`, `CASE_SCAN`, `GNU_SCAN`, `EOL`. |
| `bash -n skills/architect/preflight.sh` | UNEXECUTED in sandbox (Git Bash Win32 err 5); verified by static read plus `BASH4_SCAN`, `CASE_SCAN`, `GNU_SCAN`, `EOL`. |
| `bash -n skills/architect/postflight.sh` | UNEXECUTED in sandbox (Git Bash Win32 err 5); verified by static read plus `BASH4_SCAN`, `CASE_SCAN`, `GNU_SCAN`, `EOL`. |
| `bash -n install.sh` | UNEXECUTED in sandbox (Git Bash Win32 err 5); verified by static read plus `BASH4_SCAN`, `CASE_SCAN`, `GNU_SCAN`, `EOL`. |

### PS_PARSE

Command:
```powershell
$env:TEMP=(Resolve-Path .architect\tmp\verify-temp).Path; $env:TMP=$env:TEMP; $cmd = @'
$ProgressPreference = 'SilentlyContinue'
$bad=0; Get-ChildItem 'skills/architect/*.ps1','install.ps1' | ForEach-Object { $t=$null; $e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$t,[ref]$e); if ($e.Count) { Write-Output ($_.Name + ' PARSE_ERRORS'); $bad=1 } }; if ($bad) { exit 1 }; Write-Output 'PS_PARSE_OK'
'@; $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd)); powershell -NoProfile -EncodedCommand $encoded
```

Exit: 0
```text
PS_PARSE_OK
```

### BASH4_SCAN

Command:
```powershell
$paths=@('skills/architect/status.sh','skills/architect/watchdog.sh','skills/architect/check-runner.sh','skills/architect/preflight.sh','skills/architect/postflight.sh','install.sh'); $m=Select-String -Path $paths -Pattern 'mapfile|readarray|declare -A' -CaseSensitive; if ($m) { $m | ForEach-Object { '{0}:{1}:{2}' -f $_.Path,$_.LineNumber,$_.Line.Trim() }; exit 1 } else { Write-Output 'NO_MATCH' }
```

Exit: 0
```text
NO_MATCH
```

### CASE_SCAN

Command:
```powershell
$paths=@('skills/architect/status.sh','skills/architect/watchdog.sh','skills/architect/check-runner.sh','skills/architect/preflight.sh','skills/architect/postflight.sh','install.sh'); $m=Select-String -Path $paths -Pattern '\$\{[A-Za-z_][A-Za-z0-9_]*(\^\^|,,)[^}]*\}' -CaseSensitive; if ($m) { $m | ForEach-Object { '{0}:{1}:{2}' -f $_.Path,$_.LineNumber,$_.Line.Trim() }; exit 1 } else { Write-Output 'NO_MATCH' }
```

Exit: 0
```text
NO_MATCH
```

### VALIDATOR

Command:
```powershell
$env:TEMP=(Resolve-Path .architect\tmp\verify-temp).Path; $env:TMP=$env:TEMP; $env:UV_CACHE_DIR='.architect/tmp/uv-cache'; uv run --no-project python tests/validate_skills.py
```

Exit: 0
```text
OK - 2 skills validated, v4 contracts clean
```

### PREFIX_COUNTS

Command:
```powershell
git grep -c "PREFLIGHT: OK" -- skills/architect/preflight.sh skills/architect/preflight.ps1
```

Exit: 0
```text
skills/architect/preflight.ps1:1
skills/architect/preflight.sh:1
```

Command:
```powershell
git grep -c "CHECKRUN: ERROR" -- skills/architect/check-runner.sh skills/architect/check-runner.ps1
```

Exit: 0
```text
skills/architect/check-runner.ps1:2
skills/architect/check-runner.sh:1
```

### INTERFACE_COUNTS

Command:
```powershell
$files=@('skills/architect/status.sh','skills/architect/status.ps1','skills/architect/watchdog.sh','skills/architect/watchdog.ps1','skills/architect/check-runner.sh','skills/architect/check-runner.ps1','skills/architect/preflight.sh','skills/architect/preflight.ps1','skills/architect/postflight.sh','skills/architect/postflight.ps1'); $tokens=@('PREFLIGHT:','POSTFLIGHT:','WATCHDOG:','CHECKRUN:','TRACK','SUB','NOOPENRUN'); Write-Output 'token before_HEAD after_worktree'; foreach ($token in $tokens) { $before=0; $after=0; foreach ($file in $files) { $headLines=@(& git show "HEAD:$file" 2>$null); if ($LASTEXITCODE -eq 0) { $before += [regex]::Matches(($headLines -join "`n"), [regex]::Escape($token)).Count }; if (Test-Path -LiteralPath $file) { $after += [regex]::Matches([System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $file).Path), [regex]::Escape($token)).Count } }; Write-Output ("{0} {1} {2}" -f $token,$before,$after) }
```

Exit: 0
```text
token before_HEAD after_worktree
PREFLIGHT: 5 5
POSTFLIGHT: 20 20
WATCHDOG: 10 10
CHECKRUN: 3 3
TRACK 6 6
SUB 6 6
NOOPENRUN 4 4
```

### GNU_SCAN

Command:
```powershell
rg -n -g "*.sh" "date |sed -i|find .* -printf|grep -P|tail --|ps .*cmd=|ps .*args=|stat -c|stat -f|/proc|mktemp" skills/architect install.sh
```

Exit: 0
```text
skills/architect\check-runner.sh:19:  mktemp "$tmp_base/$1.XXXXXX" 2>/dev/null || die "tmp unavailable"
skills/architect\check-runner.sh:84:now_ms(){ perl -MTime::HiRes=time -e 'printf "%d\n", time()*1000' 2>/dev/null || printf '%s000\n' "$(date +%s)"; }
skills/architect\check-runner.sh:92:  printf 'generated: %s  runner: sh  config: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$cfg"
skills/architect\watchdog.sh:15:fsize(){ stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null || printf 0; }
skills/architect\watchdog.sh:16:now(){ date +%s; }
skills/architect\watchdog.sh:21:  if [ -d /proc ]; then
skills/architect\watchdog.sh:23:    for p in /proc/[0-9]*; do
skills/architect\watchdog.sh:30:    ps -eo time= -o args= | awk -v w="$w" 'index($0,w){split($1,a,":"); n=split($1,b,"-"); t=(n==2?b[2]:$1); split(t,c,":"); if(length(c)==3)s+=c[1]*3600+c[2]*60+c[3]; else s+=c[1]*60+c[2]} END{print s+0}'
skills/architect\status.sh:12:newest_spec(){ spec_dir="$root/docs/spec"; newest=; newest_mtime=; [ -d "$spec_dir" ] || { printf unknown; return; }; for spec in "$spec_dir"/*.md; do [ -f "$spec" ] || continue; mtime=$(stat -c %Y "$spec" 2>/dev/null || stat -f %m "$spec" 2>/dev/null || printf 0); case "$mtime" in ''|*[!0-9]*) mtime=0;; esac; if [ -z "$newest" ] || [ "$mtime" -gt "$newest_mtime" ]; then newest=$spec; newest_mtime=$mtime; fi; done; [ -n "$newest" ] && basename "$newest" || printf unknown; }
skills/architect\status.sh:75:ps -eo args= 2>/dev/null | grep 'watchdog\.\(ps1\|sh\)' >/dev/null && proc=True || proc=False
skills/architect\postflight.sh:34:  mktemp "$tmp_dir/$1.XXXXXX" 2>/dev/null || err "tmp unavailable"
```

### PATH_SCAN

Command:
```powershell
rg -n -g "*.sh" -g "*.ps1" "/tmp|C:\\" skills/architect install.sh install.ps1
```

Exit: 0
```text
skills/architect\status.sh:74:cfg=$(find "$root/.architect/tmp" -maxdepth 1 -type f -name 'wd-*.json' 2>/dev/null | wc -l | tr -d ' ')
skills/architect\status.ps1:117:$wdCfg = @(Get-ChildItem -LiteralPath (J $root ".architect/tmp") -Filter "wd-*.json")
skills/architect\postflight.sh:87:tmp_dir="$repo_root/.architect/tmp/postflight"
skills/architect\check-runner.sh:40:tmp_base="$workdir/.architect/tmp/check-runner"
```

### NO_BARE_MKTEMP

Command:
```powershell
rg -n "mktemp(\s*$|\s*\)|\s*;)" skills/architect/check-runner.sh skills/architect/postflight.sh skills/architect/watchdog.sh skills/architect/status.sh skills/architect/preflight.sh install.sh
```

Exit: 1
```text
```

### MKTEMP_LINES

Command:
```powershell
rg -n -F "mktemp" skills/architect/check-runner.sh skills/architect/postflight.sh skills/architect/watchdog.sh skills/architect/status.sh skills/architect/preflight.sh install.sh
```

Exit: 0
```text
skills/architect/check-runner.sh:19:  mktemp "$tmp_base/$1.XXXXXX" 2>/dev/null || die "tmp unavailable"
skills/architect/postflight.sh:34:  mktemp "$tmp_dir/$1.XXXXXX" 2>/dev/null || err "tmp unavailable"
```

### EOL

Command:
```powershell
git ls-files --eol skills/architect/status.sh skills/architect/watchdog.sh skills/architect/check-runner.sh skills/architect/preflight.sh skills/architect/postflight.sh install.sh skills/architect/status.ps1 skills/architect/watchdog.ps1 skills/architect/check-runner.ps1 skills/architect/preflight.ps1 skills/architect/postflight.ps1 install.ps1 .gitattributes
```

Exit: 0
```text
i/lf    w/crlf  attr/                  	.gitattributes
i/lf    w/crlf  attr/                  	install.ps1
i/lf    w/lf    attr/text eol=lf       	install.sh
i/lf    w/crlf  attr/                  	skills/architect/check-runner.ps1
i/lf    w/lf    attr/text eol=lf       	skills/architect/check-runner.sh
i/lf    w/crlf  attr/                  	skills/architect/postflight.ps1
i/lf    w/lf    attr/text eol=lf       	skills/architect/postflight.sh
i/lf    w/crlf  attr/                  	skills/architect/preflight.ps1
i/lf    w/lf    attr/text eol=lf       	skills/architect/preflight.sh
i/lf    w/crlf  attr/                  	skills/architect/status.ps1
i/lf    w/lf    attr/text eol=lf       	skills/architect/status.sh
i/lf    w/crlf  attr/                  	skills/architect/watchdog.ps1
i/lf    w/lf    attr/text eol=lf       	skills/architect/watchdog.sh
```

### DIFF_CHECK

Command:
```powershell
git diff --check
```

Exit: 0
```text
```

### CHANGED_FILES

Command:
```powershell
git status --short
```

Exit: 0
```text
 M skills/architect/check-runner.sh
 M skills/architect/postflight.sh
 M skills/architect/status.ps1
 M skills/architect/watchdog.ps1
 M skills/architect/watchdog.sh
?? docs/jobs/loop-hygiene-xplat-01.md
```

Command:
```powershell
git diff --name-only
```

Exit: 0
```text
skills/architect/check-runner.sh
skills/architect/postflight.sh
skills/architect/status.ps1
skills/architect/watchdog.ps1
skills/architect/watchdog.sh
```

Command:
```powershell
git diff --stat
```

Exit: 0
```text
 skills/architect/check-runner.sh | 18 +++++++++++++++---
 skills/architect/postflight.sh   | 21 ++++++++++++++-------
 skills/architect/status.ps1      | 11 ++++++++++-
 skills/architect/watchdog.ps1    | 12 +++++++++++-
 skills/architect/watchdog.sh     |  2 +-
 5 files changed, 51 insertions(+), 13 deletions(-)
```

STATUS: COMPLETE_WITH_CONCERNS (bash RUN items unexecuted in sandbox per policy; docs/jobs report is required md exception)
