# Gates — slice `spec-rename`

Frozen BEFORE dispatch. Read-only for everyone, builders included — any edit
to this file is an automatic slice FAIL regardless of results.

Purpose (human-directed, 2026-07-02): (1) rename the `docs/prd/` doc class to
`docs/spec/` — "spec" is the term the loop actually uses everywhere else;
(2) codify the judge-context convention so it is law, not habit: the frozen
gate file itself is the judge's entire intent context. Spec reference: this
purpose block (the change is too small for a separate spec doc — that is
itself the point of the convention).

Standing exemption (codified 2026-07-02): orchestrator commits touching ONLY
`docs/HANDOFF.md` and/or `docs/gates/` freeze files are exempt from
bounded-diff enumerations; builder lane commits are not.

## Fix contract

- **Rename:** `git mv` the three files `docs/prd/*.md` → `docs/spec/*.md`
  (same basenames). The moved files may be edited ONLY to update their own
  internal `docs/prd` cross-references to `docs/spec`; no other content
  change. `.gitignore`: the `!/docs/prd/` exception becomes `!/docs/spec/`.
- **Current-usage references:** update the PRD term and `docs/prd` paths to
  "spec" / `docs/spec` in: `skills/architect/SKILL.md`,
  `skills/architect/loop.md`, `skills/architect/research.md`,
  `skills/architect-research/SKILL.md`, `README.md` (if any),
  `DESIGN.md` (path/link targets only — prose history stays),
  `docs/adr/0001-*.md` (path pointer only — the decision text stays),
  `tests/validate_skills.py` (the `(docs|lane|gate|prd|research)` regex
  token).
- **HISTORY IS IMMUTABLE:** `docs/gates/**` and `docs/lanes/**` keep their
  existing `docs/prd` references byte-identical. `docs/HANDOFF.md` is
  orchestrator-owned and out of the lane.
- **Glossary:** `CONTEXT.md` documents the rename (PRD → spec, 2026-07-02,
  "PRD" becomes a retired term) in its existing style.
- **Judge-context convention (codify in `skills/architect/SKILL.md`):** the
  freeze/spec procedure must state: every gate file carries (a) a short
  purpose paragraph, (b) a pointer to `docs/spec/<slice>.md` when one
  exists, and (c) the frozen fix contract — together this is the judge's
  ENTIRE intent context; the C5 judge template stays pointer-only and the
  orchestrator still may not add slice-specific prose to it.

## Declared timeout ceilings

| Command | Ceiling |
|---|---|
| `uv run tests/validate_skills.py` (UV_CACHE_DIR=.architect/tmp/uv-cache if sandboxed) | 120s |
| git commands | 120s |
| anything else | 600s (default) |

## Gates

**RG1 — Suite green both shells.** `uv run tests/validate_skills.py` exits 0
from Git Bash AND from PowerShell (this also link-checks README/DESIGN).

**RG2 — Rename complete.** `git ls-files docs/prd` is EMPTY;
`git ls-files docs/spec` lists exactly `docs/spec/v3-loop.md`,
`docs/spec/v3-loop-stall-prevention.md`,
`docs/spec/v4-orchestrator-loop.md`; `git check-ignore
docs/spec/v4-orchestrator-loop.md` exits 1 (not ignored).

**RG3 — Current usage purged.**
`grep -rniE "\bprd\b" skills/ tests/validate_skills.py .gitignore README.md`
returns nothing; `grep -rn "docs/prd" skills/ README.md CONTEXT.md DESIGN.md
docs/adr/ docs/spec/ tests/ .gitignore` returns nothing.

**RG4 — Glossary records the rename.** Judge reads `CONTEXT.md`: the
PRD → spec rename is documented with the date and "PRD" marked retired.

**RG5 — Judge-context convention codified.** Judge reads
`skills/architect/SKILL.md`: the freeze/spec procedure states the gate file
carries purpose + spec pointer + fix contract as the judge's entire intent
context, with the C5 template remaining pointer-only.

**RG6 — Bounded lane diff.** The builder lane commit changes exactly: the 3
renames (with internal-pointer-only edits), `.gitignore`,
`skills/architect/SKILL.md`, `skills/architect/loop.md`,
`skills/architect/research.md`, `skills/architect-research/SKILL.md`,
`README.md` (only if it contained references), `DESIGN.md`, `CONTEXT.md`,
`docs/adr/0001-in-session-loop-replaces-external-driver.md`,
`tests/validate_skills.py`, `docs/lanes/spec-rename-01.md` (new).
`git diff <freeze>..HEAD -- docs/gates/ docs/lanes/v3- docs/lanes/v4-
docs/HANDOFF.md skills/architect/dispatch.md
skills/architect/HANDOFF.template.md .claude/ install.sh install.ps1` is
EMPTY apart from commits covered by the standing exemption.
