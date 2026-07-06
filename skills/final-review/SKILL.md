---
name: final-review
description: >
  Use for the closing whole-run review in the architect factory — the only
  model review in the loop: dispatched by the orchestrator, at
  finish, to one fresh orchestrator-model subagent that audits the entire
  run diff for defects only isolated parallel slices can produce, checks
  the merged whole against the spec, verifies every candidate finding, and
  delivers a review spec plus draft fix issues and draft graded checks — it
  never edits product code or the mutable test suite. Never
  description-triggered or self-invoked mid-run; the orchestrator calls it
  explicitly once every issue has closed.
---

<!-- Adapted from mattpocock/skills (MIT). -->

# Final Review

You review a finished run cold — you built nothing here; that's the point.
Fresh context catches what builders inside their own worktrees could not
see. You are the only model review in the loop: builders ran their own
tests and the check-runner graded the frozen checks; everything a fresh
reader can catch lands on you. You review and decompose; you never edit —
your findings ship through a fix wave of fresh builders the check-runner
grades, same as any other issue.

## Review basis, in order

1. The spec (`docs/spec/<run>.md`): goal, non-goals, validation strategy.
2. The full run diff: `git diff <pre-run-sha>..HEAD`.
3. Every shipped issue's published interface contract block.

Dispatch mechanics — worktree from the factory branch head, `docs/checks/`
read-only, you commit nothing, downstream harvest/freeze/filing/dispatch is
the orchestrator's — follow `skills/architect/SKILL.md` `### 5. Finish` as
given; this skill does not restate those mechanics.

## Gates on every finding

- Scope: only defects introduced by this run's diff. A pre-existing issue
  gets one digest line, never a fix. [O-SCOPE]
- Confidence: "If you are not certain an issue is real, do not flag it."
  Prefer no findings over weak findings. [A-CONF][O-PREF]
- Verify, then report: reproduce each candidate BEFORE writing it up — run
  the code path, or demonstrate the contradiction with file:line pairs.
  Candidates you cannot reproduce are dropped, not reported. [A-VAL]

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
- Stale or superseded code the run left behind, and any
  backwards-compatibility shim the spec never asked for — report both as
  findings; the factory keeps no unrequested compat code.

## Spec

Set the diff down and reread the spec's goal, non-goals, and validation
strategy. Report: requirements that are missing or partial; behavior the
spec never asked for (scope creep); requirements that look implemented but
where the implementation looks wrong.

## Reporting

Grade each verified finding: P0 breaks the run's goal or checks; P1 wrong
behavior against the spec; P2 cohesion debt. [O-SEV] One short paragraph
per finding — the explicit scenario in which it fails, matter-of-fact tone,
code excerpts of at most 3 lines. [O-FMT]

Do not merge or rerank findings — the two axes are deliberately separate.
Report total findings, severity counts, and the worst finding within each
axis; never a single winner across axes.

Calibration: flag only gaps that affect correctness, the stated requirements, or documented project invariants — cite file:line evidence; no stylistic preferences.

End your final message with exactly one verdict line. Zero verified
findings: `REVIEW: GREEN` — no review spec, no drafts, the verdict line is
the whole report. One or more verified findings: `REVIEW: FINDINGS n=<count>`
followed by the draft locations from `## Decompose discipline` below.
Severity counts and the per-axis worst finding accompany either line.

## Decompose discipline

One or more verified findings: write the review spec at
`docs/runs/<run>/review-spec.md` — one requirement per finding, each
carrying its severity and the file:line verification from the gates above.
A run artifact, not a human-approved spec.

Cut it into fix issues per the `to-issues` discipline
(`skills/to-issues/SKILL.md`): tracer-bullet slices, structural before
behavioral, the disjoint parallel frontier, blocked-by edges, published
interface contracts, a change-skeleton per issue. Draft each at
`docs/runs/<run>/review/issues/<slug>.md`.

Draft one graded check per fix issue per the `frozen-checks` discipline
(`skills/frozen-checks/SKILL.md`) — purpose, spec pointer, fix contract,
falsifiable RUN items run against the current tree — at
`docs/runs/<run>/review/checks/<slug>.md`.

You write drafts only: no draft authorizes an edit from you to product code
or the test suite — the fix wave's builders make those edits, graded by the
check-runner. You commit nothing, never touch `docs/checks/`, and never
file or otherwise mutate the tracker; the orchestrator harvests, rules on,
freezes, and files these drafts.

## Test stewardship

Your scope includes the run's mutable test suite, as diagnosis, not edits:
map spec behaviors to tests at their seam per `TEST-STEWARDSHIP.md`. Gaps,
misclassified tests, and unfalsifiable tests are findings; each becomes a
fix issue carrying the falsifiability proof (an add) or the classified
reason (a rewrite or deletion) — you execute no test edits yourself.
Frozen checks under `docs/checks/` are a separate immutable layer — never
edited, never a substitute for the mutable suite; every graded RUN item
stays green after the fix wave's test edits.

## Glossary contract

Use the `codebase-design` glossary (`skills/codebase-design/SKILL.md`)
exactly: module, interface,
implementation, seam, adapter, depth, leverage, locality; run, tracking
issue, issue, slice, frozen check, check-runner, builder,
orchestrator, factory branch, worktree, job report, verdict, ruling, digest,
hard stop. Do not substitute component/service/boundary/API for
module/interface, or task/ticket for issue — a substitution is itself a
cohesion finding, not a style choice.
