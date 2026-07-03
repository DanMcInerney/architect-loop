# Checks: rename-research-skill

Purpose: verify the domain-language rename in the research skill.
Spec (fix contract): `docs/spec/rename-domain-language.md`.
Files owned: `skills/architect-research/SKILL.md`,
`skills/architect-research/lanes.md` → `skills/architect-research/tactics.md`
(content created at the new name, old file deleted; the orchestrator commits,
so plain filesystem create+delete is correct — no git mv).

Executor: Git Bash preferred; PowerShell same-pattern substitution permitted
when recorded per check. Orchestrator bookkeeping commits are exempt from
touch-set checks.

## RS1 — file rename happened

Command:
`test -f skills/architect-research/tactics.md && test ! -e skills/architect-research/lanes.md && echo RS1_OK`

PASS: output `RS1_OK`.

## RS2 — retired terms absent (word-boundary)

Command:
`grep -inwE "gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag" skills/architect-research/SKILL.md skills/architect-research/tactics.md`

PASS: no output. Note: the tactics library's own coinages that used "gate"
("conjunction gate", "production-grade gate") are renamed to "…test" per the
issue body — they must not survive.

## RS3 — "frontier" only in the capability sense

Command:
`grep -inE "frontier" skills/architect-research/SKILL.md skills/architect-research/tactics.md | grep -ivE "frontier (model|codex|row|tier)|frontier-tier"`

PASS: no output.

## RS4 — new vocabulary and references present

Commands and PASS criteria:
- `grep -c "tactics.md" skills/architect-research/SKILL.md` → `1` or more
- `grep -c "lanes.md" skills/architect-research/SKILL.md` → zero matches (grep exits non-zero)
- `grep -ciE "researcher" skills/architect-research/SKILL.md` → `1` or more
- `grep -ciE "researcher" skills/architect-research/tactics.md` → `1` or more
- `head -5 skills/architect-research/SKILL.md | grep -c "name: architect-research"` → `1` (frontmatter intact)
