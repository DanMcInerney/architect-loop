# graded-expectation-divergence

Evidence: factory run judge-scout, 2026-07-05, issues #99-#101

## Symptom

Run judge-scout shipped graded RUN expectations for both PowerShell and shell
executors. Three live divergences escaped ordinary fixtures and were caught by
intent review instead:

- The shell runner graded `match:` through shell-glob case matching instead of
  fixed substring semantics.
- A space-less `match:"..."` expectation parsed differently.
- An unclosed `match:"...` expectation did not die consistently.

## Root Cause

Expectation syntax is a cross-executor language. If PowerShell and shell parse
or grade it differently, the same frozen check can mean different things on
different hosts. That breaks the check contract even when the individual test
fixtures are green.

## What Did Not Work

- Assuming simple `match:` handling was too small to need adversarial fixtures.
- Letting malformed expectations degrade into prose or partial parsing.
- Proving new grammar behavior on one executor and trusting the other.

## Route Around

- Fixture-prove every new expectation feature on both executors.
- Grade `match:` as a fixed stdout substring, never regex or shell pattern.
- Treat malformed expectations as typed runner errors: exit 5, loudly, with
  partial evidence when possible.
- Add malformed-input fixtures for parser edges, not just happy-path examples.
- Keep the intent judge's one spot-check; judge-scout showed it catches runner
  language drift that fixtures can miss.
