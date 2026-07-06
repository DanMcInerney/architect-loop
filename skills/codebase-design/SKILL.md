---
name: codebase-design
description: >
  Shared vocabulary for designing deep modules and for naming factory
  concepts consistently. Load before writing a spec, decomposing issues,
  freezing checks, or reviewing a diff - anywhere "module," "interface,"
  "issue," or "frozen check" need to mean the same thing to every skill,
  builder, and reviewer. Also covers dependency categories for deepening and
  the parallel design-it-twice pattern for exploring interfaces before
  committing to one.
---

<!-- Adapted from mattpocock/skills (MIT). -->

# Codebase Design

Design **deep modules**: a lot of behavior behind a small interface, placed
at a clean seam, testable through that interface. Use this language wherever
code or a factory issue is being designed. The aim is leverage for callers,
locality for maintainers, and testability for everyone.

## Glossary

Use these terms exactly — don't substitute component, service, boundary, or API
when you mean module or interface; don't say task or ticket for issue, or test
file for frozen check. Consistent language is the whole point.

**Design (Pocock, adapted):**

- **Module** - anything with an interface and an implementation, at any scale: a function, a package, or a whole vertical slice.
- **Interface** - everything a caller must know to use a module correctly: types, invariants, ordering, error modes, config, performance - not just a signature.
- **Implementation** - the body of code behind the interface; distinct from adapter, which names role at a seam, not substance.
- **Depth** - leverage at the interface: behavior reached per unit of interface learned. Deep means a small interface over a big implementation; shallow is the opposite, and to avoid.
- **Seam** (Feathers) - the place a module's interface lives; where behavior can change without editing there.
- **Adapter** - a concrete thing satisfying an interface at a seam. One adapter is a hypothetical seam; two make it real.
- **Leverage** - what callers get from depth: one implementation pays off across many call sites and tests.
- **Locality** - what maintainers get from depth: change and bugs concentrate in one place instead of spreading.

**Factory (one line each; matches `docs/spec/skill-library.md` Target flow):**

- **Run** - one factory build from spec approval to the closing PR, on its own factory branch.
- **Tracking issue** - the run's parent issue: dashboard, digest, preflight record.
- **Issue** - one vertical-slice unit of work: one builder job, one disjoint file set, one change-skeleton.
- **Slice** - the vertical cut an issue implements; slice names the cut, issue names its tracker record - same unit, two angles.
- **Frozen check** - the committed, read-only acceptance check a builder's work is graded against.
- **Check-runner** - the deterministic script that grades a frozen check's RUN items and exits typed (0/2/5).
- **Builder** - the fresh, worktree-isolated agent that implements one issue and never commits.
- **Intent judge** - retired (human ruling 2026-07-06): grading is the check-runner plus the closing cohesion review; no per-issue model review remains.
- **Orchestrator** - the one session that grounds, decomposes, freezes, dispatches, and integrates; never writes implementation code.
- **Factory branch** - the run's integration branch (`factory/<run>`) that job branches merge into.
- **Worktree** - the isolated git checkout a builder or reviewer works in, verified against the freeze commit.
- **Job report** - a builder's raw-evidence artifact, ending in one STATUS line.
- **Verdict** - the grading record posted on an issue at close: checkrun summary plus typed exit, postflight result, slice call, decisive reason; the closing review's run-level verdict goes on the tracking issue.
- **Ruling** - an orchestrator decision recorded post-freeze: a PHASE-0 disagreement, boundary amendment, or respawn answer.
- **Digest** - the shipped-issues, diffstat, rulings, and domain-language summary handed to the closing docs job.
- **Hard stop** - an irreversible or destructive action the loop refuses without a human ruling.

## Deep vs. shallow

A deep module hides a lot of implementation behind a small interface: few
methods, simple params, most of the complexity out of sight. A shallow
module is the opposite - an interface almost as complex as what it wraps,
often a near-passthrough. When shaping an interface, ask whether the
method count and params can shrink, and whether more logic can move inside.

## Principles

- Depth is a property of the interface, not the implementation - a deep
  module can be built from small internal seams its own tests use, without
  exposing them at the external interface.
- The deletion test: imagine deleting the module. If complexity vanishes,
  it was a pass-through; if it reappears across N callers, it was earning
  its keep.
- The interface is the test surface - callers and tests cross the same
  seam. If you want to test past the interface, the module is probably the
  wrong shape.
- One adapter means a hypothetical seam; two adapters means a real one.
  Don't introduce a seam unless something actually varies across it.

## Designing for testability

- Accept dependencies, don't create them - a function that takes its
  gateway is testable; one that builds a `StripeGateway()` internally is not.
- Return results, don't produce side effects - a function that returns a
  computed discount is testable; one that mutates a cart in place is not.
- Small surface area: fewer methods = fewer tests needed; fewer params =
  simpler test setup.

## Going deeper

- Deepening a cluster given its dependencies - see `DEEPENING.md`:
  dependency categories, seam discipline, and replace-don't-layer testing.
- Exploring alternative interfaces - see `DESIGN-IT-TWICE.md`: dispatch
  parallel subagents to design the interface several radically different
  ways, then compare on depth, locality, and seam placement.
