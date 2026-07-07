# Checks: s3-skilltext (run judge-scout)

Purpose: SKILL.md and loop.md carry the scout intake step, change-skeleton
decomposition, typed-checkrun judgment ordering, and the human-gated closing
review (spec G3, G4, G5, and G1/G2 loop wiring).
Spec: docs/spec/judge-narrowing-and-scout.md
Fix contract: on FAIL, fix skills/architect/SKILL.md or
skills/architect/loop.md — never this file. Read-only after freeze.
Executor: powershell
Note: RUN lines use the graded grammar (see s1-runner.md contract block);
the current runner ignores expectations as prose.

- RUN: `$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py` -> exit:0 match:"OK"
- RUN: `git grep -F -c "docs/runs/<run>/map.md" -- skills/architect/SKILL.md` -> exit:0
- RUN: `git grep -F -c "change-skeleton" -- skills/architect/SKILL.md` -> exit:0
- RUN: `git grep -F -c "closing review" -- skills/architect/SKILL.md` -> exit:0
- RUN: `git grep -F -c "without judge dispatch" -- skills/architect/loop.md` -> exit:0
- RUN: `if (((Get-Content skills/architect/SKILL.md | Where-Object { $_.Trim() -ne "" }).Count + (Get-Content skills/architect/loop.md | Where-Object { $_.Trim() -ne "" }).Count) -le 411) { "BUDGET_OK" } else { "BUDGET_FAIL"; exit 1 }` -> exit:0 match:"BUDGET_OK" (combined line budget; five-file guard headroom)
- Judge-only: intake dispatches one read-only code scout (builders model,
  scout job shape, per dispatch.md `## Scout dispatch`) in parallel with the
  intake question batch and its timer; the orchestrator commits the returned
  map at docs/runs/<run>/map.md; the spec and issues cite the map. Cite
  file:line in SKILL.md.
- Judge-only: decomposition requires a compact change-skeleton per issue
  (~<=30 lines: files, signatures, data flow, invariants; structure only), a
  contract-not-mandate rule naming PHASE 0 as the disagreement channel, and
  the parallel frontier computed from skeleton file-ownership. Cite
  file:line.
- Judge-only: the DONE path reads the check-runner's typed exit: exit 2
  routes to the failure ladder without judge dispatch; exit 0 dispatches the
  intent judge; exit 5 stays the recorded error rail. Both SKILL.md's loop
  step and loop.md agree. Cite file:line in both.
- Judge-only: Finish opens with the timed-ruling closing-review question
  (recommended default YES, 5-minute silence applies it), then on yes: one
  fresh subagent at the resolved strategist model at medium effort, in a
  worktree from the factory branch head, reading spec then map then run diff,
  docs/checks/ read-only, all graded RUN items across the run must stay
  green, full closing checkrun plus named test suites re-run, green-or-
  discard (red review changes never merge, discard recorded on the digest),
  merge through postflight, verdict and diffstat on the tracking issue,
  ordered BEFORE the docs-finish job. Cite file:line.
- Judge-only: Hard Rule 3 and Ground wording are consistent with the
  builders-model intent-only judge (no stale strategist-tier or
  evidence-re-grading claims). Cite file:line.
