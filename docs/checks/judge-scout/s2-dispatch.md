# Checks: s2-dispatch (run judge-scout)

Purpose: dispatch.md carries the graded-RUN grammar, the narrowed intent-only
judge templates, the scout dispatch template, and the extended grill clause;
the judge agent def matches (spec G1 text, G2, G3 template).
Spec: docs/spec/judge-narrowing-and-scout.md
Fix contract: on FAIL, fix skills/architect/dispatch.md or
.claude/agents/architect-judge.md — never this file. Read-only after freeze.
Executor: powershell
Note: RUN lines use the graded grammar (see s1-runner.md contract block);
the current runner ignores expectations as prose.

- RUN: `$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py` -> exit:0 match:"OK"
- RUN: `git grep -F -c "Per check:" -- skills/architect/dispatch.md` -> exit:1 (absence proves both judge templates dropped per-RUN transcription)
- RUN: `git grep -F -c -e "-> exit:" -- skills/architect/dispatch.md` -> exit:0 (graded grammar documented; -e guards the leading dash)
- RUN: `git grep -F -c "match:" -- skills/architect/dispatch.md` -> exit:0
- RUN: `git grep -F -c "## Scout dispatch" -- skills/architect/dispatch.md` -> exit:0
- RUN: `if ((Get-Content skills/architect/dispatch.md | Where-Object { $_.Trim() -ne "" }).Count -le 545) { "BUDGET_OK" } else { "BUDGET_FAIL"; exit 1 }` -> exit:0 match:"BUDGET_OK" (line budget funding s3; five-file guard headroom)
- Judge-only: both judge templates (C5 and codex) are intent-only: they
  require checks-integrity verdict, diff-vs-intent verdict, exactly one
  spot-check re-run of one graded RUN item with mismatch = automatic INVALID
  (both outputs quoted), and a slice verdict with one decisive reason; they
  contain NO per-check grading section and NO instruction to grade RUN items
  from the evidence file. Cite template line spans.
- Judge-only: the `## Check-runner dispatch` section documents the graded
  grammar (expectation after the closing backtick, fixed-substring match,
  no-expectation = exit 5) and typed exits 0/2/5 consistent with the
  s1-runner contract block. Cite file:line.
- Judge-only: the stress-test/grill template requires every mechanical check
  to carry a `->` expectation (a RUN item without one is a check defect) and
  adds the run-map anchor spot-check duty. Cite file:line.
- Judge-only: the `## Scout dispatch` section carries a scout template:
  read-only job, builders model, return capped at ~2,500 tokens, file:line
  anchors on every entry, honest NOT FOUND lines, no recommendations, output
  written to the path the orchestrator names (map committed by the
  orchestrator at docs/runs/<run>/map.md). Cite file:line.
- Judge-only: .claude/agents/architect-judge.md duties match the narrowed
  template (evidence-summary reading plus intent review; no per-RUN
  re-grading duty; spot-check and INVALID rules retained). Cite file:line.
