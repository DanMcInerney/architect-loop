# atomic-contract-decomposition

Evidence: factory run judge-scout, 2026-07-05, issues #99-#101

## Symptom

Run judge-scout slice #100 was killed before judgment because the work split
one atomic contract across boundaries: judge template phrases changed in one
slice while `tests/validate_skills.py` template-contract greps still enforced
the old phrases elsewhere.

The visible failure shape was a decomposition failure, not a bad patch: the
validator and the skill text described the same public contract but were owned
by different jobs.

## Root Cause

Validator-enforced contract phrases couple the skill text to the validator.
When a slice retires or renames those phrases, the validator's corresponding
contract section is part of the same product change. Splitting them creates a
false frontier: each job looks local, but neither boundary owns the whole
contract.

## What Did Not Work

- Treating template wording and validator greps as independent edits.
- Letting marker-loop coverage stand in for pairwise phrase coverage.
- Waiting for judgment to discover that a contract was only half-retired.

## Route Around

- During decomposition, identify every validator-enforced phrase that a slice
  changes or retires.
- Put the owning skill/template text and the validator contract section in the
  same boundary.
- If that coupling is discovered after freeze, kill the split job and re-spec
  the boundary instead of patching around it.
- Add a docs-finish note when the coupling teaches a reusable decomposition
  rule, as judge-scout did here.
