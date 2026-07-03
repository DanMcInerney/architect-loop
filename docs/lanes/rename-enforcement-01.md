PHASE 0 INPUT VERIFICATION

Command:
```powershell
$head = git log -1 --oneline
$gateExists = Test-Path -LiteralPath 'docs/gates/rename-enforcement.md'
"HEAD=$head"
"docs/gates/rename-enforcement.md exists=$gateExists"
```

Output:
```text
HEAD=c044e1a re-freeze: stress-test amendments to rename checks (derivative terms, grep -c output form, CSS classes, kill-switch coverage)
docs/gates/rename-enforcement.md exists=True
```

PHASE 0 PLAN

| Step | Files |
|---|---|
| Read binding spec and frozen checks | `docs/spec/rename-domain-language.md`, `docs/gates/rename-enforcement.md` |
| Update validator enforcement strings without behavior changes | `tests/validate_skills.py` |
| Update unignore entries | `.gitignore` |
| Rename prose while preserving frontmatter contracts | `.claude/agents/architect-builder.md`, `.claude/agents/architect-judge.md`, `.claude/agents/architect-monitor.md` |
| Verify installers for retired terms or renamed file references | `install.sh`, `install.ps1` |
| Run EN1-EN5 sequentially with workspace-local cache/temp paths | `docs/gates/rename-enforcement.md` |
| Write raw command output report | `docs/lanes/rename-enforcement-01.md` |

PHASE 0 DISAGREEMENTS / CHECKS

