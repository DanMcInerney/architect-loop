# Spec: loop-hygiene — judge delivery fix, close-out discipline, cross-platform audit, fresh-install cleanup

Status: APPROVED — in-session, 2026-07-04
Run branch: `factory/loop-hygiene`
Tracker: github

## Goal

Six changes to the architect skill and this repo, in one run:

1. **Fix the judge verdict hang.** The 2026-07-03 diagnosis (background judge
   subagents deliver their verdict as final plain text, which the harness
   drops; the orchestrator gets a contentless idle notification and sleeps
   deaf) still applies to Claude-backend judges. The check-runner offload
   fixed the mechanical-check half only; verdict delivery is unchanged.
   Fix: **Claude-backend judges dispatch synchronously by default**
   (`run_in_background: false`) so the verdict returns as the tool result.
   Codify the recovery ladder for any backgrounded subagent whose deliverable
   is missing: retrieve task output via the harness → one nudge → discard and
   respawn fresh; never fill in a verdict. Human ruling 2026-07-04 supersedes
   the loop-tuning "judges dispatch concurrently for every DONE" line.
2. **Parallelize judge-internal work.** Judge agent def and both judge
   templates instruct: batch all independent reads (frozen check file, spec,
   job report, rulings file, checkrun evidence) into parallel tool calls in
   one turn; serialize only dependent steps and command re-runs.
3. **Subagent/shell close-out discipline.** One declarative loop rule: after
   the orchestrator consumes a subagent result or a background process's
   typed exit, it stops/closes that subagent or shell task in the same turn,
   batching independent close-outs into parallel calls. No polling, no new
   scripts, no per-close commentary — this is mechanical bookkeeping and must
   stay token-minimal.
4. **Platform-agnostic audit.** Every script pair (`status`, `watchdog`,
   `check-runner`, `preflight`, `postflight`, installers) verified to run on
   Windows PowerShell 5.1, and bash on macOS + Linux (no GNU-only flags
   without fallback, no bashisms beyond the declared `#!/usr/bin/env bash`,
   `mapfile` watch item resolved). Skill text names both platform variants at
   every invocation point and works from both Claude Code and Codex
   orchestrators.
5. **Native tracker edges.** Sub-issues are created with native
   `gh issue create --parent <tracking> --blocked-by <n,n>` flags (verified
   present on gh 2.96.0) so the status emitter's `--json parent,blockedBy`
   query sees the graph. Retire any body/title-text edge convention for
   github mode.
