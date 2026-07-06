# Spec: ground-scripts — mechanize Ground reconcile, frontier, and spawn FF

Run: `ground-scripts`. Tracker: github.

## Goal

Replace the prose-driven mechanical steps of the factory with typed-exit
script pairs, per the 2026-07-06 script-replacement review: (a) the Ground
stage's reconcile + stop/environment gates + ready-frontier computation;
(b) the builder FIRST-ACTION worktree fast-forward check. Cross-platform
(.ps1/.sh pairs, standing ruling) and orchestrator-CLI-agnostic: the scripts
depend only on git + gh (gh only in github tracker mode), so a Claude or
Codex orchestrator invokes them identically.

## Implementation decisions

- `skills/architect/ground.ps1|.sh <run> [-RepoRoot|--repo-root <path>]`:
  parse `docs/runs/<run>/manifest.md` frontmatter; in github mode query the
  tracking issue's children (state, blockedBy) scoped by the run marker, in
  markdown mode read `docs/issues/<run>/`; verify the recorded freeze SHA and
  that `docs/checks/<run>/` is unchanged since it; list factory-branch head
  vs origin; flag job reports in `docs/jobs/<run>/` lacking checkrun
  evidence; gate on `docs/STOP` (run + primary checkout via
  `git rev-parse --git-common-dir`), uncommitted `docs/runs/<run>/STOP`, and
  `CLAUDE_CODE_SUBAGENT_MODEL` being set. Emit greppable detail lines plus
  one summary line and typed exit: 0 `GROUND: OK` (includes
  `frontier=<n>` and a `FRONTIER: <issue> <issue>...` line of open,
  fully-unblocked issues), 2 `GROUND: STOP <which>`, 3 `GROUND: DRIFT
  <fact>` (tracker/git disagreement or freeze drift), 5 `GROUND: ERROR`.
  Detection only: it never posts, edits, or decides.
- `skills/architect/ffcheck.ps1|.sh <expected-sha>`: from a job worktree,
  exit 0 `FFCHECK: OK <sha>` if HEAD already equals the SHA or was
  fast-forwarded to it (`merge-base --is-ancestor` then `merge --ff-only`);
  2 `FFCHECK: DIVERGED` when not an ancestor (never merges); 5
  `FFCHECK: ERROR`. Replaces the three-line FIRST-ACTION prose in dispatch
  blocks.
- Wiring: SKILL.md Ground section and loop.md frontier/dispatch lines invoke
  `ground`; dispatch blocks' FIRST-ACTION becomes one `ffcheck` command;
  validator gains contract checks + runnable fixtures for both pairs
  (check-runner fixture pattern).

## Non-goals

No behavior change to existing script contracts; no tracker-mode changes; no
judgment in scripts (drift is reported, ruled on by the orchestrator).

## Assumptions

1. In-session approval (verbatim): "ok lets implement the script-replacement
   findings. Make sure it's compatible cross-platform, and works whether you
   run architect from codex or from claude code."
2. Scout skipped (recorded deviation): planning context is this session's
   same-day whole-tree review; issues carry change-skeletons as usual.

## Validation strategy

Per-slice frozen checks: script pairs exist, emit the typed lines on
seeded fixture repos (OK, STOP, DRIFT, ffcheck OK/DIVERGED), both executors;
validator suite stays green end-to-end.

## Domain language

codebase-design glossary; new terms: ground snapshot, frontier line,
ffcheck.

## Approval record

- In-session approval 2026-07-06, quoted verbatim in Assumptions #1.
