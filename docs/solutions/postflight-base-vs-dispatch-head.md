# postflight-base-vs-dispatch-head

## Symptom

A review or docs job dispatched after one or more waves have already merged
onto the factory branch reuses the run's original `freeze_sha` as the base
for its own boundary or touch-set audit. Every file any earlier wave already
merged shows up in that diff even though this job never touched it, so a
boundary check built the same way postflight's touch-set audit is built would
false-positive on inherited files.

## Root Cause

`skills/architect/preflight.ps1:61-86` creates a build-issue worktree at
exactly `freeze_sha` and verifies `HEAD == freeze_sha` before dispatch, and
`skills/architect/postflight.ps1:104-110` audits that issue's touch set as
`git diff --name-only freeze_sha..job_branch`. Both are correct for a build
issue, because that issue's own frozen check was authored at that same freeze
and its worktree never sees any later commit. A review or docs job is
different: it is dispatched from the *current* factory-branch tip, after
however many build or fix waves have already merged past the original freeze.
If its own audit logic borrows the `freeze_sha..job_branch` pattern verbatim,
the base is stale relative to what this job's worktree actually started from,
and the diff includes every intervening wave's merged files as if they were
this job's own changes.

## What Did Not Work

- Treating `freeze_sha..job_branch` as a general-purpose "what did this job
  touch" formula usable by any stage, not just single-issue builder jobs.
- Assuming the run's one recorded freeze SHA is still the right diff base
  for every later-stage job, when the factory branch has moved on through
  one or more merged waves since that freeze.

## Route Around

- For a build-issue job, keep `freeze_sha..job_branch` — the worktree was
  created at that exact freeze, so the base is correct by construction.
- For a post-merge review or docs job, use the dispatch head — the
  factory-branch commit the job's own worktree was actually created from —
  as the diff base, not the run's original check-freeze SHA. A job that
  needs "everything this run has done so far" diffs against the commit
  before the run started, not against an intermediate freeze; a job that
  needs "what did I personally touch" diffs against its own dispatch head.
- When a run's freeze record is updated mid-run (e.g. the review-fanout
  spec's fix-wave freeze updating the tracking-issue body's freeze record to
  the latest freeze SHA, `docs/spec/review-fanout.md` "Draft placement"),
  any script or job that resolves freeze from that record inherits the
  update automatically; a hand-rolled audit that hardcodes an earlier freeze
  SHA does not, and drifts.
