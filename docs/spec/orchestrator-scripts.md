# Spec: orchestrator-scripts — dispatch preflight and merge postflight as typed-exit scripts

Status: APPROVED in-session 2026-07-04.
Approval record (verbatim, in-session human authorization): "go ahead and do
1. and 2." — referring to the orchestrator's offload list posted at the end
of factory run #62: (1) dispatch preflight bundle, (2) merge postflight +
touch-set audit.
Author: orchestrator session, 2026-07-04.
Evidence base: in run #62, every dispatch cost ~4-5 orchestrator tool calls
(claim, worktree add, HEAD-vs-freeze verify, frozen-file spot-check, block
assembly) and every merge cost another 4+ (merge, push, worktree remove,
branch delete), with the may-touch audit done by eyeball. All of it is
mechanics the orchestrator only needs to verify, not reason about.

## Problem

Dispatch and integration are multi-call orchestrator sequences whose outputs
land in frontier-model context. The touch-set audit — the one merge
precondition with correctness weight — is currently informal. Both are
deterministic given (issue, freeze SHA, boundaries) and belong below the LLM
layer, exactly like watchdog and check-runner.

## Goal

Two script pairs, siblings of watchdog/check-runner, config-JSON in, typed
exit out. The orchestrator writes one config, runs one command, and rules on
one line. Judgment, blocker answers, and merge DECISIONS stay with the
orchestrator; the scripts only execute and report facts.

## Non-goals

- No gh/network calls in either script (claiming, issue comments, pushes of
  the factory branch stay orchestrator-owned; postflight pushes only when
  told to via config, using plain git).
- No LLM fallback templates; where the scripts can't run, the orchestrator
  falls back to the manual sequence it uses today.
- No conflict resolution: a merge conflict aborts cleanly and exits typed —
  it is a decomposition-failure signal, never something a script fixes.
- No changes to check-runner, watchdog, or status scripts.
- Preflight's worktree creation is the Codex-backend path only; the existing
  per-harness rule (Claude-backend jobs never pre-create worktrees) stands
  and the wiring text must restate it.

## Design

Design-it-twice (interface): (A) positional CLI args — rejected: 6+ params,
quoting hazards on Windows, inconsistent with watchdog/check-runner; (B)
config JSON path as the single argument — chosen: matches both existing
siblings, diffable, written with file tools; (C) env vars — rejected:
invisible state, PS 5.1/bash divergence.

### D1. preflight.ps1 / preflight.sh

Config: see Interface contract. Behavior, in order:
1. Validate config; repo root and freeze SHA must resolve (`git cat-file -e
   <freeze_sha>^{commit}`).
2. `git -C <repo_root> worktree add <worktree> -b <job_branch> <freeze_sha>`.
3. Verify the new worktree HEAD equals the freeze SHA exactly.
4. Spot-check every path in `require_files` exists on disk in the worktree
   (the frozen check file at minimum).
5. Success: print `PREFLIGHT: OK worktree=<path> head=<sha>`; exit 0.
   Any failure: best-effort cleanup (remove the partial worktree and job
   branch if this run created them), print `PREFLIGHT: FAIL <reason>`, exit 5.
   Never leave a half-created worktree behind on FAIL.

### D2. postflight.ps1 / postflight.sh

Config: see Interface contract. Behavior, in order:
1. Validate config; refuse to run if the repo's current branch differs from
   `factory_branch` (typed ERROR, no side effects).
2. Touch-set audit BEFORE merging: changed = `git diff --name-only
   <freeze_sha>..<job_branch>`. Every changed path must match at least one
   `may_touch` glob or one `exempt` glob. Any path under `docs/checks/` is
   always a violation regardless of globs. Violations: print
   `POSTFLIGHT: VIOLATION <path>` (one line each) and exit 2 — no merge.
3. `git merge --no-ff <job_branch> -m <merge_message>`. Conflict: abort the
   merge (`git merge --abort`), print `POSTFLIGHT: CONFLICT` plus the
   conflicting paths, exit 3. The orchestrator treats exit 3 as
   kill-and-re-spec, per the existing decomposition-failure rule.
4. If `push` is true: `git push <remote> <factory_branch>`.
5. Cleanup: `git worktree remove <worktree>` (if configured) and
   `git branch -d <job_branch>`.
