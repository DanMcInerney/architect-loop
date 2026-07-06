# Check: skill-library/s10-trigger-allowlist

Purpose: both trigger-eval scripts accept fixture blocks for the seven stage
skills so the finish-boundary live eval can parse the s9-extended fixture;
typed exits, flags, and grammar semantics unchanged.
Spec: docs/spec/skill-library.md
Fix contract: a failure means an allowlist gap or an out-of-scope script
change — fix the two trigger-eval scripts only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c 'for s in codebase-design to-spec to-issues frozen-checks tdd adversarial-review cohesion-review; do grep -qF "$s" skills/architect/trigger-eval.sh || { echo "SH_MISSING: $s"; exit 3; }; done; echo SH_ALLOWLIST_OK'` -> exit:0 match:"SH_ALLOWLIST_OK"
- RUN: `bash -c 'for s in codebase-design to-spec to-issues frozen-checks tdd adversarial-review cohesion-review; do grep -qF "$s" skills/architect/trigger-eval.ps1 || { echo "PS_MISSING: $s"; exit 3; }; done; echo PS_ALLOWLIST_OK'` -> exit:0 match:"PS_ALLOWLIST_OK"
- RUN: `bash -c 'grep -qF "architect-research" skills/architect/trigger-eval.sh && grep -qF "architect-research" skills/architect/trigger-eval.ps1 && echo EXISTING_KEPT'` -> exit:0 match:"EXISTING_KEPT"
- RUN: `bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'` -> exit:0 match:"OK"

Judge-only intent items:
- The edit is allowlist-only: no parsing restructure, no typed-exit, flag, or
  grammar-semantics change in either script; both scripts accept the same
  nine names.
- RED→GREEN parse evidence in the report: pre-fix rejection of a stage-skill
  block (exit 2 quoted) and post-fix clean parse of the full fixture, with
  the live eval NOT run (headless-session cost); the report states exactly
  what was proven per script.
- Diff stays within the two scripts (≤~10 changed lines).
