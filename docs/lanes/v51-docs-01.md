# Lane report: v51-docs-01 (issue #25)

## PHASE 0

Plan:

1. Add a v5.1 addendum at the end of the existing v5 section in `DESIGN.md`
   after the current dogfood evidence block (`DESIGN.md:818`,
   `DESIGN.md:883`).
2. Add only one preflight/backend-canary sentence in `README.md` under
   Preconditions (`README.md:68-76`), because the frozen gate says README
   changes are limited to the canary/preflight sentence area
   (`docs/gates/v51-docs.md:28-30`).
3. Create this report with Phase 0, files touched, and raw gate output. Do not
   edit `docs/gates/**` or `docs/lanes/*-rulings.md`; this lane's facts come
   from `docs/lanes/v51-docs-rulings.md:7-16`.
4. Run GC1-GC4 sequentially from `docs/gates/v51-docs.md:12-25`, using
   PowerShell same-pattern commands as the sanctioned Git Bash substitution if
   needed, and `UV_CACHE_DIR=.architect/tmp/uv-cache` for GC3 if uv needs the
   workspace cache redirect.

Disagreements / spec tensions:

1. The issue body asks for "the eight retro findings (R/W summary)," but the
   spec contains eight Went Right findings and eight Went Wrong findings
   (`docs/spec/architect-v5.1.md:22-42`,
   `docs/spec/architect-v5.1.md:45-75`). Resolved as eight paired R/W summary
   bullets, not sixteen expanded paragraphs.
2. The issue says append a "§12 v5.1" addendum, while the actual document
   already has `## 12. v5 - the autonomous factory` (`DESIGN.md:818`).
   Resolved as a subsection under the existing v5 section.
3. The README gate is about the literal `HANDOFF.md`
   (`docs/gates/v51-docs.md:24-25`). The current README contains lower-case
   "handoff" as ordinary prose (`README.md:159`), so unrelated prose was not
   rewritten.

## Files touched

- `DESIGN.md`
- `README.md`
- `docs/lanes/v51-docs-01.md`

## Gates

Executor: Codex lane `v51-docs-01` in PowerShell from repo root
`C:\Users\danhm\tools\architect-loop\.architect\wt\v51-docs-01`.

### GC1

Frozen gate:

```bash
grep -q "architect-v5.1" DESIGN.md && grep -qi "backend canary" DESIGN.md
```

Sanctioned substitution used: Git Bash Win32-error-5 / PowerShell sandbox ->
PowerShell same-pattern.

Executed command:

```powershell
$ok = (Select-String -Path DESIGN.md -Pattern 'architect-v5.1' -Quiet) -and (Select-String -Path DESIGN.md -Pattern 'backend canary' -Quiet); if ($ok) { exit 0 } else { exit 1 }
```

Verbatim output:

```text
```

Exit code: 0

### GC2

Frozen gate:

```bash
grep -qi "backend canary" README.md
```

Sanctioned substitution used: Git Bash Win32-error-5 / PowerShell sandbox ->
PowerShell same-pattern.

Executed command:

```powershell
if (Select-String -Path README.md -Pattern 'backend canary' -Quiet) { exit 0 } else { exit 1 }
```

Verbatim output:

```text
```

Exit code: 0

### GC3

Frozen gate:

```bash
uv run --no-project python tests/validate_skills.py
```

Sanctioned substitution used: `UV_CACHE_DIR=.architect/tmp/uv-cache`.

Executed command:

```powershell
$env:UV_CACHE_DIR='.architect/tmp/uv-cache'; uv run --no-project python tests/validate_skills.py; exit $LASTEXITCODE
```

Verbatim output:

```text
OK - 2 skills validated, v4 contracts clean
```

Exit code: 0

### GC4

Frozen gate:

```bash
! grep -qi "HANDOFF.md" README.md
```

Sanctioned substitution used: Git Bash Win32-error-5 / PowerShell sandbox ->
PowerShell same-pattern.

Executed command:

```powershell
if (Select-String -Path README.md -Pattern 'HANDOFF\.md' -Quiet) { exit 1 } else { exit 0 }
```

Verbatim output:

```text
```

Exit code: 0

STATUS: DONE
MIRROR: ORCHESTRATOR
