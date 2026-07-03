# Checks: status-scripts

Purpose: verify the status-tree scripts and validator contract.
Spec (fix contract): `docs/spec/status-tree.md` — Interface contract section.
Files owned: `skills/architect/status.ps1`, `skills/architect/status.sh`,
`tests/validate_skills.py`.

Executor: PowerShell primary (MSYS binaries die in this sandbox); native
`git.exe` fine. `gh` is unavailable here — degraded mode is the tested path.
Orchestrator bookkeeping commits (reports under `docs/jobs/`, rulings) are
exempt from touch-set checks. Fixtures live under `.architect/tmp/stfix/`.

## SS1 — files exist with contract markers

PowerShell, PASS criteria:
- `Test-Path skills/architect/status.ps1; Test-Path skills/architect/status.sh` → `True`, `True`
- Both scripts contain all six phase glyph markers (`✓`,`◐`,`!`,`●`,`⊘`,`○`
  — in ps1 these may appear as `[char]0x2713` etc.; the check is that
  `check_status_contract` in WA-style terms passes, see SS5) and the literal
  `NO ACTIVE FACTORY RUN`:
  `(Select-String -Path skills/architect/status.sh -Pattern 'NO ACTIVE FACTORY RUN').Count` → ≥1
  `(Select-String -Path skills/architect/status.ps1 -Pattern 'NO ACTIVE FACTORY RUN').Count` → ≥1
- `(Get-Content skills/architect/status.sh -TotalCount 1)` starts with `#!`

## SS2 — ps1 parses

Run directly in the PowerShell session (not nested `powershell -Command`):
```powershell
$e = $null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path 'skills/architect/status.ps1').Path, [ref]$null, [ref]$e) | Out-Null
if ($e.Count -eq 0) { 'SS2_OK' } else { $e }
```
PASS: `SS2_OK`.

## SS3 — functional: fixture tree renders BUILDING, QUEUED, MERGED

Setup fixtures under `.architect/tmp/stfix/` simulating a run named in the
job report (a fake worktree dir `wt/demo-job-01` containing no report; an
events file `wt/demo-job-01.events.jsonl` whose last command event is
recognizable, e.g. containing `"command":"pytest -q"`). Invoke the script
with `-RepoRoot` pointed at a fixture root laid out like a repo (the script
must accept the flag per the spec). Because `gh` is absent, the header must
carry `tracker: unavailable (local view)`.

PASS criteria (verbatim output pasted):
- exit code 0
- output contains `tracker: unavailable (local view)`
- a `●` (BUILDING) line for the fixture job and a `last:` sub-line
  containing `pytest -q`
- with a second fixture where the report exists and ends
  `STATUS: BLOCKED (x)`, a `!` line appears
- with no factory artifacts at all (empty fixture root), output contains
  `NO ACTIVE FACTORY RUN` and exit 0

## SS4 — piped output contains zero ESC bytes

PowerShell:
```powershell
$out = & powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1 | Out-String
([Text.Encoding]::UTF8.GetBytes($out) -contains 27)
```
PASS: `False`. (Same idea for status.sh is composite-side; record that.)

## SS5 — validator contract

- `(Select-String -Path tests/validate_skills.py -Pattern '"status.ps1"').Count` → ≥1
- `(Select-String -Path tests/validate_skills.py -Pattern '"status.sh"').Count` → ≥1
- `(Select-String -Path tests/validate_skills.py -Pattern 'check_status_contract').Count` → ≥2 (definition + call)
- `$env:UV_CACHE_DIR='.architect/tmp/uv-cache'; uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('SS5_OK')"` → `SS5_OK`

## SS6 — read-only guard (static)

`Select-String -Path skills/architect/status.ps1,skills/architect/status.sh -Pattern 'Stop-Process|taskkill|Remove-Item|rm -|git (add|commit|push)'`
PASS: no matches — the status tree reads; it never mutates.
