# Checks: s2-dispatch2 (run judge-scout, re-spec of s2-dispatch after decomposition-failure kill)

Purpose: dispatch.md carries the graded-RUN grammar, the narrowed intent-only
judge templates, the scout dispatch template, and the extended grill clause;
the judge agent def matches; AND the validator's judge-template contract
greps assert the narrowed phrases (the atomic contract lives in one slice
now). Spec: docs/spec/judge-narrowing-and-scout.md
Fix contract: on FAIL, fix skills/architect/dispatch.md,
.claude/agents/architect-judge.md, or the judge-template contract-grep
section of tests/validate_skills.py — never this file. Read-only after freeze.
Executor: powershell
Note: RUN lines use the graded grammar (s1 shipped; the runner grades them).

- RUN: `$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py` -> exit:0 match:"OK" (REAL proof now: post-s1 tree, aligned greps required)
- RUN: `git grep -F -c "Per check:" -- skills/architect/dispatch.md` -> exit:1 (absence proves both judge templates dropped per-RUN transcription)
- RUN: `git grep -F -c "Per check:" -- tests/validate_skills.py` -> exit:1 (absence proves the retired contract grep is gone from the validator)
- RUN: `git grep -F -c -e "-> exit:" -- skills/architect/dispatch.md` -> exit:0 (graded grammar documented)
- RUN: `git grep -F -c "match:" -- skills/architect/dispatch.md` -> exit:0
- RUN: `git grep -F -c "## Scout dispatch" -- skills/architect/dispatch.md` -> exit:0
- RUN: `if ((Get-Content skills/architect/dispatch.md | Where-Object { $_.Trim() -ne "" }).Count -le 545) { "BUDGET_OK" } else { "BUDGET_FAIL"; exit 1 }` -> exit:0 match:"BUDGET_OK"
- Judge-only: both judge templates (C5 and codex) are intent-only: they
  require checks-integrity verdict, diff-vs-intent verdict, exactly one
  spot-check re-run of one graded RUN item with mismatch = automatic INVALID
  (both outputs quoted), and a slice verdict with one decisive reason; they
  contain NO per-check grading section and NO instruction to grade RUN items
  from the evidence file. Cite template line spans.
- Judge-only: tests/validate_skills.py's judge-template contract greps
  assert the NARROWED template phrases (evidence-SUMMARY reading; re-run
  exactly ONE graded RUN item; mismatch = automatic INVALID) instead of the
  retired "Per check:" / "re-run at least one RUN command" strings; the
  validator still asserts all four template marker pairs exist. Cite
  file:line.
- Judge-only: the `## Check-runner dispatch` section documents the graded
  grammar (expectation after the closing backtick, fixed-substring match,
  no-expectation = exit 5) and typed exits 0/2/5 consistent with the shipped
  s1 runner. Cite file:line.
- Judge-only: the stress-test/grill template requires every mechanical check
  to carry a `->` expectation and adds the run-map anchor spot-check duty.
  Cite file:line.
- Judge-only: the `## Scout dispatch` section carries a scout template:
  read-only job, builders model, return capped at ~2,500 tokens, file:line
  anchors on every entry, honest NOT FOUND lines, no recommendations, output
  written to the path the orchestrator names (map committed by the
  orchestrator at docs/runs/<run>/map.md); SKILL.md's pointer to this
  heading resolves. Cite file:line.
- Judge-only: .claude/agents/architect-judge.md duties match the narrowed
  template (evidence-summary reading plus intent review; no per-RUN
  re-grading duty; spot-check and INVALID rules retained). Cite file:line.
