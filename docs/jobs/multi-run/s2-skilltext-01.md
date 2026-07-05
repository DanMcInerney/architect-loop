# PHASE 0

Plan:
1. Keep `docs/checks/` read-only.
2. Edit only `skills/architect/SKILL.md`, `skills/architect/tracker.md`, `skills/architect/dispatch.md`, `skills/architect/loop.md`.
3. Replace tracker highest-parent scan with `docs/runs/<run>/manifest.md` pinning and `docs/issues/<run>/` numbering.
4. Add pinned-run grounding, intake ordering, run marker, stop semantics, one-checkout-per-live-run, status slug invocation.
5. Namespace dispatch/loop examples for `docs/checks/<run>/`, `docs/jobs/<run>/`, `job/<run>/`, `.architect/wt/<run>/`.
6. Preserve template marker comments and validator guards.
7. Run frozen RUN commands and `uv run python tests/validate_skills.py`.

Disagreements / concerns:
1. Report path boundary tension: frozen check requires `docs/jobs/multi-run/s2-skilltext-01.md` at `docs/checks/multi-run/s2-skilltext.md:11-13`; implementation boundary names only the four skill files.
2. Status interface live mismatch: `docs/spec/multi-run.md:57-63` requires run slug status scripts; current `skills/architect/status.ps1:1` takes only `RepoRoot`, current `skills/architect/status.sh:5` discards unknown positional args, and old selection remains at `skills/architect/status.ps1:88` / `skills/architect/status.sh:56`. Sibling job owns scripts.

# Input Verification

Command:
```powershell
$head = git rev-parse HEAD
$exists = Test-Path -LiteralPath 'docs/checks/multi-run/s2-skilltext.md'
"HEAD=$head"
"CHECK_EXISTS=$exists"
if ($head -ne 'd9efaf6b8a2f7d77fc0f511d7ce5427803450e43') { exit 10 }
if (-not $exists) { exit 11 }
exit 0
```
stdout:
```text
HEAD=d9efaf6b8a2f7d77fc0f511d7ce5427803450e43
CHECK_EXISTS=True
```
stderr:
```text
```
exit code: 0

# Dependency Probes

Command:
```powershell
git --version
uv --version
python --version
$gh = Get-Command gh -ErrorAction SilentlyContinue; if ($gh) { "gh=$($gh.Source)" } else { 'gh=NOT_FOUND' }
```
stdout:
```text
git version 2.51.2.windows.1
uv 0.9.10 (44f5a14f4 2025-11-17)
gh=C:\Program Files\GitHub CLI\gh.exe
Python was not found; run without arguments to install from the Microsoft Store, or disable this shortcut from Settings > Apps > Advanced app settings > App execution aliases.
```
stderr:
```text
```
exit code: 0

# Non-Blank Lines

| File | Before | After |
|---|---:|---:|
| `skills/architect/SKILL.md` | 240 | 255 |
| `skills/architect/tracker.md` | 60 | 66 |
| `skills/architect/dispatch.md` | 566 | 572 |
| `skills/architect/loop.md` | 118 | 120 |

After capped set:
```text
skills/architect total capped set	1088
```

# Judge-Only Citations

```text
skills/architect/SKILL.md:63-65 pinned run grounding and wider tracker out of scope
skills/architect/dispatch.md:369-371 wrong-author or missing-run-marker sub-issue never dispatched, digest escalation
skills/architect/SKILL.md:167-169 one checkout per live run
skills/architect/SKILL.md:104-110 create tracking issue first, then write docs/runs/<run>/manifest.md
skills/architect/SKILL.md:72-73 docs/STOP checked in run checkout and primary checkout via git common dir
skills/architect/loop.md:124 global plus per-run stop table row
```

# Frozen RUN Checks

Command:
```powershell
git grep -F -c "docs/runs/<run>/manifest.md" -- skills/architect/SKILL.md skills/architect/tracker.md
```
stdout:
```text
skills/architect/SKILL.md:2
skills/architect/tracker.md:1
```
stderr:
```text
```
exit code: 0

Command:
```powershell
git grep -F -c "architect-run:" -- skills/architect
```
stdout:
```text
skills/architect/SKILL.md:2
skills/architect/dispatch.md:1
```
stderr:
```text
```
exit code: 0

Command:
```powershell
git grep -F -c "docs/checks/<run>/" -- skills/architect
```
stdout:
```text
skills/architect/SKILL.md:1
skills/architect/dispatch.md:6
```
stderr:
```text
```
exit code: 0

Command:
```powershell
git grep -F -c "docs/jobs/<run>/" -- skills/architect
```
stdout:
```text
skills/architect/SKILL.md:1
skills/architect/dispatch.md:14
skills/architect/loop.md:2
```
stderr:
```text
```
exit code: 0

Command:
```powershell
git grep -F -c "docs/issues/<run>/" -- skills/architect/tracker.md
```
stdout:
```text
skills/architect/tracker.md:3
```
stderr:
```text
```
exit code: 0

Command:
```powershell
git grep -F -c "job/<run>/" -- skills/architect/dispatch.md
```
stdout:
```text
skills/architect/dispatch.md:5
```
stderr:
```text
```
exit code: 0

Command:
```powershell
git grep -F -c "docs/runs/<run>/STOP" -- skills/architect
```
stdout:
```text
skills/architect/SKILL.md:2
skills/architect/loop.md:2
```
stderr:
```text
```
exit code: 0

Command:
```powershell
git grep -F -n "highest such number wins" -- skills/architect
```
stdout:
```text
```
stderr:
```text
```
exit code: 1

Command:
```powershell
$env:UV_CACHE_DIR = '.architect/tmp/uv-cache'
$env:TEMP = '.architect/tmp/s2-skilltext-temp'
$env:TMP = '.architect/tmp/s2-skilltext-temp'
uv run python tests/validate_skills.py
```
stdout:
```text
OK - 2 skills validated, v4 contracts clean
```
stderr:
```text
```
exit code: 0

MIRROR: ORCHESTRATOR
STATUS: COMPLETE_WITH_CONCERNS (report path required outside implementation boundary; status script interface owned by sibling job and not live in this checkout)
