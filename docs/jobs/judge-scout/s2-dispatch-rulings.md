# Post-freeze rulings: judge-scout/s2-dispatch (re-spec lineage)

RULING 1 (2026-07-05, job -01 killed pre-judgment): decomposition failure —
the narrowed judge templates and the validator's template-contract greps are
one atomic contract; boundary re-specced to own both (see issue #100
comments). Not a builder defect.

RULING 2 (2026-07-05, after job -02 judgment FAIL): the validator's template
marker-pair existence loop must cover ALL FOUR marker pairs in dispatch.md
(architect-judge-template, architect-codex-judge-template,
architect-stress-test-template, architect-monitor-fallback-template), per
the frozen check's "all four template marker pairs" clause. The narrowed-
phrase assertions apply to the two judge templates only, as built. Extend
the loop at tests/validate_skills.py:317-323; change nothing else. All other
judgment-2 items PASSed; keep them as built.
