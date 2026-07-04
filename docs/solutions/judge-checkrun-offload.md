# Judge Checkrun Offload
Recorded: 2026-07-04

## Symptom

Frontier-priced judges were spending most of their turns on greps and other
frozen mechanical checks. The approved judge-runner spec recorded 135
`command → expected` items across 15 frozen check files, about 9 per file,
with `tracker-adapter.md` 17-of-18 mechanical.

## Diagnosis

Judgment had two jobs mixed together: deterministic command execution and
actual review. The first job only needs exact shell output and exit codes; the
second job still needs a fresh orchestrator-tier judge for evidence grading,
checks integrity, and diff-vs-intent. Running both inside the judge wasted the
judge context and made shell-dependent checks force cross-family Codex judges
when Claude subagents lost shell tools.

## Fix

Use a deterministic check-runner script to execute frozen `- RUN:` commands
and write a durable checkrun evidence file. The judge reads that file, grades
the captured evidence against the frozen expectations, executes judge-only
items, re-runs at least one RUN command as an honesty spot-check, and still
rules on diff-vs-intent.

## What Did Not Work

- Run-context note: the pre-freeze grill caught four decomposition defects
  before they became builder work: a spec/fixture count contradiction, an
  unguarded V4 tracked-file mutation, implicit commit-ordering for freeze SHA
  HEAD integrity, and non-falsifiable bare-number greps.
- The jr-wiring first judgment passed W1-W6 but failed diff-vs-intent because
  the Codex judge intro listed the old placeholder set and omitted the new
  checkrun evidence path; the respawn contract added that path explicitly
  (`docs/jobs/jr-wiring-rulings.md`).
- The jr-runner builder could not execute the Bash runner in this Codex
  Windows sandbox; the report recorded `check-runner.sh` as UNEXECUTED
  because Git Bash dies here with Win32 error 5. The jr-runner check file
  required a non-Codex-sandbox judge for that Bash fixture.
