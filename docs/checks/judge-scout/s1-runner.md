# Checks: s1-runner (run judge-scout)

Purpose: the deterministic check-runner grades RUN items itself and returns
typed verdicts, so no LLM re-grades mechanical checks (spec G1).
Spec: docs/spec/judge-narrowing-and-scout.md
Fix contract: on FAIL, fix the scripts, fixtures, or validator — never this
file. This file is read-only after freeze.
Executor: powershell
Note: RUN lines below already use the graded grammar this slice builds; the
current runner ignores expectation tokens as prose, the new runner grades
them — both compatible (grill finding, 2026-07-05).

Graded-RUN contract under test (normative for this slice):
`- RUN: `<command>` -> exit:<n>` optionally followed by ` match:"<substring>"`.
The expectation starts immediately after the closing backtick; anything after
the expectation tokens is judge-facing prose the runner ignores. `match` is a
FIXED substring tested against captured stdout only (grep -F semantics; ruled
on issue #98; spec A1 amended to match). A RUN line with no `->` expectation
is a grammar error: the runner exits 5 `CHECKRUN: ERROR` naming file and
line, leaving no partial evidence. Evidence file: each RUN item records
`expected: <expectation>` and `verdict: PASS|FAIL`; a
`CHECKRUN SUMMARY: run_items=<n> pass=<n> fail=<n>` line precedes the
integrity block. Typed exits: 0 = evidence written and fail=0; 2 = evidence
written and fail>0; 5 = error, no partial evidence. Integrity fields stay
data-only (judge territory), never part of grading.

- RUN: `$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py` -> exit:0 match:"OK" (cache redirect embedded per dispatch.md substitutions table)
- RUN: `git grep -F -c "CHECKRUN SUMMARY:" -- skills/architect/check-runner.ps1` -> exit:0
- RUN: `git grep -F -c "CHECKRUN SUMMARY:" -- skills/architect/check-runner.sh` -> exit:0
- RUN: `git grep -F -c "verdict: " -- skills/architect/check-runner.ps1` -> exit:0
- RUN: `git grep -F -c "verdict: " -- skills/architect/check-runner.sh` -> exit:0
- RUN: `git grep -F -l -e "-> exit:" -- tests/fixtures/checkrun` -> exit:0 (at least one graded fixture exists; -e guards the leading dash)
- Judge-only: tests/validate_skills.py contains a graded-runner fixture check
  that asserts, for BOTH executors where runnable (recorded substitution rules
  apply): (a) an all-pass graded fixture yields exit 0 with fail=0 in the
  summary; (b) a fixture containing a failing item — including an absence
  check `-> exit:1` that actually returns exit 0 — yields exit 2 with the
  failing item's verdict FAIL; (c) a fixture with a RUN line missing `->`
  yields exit 5 and no evidence file. Cite validator file:line per assertion.
- Judge-only: match grading is fixed-substring against stdout (no regex
  engine call on the expectation) in both check-runner.ps1 and
  check-runner.sh; cite file:line.
- Judge-only: existing ungraded fixtures under tests/fixtures/checkrun/ were
  migrated to graded form or retired; no fixture exercises the retired
  prose-only path as a passing case.
