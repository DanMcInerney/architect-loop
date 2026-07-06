---
name: cohesion-review
description: >
  Use for the closing whole-run review in the architect factory: dispatched
  by the orchestrator, at finish, to one fresh orchestrator-model subagent
  that audits the entire run diff for defects only isolated parallel slices
  can produce, then checks the merged whole against the spec. Never
  description-triggered or self-invoked mid-run; the orchestrator calls it
  explicitly once every issue has closed.
---

# Cohesion Review

You review a finished run cold. You built nothing here — that's the point.
Fresh context catches what builders inside their own worktree could not see.

## Review basis, in order

1. The spec (`docs/spec/<run>.md`): goal, non-goals, validation strategy.
2. The full run diff: `git diff <pre-run-sha>..HEAD`.
3. Every shipped issue's published interface contract block.

Dispatch mechanics — worktree from the factory branch head, `docs/checks/`
read-only, green-or-discard, merge through postflight, verdict on the
tracking issue — are not restated here: see `skills/architect/SKILL.md`
`### 5. Finish`, first paragraph. Follow those rules as given.

## Cohesion

Isolation is what let slices run in parallel; it is also the only thing
that can go wrong here. Walk the diff hunting for:

- Duplicated concepts or helpers implemented twice under different names.
- Naming that diverges from the codebase-design glossary (below).
- Interface drift: a producer slice's published contract vs. what its
  consumers actually call.
- Contradictory cross-slice assumptions — A assumes absent what B added; C
  removes what D extends.
- Inconsistent error handling for the same class of failure across slices.
- Shared-surface tracing: walk every surface two or more slices touch and
  confirm both edits agree on its shape.

## Spec

Set the diff down and read the spec's goal, non-goals, and validation
strategy again. Does the merged whole satisfy them? Scope beyond the
approved spec — anything a slice built that the spec never asked for — is
a finding here, not praise.

## Reporting

Do not merge or rerank findings across the two axes; they measure different
failures. Report a count plus the single worst finding for each axis
separately.

Calibration: flag only gaps that affect correctness, the stated requirements, or documented project invariants — cite file:line evidence; no stylistic preferences.

## Edit discipline

Fix findings directly in the review worktree; the two-axis reporting shape
above is unchanged by your fixes. What must stay green and when the whole
worktree is discarded are the orchestrator's green-or-discard rules —
`skills/architect/SKILL.md` `### 5. Finish`, first paragraph — not yours to
restate or relax.

## Glossary contract

Use the `codebase-design` glossary exactly: module, interface,
implementation, seam, adapter, depth, leverage, locality; run, tracking
issue, issue, slice, frozen check, check-runner, builder, intent judge,
orchestrator, factory branch, worktree, job report, verdict, ruling, digest,
hard stop. Do not substitute component/service/boundary/API for
module/interface, or task/ticket for issue — a substitution is itself a
cohesion finding, not a style choice.
