# Lane report — spec-rename-01

Slice `spec-rename`, frozen gates `docs/gates/spec-rename.md` (freeze `865f330`,
branch `slice/spec-rename`). Single lane, shape `ship`. Builder never
committed (git working-tree edits + staged renames only).

## PHASE 0 disagreements (recorded before any edit)

1. **DESIGN.md ambiguity resolved against RG3's exact scope, not just the
   BOUNDARIES prose.** "path/link targets only — prose history stays" alone
   under-specifies which of DESIGN.md's 8 PRD-related lines to touch. RG3's
   bare-word grep (`\bprd\b`) excludes DESIGN.md; its `docs/prd` literal-string
   grep includes it. Resolved by changing exactly the 4 lines containing the
   literal substring `docs/prd` (now-current-design lines 360 and 386 in the
   "Optional pre-spec research fan-out" section, plus historical-citation
   lines 487 and 621), and leaving the 4 bare-word "PRD" occurrences (lines
   38, 377, 526, 676 — genuine dated historical/naming narrative) untouched.
   For lines 360/386 I converted the full sentence (not just the path) to
   "spec" wording so the sentence reads consistently rather than mixing
   "PRD" prose with a `docs/spec` path in the same clause — MODIFY-by-
   interpretation, flagging it for judge review.
2. **`docs/adr/0001-in-session-loop-replaces-external-driver.md` is listed as
   MAY TOUCH but verified to contain zero "PRD"/"docs/prd" occurrences**
   (checked via Read + Grep before editing). Left untouched rather than
   inventing a change under "path pointer only," per the boundary's own "no
   other content change" restriction.
3. **Real conflict found and fixed during gate verification, not before
   coding:** my first CONTEXT.md draft (RG4: document the rename) wrote out
   the literal old path `` `docs/prd/` `` for clarity, which collided with
   RG3's `docs/prd` literal-string grep — RG3 explicitly includes CONTEXT.md
   in that grep's file list. Reworded to describe "the old PRD doc directory"
   without spelling out the literal path; both RG3 greps and RG4's intent
   (documents the rename, dated, "PRD" marked retired) now hold
   simultaneously. Recording this because it's a genuine spec self-tension
   (RG3 vs RG4) resolved by wording, not by leaving one gate unmet.
4. No other disagreements. Checked `.gitignore` lines 4–14 (only the
   `!/docs/prd/` line needed the path swap), confirmed all 3 `docs/prd/*.md`
   basenames match RG2's expected `docs/spec/*.md` set, and confirmed via grep
   that `skills/architect/dispatch.md` and
   `skills/architect/HANDOFF.template.md` (MUST NOT TOUCH) already contain no
   PRD references, so no boundary tension there.

## Files changed

