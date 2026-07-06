# Frozen check — s1-skill (run architect-fast)

Purpose: prove the new `/architect-fast` loop skill exists as one
self-contained SKILL.md carrying the fast lane's whole contract — identity
frontmatter, size ceiling, recorded relaxations, substitution table, and the
lint-safe vocabulary the validator will enforce once s2 registers it.
Spec: `docs/spec/architect-fast.md` (`## Target flow`,
`## Implementation decisions`). Fix contract: a failure below means
`skills/architect-fast/SKILL.md` is missing, off-contract, over budget, or
uses banned vocabulary — fix that one file; no other file is in this slice.

Grading: deterministic check-runner per `skills/architect/dispatch.md`
`## Check-runner dispatch`, runner config `executor: bash` — several items
use `test`, `$( )`, and pipes, so the PowerShell executor is not valid for
this file. Builder files are untracked in the job worktree, so items use
filesystem `grep`/`test`, never `git grep`.

## Graded items

- RUN: `test -f skills/architect-fast/SKILL.md` -> exit:0
- RUN: `grep -c '^name: architect-fast$' skills/architect-fast/SKILL.md` -> exit:0 match:"1"
- RUN: `grep -c '^effort: high$' skills/architect-fast/SKILL.md` -> exit:0 match:"1"
- RUN: `grep -F -c 'light factory lane' skills/architect-fast/SKILL.md` -> exit:0
- RUN: `grep -F -c 'size ceiling' skills/architect-fast/SKILL.md` -> exit:0
- RUN: `grep -F -c 'Hard Rules 3 and 4' skills/architect-fast/SKILL.md` -> exit:0
- RUN: `grep -F -c 'docs job' skills/architect-fast/SKILL.md` -> exit:0
- RUN: `grep -F -c 'no frozen check files, no check-runner' skills/architect-fast/SKILL.md` -> exit:0
- RUN: `grep -F -c '## Substitutions' skills/architect-fast/SKILL.md` -> exit:0 match:"1"
- RUN: `grep -F -c 'dispatch-head SHA' skills/architect-fast/SKILL.md` -> exit:0
- RUN: `grep -F -c 'recorded final-review substitute' skills/architect-fast/SKILL.md` -> exit:0
- RUN: `grep -c -w 'component' skills/architect-fast/SKILL.md` -> exit:1 match:"0"
- RUN: `grep -c -w 'ticket' skills/architect-fast/SKILL.md` -> exit:1 match:"0"
- RUN: `grep -c -i 'boundar' skills/architect-fast/SKILL.md` -> exit:1 match:"0"
- RUN: `grep -c -i 'sentinel' skills/architect-fast/SKILL.md` -> exit:1 match:"0"
- RUN: `grep -c '^LOOP:' skills/architect-fast/SKILL.md` -> exit:1 match:"0"
- RUN: `test $(grep -c . skills/architect-fast/SKILL.md) -le 160` -> exit:0
- RUN: `uv run python tests/validate_skills.py` -> exit:0 match:"OK - 11 skills validated"

## Judge-only intent items (closing review)

- The frontmatter description is the issue's C1 text verbatim, ≤1024 chars.
- The `## Substitutions` table carries all nine substitution rows from the
  spec's Implementation decisions, each naming the reused contract and its
  fast-lane replacement.
- Every `skills/...` pointer names a real file and a real heading.
- The orchestrator review is described as fast-lane-only, never as part of
  `/architect`'s flow.
