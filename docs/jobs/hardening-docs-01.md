# hardening-docs-01

MIRROR: ORCHESTRATOR

## PHASE 0

Plan:

| Step | Files |
|---|---|
| Verify frozen input | `git log -1 --oneline`; `docs/checks/hardening-docs.md` |
| Read acceptance and source evidence | `docs/checks/hardening-docs.md`; `docs/spec/ops-hardening.md`; `docs/research/factory-hardening-evidence.md` |
| Patch allowed docs | `DESIGN.md`; `README.md`; `CONTEXT.md`; `docs/solutions/monitor-per-job-evidence.md`; `docs/solutions/git-bash-msys-codex-sandbox.md` |
| Run frozen checks sequentially | `docs/checks/hardening-docs.md` |

Disagreements:

| Item | Result | Checked |
|---|---|---|
| Issue/spec | none | `docs/checks/hardening-docs.md`; `docs/spec/ops-hardening.md`; `docs/research/factory-hardening-evidence.md`; `DESIGN.md`; `README.md`; `CONTEXT.md`; `docs/solutions/monitor-per-job-evidence.md` |

First-action input verification:

```powershell
git.exe log -1 --oneline
Test-Path -LiteralPath 'docs/checks/hardening-docs.md' | ForEach-Object { "docs/checks/hardening-docs.md exists: $_" }
```

```text
1d120d3 merge job hardening-dispatch-01 (judge PASS after PHASE-0 ruling, #38)
docs/checks/hardening-docs.md exists: True
```

DD4 pre-edit baseline:

```powershell
git.exe diff --stat $(git.exe rev-list -1 HEAD -- docs/solutions/monitor-per-job-evidence.md) -- docs/solutions/monitor-per-job-evidence.md
```

```text
```

## DD1

```powershell
git.exe grep -c "factory-hardening-evidence" -- DESIGN.md
```

```text
DESIGN.md:3
```

```powershell
git.exe grep -ci "watchdog" -- DESIGN.md
```

```text
DESIGN.md:5
```

```powershell
git.exe grep -ci "gas town\|gastown" -- DESIGN.md
```

```text
DESIGN.md:1
```

```powershell
git.exe grep -c "CreateFileMapping" -- DESIGN.md
```

```text
DESIGN.md:2
```

```powershell
git.exe grep -cE "codex#12000|codex/issues/12000" -- DESIGN.md
```

```text
DESIGN.md:1
```

```powershell
git.exe grep -ci "30 days\|30-day" -- DESIGN.md
```

```text
DESIGN.md:1
```

```powershell
git.exe grep -n "Stalled jobs" -- DESIGN.md
```

```text
DESIGN.md:484:| Stalled jobs | Watchdog script: growth + process + repeated-action checks; orchestrator rules on typed evidence; no kill ceilings |
```

## DD2

```powershell
git.exe grep -ci "watchdog" -- README.md
```

```text
README.md:6
```

```powershell
git.exe grep -c "APPROVE" -- README.md
```

```text
README.md:1
```

```powershell
Select-String -Path 'README.md' -Pattern 'watchdog|monitor|LLM|detection' -Context 1,1
```

