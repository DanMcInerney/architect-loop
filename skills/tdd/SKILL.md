---
name: tdd
description: Test-driven development for factory builders. Use when a ship job implements at the issue's pre-agreed seams — the red -> green loop, one test then one minimal implementation per cycle, never a refactor while RED.
---

<!-- Adapted from mattpocock/skills (MIT). -->

# Test-Driven Development

TDD is the red -> green loop. This skill is the reference that makes that loop
produce tests worth keeping. Consult it before and during the loop, not after.

## Seams are pre-agreed, not interviewed

A **seam** is the public boundary you test at — the interface where you
observe behavior without reaching inside. In this factory the seams are
already agreed before you start: they're named in the issue body and the
spec. A builder never interviews a user to find seams; if an issue names
none, that's a spec gap to report, not a prompt to go ask someone.

Frozen checks under `docs/checks/` are read-only grading — not your tests.
They verify the slice from outside, after the fact. Write your own tests at
the issue's named seams and run them yourself before you report. A green
frozen check with no tests of your own is not done.

## What a good test is

Tests verify behavior through the seam, not implementation details. A good
test reads like a specification and survives refactors because it doesn't
care about internal structure. See [tests.md](tests.md) for examples and
[mocking.md](mocking.md) for mocking guidance.

## Anti-patterns

- **Implementation-coupled** — mocks internal collaborators, tests private
  methods, or verifies through a side channel. Tell: it breaks on refactor
  with no behavior change.
- **Tautological** — the assertion recomputes the expected value the way the
  implementation does, so it passes by construction. Expected values come
  from an independent source: a known-good literal, a worked example, the spec.
- **Horizontal slicing** — writing every test first, then all implementation.
  Work in **vertical slices** instead: one test -> one minimal implementation
  -> repeat, each test a **tracer bullet** answering what the last cycle
  taught you.

## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code
  to pass it. Don't anticipate future tests or add speculative features.
- **One slice at a time.** One seam, one test, one minimal implementation
  per cycle.
- **Never refactor while RED.** Refactoring belongs to review, not the
  red -> green cycle.
- **Mock at system boundaries only** — external systems, time, randomness.
  Never your own modules.

## Report only what you proved

Evidence-ground every claim: report only what a tool result from this
session actually shows — the command output and exit code from a test you
ran, not a claim of passing without the run behind it.
