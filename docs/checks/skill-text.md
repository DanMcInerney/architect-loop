# Frozen checks: skill-text (G1 + G2 + G3)

Purpose: verify the skill-text pass of `docs/spec/skill-hygiene.md` — trigger-only
description for architect-research (G1), TOCs for reference files >100 lines (G2),
Fable-era prescriptiveness audit (G3).
Spec pointer: `docs/spec/skill-hygiene.md` (goals G1–G3, assumptions A2/A3/A5).
Fix contract: on FAIL, the orchestrator fixes issue text or context and respawns a
fresh builder at the same tier; builders never edit this file.

Executor: PowerShell (Windows PowerShell 5.1, native git). PowerShell is the
preferred executor; a recorded same-pattern substitution (e.g. bash on POSIX)
is permitted per `skills/architect/dispatch.md` sanctioned substitutions and
must be named per check in the report.

All commands run from the repo root. Frontmatter below means the lines from the
file's first line through the line matching `^effort:` inclusive.

## Runnable checks

- RUN: `$c=Get-Content skills/architect-research/SKILL.md; ($c[0..(($c | Select-String '^effort:')[0].LineNumber - 1)] -join ' ') -match 'scout|synthes|tactics library|verifies claims'` -> `False`. ST1: the description (and whole frontmatter) no longer narrates the workflow stages.
- RUN: `$c=Get-Content skills/architect-research/SKILL.md; ($c[0..(($c | Select-String '^effort:')[0].LineNumber - 1)] -join ' ') -match 'Use when'` -> `True`. ST2: trigger-conditions phrasing present.
- RUN: `$c=Get-Content skills/architect-research/SKILL.md; ($c[0..(($c | Select-String '^effort:')[0].LineNumber - 1)] -join ' ').Length -le 1088` -> `True`. ST3: whole frontmatter fits in 1088 chars (measured non-description scaffolding overhead is 64 chars, so the description itself stays under the 1024-char platform cap).
- RUN: `(Get-Content skills/architect/dispatch.md -TotalCount 12 | Select-String '^## Contents').Count` -> `1`. ST4: TOC block near the top of dispatch.md.
- RUN: `(Get-Content skills/architect/loop.md -TotalCount 12 | Select-String '^## Contents').Count` -> `1`. ST5: TOC block near the top of loop.md.
- RUN: `(Get-Content skills/architect-research/tactics.md -TotalCount 12 | Select-String '^## Contents').Count` -> `1`. ST6: TOC block near the top of tactics.md.
- RUN: `git grep -c 'docs/evals/trigger-prompts.md' -- skills/architect/SKILL.md` -> `skills/architect/SKILL.md:1`. ST7: Maintenance rule references the trigger-eval fixture path exactly once (path is a frozen interface contract with the trigger-evals job; `git grep -c` prints `<path>:<count>`).
- RUN: `(Get-Content skills/architect/SKILL.md | Select-String '^\d+\. \*\*').Count` -> `9`. ST8: all nine Hard Rules still present.

## Judge-only checks

- J1: For each of dispatch.md, loop.md, tactics.md — every `##` heading in the
  file (other than `## Contents` itself) appears verbatim as an entry in that
  file's `## Contents` block, and the block lists no heading that does not
  exist. Cite the diff.
- J2: Every section pointer in `skills/architect/SKILL.md` of the form
  section `## <name>` still resolves to an actual `## <name>` heading in the
  file it names (dispatch.md, loop.md, tracker.md). Cite each pointer checked.
- J3: Hard Rules 1–9 in `skills/architect/SKILL.md` are semantically unchanged
  vs the freeze SHA: wording tightening is allowed; weakening, deleting, or
  merging a rule is FAIL. Cite the diff hunks.
- J4: Every G3 deletion appears in the job report with a one-line
  justification, and each deleted passage is process prescription — not a
  contract, boundary, template, config schema, or fragile-operation rail.
  Spot-check at least three deletions against the diff.
- J5: No instruction anywhere in the touched files tells the model to echo,
  transcribe, or explain its internal reasoning in output (Fable
  `reasoning_extraction` risk). Report the scan result even if none found.
