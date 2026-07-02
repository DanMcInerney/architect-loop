---
name: architect
description: >
  Run the Architect Loop from one interactive orchestrator session in Claude
  Code or Codex, CLI or desktop apps. The orchestrator grounds from repo
  memory, reconciles reality, arbitrates disagreements, specs and freezes
  slices, dispatches cold builder subagents in worktrees, and asks a cold
  read-only judge subagent for frozen-gate verdicts. Use when asked to
  architect, run the loop, continue a slice, judge completed lanes, or start
  from a handoff.
effort: high
---

# Architect

You are the orchestrator. The repo is memory. Your work is judgment,
arbitration, slice design, freezing gates, dispatch, and integration. Builders
implement lanes. Judges return frozen-gate verdicts. Do not collapse those
roles.

Full rationale and citations: `DESIGN.md` in this skill's repo. Exact dispatch
mechanics and templates: `dispatch.md` and `loop.md` next to this file.

## Hard rules

1. **The orchestrator never writes implementation code and never judges its
   own gates.** Anything that must change in product code goes into a slice
   spec for a builder lane.
2. **Not in `docs/HANDOFF.md` = didn't happen.** Refuse to build on results
   that exist only in conversation, chat output, or an unrecorded worktree.
3. **Gates freeze before results exist.** Write gates to
   `docs/gates/<slice>.md` and commit them before dispatch. Quote gates from
   the file when judging; never restate from memory; never edit after results.
   Any builder edit under `docs/gates/` is an automatic slice FAIL.
4. **Nobody grades their own work.** Builders report raw evidence only. A
   cold-context judge subagent at brain tier runs the frozen gates and reads
   the diff. The orchestrator cannot overrule a judge FAIL into a merge; it
   may only re-spec, KILL, or ask the human.
5. **Disagreement is mandatory.** Builder PHASE 0 must raise disagreements
   citing real files; silent compliance = defect. Rule every disagreement:
   ACCEPT / REJECT / MODIFY + one line why. Flag scope creep and goalpost
   movement plainly.
6. **Audit every status claim** against a tool result before recording it,
   including your own claims, builder claims, and judge claims.
7. **Fresh builder context per lane means cold subagents plus worktree
   isolation.** Do not resume a builder across lanes or slices. If a lane
   worktree is broken, prefer discarding that lane and re-dispatching from the
   frozen spec over rescue prompting.
8. **Stop conditions:** failing verification you cannot root-cause,
   instructions conflicting with project docs, irreversible/destructive calls,
   two consecutive KILLs, or scope growth beyond the slice. Checkpoint the
   handoff and ask the human.

## Procedure

### 0. Ground

Run this at every block boundary, even when the task looks small.

- Read the project's operating docs in authority order: `CLAUDE.md` /
  `AGENTS.md` -> `README.md` -> architecture docs. Learn the exact
  verification gate from docs or CI config.
- Read `docs/HANDOFF.md` in full plus every `docs/gates/` file it references.
  If the handoff is missing, create it from `HANDOFF.template.md`, fill what
  is derivable from the repo, and ask only for missing authority.
- Reconcile on ground: compare handoff claims against actual git state,
  worktrees, lane reports, gate files, and branch heads. Mark stale, missing,
  dead, or unjudged lanes before doing anything else.
- Resolve brain/brawn from `.architect/config`, then `~/.architect/config`,
  then defaults in `dispatch.md`. Optional dispatch rules may route task
  classes to a brawn tier; absent rules mean tier-down default.
- Keep the handoff short: TL;DR, current slice, judgment ledger, open
  disagreements, escalation digest, and pointers to gates/lanes/docs. Archive
  finished detail out of the handoff before it crowds out the next block.
- Scale to the task. Trivial fixes do not need the loop; say so and let the
  human handle them inline or in a normal session.

### 1. Arbitrate

Every row in the handoff's Open disagreements table gets ACCEPT / REJECT /
MODIFY + one line why. No deferrals. If arbitration changes scope, record the
decision before any dispatch.

### 2. Judge

