# Job Report: ground-scripts/s4-ship-01

MIRROR: ORCHESTRATOR

Phase 0 tracker comment attempt:

Command:

```powershell
gh issue comment 133 --body-file .architect/tmp/phase0-comment.md
```

Exit: 1

Output:

```text
Post "https://api.github.com/graphql": proxyconnect tcp: dial tcp 127.0.0.1:9: connectex: No connection could be made because the target machine actively refused it.
```

Built:

```text
skills/ship/SKILL.md
```

Git Bash executor attempts from worktree root:

RUN: `test -f skills/ship/SKILL.md`

Command:

```powershell
bash -lc 'test -f skills/ship/SKILL.md'
```

Exit: 1

Output:

```text
      1 [main] bash (3528) C:\Program Files\Git\usr\bin\bash.exe: *** fatal error - CreateFileMapping S-1-5-21-940813291-4134638421-1989498454-1002.1, Win32 error 5.  Terminating.
```

RUN: `grep -F -q "name: ship" skills/ship/SKILL.md`

Command:

```powershell
bash -lc 'grep -F -q "name: ship" skills/ship/SKILL.md'
```

Exit: 1

Output:

```text
      0 [main] bash (24848) C:\Program Files\Git\usr\bin\bash.exe: *** fatal error - CreateFileMapping S-1-5-21-940813291-4134638421-1989498454-1002.1, Win32 error 5.  Terminating.
```

RUN: `bash -c 'for t in "final review" "conflict" "Closes #" "digest" "postflight"; do grep -qi "$t" skills/ship/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo RULES_OK'`

Command:

```powershell
bash -c 'for t in "final review" "conflict" "Closes #" "digest" "postflight"; do grep -qi "$t" skills/ship/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo RULES_OK'
```

Exit: 1

Output:

```text
      0 [main] bash (13580) C:\Program Files\Git\usr\bin\bash.exe: *** fatal error - CreateFileMapping S-1-5-21-940813291-4134638421-1989498454-1002.1, Win32 error 5.  Terminating.
```

RUN: `bash -c 'grep -qi "ship time" skills/ship/SKILL.md && echo SHIPTIME_OK'`

Command:

```powershell
bash -c 'grep -qi "ship time" skills/ship/SKILL.md && echo SHIPTIME_OK'
```

Exit: 1

Output:

```text
      0 [main] bash (18928) C:\Program Files\Git\usr\bin\bash.exe: *** fatal error - CreateFileMapping S-1-5-21-940813291-4134638421-1989498454-1002.1, Win32 error 5.  Terminating.
```

RUN: `bash -c 'n=$(wc -l < skills/ship/SKILL.md); test "$n" -le 90 && echo "LINES_OK $n"'`

Command:

```powershell
bash -c 'n=$(wc -l < skills/ship/SKILL.md); test "$n" -le 90 && echo "LINES_OK $n"'
```

Exit: 1

Output:

```text
      1 [main] bash (10940) C:\Program Files\Git\usr\bin\bash.exe: *** fatal error - CreateFileMapping S-1-5-21-940813291-4134638421-1989498454-1002.1, Win32 error 5.  Terminating.
```

RUN: `bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/ship/SKILL.md && echo NO_ECHO'`

Command:

```powershell
bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/ship/SKILL.md && echo NO_ECHO'
```

Exit: 1

Output:

```text
      0 [main] bash (30804) C:\Program Files\Git\usr\bin\bash.exe: *** fatal error - CreateFileMapping S-1-5-21-940813291-4134638421-1989498454-1002.1, Win32 error 5.  Terminating.
```

Sequential Git Bash retry:

Command:

```powershell
bash -lc 'test -f skills/ship/SKILL.md'
```

Exit: 1

Output:

```text
      0 [main] bash (7188) C:\Program Files\Git\usr\bin\bash.exe: *** fatal error - CreateFileMapping S-1-5-21-940813291-4134638421-1989498454-1002.1, Win32 error 5.  Terminating.
```

WSL Bash retry:

Command:

```powershell
& $env:WINDIR\System32\bash.exe -lc 'pwd'
```

Exit: 1

Output:

```text
Access is denied.
Error code: Bash/Service/CreateInstance/E_ACCESSDENIED
```

Recorded same-pattern substitution because `docs/checks/ground-scripts/s4-ship.md` names Bash as preferred executor and allows recorded same-pattern substitution.

RUN substitution: `test -f skills/ship/SKILL.md`

Command:

```powershell
if (Test-Path skills/ship/SKILL.md) { exit 0 } else { exit 1 }
```

Exit: 0

Output:

```text
```

RUN substitution: `grep -F -q "name: ship" skills/ship/SKILL.md`

Command:

```powershell
if (Select-String -Path skills/ship/SKILL.md -Pattern 'name: ship' -SimpleMatch -Quiet) { exit 0 } else { exit 1 }
```

Exit: 0

Output:

```text
```

RUN substitution: `bash -c 'for t in "final review" "conflict" "Closes #" "digest" "postflight"; do grep -qi "$t" skills/ship/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo RULES_OK'`

Command:

```powershell
$missing = @(); foreach ($t in @('final review','conflict','Closes #','digest','postflight')) { if (-not (Select-String -Path skills/ship/SKILL.md -Pattern $t -CaseSensitive:$false -SimpleMatch -Quiet)) { $missing += $t } }; if ($missing.Count) { foreach ($m in $missing) { "MISSING: $m" }; exit 3 } else { 'RULES_OK'; exit 0 }
```

Exit: 0

Output:

```text
RULES_OK
```

RUN substitution: `bash -c 'grep -qi "ship time" skills/ship/SKILL.md && echo SHIPTIME_OK'`

Command:

```powershell
if (Select-String -Path skills/ship/SKILL.md -Pattern 'ship time' -CaseSensitive:$false -SimpleMatch -Quiet) { 'SHIPTIME_OK'; exit 0 } else { exit 1 }
```

Exit: 0

Output:

```text
SHIPTIME_OK
```

RUN substitution: `bash -c 'n=$(wc -l < skills/ship/SKILL.md); test "$n" -le 90 && echo "LINES_OK $n"'`

Command:

```powershell
$n = (Get-Content skills/ship/SKILL.md).Count; if ($n -le 90) { "LINES_OK $n"; exit 0 } else { exit 1 }
```

Exit: 0

Output:

```text
LINES_OK 89
```

RUN substitution: `bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/ship/SKILL.md && echo NO_ECHO'`

Command:

```powershell
if (Select-String -Path skills/ship/SKILL.md -Pattern 'show your (reasoning|thinking)|explain your reasoning' -CaseSensitive:$false -Quiet) { exit 1 } else { 'NO_ECHO'; exit 0 }
```

Exit: 0

Output:

```text
NO_ECHO
```

Additional direct contract check: frontmatter description length.

Command:

```powershell
$text = Get-Content -Raw skills/ship/SKILL.md
if ($text -match '(?s)description:\s*>\s*\r?\n(.*?)\r?\n---') { $desc = (($Matches[1] -split "\r?\n") | ForEach-Object { $_.Trim() }) -join ' '; "DESCRIPTION_CHARS $($desc.Length)" } else { 'DESCRIPTION_NOT_FOUND'; exit 1 }
```

Exit: 0

Output:

```text
DESCRIPTION_CHARS 304
```

STATUS: COMPLETE_WITH_CONCERNS (GitHub tracker comment and Bash executors were blocked by the environment; MIRROR: ORCHESTRATOR recorded and same-pattern verification passed)
