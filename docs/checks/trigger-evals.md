# Frozen checks: trigger-evals (G5)

Purpose: verify the trigger-eval fixture and best-effort harness of
`docs/spec/skill-hygiene.md` G5.
Spec pointer: `docs/spec/skill-hygiene.md` (goal G5, human ruling: lightweight
fixture; harness best-effort with no silent fallback).
Fix contract: on FAIL, the orchestrator fixes issue text or context and respawns a
fresh builder at the same tier; builders never edit this file.

Executor: PowerShell (Windows PowerShell 5.1, native git). PowerShell is the
preferred executor; a recorded same-pattern substitution is permitted per
`skills/architect/dispatch.md` sanctioned substitutions and must be named per
check in the report.

Fixture format contract (frozen): each prompt is a block of exactly three lines —
`- PROMPT: <text>` then indented `SKILL: architect` or `SKILL: architect-research`
then indented `EXPECT: trigger` or `EXPECT: no-trigger`.

## Runnable checks

- RUN: `git check-ignore -q docs/evals/trigger-prompts.md; $LASTEXITCODE` -> `1`. TE1: the fixture path is NOT gitignored (requires the `!/docs/evals/` whitelist line in `.gitignore`).
- RUN: `(Get-Content docs/evals/trigger-prompts.md | Select-String '^- PROMPT:').Count -ge 20` -> `True`. TE2: at least 10 prompts per skill.
- RUN: `(Get-Content docs/evals/trigger-prompts.md | Select-String '^\s+SKILL: architect$').Count -ge 10` -> `True`. TE3: at least 10 prompts target /architect.
- RUN: `(Get-Content docs/evals/trigger-prompts.md | Select-String '^\s+SKILL: architect-research$').Count -ge 10` -> `True`. TE4: at least 10 prompts target /architect-research.
- RUN: `(Get-Content docs/evals/trigger-prompts.md | Select-String '^\s+EXPECT: no-trigger').Count -ge 4` -> `True`. TE5: at least 2 negative controls per skill (4 total minimum).
- RUN: `$f=Get-Content docs/evals/trigger-prompts.md; (($f | Select-String '^- PROMPT:').Count -eq ($f | Select-String '^\s+EXPECT:').Count) -and (($f | Select-String '^- PROMPT:').Count -eq ($f | Select-String '^\s+SKILL:').Count)` -> `True`. TE6: every prompt carries exactly one SKILL and one EXPECT line.
- RUN: `Test-Path skills/architect/trigger-eval.ps1` -> `True`. TE7: PowerShell harness exists.
- RUN: `Test-Path skills/architect/trigger-eval.sh` -> `True`. TE8: POSIX harness exists.

## Judge-only checks

- J1: The job report contains either (a) evidence of at least one harness
  invocation (`trigger-eval.ps1` run output showing prompts submitted via
  `claude -p` and Skill-invocation detection results), or (b) an explicit
  not-viable record naming the exact command tried and its verbatim
  failure output. Absence of both is FAIL (no silent fallback).
- J2: Prompt mix per skill covers the spec's four categories — explicit
  invocation, implicit (e.g. "continue the factory"), contextual, and
  negative controls (ordinary coding requests must not trigger /architect;
  narrow slice-level fact checks must not trigger /architect-research).
  Cite one example of each category per skill from the fixture.
- J3: The `.gitignore` diff adds only the `!/docs/evals/` whitelist line and
  changes nothing else.
- J4: The harness scripts read prompts from the fixture file rather than
  hardcoding them, and never edit any file (read-and-report only).