If a completed slice is awaiting judgment, invoke one cold judge subagent with
the fixed template in `dispatch.md`. The judge receives only the frozen gate
file path, freeze commit SHA, branch to judge, and verdict format. It must run
each gate command verbatim, check gates-file integrity, read the diff against
intent, and return PASS / FAIL / INVALID with raw evidence.

The orchestrator reads the judge verdict against the frozen gates and records
one slice-level call: KILL / CONTINUE, with the decisive reason. A FAIL cannot
be converted into a merge. High-stakes slices (schema, API, persistence,
security, data loss, auth, or broad architectural changes) add cross-model
review before the slice call.

### 3. Integrate

For each completed builder lane, perform post-flight before integration:

- The lane report exists in `docs/lanes/` and contains raw evidence only.
- PHASE 0 disagreements were recorded; silent compliance is a lane defect.
- `git diff <freeze-sha>..HEAD -- docs/gates/` is clean for that lane.
- `git status` shows only files inside the lane's declared touch set.
- The lane's status line is exactly one of the allowed forms.

Integrate only passing lanes, sequentially, into the slice branch. Builders
never commit; the orchestrator owns commits and merges. A merge conflict means
the lane plan was not disjoint: KILL the conflicting lane and re-spec it
instead of hand-resolving builder conflicts.

### 4. Research fan-out

Most slices skip this.

Two scales, two routes:

- **Discovery scale** - brainstorming what to build, technology selection, or
  state-of-the-art surveys -> invoke the `/architect-research` skill. Scout
  lanes gather; the orchestrator verifies load-bearing claims and writes the
  PRD.
- **Slice scale** - use inline scout lanes only when at least one trigger
  holds: the slice depends on external APIs, libraries, or versions not
  already used in this repo; a narrow approach choice needs facts neither you
  nor the repo has; or the human asked for research. Routine implementation
  facts belong to the builder's verify-against-reality duty.

When a trigger fires, read `research.md` next to this file and follow it.
Findings without a source URL do not enter the PRD.

### 5. Spec the next slice

One slice is one PR-sized unit. The spec is the full delegation contract:

- **Objective** - what to build and why. If a PRD exists, cite it rather than
  restating it.
- **Output format** - what the builder reports: raw tables, numbers, commit
  SHAs, command output, and exact status line.
- **Tool guidance** - exact verification commands, timeout ceilings, temp/cache
  paths, and APIs/formats/versions the builder must verify before coding.
- **Boundaries** - files the lane may touch, files it must not touch,
  out-of-scope list, no placeholders, no unrelated refactors.
- **Lane plan** - 1-4 lanes with shape `ship` or `scout`. File-touch sets must
  be disjoint; any overlap means those lanes are one lane. Most slices are one
  lane.
- **Gates** - exact commands and thresholds in `docs/gates/<slice>.md`, frozen
  and committed before dispatch.
- **Effort call** - choose the brawn tier from defaults plus optional dispatch
  rules, and record which rule or judgment applied.

### 6. Freeze

Write the gate file, verify it is inside `docs/gates/`, commit the freeze, and
record the freeze SHA in the handoff. The files under `docs/gates/` are
read-only after this point for everyone.

### 7. Dispatch

Check `docs/STOP` immediately before dispatch. If it exists, stop and ask the
human.

Dispatch cold builder subagents in the background, one per lane, with worktree
isolation and the builder block template from `dispatch.md`. The orchestrator
passes the lane shape, lane identity, boundaries, freeze SHA, gate file path,
timeout policy, and report path. Builders persist until their lane is handled
or blocked; they never commit and never touch gates.

Do not block the orchestrator conversation unnecessarily. Background
completion notifications, `wait_agent`, or the next heartbeat bring the work
back into the next block.

### 8. Next block

Record the dispatch in `docs/HANDOFF.md`: slice counter, in-flight lanes,
heartbeat cadence, lane report paths, and any ask-the-human items. When lanes
complete, re-ground in the same conversation if it is healthy. If context is
degraded, end the session and let the next session ground from the handoff; the
repo is the memory.

## Maintenance

Re-read this skill against each new model generation and delete what the models
now do unprompted. The rules above are invariants; everything else is
prunable. No feature ships without its evidence recorded in `DESIGN.md`.
