# Checks: rename-build-skill

Purpose: verify the domain-language rename in the build-loop skill files.
Spec (fix contract): `docs/spec/rename-domain-language.md` — its
"Interface contract" section holds the exact shared strings.
Files owned: `skills/architect/SKILL.md`, `skills/architect/loop.md`,
`skills/architect/dispatch.md`, `skills/architect/research.md`.

Executor: Git Bash preferred; PowerShell same-pattern substitution permitted
when recorded per check. Orchestrator bookkeeping commits (job reports under
`docs/lanes/`, rulings files) are exempt from touch-set checks.

## BS1 — retired terms absent (word-boundary)

Command:
`git grep -inwE "gate|gates|gated|brain|brawn|lane|lanes|cold|epic|grill|grilled|grilling|dag" -- skills/architect/`

PASS: no output (grep exits non-zero). Case-insensitive whole-word match, so
"delegate/delegation/aggregate" do not trip it.

## BS2 — "frontier" retired in the scheduling sense only

Command:
`git grep -inE "frontier" -- skills/architect/ | grep -ivE "frontier (model|codex|row|tier)|frontier-tier"`

PASS: no output. Capability-sense uses ("frontier model", "frontier Codex
row") remain legitimate.

## BS3 — "stop rail" and "spec gate" retired

Command:
`git grep -inE "stop rail|spec gate" -- skills/architect/`

PASS: no output.

## BS4 — dispatch.md contract strings present

Commands and PASS criteria (`git grep -c` reports `<path>:<count>`):
- `git grep -c "Frozen check file path:" -- skills/architect/dispatch.md` → `skills/architect/dispatch.md:2`
- `git grep -c "Checks integrity:" -- skills/architect/dispatch.md` → `skills/architect/dispatch.md:2`
- `git grep -c "Per check:" -- skills/architect/dispatch.md` → `skills/architect/dispatch.md:2`
- `git grep -c "## Stress-test delegation template" -- skills/architect/dispatch.md` → `skills/architect/dispatch.md:1`
- `git grep -c "architect-stress-test-template:start" -- skills/architect/dispatch.md` → `skills/architect/dispatch.md:1`
- `git grep -c "architect-grill-template" -- skills/architect/dispatch.md` → no output / zero matches (grep exits non-zero)
- `git grep -cE "^orchestrator = " -- skills/architect/dispatch.md` → count ≥ 1
- `git grep -cE "^builders = " -- skills/architect/dispatch.md` → count ≥ 1

## BS5 — new vocabulary present

Command:
`git grep -lE "docs/checks/" -- skills/architect/SKILL.md skills/architect/dispatch.md && git grep -lE "docs/jobs/" -- skills/architect/dispatch.md && git grep -liE "tracking issue" -- skills/architect/SKILL.md && git grep -liE "ready issues" -- skills/architect/loop.md && git grep -liE "hard stop" -- skills/architect/SKILL.md && git grep -li "kill switch" -- skills/architect/`

PASS: exit code 0 (every grep found its file).

## BS6 — cross-file pointers still resolve

Every `## <heading>` that `SKILL.md` points to must exist verbatim in its
target file. Commands (`git grep -c` reports `<path>:<count>`):
- `git grep -c "## Model alias table" -- skills/architect/dispatch.md` → count 1
- `git grep -c "## Issue conventions" -- skills/architect/dispatch.md` → count 1
- `git grep -c "## Monitor dispatch" -- skills/architect/dispatch.md` → count 1
- `git grep -c "## Respawn-with-answer template" -- skills/architect/dispatch.md` → count 1
- `git grep -c "## Factory block procedure" -- skills/architect/loop.md` → count 1
- SKILL.md's pointer list names only sections that the two greps above
  confirm (`git grep -n "dispatch.md section\|loop.md section" -- skills/architect/SKILL.md`
  output reviewed against them).

PASS: all counts exactly 1 and no dangling pointer named.
