# Frozen check — s3-docs (run architect-fast)

Purpose: prove the product docs and the scoped glossary amendments present
the fast lane accurately — README usage + design + details, a flow diagram,
the DESIGN.md rationale, and the one-clause orchestrator amendments in the
repo glossary and the shared vocabulary skill. Spec:
`docs/spec/architect-fast.md` (`## Implementation decisions`, registration
adapters + glossary amendments; `## Domain language`). Fix contract: a
failure below means one of README.md, DESIGN.md, CONTEXT.md,
`assets/architect-fast-flow.svg`, or `skills/codebase-design/SKILL.md` is
missing its contracted content — fix within that file set only.

Grading: deterministic check-runner per `skills/architect/dispatch.md`
`## Check-runner dispatch`, runner config `executor: bash` — items use
`test`, so the PowerShell executor is not valid for this file. This slice
runs parallel with s1, so its validator run may report 10 or 11 skills —
the summary prefix alone is graded.

## Graded items

- RUN: `grep -F -c '/architect-fast <small change>' README.md` -> exit:0 match:"1"
- RUN: `grep -F -c '### /architect-fast' README.md` -> exit:0 match:"2"
- RUN: `grep -F -c 'assets/architect-fast-flow.svg' README.md` -> exit:0 match:"1"
- RUN: `test -f assets/architect-fast-flow.svg` -> exit:0
- RUN: `grep -F -c '### The fast lane' DESIGN.md` -> exit:0 match:"1"
- RUN: `grep -F -c '/architect-fast' DESIGN.md` -> exit:0
- RUN: `grep -i -c 'fast lane' CONTEXT.md` -> exit:0
- RUN: `grep -F -c 'fast lane (/architect-fast)' skills/codebase-design/SKILL.md` -> exit:0 match:"1"
- RUN: `uv run python tests/validate_skills.py` -> exit:0 match:"OK -"

## Judge-only intent items (closing review)

- The README subsections match the issue's C2 contract: size ceiling, the
  orchestrator review replacing check-runner + final review with the
  Hard-Rule relaxations recorded and the PR named as later eyes, timed
  fallback wake, dispatch-head postflight base; nothing describes fast-lane
  behavior as `/architect` behavior, and the retired per-issue Judge stays
  retired.
- The SVG is style-matched to the existing flow assets and readable on
  light and dark themes.
- The DESIGN.md subsection follows the sibling-loop rationale shape and the
  989-guard sentence is untouched.
- CONTEXT.md carries both the Orchestrator clause and the Fast lane entry.
