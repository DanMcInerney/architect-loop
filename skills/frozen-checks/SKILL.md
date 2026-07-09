---
name: frozen-checks
description: >
  Use when the strategist drafts per-issue graded checks after decomposition
  and before builder dispatch. Produces one check file per
  issue at `docs/checks/<run>/<slice>.md`, frozen in git, read-only after.
---

# Frozen checks

One check file per issue, at `docs/checks/<run>/<slice>.md`. Open it with
purpose, a spec pointer, and a fix contract stating what a failure means and
which file to fix — that header is the closing review's entire intent context
for the issue. Write for a reader with no other memory of this run, in the
codebase-design vocabulary (`skills/codebase-design/SKILL.md`).

## RUN grammar

Normative from the shipped runner, `skills/architect/check-runner.ps1`; cite
it, do not restate it divergently from `skills/architect/dispatch.md`'s
`## Check-runner dispatch`. A graded item is exactly:

``- RUN: `command` -> exit:<n>`` with optional trailing `match:"<substring>"`.

`match:` is a fixed, case-sensitive stdout substring — never a regex. A RUN
item without an `-> exit:<n>` expectation makes the runner exit 5 with no
partial evidence kept; that is a check defect, not a builder defect. Every
other line — rationale, judge-only intent items — is read by the closing
review and the orchestrator, never graded by the runner.

## Falsifiable and atomic

Each RUN item asserts exactly one falsifiable fact. Run every draft command
against the current tree before freezing; a check that cannot fail is not a
check.

Attack-list, run before freeze:
- Repo-name grep collisions — a pattern that matches unrelated hits because
  it contains the repo's own name.
- Self-matching — a pattern that matches the check file itself, not just
  the intended target.
- `git grep` is blind to a builder's untracked new files in a worktree that
  hasn't staged them; use filesystem `grep`/`test` there instead.
- New artifact paths — run `git check-ignore <path>`; a gitignored path
  never gets graded no matter what the check says.

## Dependency surface

A RUN command's dependency set — the test files, validators, and scripts it
executes — is part of the check's enforcement surface: agents that game a
check edit the test, not the criteria file. Name that set in the check
header. Decomposition keeps those files out of MAY TOUCH by default; when an
issue legitimately owns one (a job writing the tests a RUN item runs), every
builder edit to it must be disclosed in the job report, and the orchestrator
re-verifies intent before trusting a green — the edited dependency must
still fail a known-bad input.

## Freeze protocol

All check files for a run commit to the factory branch before any builder is
dispatched; record the freeze SHA on the tracking issue.
After that commit, everything under `docs/checks/` is read-only to every
builder and reviewer — an edit there is an automatic FAIL regardless of the
rest of the job report. An intent change discovered after freeze is a
ruling: it goes in the run's rulings file, never a rewrite of the frozen
check.

## Duration hints

An issue or check file may note a duration hint in prose (e.g. "full suite
~20m") so a monitor doesn't mistake legitimate long work for a stall. A hint
is informative only — never a kill ceiling, never a RUN expectation.
