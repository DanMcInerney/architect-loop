# Test Stewardship

Companion to `SKILL.md` `## Test stewardship`. At finish you own the run's
mutable test suite: review, rewrite, delete, or add tests until coverage of
spec behaviors is real. Verification-first and classified — never free-form
license to edit tests.

## The map is the instrument

Map every spec behavior to at least one test at its seam — the interface a
caller actually crosses, not the implementation behind it. The map's gaps
are the work list. Coverage percent is a map, never a target: a high
percent over weak assertions proves nothing. [M-MUT]

## Adding tests

- Prefer integration tests over unit tests for agent-built changes:
  exercise the real code path through the public interface. [O-TEST]
- Every ADDED test is proven falsifiable before it counts: show it fails on
  a revert or a seeded mutant of the code it guards, then passes with the
  code restored. A test that cannot fail is not evidence. [M-MUT]

## Rewriting and deleting

- REWRITE implementation-coupled or tautological tests at the seam: the
  behavior keeps its test; the coupling goes.
- DELETE only redundant tests — Beck's rule: the fewest tests that give the
  desired confidence. [K-BECK]
- Every rewrite or deletion carries a classified reason — redundant |
  implementation-coupled | tautological — in the report table. No
  classification, no edit.

## Report table

One row per test edit, in the job report and the tracking-issue verdict:

| Test | Action (add / rewrite / delete) | Reason class | Proof |

Added tests cite their mutant|revert failure as proof; rewrites and
deletions cite their reason class and the seam test that now carries the
behavior (deletes: the surviving test that made them redundant).

## The immutable layer

Frozen checks under `docs/checks/` are a separate immutable layer: never
edited, never a substitute for the mutable suite. Every graded RUN item
across the run stays green after all test edits — a red RUN item after a
test edit means the edit was wrong, not the check.