6. Success: print `POSTFLIGHT: OK merge=<sha> changed=<n>`; exit 0. Config
   or git errors: `POSTFLIGHT: ERROR <reason>`, exit 5, and never leave a
   half-merged state (abort in-progress merges before exiting).

### D3. Wiring

- dispatch.md: new `## Preflight and postflight dispatch` section — config
  contracts verbatim, typed exits, the rule that exit 3 = decomposition
  failure and exit 2 = automatic FAIL evidence for the job, Codex-backend
  scoping note. The dispatch hard-stop preconditions text points at
  preflight; the Integration commands section points at postflight and keeps
  the manual sequence as the recorded fallback.
- loop.md: the merge step names postflight and its typed exits.
- SKILL.md: step 3's dispatch-precondition sentence and step 4's merge
  sentence name the scripts. Minimal edits; the invariants do not change.

### D4. Glob semantics (pinned, both scripts identical)

`may_touch`/`exempt` entries are path prefixes or shell-style globs matched
against repo-relative forward-slash paths: `docs/jobs/` matches any path
under it (prefix rule when the entry ends with `/`); `skills/architect/*.md`
matches by glob. Matching is case-sensitive. No regex.

## Interface contract

preflight config JSON:

```json
{
  "repo_root": "<abs path>",
  "freeze_sha": "<sha>",
  "worktree": ".architect/wt/<slug>-<NN>",
  "job_branch": "job/<slug>-<NN>",
  "require_files": ["docs/checks/<slug>.md"]
}
```

postflight config JSON:

```json
{
  "repo_root": "<abs path>",
  "factory_branch": "factory/<run>",
  "job_branch": "job/<slug>-<NN>",
  "freeze_sha": "<sha>",
  "may_touch": ["skills/architect/preflight.ps1", "tests/fixtures/orchscripts/"],
  "exempt": ["docs/jobs/"],
  "merge_message": "<text>",
  "push": false,
  "remote": "origin",
  "worktree": ".architect/wt/<slug>-<NN>"
}
```

Typed exits — preflight: 0 `PREFLIGHT: OK`, 5 `PREFLIGHT: FAIL`; postflight:
0 `POSTFLIGHT: OK`, 2 `POSTFLIGHT: VIOLATION`, 3 `POSTFLIGHT: CONFLICT`,
5 `POSTFLIGHT: ERROR`. Scripts never post to the tracker, never grade, never
resolve conflicts.

## Assumptions

- A1. Scripts run on the orchestrator's machine (no codex-sandbox
  constraints); Git Bash is available for the .sh variants at check time.
- A2. `docs/jobs/` is the only default exempt prefix; rulings and reports
  land there. Additional exemptions are per-config, explicit.
- A3. Branch deletion uses `-d` (merged-only); a failed `-d` after a
  successful merge is a warning in output, not a typed failure.
- A4. This run itself judges via the new check-runner evidence path (first
  live use); any D3-format deviation found in the first evidence file is a
  run finding for the digest, handled by the failure ladder, not a reason to
  bypass the runner.

## Validation strategy

Fixture-based, against a scratch git repo built by a fixture script the
builder ships (`tests/fixtures/orchscripts/make-fixture.ps1` / `.sh`): a tiny
repo with a factory branch, a freeze commit, and three job branches — one
clean, one touching a forbidden path, one guaranteed to conflict. Frozen RUN
checks: build the fixture; preflight OK on a fresh worktree (typed line +
exit 0); preflight FAIL on a bad freeze SHA (exit 5, no worktree debris);
postflight OK merges the clean branch (typed line, exit 0); postflight
VIOLATION on the forbidden-path branch (exit 2, factory branch unmoved);
postflight CONFLICT on the conflicting branch (exit 3, merge aborted, clean
`git status --porcelain`); non-grading negative grep (no PASS/FAIL/INVALID
strings); both .sh variants exercise the same paths under bash. Wiring and
validator slices use grep-anchor checks as in run #62.

## Decomposition sketch

- OS1 `scripts`: preflight.ps1/.sh, postflight.ps1/.sh, fixture builder +
  fixture configs under tests/fixtures/orchscripts/. No blockers.
- OS2 `wiring`: SKILL.md, loop.md, dispatch.md. Disjoint from OS1. No blockers.
- OS3 `validator`: tests/validate_skills.py contracts. Blocked by OS1+OS2.
- OS4 `docs`: README, DESIGN.md, docs/solutions entry. Blocked by all;
  finish job.