```text

  README.md:46:The factory can run up to five builder jobs at once, plus one deterministic
> README.md:47:watchdog. The watchdog checks for stalled jobs using output growth, process
> README.md:48:activity, and repeated-command tails. No LLM sits in the detection loop; the
  README.md:49:script exits with evidence, and the orchestrator decides what to do.
  README.md:72:| Fresh judge owns the merge | A failing verdict cannot be talked around by anyone |
> README.md:73:| Deterministic watchdog | Stalls wake the orchestrator with evidence; the watchdog never kills or 
decides |
  README.md:74:| Builder boundaries | Each job gets a may-touch and must-not-touch set, then reports raw evidence |
  README.md:118:That's the whole interface. No daemons, no driver scripts, no extra windows.
> README.md:119:Builders, watchdogs, and judges run inside the session you're
  README.md:120:looking at, with durable state mirrored through GitHub issues and repo files.
  README.md:184:| [skills/architect/SKILL.md](skills/architect/SKILL.md) | The orchestrator role: intake, spec 
approval, factory loop, and hard stops |
> README.md:185:| [skills/architect/dispatch.md](skills/architect/dispatch.md) | Model aliases, issue conventions, 
builder/judge templates, watchdog dispatch, and respawn rules |
> README.md:186:| [skills/architect/loop.md](skills/architect/loop.md) | Factory event loop, watchdog protocol, 
failure ladder, and safety rails |
  README.md:187:| [skills/architect/research.md](skills/architect/research.md) | Slice-scale inline fact-check fan-out 
|
  README.md:206:
> README.md:207:**Can I watch?** Yes. Builders, watchdogs, and judges run inside your open
  README.md:208:session, and issue comments carry the durable progress trail.
```

```powershell
git.exe grep -inE "architect-monitor\.md" -- README.md DESIGN.md CONTEXT.md
```

```text
```

## DD3

```powershell
git.exe grep -ci "watchdog" -- CONTEXT.md
```

```text
CONTEXT.md:5
```

```powershell
Select-String -Path 'CONTEXT.md' -Pattern 'LLM monitor sweep' -Context 0,1
```

```text

> CONTEXT.md:93:- **LLM monitor sweep** - replaced by the watchdog script. The fallback
  CONTEXT.md:94:  template remains in `dispatch.md`.
```

```powershell
(Get-Content -LiteralPath 'CONTEXT.md' | Select-Object -First ((Select-String -Path 'CONTEXT.md' -Pattern '^## Retired terms').LineNumber - 1)) | Select-String -Pattern '\b(gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag)\b' -CaseSensitive:$false
```

```text
```

## DD4

```powershell
Test-Path -LiteralPath 'docs/solutions/git-bash-msys-codex-sandbox.md'
```

```text
True
```

```powershell
Select-String -Path 'docs/solutions/git-bash-msys-codex-sandbox.md' -Pattern 'CreateFileMapping|Win32 error 5|works|dies|openai/codex'
```

```text

docs\solutions\git-bash-msys-codex-sandbox.md:4:die at startup in the Codex Windows workspace-write sandbox with
docs\solutions\git-bash-msys-codex-sandbox.md:5:`CreateFileMapping ... Win32 error 5. Terminating.`
docs\solutions\git-bash-msys-codex-sandbox.md:8:startup path for per-user shared memory sections 
(`CreateFileMappingW`).
docs\solutions\git-bash-msys-codex-sandbox.md:15:| PowerShell | works |
docs\solutions\git-bash-msys-codex-sandbox.md:16:| Native `git.exe`, including `git grep` | works |
docs\solutions\git-bash-msys-codex-sandbox.md:17:| Git Bash `bash.exe` | dies with `CreateFileMapping` / `Win32 error 
5` |
docs\solutions\git-bash-msys-codex-sandbox.md:18:| Git for Windows `usr/bin/grep.exe`, `sed.exe` | dies the same way |
docs\solutions\git-bash-msys-codex-sandbox.md:19:| Windows outside Codex sandbox | works on this machine |
docs\solutions\git-bash-msys-codex-sandbox.md:26:**Upstream:** 
[openai/codex#12000](https://github.com/openai/codex/issues/12000)
docs\solutions\git-bash-msys-codex-sandbox.md:27:and 
[openai/codex#21715](https://github.com/openai/codex/issues/21715).
```

```powershell
git.exe grep -ci "watchdog" -- docs/solutions/monitor-per-job-evidence.md
```

```text
docs/solutions/monitor-per-job-evidence.md:1
```

```powershell
git.exe diff --stat $(git.exe rev-list -1 HEAD -- docs/solutions/monitor-per-job-evidence.md) -- docs/solutions/monitor-per-job-evidence.md
```

