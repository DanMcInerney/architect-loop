# Post-freeze rulings: skill-guards-01

Append-only; orchestrator-owned. Judges read this file, not thread prose.

- RULING 2026-07-04 (PHASE-0 concern 1): spec G3's phrase "fix DESIGN.md to
  match the enforced 900" describes the drift class, written before A1 was
  approved; spec §Validation states the controlling form: "DESIGN.md says 900
  (or the approved new cap)". A1 (approved verbatim "approve") sets the cap to
  1100. Builder's use of 1100 in DESIGN.md and the validator is CORRECT and is
  not a diff-vs-intent defect.
- RULING 2026-07-04 (PHASE-0 concern 2): SG7 greps only `800-non-blank`
  (DESIGN.md:572); the dispatch block additionally instructed fixing the
  DESIGN.md:648 risk-table cell "800-line guard". The builder fixed both.
  The extra DESIGN.md edit is in-boundary (DESIGN.md is MAY TOUCH) and
  intended — not a silent scope addition.
