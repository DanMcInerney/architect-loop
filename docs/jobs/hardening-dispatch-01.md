# hardening-dispatch-01

## FIRST-ACTION verification

Command:
```powershell
git log -1 --oneline; if (Test-Path -LiteralPath 'docs/checks/hardening-dispatch.md') { Select-String -LiteralPath 'docs/checks/hardening-dispatch.md' -Pattern 'architect-monitor\\.md' } else { Write-Output 'MISSING docs/checks/hardening-dispatch.md' }
```

Output:
```text
ea07690 re-freeze: DB3/DD2 pattern targets the deleted file (PHASE-0 blocker on #38 upheld); ruling recorded
C:\Users\danhm\architect-loop\.architect\wt\hardening-dispatch-01\docs\checks\hardening-dispatch.md:37:- `git grep -inE "architect-monitor\.md" -- ':!docs/spec' ':!docs/research' ':!docs/solutions' ':!docs/adr' ':!docs/checks' ':!docs/jobs' ':!docs/gates' ':!docs/lanes' ':!README.md' ':!DESIGN.md' ':!CONTEXT.md'` → no output.
```
Exit code: 0

## DB1.1 monitor heading

Command:
```powershell
git grep -c '## Monitor dispatch' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB1.2 watchdog ps1

Command:
```powershell
git grep -c 'watchdog.ps1' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:2
```
Exit code: 0

## DB1.3 watchdog sh

Command:
```powershell
git grep -c 'watchdog.sh' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:2
```
Exit code: 0

## DB1.4 config keys

Command:
```powershell
git grep -cE 'stall_after_min|sweep_sec' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:3
```
Exit code: 0

## DB1.5 ALL_DONE

Command:
```powershell
git grep -c 'WATCHDOG: ALL_DONE' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB1.6 INTEGRATED

Command:
```powershell
git grep -c 'WATCHDOG: INTEGRATED' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB1.7 STALL

Command:
```powershell
git grep -c 'WATCHDOG: STALL' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB1.8 REPEAT

Command:
```powershell
git grep -c 'WATCHDOG: REPEAT' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB2.1 fallback start marker

Command:
```powershell
git grep -c 'architect-monitor-fallback-template:start' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB2.2 fallback end marker

Command:
```powershell
git grep -c 'architect-monitor-fallback-template:end' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB2.3 integrated fallback exit

Command:
```powershell
git grep -c 'INTEGRATED_BY_ORCHESTRATOR' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB2.4 per-job evidence line

Command:
```powershell
Select-String -LiteralPath 'skills/architect/dispatch.md' -Pattern 'Quiet exit is allowed ONLY|byte size as evidence'
```

Output:
```text
C:\Users\danhm\architect-loop\.architect\wt\hardening-dispatch-01\skills\architect\dispatch.md:358:Quiet exit is allowed ONLY when, for every job, you list the report path and
C:\Users\danhm\architect-loop\.architect\wt\hardening-dispatch-01\skills\architect\dispatch.md:359:byte size as evidence. If a worktree or events file vanished because the
```
Exit code: 0

## DB3.1 deleted definition

Command:
```powershell
Test-Path .claude/agents/architect-monitor.md
```

Output:
```text
False
```
Exit code: 0

## DB3.2 no dangling file references

Command:
```powershell
git grep -inE 'architect-monitor\.md' -- ':!docs/spec' ':!docs/research' ':!docs/solutions' ':!docs/adr' ':!docs/checks' ':!docs/jobs' ':!docs/gates' ':!docs/lanes' ':!README.md' ':!DESIGN.md' ':!CONTEXT.md'
```

Output:
```text
```
Exit code: 1

## DB4.1 MSYS2

Command:
```powershell
git grep -ci 'MSYS2' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB4.2 CreateFileMapping

Command:
```powershell
git grep -c 'CreateFileMapping' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:3
```
Exit code: 0

## DB4.3 upstream issue

Command:
```powershell
git grep -cE 'openai/codex#12000|codex#12000' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB4.4 POSIX unaffected sentence

