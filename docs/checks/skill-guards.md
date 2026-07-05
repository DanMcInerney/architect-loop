# Frozen checks: skill-guards (G4)

Purpose: verify the validator-guard updates of `docs/spec/skill-hygiene.md` G4
(scope extension, caps, token rule, corrected rationale, drift checks).
Spec pointer: `docs/spec/skill-hygiene.md` (goal G4, assumption A1 approved:
five-file cap 1100, architect-research pair cap 500; A4: deterministic token
proxy words x 1.33).
Fix contract: on FAIL, the orchestrator fixes issue text or context and respawns a
fresh builder at the same tier; builders never edit this file.

Executor: PowerShell (Windows PowerShell 5.1, native git). PowerShell is the
preferred executor; a recorded same-pattern substitution is permitted per
`skills/architect/dispatch.md` sanctioned substitutions and must be named per
check in the report. If `uv` hits an AppData cache denial in a sandbox, use
`UV_CACHE_DIR=.architect/tmp/uv-cache` (recorded substitution).

## Runnable checks

- RUN: `uv run --no-project python tests/validate_skills.py; $LASTEXITCODE` -> last line `0`. SG1: full validator suite green on the post-build tree. Duration hint: ~1m.
- RUN: `(Get-Content tests/validate_skills.py | Select-String 'research\.md').Count -ge 2` -> `True`. SG2: guard scope includes research.md beyond the pre-existing single REQUIRED_SIBLINGS occurrence (pre-build baseline: 1).
- RUN: `(Get-Content tests/validate_skills.py | Select-String 'tracker\.md').Count -ge 5` -> `True`. SG3: guard scope includes tracker.md beyond the pre-existing occurrences (pre-build baseline: 4).
- RUN: `(Get-Content tests/validate_skills.py | Select-String '1100').Count -ge 1` -> `True`. SG4: five-file cap constant present (pre-build baseline: 0).
- RUN: `(Get-Content tests/validate_skills.py | Select-String 'tactics\.md').Count -ge 2` -> `True`. SG5: architect-research pair guard present beyond the pre-existing single REQUIRED_SIBLINGS occurrence (pre-build baseline: 1).
- RUN: `(Get-Content tests/validate_skills.py | Select-String '5000|5_000').Count -ge 1` -> `True`. SG6: SKILL.md token-proxy guard constant present (pre-build baseline: 0).
- RUN: `(Get-Content DESIGN.md | Select-String '800-non-blank').Count` -> `0`. SG7: stale 800-line guard text removed from DESIGN.md (pre-build baseline: 1).
- RUN: `(Get-Content tests/validate_skills.py | Select-String '## Contents').Count -ge 1` -> `True`. SG8: TOC-presence check present in the validator (pre-build baseline: 0).

## Judge-only checks

- J1: The validator contains a check that FAILS when DESIGN.md's stated guard
  cap number differs from the enforced constant in the validator (the
  800-vs-900 drift class). Verify by reading the check's code; cite lines.
- J2: The token guard uses a deterministic local proxy with the formula
  recorded in a comment in the test (A4: words x 1.33 or an equivalent stated
  formula); no network or tokenizer-package dependency was added.
- J3: DESIGN.md's guard rationale is updated per G4d: the evidence cliff is
  exhaustive/comprehensive content and skill count (SkillsBench v4), not line
  200; compaction reattach economics (first 5,000 tokens per skill, 25,000
  combined) are named as the binding constraint. Cite the new text.
- J4: The TOC-presence check covers every skill reference file over 100
  non-blank lines in both skill directories and would FAIL on a file lacking
  a `## Contents` block. Cite the code.
- J5: New guard caps are enforced as errors (append to the validator's errors
  list), consistent with existing guard style; no warnings-only softening.
