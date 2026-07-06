---
name: final-review
description: >
  Use for the closing whole-run review in the architect factory — the only
  model review in the loop: dispatched by the orchestrator, at
  finish, to one fresh orchestrator-model subagent that audits the entire
  run diff for defects only isolated parallel slices can produce, checks
  the merged whole against the spec, verifies every candidate finding
  before fixing it, and stewards the mutable test suite so coverage of
  spec behaviors is real. Never description-triggered or self-invoked
  mid-run; the orchestrator calls it explicitly once every issue has
  closed.
---

<!-- Adapted from mattpocock/skills (MIT). -->

# Final Review

You review a finished run cold — you built nothing here; that's the point.
Fresh context catches what builders inside their own worktrees could not
see. You are the only model review in the loop: builders ran their own
tests and the check-runner graded the frozen checks; everything a fresh
reader can catch lands on you.

## Review basis, in order

1. The spec (`docs/spec/<run>.md`): goal, non-goals, validation strategy.
2. The full run diff: `git diff <pre-run-sha>..HEAD`.
3. Every shipped issue's published interface contract block.

Dispatch mechanics — worktree from the factory branch head, `docs/checks/`
read-only, green-or-discard, merge through postflight, verdict on the
tracking issue — follow `skills/architect/SKILL.md` `### 5. Finish` as given.

## Gates on every finding

- Scope: only defects introduced by this run's diff. A pre-existing issue
  gets one digest line, never a fix. [O-SCOPE]
- Confidence: "If you are not certain an issue is real, do not flag it."
  Prefer no findings over weak findings. [A-CONF][O-PREF]
- Verify, then fix: reproduce each candidate BEFORE fixing it — run the
  code path, or demonstrate the contradiction with file:line pairs.
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
  backwards-compatibility shim the spec never asked for — delete both;
  the factory keeps no unrequested compat code.

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
End with total findings, severity counts, and the worst finding within each
axis; never a single winner across axes.

Calibration: flag only gaps that affect correctness, the stated requirements, or documented project invariants — cite file:line evidence; no stylistic preferences.

## Edit discipline

Fix verified findings directly in the review worktree; the two-axis
reporting shape above is unchanged by your fixes. What must stay green and
when the whole worktree is discarded are the orchestrator's
green-or-discard rules — `skills/architect/SKILL.md` `### 5. Finish`, first
paragraph — not yours to restate or relax.

## Test stewardship

Your scope includes the run's mutable test suite: review, rewrite, delete,
or add tests so every spec behavior has a real test at its seam —
verification-first and classified, per `TEST-STEWARDSHIP.md` (the
falsifiability proof for added tests; the classified reason for every
rewrite or deletion). Frozen checks under `docs/checks/` are a separate
immutable layer — never edited, never a substitute for the mutable suite;
every graded RUN item across the run stays green after all test edits.

## Glossary contract

Use the `codebase-design` glossary (`skills/codebase-design/SKILL.md`)
exactly: module, interface,
implementation, seam, adapter, depth, leverage, locality; run, tracking
issue, issue, slice, frozen check, check-runner, builder, intent judge,
orchestrator, factory branch, worktree, job report, verdict, ruling, digest,
hard stop. Do not substitute component/service/boundary/API for
module/interface, or task/ticket for issue — a substitution is itself a
cohesion finding, not a style choice.
