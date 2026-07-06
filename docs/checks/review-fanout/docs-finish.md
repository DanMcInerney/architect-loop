# Check: review-fanout/docs-finish

Purpose: product docs describe the review-and-decompose finish boundary —
readme, design doc, context glossary, and flow diagram no longer present
the direct-edit closing review as current truth.
Spec: docs/spec/review-fanout.md
Fix contract: a failure means a product doc still tells the old story or
the validator is red — fix `README.md`, `DESIGN.md`, `CONTEXT.md`,
`assets/architect-flow.svg`, or `docs/solutions/` files only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c 'grep -qiE "fix[- ]wave|review spec" README.md && echo README_NEW'` -> exit:0 match:"README_NEW"
- RUN: `bash -c 'grep -qiE "fix[- ]wave" CONTEXT.md && grep -qiE "review spec" CONTEXT.md && echo CONTEXT_VOCAB'` -> exit:0 match:"CONTEXT_VOCAB"
- RUN: `bash -c 'grep -qiE "fix (builders|issues|wave)" assets/architect-flow.svg && echo SVG_NEW'` -> exit:0 match:"SVG_NEW"
- RUN: `bash -c 'grep -qiE "fix[- ]wave" DESIGN.md && grep -qi "review-fanout" DESIGN.md && echo DESIGN_EVIDENCE'` -> exit:0 match:"DESIGN_EVIDENCE"
- RUN: `uv run python tests/validate_skills.py` -> exit:0 match:"OK - "

Reviewer intent items (orchestrator grades directly - final review has run):
- Run-history sections in DESIGN.md stay untouched as history; the new flow
  lands as current truth plus a dated evidence entry for this run.
- The flow diagram keeps its hand-written style; the final-review box and
  caption describe reviewer -> fix issues -> parallel fix builders.
- CONTEXT.md defines review spec, fix issue, fix wave, review cycle once
  each; green-or-discard moves to Retired terms.