| File | Change |
|---|---|
| `docs/prd/v3-loop.md` -> `docs/spec/v3-loop.md` | rename (git mv, no internal `docs/prd` cross-refs existed, no content edit) |
| `docs/prd/v3-loop-stall-prevention.md` -> `docs/spec/v3-loop-stall-prevention.md` | rename (git mv, no content edit) |
| `docs/prd/v4-orchestrator-loop.md` -> `docs/spec/v4-orchestrator-loop.md` | rename (git mv, no content edit) |
| `.gitignore` | `!/docs/prd/` -> `!/docs/spec/` |
| `skills/architect/SKILL.md` | 3x PRD->spec term edits; added judge-context convention paragraph to `### 6. Freeze` (RG5) |
| `skills/architect/loop.md` | 2x PRD->spec term edits |
| `skills/architect/research.md` | 6x PRD->spec term/path edits (incl. `docs/prd/<slice>.md` -> `docs/spec/<slice>.md`) |
| `skills/architect-research/SKILL.md` | 2x PRD->spec term/path edits (incl. `docs/prd/<slice>.md` -> `docs/spec/<slice>.md`) |
| `README.md` | 1x PRD->spec term edit |
| `DESIGN.md` | 4x literal `docs/prd` -> `docs/spec` path edits (2 converted to full "spec" sentences per disagreement #1); 4 bare "PRD" historical-prose occurrences left untouched |
| `CONTEXT.md` | added retired-term glossary entry: PRD -> spec, 2026-07-02 |
| `tests/validate_skills.py` | regex token `prd` -> `spec` in `check_siblings` sibling-reference allowlist |
| `docs/lanes/spec-rename-01.md` | new (this report) |

Untouched, verified no changes needed: `docs/adr/0001-in-session-loop-replaces-external-driver.md`
(zero PRD references found).

## Gate commands (sequential, verbatim)

**RG1a — validator, Git Bash.** Executor: Bash.
```
$ UV_CACHE_DIR=.architect/tmp/uv-cache uv run tests/validate_skills.py
OK - 2 skills validated, v4 contracts clean
EXIT_CODE=0
```

**RG1b — validator, PowerShell.** Executor: PowerShell.
```
PS> $env:UV_CACHE_DIR = ".architect/tmp/uv-cache"; uv run tests/validate_skills.py
OK - 2 skills validated, v4 contracts clean
EXIT_CODE=0
```

**RG2a — `git ls-files docs/prd` (expect EMPTY).** Executor: Bash.
```
$ git ls-files docs/prd
(no output)
EXIT_CODE=0
```

**RG2b — `git ls-files docs/spec` (expect exactly 3 files).** Executor: Bash.
```
$ git ls-files docs/spec
docs/spec/v3-loop-stall-prevention.md
docs/spec/v3-loop.md
docs/spec/v4-orchestrator-loop.md
EXIT_CODE=0
```

**RG2c — `git check-ignore docs/spec/v4-orchestrator-loop.md` (expect exit 1 = not ignored).** Executor: Bash.
```
$ git check-ignore docs/spec/v4-orchestrator-loop.md
(no output)
EXIT_CODE=1
```

**RG3a — bare `prd` term purge (expect nothing).** Executor: Bash (Git Bash `grep`, not `rg`).
```
$ grep -rniE "\bprd\b" skills/ tests/validate_skills.py .gitignore README.md
(no output)
EXIT_CODE=1
```

**RG3b — `docs/prd` path purge (expect nothing). Run twice: first pass caught a real defect (see disagreement #3), fixed, re-run clean.** Executor: Bash.
```
$ grep -rn "docs/prd" skills/ README.md CONTEXT.md DESIGN.md docs/adr/ docs/spec/ tests/ .gitignore
CONTEXT.md:59:- **PRD** — renamed to **spec** (2026-07-02); `docs/prd/` renamed to
EXIT_CODE=0   <- FAIL, fixed CONTEXT.md wording, re-ran:

$ grep -rn "docs/prd" skills/ README.md CONTEXT.md DESIGN.md docs/adr/ docs/spec/ tests/ .gitignore
(no output)
EXIT_CODE=1
```

**RG1 re-verified after the CONTEXT.md fix.** Executor: Bash.
```
$ UV_CACHE_DIR=.architect/tmp/uv-cache uv run tests/validate_skills.py
OK - 2 skills validated, v4 contracts clean
EXIT_CODE=0
```

**RG6 (second clause) — no drift on frozen/off-limits paths since freeze.** Executor: Bash.
```
$ git diff 865f330..HEAD -- docs/gates/ docs/lanes/v3- docs/lanes/v4- docs/HANDOFF.md skills/architect/dispatch.md skills/architect/HANDOFF.template.md .claude/ install.sh install.ps1
diff --git a/docs/HANDOFF.md b/docs/HANDOFF.md
index 92d05de..dcfedf4 100644
--- a/docs/HANDOFF.md
+++ b/docs/HANDOFF.md
@@ -65,6 +65,13 @@
   ...
+- **PR #9 open** (pr/v4-loop -> main on origin): all of v4. **Slice
+  `spec-rename` IN FLIGHT** (human-directed): docs/prd -> docs/spec rename +
+  codify judge-context convention (gate file = judge's entire intent
+  context). Gates RG1-RG6 frozen 865f330 on slice/spec-rename; sonnet
+  builder dispatched. History immutable: frozen gates/lanes keep old
+  docs/prd references byte-identical. On PASS: merge to main + push to
+  pr/v4-loop so PR #9 stays one unit.
 - Historical: v4-core first judgment 2026-07-02: ...
EXIT_CODE=0
```
This diff touches only `docs/HANDOFF.md` (the orchestrator's own
freeze+dispatch commit `dec808f`), covered by the gate file's standing
exemption for orchestrator commits touching only `docs/HANDOFF.md`/
`docs/gates/`. No lane commit exists (builder never commits) and no other
frozen/off-limits path changed.

## Final `git status --porcelain`

```
 M .gitignore
 M CONTEXT.md
 M DESIGN.md
 M README.md
R  docs/prd/v3-loop-stall-prevention.md -> docs/spec/v3-loop-stall-prevention.md
R  docs/prd/v3-loop.md -> docs/spec/v3-loop.md
R  docs/prd/v4-orchestrator-loop.md -> docs/spec/v4-orchestrator-loop.md
 M skills/architect-research/SKILL.md
 M skills/architect/SKILL.md
 M skills/architect/loop.md
 M skills/architect/research.md
 M tests/validate_skills.py
?? docs/lanes/spec-rename-01.md
```
(the `??` line is this report, written after the status snapshot above was
captured for the table; renames were `git mv`-staged, all other edits are
unstaged working-tree changes — orchestrator owns commits.)

`git diff --numstat` (staged, the 3 renames): all `0 0` (rename only, no
content delta). Unstaged: `.gitignore` 1/1, `CONTEXT.md` 3/0, `DESIGN.md`
5/5, `README.md` 1/1, `skills/architect-research/SKILL.md` 2/2,
`skills/architect/SKILL.md` 9/3, `skills/architect/loop.md` 2/2,
`skills/architect/research.md` 6/6, `tests/validate_skills.py` 1/1.

## Gate RG4 / RG5 (judge-read, not command-verified)

- RG4: `CONTEXT.md` "Retired terms" section now includes a PRD -> spec entry
  dated 2026-07-02 marking "PRD" retired.
- RG5: `skills/architect/SKILL.md` `### 6. Freeze` now states the gate file
  carries purpose + spec pointer + fix contract as the judge's entire intent
  context, and that the C5 template in `dispatch.md` stays pointer-only
  (dispatch.md itself untouched, already compliant, confirmed by Read).

STATUS: COMPLETE
