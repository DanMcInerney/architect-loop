# Test Stewardship

Companion to `SKILL.md` `## Test stewardship`. At finish you diagnose the
run's mutable test suite — you do not edit it. Map every spec behavior to a
test, and turn every gap or defect into a fix-issue requirement,
verification-first and classified, never free-form license to guess.

## The map is the instrument

Map every spec behavior to at least one test at its seam — the interface a
caller actually crosses, not the implementation behind it. The map's gaps
are the work list: each gap is a diagnosis, and each diagnosis becomes a fix
issue naming the missing test and its seam. Coverage percent is a map,
never a target: a high percent over weak assertions proves nothing. [M-MUT]

## Diagnosing an add

A missing test is a fix-issue requirement naming the seam and the behavior
it must cover. The fix issue carries the falsifiability obligation forward:
its builder proves the new test fails on a revert or a seeded mutant of the
code it guards, then passes with the code restored — a test that cannot
fail is not evidence. [M-MUT] Prefer integration tests over unit tests for
agent-built changes: exercise the real code path through the public
interface. [O-TEST]

## Diagnosing a rewrite or delete

- REWRITE candidates: implementation-coupled or tautological tests at the
  seam — the behavior keeps its test in the fix issue; the coupling goes.
- DELETE candidates: only redundant tests — Beck's rule: the fewest tests
  that give the desired confidence. [K-BECK]
- Every rewrite or deletion candidate becomes a fix-issue requirement
  carrying a classified reason — redundant | implementation-coupled |
  tautological. No classification, no fix issue.

## Diagnosis table

One row per diagnosed test, in the review spec and the verdict:

| Test | Action (add / rewrite / delete) | Reason class | Fix issue |

The fix issue is where the falsifiability proof (adds) or the reason class
plus surviving seam test (rewrites, deletes) lands — this table cites the
fix issue; the reviewer's diagnosis stops short of carrying the proof
itself.

## The immutable layer

Frozen checks under `docs/checks/` are a separate immutable layer: never
edited, never a substitute for the mutable suite. Every graded RUN item
across the run stays green after the fix wave's test edits — a red RUN item
after a test edit means the edit was wrong, not the check.