6. **Builder-run docs finish + fresh-install cleanup.** The finish docs job
   is always a dispatched builder given a change-context digest (shipped
   issues with one-line summaries, per-issue diffstat, rulings/solutions
   pointers, domain-language changes) — the orchestrator never writes product
   docs. As the run's final act, the repo is stripped to install-ready:
   delete all of `docs/` (spec, research, solutions, adr, jobs, checks,
   gates, lanes — including this run's own artifacts); DESIGN.md and skill
   text citations that point into deleted paths are rewritten to git-history
   pointers first, by the docs job.

## Non-goals

- No change to the codex-backend judge path (`codex exec -o <file>`, process
  exit wakes the loop) — it does not have the delivery defect.
- No new cleanup script or watchdog feature; close-out is skill text using
  harness-native stop mechanisms.
- No CI matrix, no new test framework; validation stays
  `tests/validate_skills.py` + frozen RUN checks.
- No tracker adapters beyond the gh flag change; markdown mode's frontmatter
  edges are already native to that mode.
- No re-litigation of the check-runner design or the frozen-check invariants.

## Approval record

- Q1 (judge fix shape): human selected **"Synchronous by default"** —
  `run_in_background: false`, verdict as tool result; supersedes the prior
  concurrent-judges ruling. In-session answer, 2026-07-04.
- Q2 (cleanup scope): human selected **"Delete all of docs/"** — including
  this run's own spec/checks/jobs; survivors are README.md, DESIGN.md,
  CONTEXT.md, LICENSE, assets/, skills/, .claude/agents, installers, tests/.
  In-session answer, 2026-07-04.
- Run authorization: in-session AskUserQuestion 2026-07-04, question "Approve
  the loop-hygiene run? Spec: docs/spec/loop-hygiene.md — 3 slices (judge-path
  skill text, xplat script audit, docs-finish), then orchestrator deletes all
  of docs/ and opens the closing PR..." — human answered exactly: **"APPROVE"**.
  Recorded verbatim per the approval rule.

## Assumptions

- A1: Native sub-issue links (not a text convention) fix the tracker defect;
  `gh issue create --parent/--blocked-by/--blocking` verified on gh 2.96.0.
- A2: The final `docs/` deletion is an orchestrator bookkeeping commit after
  the last judgment (a builder cannot delete `docs/checks/` — automatic-FAIL
  rule). The docs job lands the citation rewrites first so nothing dangles.
- A3: The sync-dispatch rule applies to harness-native background subagent
  judges (Claude Agent tool). Codex judges keep their typed-exit path.
- A4: Close-out uses harness-native stop (e.g. TaskStop / process kill),
  specified declaratively in loop text; no script.
- A5: Platform-agnostic = PowerShell 5.1+ on Windows, bash on macOS/Linux;
  both Claude Code and Codex orchestrators; no CI added.
- A6: Prior "judges dispatch concurrently" loop-tuning line is superseded by
  Q1; the rest of that ruling (frontier recompute on every merge, batched
  bookkeeping, serial merges/synthesis) stands.
- A7: `docs/STOP` semantics, `.gitignore` docs/ carve-outs, and the
  `/docs/*` ignore block are updated by the docs job only to the extent the
  deletion makes lines dead; `docs/STOP` kill-switch path stays valid (the
  directory may be recreated at any time).

## Preflight evidence

- gh 2.96.0, authenticated (`DanMcInerney`, keyring), remote
  `origin=https://github.com/DanMcInerney/architect-loop`.
- `gh issue create` exposes `--parent`, `--blocked-by`, `--blocking`.
- codex-cli 0.139.0 on PATH → builders default `codex/best` (gpt-5.5 xhigh).
- Claude judge-agent canary 2026-07-04: spawn returned `CANARY: DEGRADED` —
  Glob/Read/Grep only, both shell tools stripped (D12 pattern, now 7/7 on
  this machine). Judges this run: codex backend per the recorded D12
  mitigation. The synchronous dispatch mechanics themselves verified live:
  verdict text returned as the tool result.
- Codex builder canary: launched; result recorded on the tracking issue
  before decomposition.
- `docs/STOP`: absent.

## Slices (decomposition sketch)

| Slice | Files (may-touch) | Blocked by |
|---|---|---|
| `judge-path` — sync judge dispatch, recovery ladder, close-out rule, judge parallel reads, native gh edges, builder-run docs-finish contract | `skills/architect/SKILL.md`, `loop.md`, `dispatch.md`, `tracker.md`, `.claude/agents/architect-judge.md`, `.claude/agents/architect-builder.md`, `tests/validate_skills.py` | — |
| `xplat` — cross-platform audit + fixes of all script pairs and installers | `skills/architect/*.ps1`, `skills/architect/*.sh`, `install.ps1`, `install.sh`, `tests/fixtures/**` | — |
| `docs-finish` — product docs update from change-context digest; citation rewrite to git-history pointers; solutions entries folded into DESIGN evidence | `README.md`, `DESIGN.md`, `CONTEXT.md`, `.gitignore` | judge-path, xplat |

Then: orchestrator bookkeeping — delete `docs/` recursively, final digest, PR
`factory/loop-hygiene → main` with `Closes #<tracking>`.

## Validation strategy

- `python tests/validate_skills.py` exits 0 after every slice (validator is
  updated in `judge-path` where guarded contracts change).
- Frozen `- RUN:` checks per slice: greps proving the sync-dispatch line,
  close-out rule, parallel-reads instruction, and `--parent`/`--blocked-by`
  command forms exist; `bash -n` parse checks for every `.sh`;
  PowerShell parser checks for every `.ps1`.
- xplat slice reports a per-script parity table (Windows PS 5.1 / macOS bash
  / Linux bash) with the exact construct audited for each row.
- Native-edge fix validated live this run: sub-issues created with
  `--parent` must appear in `status` script output (`tracker: #<n>` +
  SUB rows) — the defect that motivated the fix.

## Domain language

- **close-out** — stopping a consumed subagent/background task in the same
  turn its result was consumed.
- **sync judge** — judge dispatched with `run_in_background: false`.
- **change-context digest** — the shipped-issues + diffstat + rulings block
  the docs job receives in its dispatch context.
- **recovery ladder** — retrieve-output → nudge once → discard + respawn
  fresh; never author a missing verdict.