```text
 docs/solutions/monitor-per-job-evidence.md | 4 ++++
 1 file changed, 4 insertions(+)
warning: in the working copy of 'docs/solutions/monitor-per-job-evidence.md', LF will be replaced by CRLF the next time Git touches it
```

## DD5

```powershell
git.exe grep -oE "\]\((docs/[^)#]+)\)" -- DESIGN.md README.md
```

```text
DESIGN.md:](docs/spec/architect-v5.md)
DESIGN.md:](docs/adr/0001-in-session-loop-replaces-external-driver.md)
DESIGN.md:](docs/research/autonomous-software-factory.md)
DESIGN.md:](docs/spec/architect-v5.md)
DESIGN.md:](docs/research/autonomous-software-factory.md)
DESIGN.md:](docs/spec/architect-v5.md)
DESIGN.md:](docs/spec/architect-v5.1.md)
DESIGN.md:](docs/research/loop-improvements.md)
DESIGN.md:](docs/research/autonomous-software-factory.md)
DESIGN.md:](docs/research/factory-hardening-evidence.md)
DESIGN.md:](docs/solutions/worktree-stale-snapshot.md)
DESIGN.md:](docs/research/factory-hardening-evidence.md)
DESIGN.md:](docs/research/lesson-store-evidence.md)
DESIGN.md:](docs/research/loop-improvements.md)
DESIGN.md:](docs/research/agent-pipeline-patterns.md)
DESIGN.md:](docs/adr/0001-in-session-loop-replaces-external-driver.md)
DESIGN.md:](docs/spec/architect-v5.md)
DESIGN.md:](docs/solutions/subagent-shell-strip-codex-fallback.md)
DESIGN.md:](docs/research/factory-hardening-evidence.md)
DESIGN.md:](docs/solutions/git-bash-msys-codex-sandbox.md)
DESIGN.md:](docs/solutions/uv-cache-sandbox-redirect.md)
```

```powershell
$matches = git.exe grep -oE "\]\((docs/[^)#]+)\)" -- DESIGN.md README.md
$targets = foreach ($m in $matches) { if ($m -match '\]\((docs/[^)#]+)\)') { $Matches[1] } }
$targets | Sort-Object -Unique | ForEach-Object { "$_ : $(Test-Path -LiteralPath $_)" }
```

```text
docs/adr/0001-in-session-loop-replaces-external-driver.md : True
docs/research/agent-pipeline-patterns.md : True
docs/research/autonomous-software-factory.md : True
docs/research/factory-hardening-evidence.md : True
docs/research/lesson-store-evidence.md : True
docs/research/loop-improvements.md : True
docs/solutions/git-bash-msys-codex-sandbox.md : True
docs/solutions/subagent-shell-strip-codex-fallback.md : True
docs/solutions/uv-cache-sandbox-redirect.md : True
docs/solutions/worktree-stale-snapshot.md : True
docs/spec/architect-v5.1.md : True
docs/spec/architect-v5.md : True
```

## Boundary

```powershell
git.exe status --short
```

```text
 M CONTEXT.md
 M DESIGN.md
 M README.md
 M docs/solutions/monitor-per-job-evidence.md
?? docs/jobs/hardening-docs-01.md
?? docs/solutions/git-bash-msys-codex-sandbox.md
```

```powershell
git.exe diff --name-only
```

```text
CONTEXT.md
DESIGN.md
README.md
docs/solutions/monitor-per-job-evidence.md
warning: in the working copy of 'CONTEXT.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'DESIGN.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'README.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'docs/solutions/monitor-per-job-evidence.md', LF will be replaced by CRLF the next time Git touches it
```

```powershell
git.exe ls-files --others --exclude-standard
```

```text
docs/jobs/hardening-docs-01.md
docs/solutions/git-bash-msys-codex-sandbox.md
```

STATUS: COMPLETE