Command:
```powershell
Get-Content -LiteralPath 'skills/architect/dispatch.md' | Select-Object -Index 386,387
```

Output:
```text
token. Native `git.exe` and PowerShell are unaffected; POSIX/macOS/Linux
sandboxes are unaffected. Known upstream: openai/codex#12000 and
```
Exit code: 0

## DB4.5 Windows primary sentence

Command:
```powershell
Select-String -LiteralPath 'skills/architect/dispatch.md' -Pattern 'PowerShell \+ native git subcommands on Windows'
```

Output:
```text
C:\Users\danhm\architect-loop\.architect\wt\hardening-dispatch-01\skills\architect\dispatch.md:390:primary for sandboxed jobs: PowerShell + native git subcommands on Windows,
```
Exit code: 0

## DB5.1 shell hygiene heading

Command:
```powershell
git grep -c '## Orchestrator shell hygiene' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB5.2 absolute path

Command:
```powershell
git grep -ci 'absolute path' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB5.3 heredoc

Command:
```powershell
git grep -ci 'heredoc' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB5.4 persisted cwd

Command:
```powershell
git grep -ci 'persisted cwd\|persistent cwd\|current directory persists' -- skills/architect/dispatch.md
```

Output:
```text
skills/architect/dispatch.md:1
```
Exit code: 0

## DB6.1 monitor protocol heading

Command:
```powershell
git grep -c '## Monitor protocol' -- skills/architect/loop.md
```

Output:
```text
skills/architect/loop.md:1
```
Exit code: 0

## DB6.2 watchdog count

Command:
```powershell
git grep -ci 'watchdog' -- skills/architect/loop.md
```

Output:
```text
skills/architect/loop.md:7
```
Exit code: 0

## DB6.3 factory block heading

Command:
```powershell
git grep -c '## Factory block procedure' -- skills/architect/loop.md
```

Output:
```text
skills/architect/loop.md:1
```
Exit code: 0

## DB6.4 cheapest tier hits

Command:
```powershell
git grep -ci 'cheapest tier' -- skills/architect/loop.md
```

Output:
```text
```
Exit code: 1

## DB6.5 ruling option lines

Command:
```powershell
Select-String -LiteralPath 'skills/architect/loop.md' -Pattern 'WATCHDOG: ALL_DONE|WATCHDOG: INTEGRATED|WATCHDOG: STALL|WATCHDOG: REPEAT'
```

Output:
```text
C:\Users\danhm\architect-loop\.architect\wt\hardening-dispatch-01\skills\architect\loop.md:44:- Exit 0 `WATCHDOG: ALL_DONE` -> proceed to the judging backlog for every
C:\Users\danhm\architect-loop\.architect\wt\hardening-dispatch-01\skills\architect\loop.md:46:- Exit 2 `WATCHDOG: INTEGRATED` -> benign mid-sweep integration; relaunch the
C:\Users\danhm\architect-loop\.architect\wt\hardening-dispatch-01\skills\architect\loop.md:48:- Exit 3 `WATCHDOG: STALL` -> run the rescue ladder: inspect the named job,
C:\Users\danhm\architect-loop\.architect\wt\hardening-dispatch-01\skills\architect\loop.md:51:- Exit 4 `WATCHDOG: REPEAT` -> rule intentional-vs-stuck before action; the
```
Exit code: 0

## DB7 size guard

Command:
```powershell
$env:UV_CACHE_DIR='.architect/tmp/uv-cache'; uv run --no-project python -c "import sys; t=sum(1 for p in ['skills/architect/SKILL.md','skills/architect/loop.md','skills/architect/dispatch.md'] for l in open(p,encoding='utf-8') if l.strip()); print(t)"
```

Output:
```text
766
```
Exit code: 0

STATUS: COMPLETE