| Item | Evidence |
|---|---|
| Disagreement: `implement` skill says commit; issue says do not commit. | `C:\Users\danhm\.agents\skills\implement\SKILL.md`: `Commit your work to the current branch.` / issue: `Do NOT commit and do NOT run git add / git mv` |
| Scope checked sound: frozen check says files owned are the seven requested files. | `docs/gates/rename-enforcement.md`: `Files owned: ... tests/validate_skills.py, .gitignore, install.sh, install.ps1.` |
| Scope checked sound: spec A2 says this run's artifacts still use `docs/gates/` and `docs/lanes/`. | `docs/spec/rename-domain-language.md`: `This run's own artifacts follow the currently installed skill: its check files freeze under docs/gates/, job reports under docs/lanes/.` |
| Pre-edit tracked status | `git status --short` output: empty |
| Installer check | See pre-edit term scan output below: no `install.sh` or `install.ps1` rows. |

MIRROR: ORCHESTRATOR

PRE-EDIT TERM SCAN

Command:
```powershell
rg -n -i "gate|gates|gated|lane|lanes|brain|brawn|cold|epic|grill|grilled|grilling|dag|stop rail|spec gate" tests/validate_skills.py .claude/agents install.sh install.ps1 .gitignore docs/spec/rename-domain-language.md
```

Output:
```text
.gitignore:7:!/docs/gates/
.gitignore:8:!/docs/lanes/
docs/spec/rename-domain-language.md:4:after reading the docs (DAG, gate, cold, epic, brain/brawn, lane, grill,
docs/spec/rename-domain-language.md:5:frontier, stop rail) is replaced with terms a first-time reader already knows.
docs/spec/rename-domain-language.md:18:| brain (role) | **orchestrator** | "orchestrator-tier" replaces "brain-tier" |
docs/spec/rename-domain-language.md:19:| brawn (role) | **builders** / a builder | |
docs/spec/rename-domain-language.md:20:| `brain =` / `brawn =` config keys | **`orchestrator =`** / **`builders =`** | no aliases; old keys hit the existing unknown-key warning |
docs/spec/rename-domain-language.md:21:| gate / gate file | **check** / check file | "frozen checks", "acceptance checks" |
docs/spec/rename-domain-language.md:22:| `docs/gates/` | **`docs/checks/`** | future runs; see A2 |
docs/spec/rename-domain-language.md:23:| spec gate | **spec approval** | the word "gate" disappears entirely |
docs/spec/rename-domain-language.md:24:| cold (agent) | **fresh** | judge may also be described as "independent" |
docs/spec/rename-domain-language.md:25:| epic (issue) | **tracking issue** | |
docs/spec/rename-domain-language.md:26:| issue DAG | **the plan** / issues linked with blocked-by | "DAG" retired as a noun |
docs/spec/rename-domain-language.md:28:| lane / lane report | **job** / job report | build loop |
docs/spec/rename-domain-language.md:29:| `docs/lanes/` | **`docs/jobs/`** | future runs; see A2 |
docs/spec/rename-domain-language.md:31:| grill | **stress-test** | "one fresh stress-test pass attacks the whole plan" |
docs/spec/rename-domain-language.md:32:| stop rails | **hard stops** | |
docs/spec/rename-domain-language.md:34:| research lane | **researcher** | research skill |
docs/spec/rename-domain-language.md:35:| `skills/architect-research/lanes.md` | **`tactics.md`** | file renamed; validator + references updated |
docs/spec/rename-domain-language.md:58:| Research skill | `skills/architect-research/SKILL.md`, `lanes.md` -> `tactics.md` |
docs/spec/rename-domain-language.md:71:  the `(brain|brawn)` alternation.
docs/spec/rename-domain-language.md:73:  `Frozen gate file path:`; `Per check:` replaces `Per gate:`;
docs/spec/rename-domain-language.md:74:  `Checks integrity:` replaces `Gates integrity:`. HTML comment markers
docs/spec/rename-domain-language.md:76:  `architect-grill-template`) keep their names EXCEPT
docs/spec/rename-domain-language.md:77:  `architect-grill-template` -> `architect-stress-test-template`.
docs/spec/rename-domain-language.md:78:- Section headings renamed: dispatch.md `## Grill delegation template` ->
docs/spec/rename-domain-language.md:83:- `.gitignore`: add `!/docs/checks/` and `!/docs/jobs/`; KEEP `!/docs/gates/`
docs/spec/rename-domain-language.md:84:  and `!/docs/lanes/` (historical branches and this run's own artifacts).
docs/spec/rename-domain-language.md:88:- **A1.** "epic" -> "tracking issue"; "digest" stays "digest".
docs/spec/rename-domain-language.md:91:  its check files freeze under `docs/gates/`, job reports under `docs/lanes/`.
docs/spec/rename-domain-language.md:93:  truthful: first mention reads "the stress-test pass (called the *grill* in
docs/spec/rename-domain-language.md:95:- **A4.** `CONTEXT.md`'s "Retired terms" section absorbs: gate, DAG, cold,
docs/spec/rename-domain-language.md:96:  epic, brain, brawn, lane, grill, frontier, stop rail -- one line each with
docs/spec/rename-domain-language.md:107:  sensitivity chosen to avoid substring traps ("delegate", "aggregated",
docs/spec/rename-domain-language.md:108:  "Plane") and exempt CONTEXT.md's retired-terms section and A3 historical
tests/validate_skills.py:28:    "architect-research": ["lanes.md"],
tests/validate_skills.py:108:        if re.match(r"(docs|lane|gate|spec|research)", ref):
tests/validate_skills.py:177:ROLE_CONFIG_RE = re.compile(r"^(brain|brawn)\s*=\s*(claude|codex)/[^\s/#]+(:[^\s/#]+)?$")
tests/validate_skills.py:192:        if any(line.startswith(("brain =", "brawn =", "when ")) for line in lines):
tests/validate_skills.py:196:        errors.append("skills/architect: no fenced C2/C2' config example with brain/brawn or dispatch rules")
tests/validate_skills.py:228:        "Frozen gate file path:",
tests/validate_skills.py:232:        "Gates integrity:",
tests/validate_skills.py:234:        "Per gate:",
.claude/agents\architect-monitor.md:3:description: Detection-only liveness sweeps over in-flight factory lanes. Use when the orchestrator has dispatched brawn builder lanes and needs a cheap background watcher to flag stalls with evidence -- never to kill, nudge, or judge a lane.
.claude/agents\architect-monitor.md:9:You are an architect monitor. Your task is: sweep the in-flight factory lanes
.claude/agents\architect-monitor.md:16:- You receive a list of in-flight lanes: report paths, worktree paths, and
.claude/agents\architect-monitor.md:19:- Sweep every 10 min. Per lane, check: report/output file growth since the
.claude/agents\architect-monitor.md:21:  the lane's output is a repeated identical command (a stall signal).
.claude/agents\architect-monitor.md:22:- All lanes healthy -> sleep, then sweep again.
.claude/agents\architect-monitor.md:23:- All lanes done (every lane report ends with a STATUS line) -> exit quietly
.claude/agents\architect-monitor.md:25:- ANY anomaly on ANY lane -> exit IMMEDIATELY with an evidence report: lane
.claude/agents\architect-monitor.md:27:  and the duration-hint context for that lane. Stop sweeping the moment you
.claude/agents\architect-monitor.md:29:- You never kill a process, never message a lane, and never judge quality --
.claude/agents\architect-monitor.md:30:  evidence only. The brain reads your evidence and rules on what happens
.claude/agents\architect-monitor.md:41:You do not have write tools. You cannot fix, nudge, or touch a lane even if
.claude/agents\architect-judge.md:3:description: Runs frozen architect gates as a cold read-only judge, checks gates integrity and diff intent, and returns PASS/FAIL/INVALID verdicts with raw evidence only.
.claude/agents\architect-judge.md:14:- Read the frozen gate file named in the prompt.
.claude/agents\architect-judge.md:15:- Read `docs/lanes/<issue-slug>-rulings.md` when present. It is
.claude/agents\architect-judge.md:17:  the frozen gate file, spec, and lane report. If it is absent or empty, record
.claude/agents\architect-judge.md:19:- Check gates integrity with the freeze commit SHA and branch to judge.
.claude/agents\architect-judge.md:20:- Run each gate command exactly as written, unless the command is impossible to
.claude/agents\architect-judge.md:24:- Return verdicts only: per-gate PASS / FAIL / INVALID, gates-integrity
.claude/agents\architect-judge.md:33:- If Bash is absent at runtime (desktop strip, D9), run gate commands via the
.claude/agents\architect-builder.md:3:description: Runs one architect builder lane from a frozen slice spec, respecting lane boundaries, worktree isolation, raw-only reporting, and never committing or pushing.
.claude/agents\architect-builder.md:11:You are an architect builder. Your task is: execute exactly one lane from the
.claude/agents\architect-builder.md:19:- Obey the lane shape. `ship` may change only the files in BOUNDARIES. `scout`
.claude/agents\architect-builder.md:21:- Build your lane only. The orchestrator owns lane splitting; files outside
.claude/agents\architect-builder.md:23:- The files under `docs/gates/` are read-only at all times.
.claude/agents\architect-builder.md:24:- The files matching `docs/lanes/*-rulings.md` are also read-only at all
.claude/agents\architect-builder.md:25:  times. They are orchestrator-owned, the same class as `docs/gates/`; creating
.claude/agents\architect-builder.md:26:  or editing one fails the lane.
.claude/agents\architect-builder.md:32:- Run the lane's gate commands sequentially with temp/cache paths inside
.claude/agents\architect-builder.md:34:- Write the lane report exactly where requested -- the convention is
.claude/agents\architect-builder.md:35:  `docs/lanes/<issue-slug>-01.md` -- as the raw-evidence artifact: tables,
.claude/agents\architect-builder.md:40:- Mirror duty: when the lane's final STATUS is reached, post it plus a short
.claude/agents\architect-builder.md:52:- If Bash is absent at runtime (desktop strip, D9), run gate commands via the
.claude/agents\architect-builder.md:54:  lane report.
.claude/agents\architect-builder.md:56:Verdicts belong to the judge, orchestrator, and human. Persist until the lane is
```

POST-EDIT LOCAL TERM SCAN

Command:
```powershell
rg -n -i "\b(gate|gates|gated|lane|lanes|brain|brawn|cold|epic|grill|grilled|grilling|dag)\b|stop rail|spec gate" tests/validate_skills.py .claude/agents install.sh install.ps1 .gitignore
```

Output:
```text
.gitignore:9:!/docs/gates/
.gitignore:10:!/docs/lanes/
```

EN1 - RETIRED TERMS ABSENT

Executor: PowerShell.

Command:
```powershell
git grep -inwE "gate|gates|gated|lane|lanes|brain|brawn|cold|epic|grill|grilled|grilling|dag" -- tests/validate_skills.py .claude/agents/ install.sh install.ps1
```

Exit code: 1

Output:
```text
```

Command:
```powershell
git grep -inE "stop rail|spec gate" -- tests/validate_skills.py .claude/agents/ install.sh install.ps1
```

Exit code: 1

Output:
```text
```

EN2 - .gitignore UNIGNORE COUNTS

Executor: PowerShell.

Command:
```powershell
grep -c '^!/docs/checks/$' .gitignore && grep -c '^!/docs/jobs/$' .gitignore && grep -c '^!/docs/gates/$' .gitignore && grep -c '^!/docs/lanes/$' .gitignore
```

Exit code: 1

Output:
```text
At line:2 char:39
+ grep -c '^!/docs/checks/$' .gitignore && grep -c '^!/docs/jobs/$' .gi ...
+                                       ~~
The token '&&' is not a valid statement separator in this version.
At line:2 char:78
+ ... hecks/$' .gitignore && grep -c '^!/docs/jobs/$' .gitignore && grep -c ...
+                                                                ~~
The token '&&' is not a valid statement separator in this version.
At line:2 char:118
+ ... jobs/$' .gitignore && grep -c '^!/docs/gates/$' .gitignore && grep -c ...
+                                                                ~~
The token '&&' is not a valid statement separator in this version.
    + CategoryInfo          : ParserError: (:) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : InvalidEndOfLine
```

PowerShell same-pattern substitution:
```powershell
foreach ($pattern in @('^!/docs/checks/$','^!/docs/jobs/$','^!/docs/gates/$','^!/docs/lanes/$')) { (Select-String -Path '.gitignore' -Pattern $pattern).Count }
```

Exit code: 0

Output:
```text
1
1
1
1
```

EN3 - VALIDATOR CONTRACT

Executor: PowerShell.

Command:
```powershell
grep -cE "orchestrator\|builders" tests/validate_skills.py
```

Exit code: 1

Output:
```text
      0 [main] grep (37548) C:\Program Files\Git\usr\bin\grep.exe: *** fatal error - CreateFileMapping S-1-5-21-940813291-4134638421-1989498454-1002.1, Win32 error 5.  Terminating.
```

PowerShell same-pattern substitution:
```powershell
(Select-String -Path 'tests/validate_skills.py' -Pattern 'orchestrator\|builders').Count
```

Exit code: 0

Output:
```text
1
```

PowerShell same-pattern substitution:
```powershell
(Select-String -Path 'tests/validate_skills.py' -Pattern '"tactics\.md"').Count
```

Exit code: 0

Output:
```text
1
```

PowerShell same-pattern substitution:
```powershell
(Select-String -Path 'tests/validate_skills.py' -Pattern '"lanes\.md"').Count
```

Exit code: 0

Output:
```text
0
```

PowerShell same-pattern substitution:
```powershell
(Select-String -Path 'tests/validate_skills.py' -Pattern '"Frozen check file path:"').Count
```

Exit code: 0

Output:
```text
1
```

PowerShell same-pattern substitution:
```powershell
(Select-String -Path 'tests/validate_skills.py' -Pattern '"Checks integrity:"').Count
```

Exit code: 0

Output:
```text
1
```

PowerShell same-pattern substitution:
```powershell
(Select-String -Path 'tests/validate_skills.py' -Pattern '"Per check:"').Count
```

Exit code: 0

Output:
```text
1
```

PowerShell same-pattern substitution:
```powershell
(Select-String -Path 'tests/validate_skills.py' -Pattern '"Frozen gate file path:"').Count
```

Exit code: 0

Output:
```text
0
```

EN4 - AGENT CONTRACTS

Executor: PowerShell.

PowerShell same-pattern substitution:
```powershell
(Select-String -Path '.claude/agents/architect-builder.md' -Pattern 'isolation: worktree').Count
```

Exit code: 0

Output:
```text
1
```

PowerShell same-pattern substitution:
```powershell
(Select-String -Path '.claude/agents/architect-builder.md' -Pattern 'model: inherit').Count
```

Exit code: 0

Output:
```text
1
```

PowerShell same-pattern substitution:
```powershell
(Select-String -Path '.claude/agents/architect-builder.md' -Pattern 'Bash\(git commit \*\)').Count
```

Exit code: 0

Output:
```text
1
```

PowerShell same-pattern substitution:
```powershell
(Select-String -Path '.claude/agents/architect-judge.md' -Pattern 'model: inherit').Count
```

Exit code: 0

Output:
```text
1
```

PowerShell same-pattern substitution:
```powershell
$line = (Select-String -Path '.claude/agents/architect-judge.md' -Pattern '^tools:').Line
if ($line -match '\b(Edit|Write)\b') { 1 } else { 0 }
```

Exit code: 0

Output:
```text
0
```

EN5 - PYTHON SYNTAX

Executor: PowerShell.

PowerShell environment substitution for `UV_CACHE_DIR=.architect/tmp/uv-cache`:
```powershell
$env:UV_CACHE_DIR = '.architect/tmp/uv-cache'
uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('EN5_OK')"
```

Exit code: 0

Output:
```text
EN5_OK
```

TOUCH SET AUDIT

Command:
```powershell
git status --short
```

Output:
```text
 M .claude/agents/architect-builder.md
 M .claude/agents/architect-judge.md
 M .claude/agents/architect-monitor.md
 M .gitignore
 M tests/validate_skills.py
?? docs/lanes/
```

Command:
```powershell
git diff --name-only
```

Output:
```text
.claude/agents/architect-builder.md
.claude/agents/architect-judge.md
.claude/agents/architect-monitor.md
.gitignore
tests/validate_skills.py
warning: in the working copy of '.claude/agents/architect-builder.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of '.claude/agents/architect-judge.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of '.claude/agents/architect-monitor.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of '.gitignore', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'tests/validate_skills.py', LF will be replaced by CRLF the next time Git touches it
```

Command:
```powershell
git status --short -- docs/gates
```

Output:
```text
```

STATUS: COMPLETE
