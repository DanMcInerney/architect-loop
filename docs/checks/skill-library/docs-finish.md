# Check: skill-library/docs-finish

Purpose: docs debt consumed — solutions notes written, product docs aligned
with the shipped library, guard re-baseline consistent, no hand-drawn assets
touched. Orchestrator-graded (human-ruled: no cold judge for docs jobs).
Spec: docs/spec/skill-library.md
Fix contract: a failure means a missing note, a stale doc claim, or an
inconsistent guard re-baseline — fix the named docs/config files only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c 'for f in agent-worktrees-branch-from-main grep-qif-sigabrt judge-verdict-delivery trigger-eval-finish-boundary; do test -f "docs/solutions/$f.md" || { echo "MISSING: $f"; exit 3; }; done; echo SOLUTIONS_OK'` -> exit:0 match:"SOLUTIONS_OK"
- RUN: `bash -c 'grep -qi "cohesion-review" README.md && grep -qi "to-spec" README.md && echo README_OK'` -> exit:0 match:"README_OK"
- RUN: `bash -c 'grep -qi "adversarial-review" CONTEXT.md && echo CONTEXT_OK'` -> exit:0 match:"CONTEXT_OK"
- RUN: `bash -c 'grep -qF "__pycache__" .gitignore && echo GITIGNORE_OK'` -> exit:0 match:"GITIGNORE_OK"
- RUN: `bash -c '! grep -qi "codex-first" skills/architect-research/SKILL.md && echo RESEARCH_FIXED'` -> exit:0 match:"RESEARCH_FIXED"
- RUN: `bash -c 'git diff --stat HEAD -- assets/ | wc -l | grep -qx "0" && echo ASSETS_UNTOUCHED'` -> exit:0 match:"ASSETS_UNTOUCHED"
- RUN: `bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'` -> exit:0 match:"OK"

Orchestrator-graded intent items (no cold judge; graded from this evidence
plus the report):
- Solutions notes carry evidence pointers (issue numbers, commit SHAs) and
  the what-did-not-work detail, matching the existing docs/solutions format.
- README preserves the human voice, product-page shape, Details tags, and
  Config section; flow text matches the shipped library; needed SVG updates
  listed in the report, assets untouched.
- DESIGN.md gained the run's evidence section; the 1100-guard statement and
  `check_design_guard_cap` were changed consistently or not at all.
- CONTEXT.md terms reconciled with the glossary; no stale pre-library flow
  claims remain in the named files.
