# skill-guards-01

## PHASE 0

First action:

```powershell
$check = Test-Path -LiteralPath 'docs/checks/skill-guards.md'; "CHECK_EXISTS=$check"; git.exe status --short
```

```text
CHECK_EXISTS=True
```

Freeze check:

```powershell
git.exe log -1 --format=%H -- docs/checks/skill-guards.md
```

```text
a3d7a231751988577b2e4ec763c7e2674f9d0c06
```

Live executor:

```powershell
$PSVersionTable.PSVersion.ToString(); (Get-Command git.exe).Source; git.exe --version; (Get-Command uv).Source; uv --version; if (Test-Path pyproject.toml) { 'PYPROJECT=present' } else { 'PYPROJECT=absent' }; if (Test-Path requirements.txt) { 'REQUIREMENTS=present' } else { 'REQUIREMENTS=absent' }
```

```text
5.1.26100.8655
C:\Program Files\Git\mingw64\bin\git.exe
git version 2.51.2.windows.1
C:\Users\danhm\.local\bin\uv.exe
uv 0.9.10 (44f5a14f4 2025-11-17)
PYPROJECT=absent
REQUIREMENTS=absent
```

Pre-edit validator:

```powershell
New-Item -ItemType Directory -Force -Path .architect/tmp/uv-cache | Out-Null; $env:UV_CACHE_DIR = '.architect/tmp/uv-cache'; uv run --no-project python tests/validate_skills.py; $LASTEXITCODE
```

```text
OK - 2 skills validated, v4 contracts clean
0
```

Disagreements:

| Item | File evidence | Handling |
|---|---|---|
| Source spec G3 says DESIGN.md should match enforced 900; G4/A1 and dispatch say 1100. | docs/spec/skill-hygiene.md:103-104; docs/spec/skill-hygiene.md:109-115; docs/spec/skill-hygiene.md:149-161 | Used 1100. |
| SG7 only greps `800-non-blank`; dispatch also requires replacing risk-table `800-line guard`. | docs/checks/skill-guards.md:25; DESIGN.md:648 | Replaced both DESIGN.md strings. |

Plan:

| Step | Files |
|---|---|
| Validator constants and guards | tests/validate_skills.py |
| DESIGN stale sentence and risk-table cell | DESIGN.md |
| Raw report | docs/jobs/skill-guards-01.md |
| Verify | SG1-SG8 sequentially |

Initial counts:

```text
skills/architect/SKILL.md	215
skills/architect/dispatch.md	566
skills/architect/loop.md	114
skills/architect/tracker.md	60
skills/architect/research.md	75
skills/architect-research/SKILL.md	146
skills/architect-research/tactics.md	177
```

Prior report further DESIGN contradictions:

```powershell
$matches = Select-String -Path docs/jobs/skill-text-01.md -Pattern 'DESIGN\.md:(?!572|648)\d+'; if ($matches) { $matches | ForEach-Object { "$($_.LineNumber):$($_.Line)" } } else { 'NO ADDITIONAL DESIGN.md:<line> MATCHES' }
```

```text
NO ADDITIONAL DESIGN.md:<line> MATCHES
```

## RUN Checks

SG1

Executor: PowerShell 5.1 + native git.exe; substitution: `UV_CACHE_DIR=.architect/tmp/uv-cache`.

```powershell
uv run --no-project python tests/validate_skills.py; $LASTEXITCODE
```

```text
OK - 2 skills validated, v4 contracts clean
0
```

SG2

Executor: PowerShell 5.1 + native git.exe.

```powershell
(Get-Content tests/validate_skills.py | Select-String 'research\.md').Count -ge 2
```

```text
True
```

SG3

Executor: PowerShell 5.1 + native git.exe.

```powershell
(Get-Content tests/validate_skills.py | Select-String 'tracker\.md').Count -ge 5
```

```text
True
```

SG4

Executor: PowerShell 5.1 + native git.exe.

```powershell
(Get-Content tests/validate_skills.py | Select-String '1100').Count -ge 1
```

```text
True
```

SG5

Executor: PowerShell 5.1 + native git.exe.

```powershell
(Get-Content tests/validate_skills.py | Select-String 'tactics\.md').Count -ge 2
```

```text
True
```

SG6

Executor: PowerShell 5.1 + native git.exe.

```powershell
(Get-Content tests/validate_skills.py | Select-String '5000|5_000').Count -ge 1
```

```text
True
```

SG7

Executor: PowerShell 5.1 + native git.exe.

```powershell
(Get-Content DESIGN.md | Select-String '800-non-blank').Count
```

```text
0
```

SG8

Executor: PowerShell 5.1 + native git.exe.

```powershell
(Get-Content tests/validate_skills.py | Select-String '## Contents').Count -ge 1
```

```text
True
```

## Additional Raw Evidence

Validator anchors:

```text
26	ARCHITECT_SKILL_TEXT_MAX_NON_BLANK = 1100
27	ARCHITECT_RESEARCH_TEXT_MAX_NON_BLANK = 500
28	SKILL_BODY_TOKEN_PROXY_MAX = 5_000
29	SKILL_BODY_TOKEN_PROXY_FACTOR = 1.33
30	REFERENCE_TOC_NON_BLANK_THRESHOLD = 100
392	def check_skill_text_size() -> None:
421	def check_architect_research_text_size() -> None:
440	def check_skill_body_token_budgets() -> None:
452	def check_reference_tocs() -> None:
467	def check_design_guard_cap() -> None:
```

Formula/rationale anchors:

```text
394	    exhaustive/comprehensive content and skill count (SkillsBench v4), not a
395	    200-line target. Compaction reattach economics are the binding constraint:
416	            "SkillsBench v4 exhaustive/comprehensive content and skill count cliff; "
417	            "compaction reattaches first 5,000 tokens per invoked skill, 25,000 combined)"
442	        # Deterministic local proxy per A4: estimated tokens = word count * 1.33.
448	                "(A4 words x 1.33; compaction reattaches first 5,000 tokens per invoked skill)"
```

Post-edit counts:

```text
skills/architect/SKILL.md	215
skills/architect/dispatch.md	566
skills/architect/loop.md	114
skills/architect/tracker.md	60
skills/architect/research.md	75
TOTAL	1030
skills/architect-research/SKILL.md	146
skills/architect-research/tactics.md	177
PAIR_TOTAL	323
```

DESIGN grep:

```text
C:\Users\danhm\tools\architect-loop\.architect\wt\skill-guards-01\DESIGN.md:572:- **A 1100-non-blank-line size guard is enforced by the validator (P5).**
C:\Users\danhm\tools\architect-loop\.architect\wt\skill-guards-01\DESIGN.md:649:| Harness bloat / obsolescence | Thin declarative skill; 1100-non-blank-line guard; per-model-generation pruning review |
```

docs/checks diff:

```powershell
git.exe diff --name-only -- docs/checks/
```

```text
```

Diff names before report:

```text
DESIGN.md
tests/validate_skills.py
warning: in the working copy of 'DESIGN.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'tests/validate_skills.py', LF will be replaced by CRLF the next time Git touches it
```

Final Git Output:

```powershell
git.exe status --short
```

```text
 M DESIGN.md
 M tests/validate_skills.py
?? docs/jobs/skill-guards-01.md
```

MIRROR: ORCHESTRATOR

STATUS: COMPLETE_WITH_CONCERNS (docs/spec/skill-hygiene.md:103-104 says enforced 900 while G4/A1 dispatch uses 1100; docs/checks/skill-guards.md:25 SG7 does not grep DESIGN.md risk-table 800-line wording)
