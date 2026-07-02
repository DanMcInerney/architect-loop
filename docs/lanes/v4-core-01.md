# v4-core-01 raw results

## Files changed

| File | + | - |
|---|---:|---:|
| skills/architect/HANDOFF.template.md | 63 | 29 |
| skills/architect/SKILL.md | 152 | 159 |
| skills/architect/dispatch.md | 145 | 152 |
| skills/architect/loop.md | 115 | 126 |
| tests/validate_skills.py | 160 | 151 |
| .claude/agents/architect-builder.md | 37 | 0 |
| .claude/agents/architect-judge.md | 25 | 0 |
| docs/lanes/v4-core-01.md | 255 | 0 |

## PowerShell suite

Command:

```powershell
$env:UV_CACHE_DIR='.architect/tmp/uv-cache'; uv run tests/validate_skills.py
```

Exit code: 0

Output:

```text
OK - 2 skills validated, v4 contracts clean
```

## Git Bash suite attempt

Command:

```powershell
bash -lc 'UV_CACHE_DIR=.architect/tmp/uv-cache uv run tests/validate_skills.py'
```

Exit code: 1

Output:

```text
Access is denied.
Error code: Bash/Service/CreateInstance/E_ACCESSDENIED
```

## VG5 exact grep: sentinel

Command:

```powershell
grep -ri sentinel skills/
```

Exit code: 1

Output:

```text
grep : The term 'grep' is not recognized as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is 
correct and try again.
At line:2 char:1
+ grep -ri sentinel skills/
+ ~~~~
    + CategoryInfo          : ObjectNotFound: (grep:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException
```

## VG5 exact grep: LOOP

Command:

```powershell
grep -rn "^LOOP:" skills/
```

Exit code: 1

Output:

```text
grep : The term 'grep' is not recognized as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is 
correct and try again.
At line:2 char:1
+ grep -rn "^LOOP:" skills/
+ ~~~~
    + CategoryInfo          : ObjectNotFound: (grep:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException
```

## VG5 fallback rg: sentinel

Command:

```powershell
rg -i sentinel skills
```

Exit code: 1

Output:

```text
```

## VG5 fallback rg: LOOP

Command:

```powershell
rg -n "^LOOP:" skills
```

Exit code: 1

Output:

```text
```

## Out-of-scope tracked diff check

Command:

```powershell
git diff --name-only 0f6442d -- bin tests/driver-canary.ps1 docs/gates docs/prd docs/adr docs/HANDOFF.md CONTEXT.md DESIGN.md README.md skills/architect/research.md install.ps1 install.sh .claude/settings.json .gitignore
```

Exit code: 0

Output:

```text
```

## git diff --check

Command:

```powershell
git diff --check
```

Exit code: 0

Output:

```text
warning: in the working copy of 'skills/architect/HANDOFF.template.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/SKILL.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/dispatch.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/loop.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'tests/validate_skills.py', LF will be replaced by CRLF the next time Git touches it
```

## git diff --numstat

Command:

```powershell
git diff --numstat 0f6442d -- skills/architect/SKILL.md skills/architect/loop.md skills/architect/dispatch.md skills/architect/HANDOFF.template.md tests/validate_skills.py
```

Exit code: 0

Output:

```text
63	29	skills/architect/HANDOFF.template.md
152	159	skills/architect/SKILL.md
145	152	skills/architect/dispatch.md
115	126	skills/architect/loop.md
160	151	tests/validate_skills.py
warning: in the working copy of 'skills/architect/HANDOFF.template.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/SKILL.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/dispatch.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/loop.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'tests/validate_skills.py', LF will be replaced by CRLF the next time Git touches it
```

## git diff --stat vs freeze commit 0f6442d

Command:

```powershell
git diff --stat 0f6442d
```

Exit code: 0

Output:

```text
 skills/architect/HANDOFF.template.md |  92 +++++++----
 skills/architect/SKILL.md            | 311 +++++++++++++++++------------------
 skills/architect/dispatch.md         | 297 ++++++++++++++++-----------------
 skills/architect/loop.md             | 241 +++++++++++++--------------
 tests/validate_skills.py             | 311 ++++++++++++++++++-----------------
 5 files changed, 635 insertions(+), 617 deletions(-)
warning: in the working copy of 'skills/architect/HANDOFF.template.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/SKILL.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/dispatch.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/loop.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'tests/validate_skills.py', LF will be replaced by CRLF the next time Git touches it
```

## git status --porcelain

Command:

```powershell
git status --porcelain
```

Exit code: 0

Output:

```text
 M skills/architect/HANDOFF.template.md
 M skills/architect/SKILL.md
 M skills/architect/dispatch.md
 M skills/architect/loop.md
 M tests/validate_skills.py
?? .claude/
?? docs/lanes/v4-core-01.md
```

## git status --porcelain -uall

Command:

```powershell
git status --porcelain -uall
```

Exit code: 0

Output:

```text
 M skills/architect/HANDOFF.template.md
 M skills/architect/SKILL.md
 M skills/architect/dispatch.md
 M skills/architect/loop.md
 M tests/validate_skills.py
?? .claude/agents/architect-builder.md
?? .claude/agents/architect-judge.md
?? .claude/settings.json
?? docs/lanes/v4-core-01.md
```

STATUS: COMPLETE_WITH_CONCERNS (Git Bash suite blocked by Bash/Service/CreateInstance/E_ACCESSDENIED; exact grep command unavailable in PowerShell; VG7/VG8 canaries not run by this builder; pre-existing untracked .claude/settings.json remains)
