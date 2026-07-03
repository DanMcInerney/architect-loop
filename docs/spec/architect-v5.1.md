# Spec: architect v5.1 — hardening from the first factory run

Status: DRAFT — awaiting human review at the spec gate.
Author: brain session, 2026-07-02 (same-day retro of the v5 dogfood run).
Evidence base: epic #12 and issues #13–#18 (full verdict/ruling trail),
`docs/solutions/` (4 codified diagnoses), `docs/lanes/v5-*-01.md` (raw lane
reports), PR #19. This spec exists because the v5 run generated defects the
shipped skill text does not yet prevent — the codify loop closing on itself.

## Problem

The first v5 run completed autonomously (zero human questions post-gate,
6/6 issues judged and merged), but produced eight distinct findings whose
fixes currently live only in `docs/solutions/`, issue comments, or the
orchestrator's session memory. A future run on a fresh machine or fresh
session would re-hit five of them. The operating text (SKILL.md, loop.md,
dispatch.md, grill template) must absorb what the run learned.

## Retro summary (evidence, one line each)

WENT RIGHT — protected, do not regress:
- R1. Blocker protocol: lane #13's first spawn exited BLOCKED-with-evidence
  instead of idling; diagnosis + respawn worked first try (#13 comments).
- R2. PHASE 0 caught an ORCHESTRATOR defect (#15: issue body forced
  kill-ceiling text the spec abolished) — disagreement duty works against
  the brain, not just the spec.
- R3. Cold judge diff-vs-intent caught a masked failure that five green
  gates missed (#17: validator link-check exception hiding a broken README
  link) — the marquee validation of nobody-grades-their-own-work.
- R4. One decomposition grill caught 3 falsified gate clauses + 2 traps
  BEFORE freeze (CRLF anchors, vacuous DC2, HR4 scope trap, missing
  validator gates, zero budget headroom).
- R5. Judge verdict discipline: environmental failure returned INVALID (#16
  AG6), not FAIL — evidence completed separately without re-judging work.
- R6. Interface handoff blocks: four parallel lanes converged on exactly
  matching cross-file anchors; zero merge conflicts.
- R7. Raw-evidence culture held under tool deprivation: shell-stripped
  builders labeled Grep-tool substitutions as substitutions and reported
  unrunnable gates as UNEXECUTED rather than fabricating passes.
- R8. Tier data point: 3 of 4 first-wave lanes were sonnet:high and their
  work passed cold judges — cheap brawn sufficed for skill-text work
  (their only failures were environmental, not quality).

WENT WRONG — each maps to a design decision below:
- W1. Claude-backend subagent spawns lost both shells 5/5 times (D12);
  brawn backend choice (spec A4) was falsified minutes after dispatch;
  the fallback was improvised mid-wave. → D1
- W2. First harness worktree had a stale file snapshot (ref at freeze,
  files pre-freeze) because the freeze commit was not pushed/visible when
  the spawn forked. → D2
- W3. Two decomposition defects escaped the grill because it only read
  GATE files: the #15 issue-body/spec contradiction and the #17
  deleted-file reference (README link) were in artifacts the grill never
  received; #18's `.gitignore` invisibility (docs/solutions under
  `/docs/*`) was a third unchecked class. → D3
- W4. Post-freeze rulings (PHASE-0 rulings, boundary amendments) had no
  durable in-repo home; they were injected into judge blocks as ad hoc
  prose — a steering risk and a violation of the gate-file-is-the-intent
  convention in spirit. → D4
- W5. Codex-backend judge blocks were hand-assembled 6 times (role
  preamble, substitution permissions, tree-audit warning); the
  UV_CACHE_DIR redirect was rediscovered by one judge and manually
  propagated. dispatch.md's C5 covers only the Claude-backend judge. → D5
- W6. The monitor's real lifecycle didn't match loop.md: spawned as a
  teammate it IDLED (idle notifications) instead of exiting, and required
  a formal shutdown_request; loop.md promises "exit quietly." Detection
  added no value this run (harness notifications covered 100% of events),
  but the text/mechanics mismatch will confuse the next orchestrator. → D6
- W7. "Brawn writes to the issue" was 0% achieved: codex sandbox has no
  network, Claude spawns had no shell — every mirror was
  MIRROR: ORCHESTRATOR. Worked fine, but it is an undocumented deviation
  from spec D8. → D7 (accept + document, not build)
- W8. Pre-factory commits (spec, research, gates) landed on main and main
  was pushed mid-run to fix W2 — branch hygiene was improvised. → D2

## Design decisions

### D1. Backend canary at preflight (fixes W1)
Intake preflight gains one step: before decomposition records the brawn
backend, spawn ONE trivial canary per candidate backend (task: "run
`git log -1 --oneline` and echo the tool names you actually have; exit").
A backend whose canary lacks a working shell executor is DEGRADED; the
orchestrator selects the fallback backend THEN, records the substitution
in the spec's preflight section, and dispatch rules resolve against the
verified backend. Cost: one cheap spawn per backend, ~1 min. The epic
carries the canary evidence. No mid-wave backend switching unless a
canary-passing backend later degrades (then the existing failure ladder
applies).

### D2. Factory branch from spec approval; freeze→push→dispatch (fixes W2, W8)
On spec approval the orchestrator cuts `factory/<run>` and ALL run commits
(spec amendments, gates, freeze, lane merges) land there; main stays
untouched until the single closing PR. The dispatch precondition becomes
three checks, in order, hard-stop on failure: (1) freeze committed on the
factory branch; (2) branch pushed (or verified locally visible to the
spawn mechanism — evidence from this run says pushed is the safe form);
(3) after each spawn, verify the worktree HEAD equals the freeze commit
AND spot-check one frozen file exists on disk (`docs/gates/<slug>.md`).
Builders keep their existing FIRST-ACTION input-verification duty as the
last line of defense.

### D3. Grill scope: gates + issue bodies + repo-reality sweeps (fixes W3)
The decomposition grill's frozen template gains three checks, each
evidenced by a caught-or-missed defect this run:
- (a) **Issue-body contradiction check**: the grill receives the issue
  bodies (pasted, since sandboxes lack gh) and attacks them against the
  spec the same way it attacks gate clauses — would have caught #15's
  kill-ceiling contradiction.
- (b) **Deleted/renamed-file reference sweep**: for every file a lane
  deletes or renames, grep the whole repo for references and verify the
  owning lane's boundary covers them or a dependency edge orders the fix —
  would have caught #17's README link.
- (c) **Committability check**: for every NEW artifact path a lane will
  create, run `git check-ignore` and fail the plan if the path is ignored —
  would have caught #18's invisible `docs/solutions/`.

### D4. Rulings file: post-freeze intent lives in git (fixes W4)
New convention: `docs/lanes/<issue-slug>-rulings.md`, orchestrator-owned
and orchestrator-written, committed before any judge dispatch for that
issue. It accumulates, append-only: PHASE-0 rulings (ACCEPT/REJECT/MODIFY
+ one line why), boundary amendments, and respawn-with-answer summaries.
The judge's intent context becomes exactly four pointers: frozen gate file
+ spec + lane report + rulings file (empty/absent = no post-freeze
rulings). Judge blocks stop carrying ad hoc ruling prose. Builders may not
touch `*-rulings.md` (same class as gates). The issue thread remains the
human-readable mirror; git remains the judge-readable truth.

### D5. Codex-judge template + substitution table frozen in dispatch.md (fixes W5)
dispatch.md gains: (a) a fixed CODEX-backend judge block template (role
preamble: cold/read-only conduct, tree-audit warning, verdict format —
same fields as C5) parallel to the existing C5; (b) a short **Sanctioned
substitutions** table in "## Duration hints and liveness": Git Bash
Win32-err-5 → PowerShell same-pattern (recorded per gate);
uv AppData-cache denial → `UV_CACHE_DIR=.architect/tmp/uv-cache`
(recorded); gh absent in sandbox → MIRROR: ORCHESTRATOR. Every entry
already has a docs/solutions file; the table is the operational pointer so
no agent rediscovers them.

### D6. Monitor spawn semantics: background subagent, not teammate (fixes W6)
loop.md "## Monitor protocol" and the monitor def gain the lifecycle facts
this run established: the monitor MUST be spawned as a background subagent
whose COMPLETION re-invokes the orchestrator (that is the alert channel);
teammate-style spawns idle instead of exiting and need a formal
`shutdown_request` — permitted as the stand-down mechanism when a teammate
spawn is unavoidable, but not the default. Also record the observed
baseline: when all lanes complete normally, harness notifications cover
every event and the monitor's quiet exit is its only output — that is
success, not waste.

### D7. Issue-mirror reality documented (accepts W7)
dispatch.md "## Issue conventions" states plainly: on current backends
(codex: no network; Claude subagents: shell-strip watch item) builders
usually CANNOT post to issues; MIRROR: ORCHESTRATOR is the normal mode,
and the orchestrator mirrors at event boundaries it already occupies
(blocker, verdict, close). Direct builder posting remains permitted where
a backend supports it. No new tooling — simplicity ruling.

### D8. Keep-list (anti-regression)
R1–R8 are named invariants for this slice: no deliverable may weaken the
blocker-exit protocol, PHASE-0 duty, cold-judge diff-vs-intent, the
one-grill convention, interface handoff blocks, raw-evidence substitution
labeling, or INVALID-vs-FAIL verdict discipline. Tier default stays
same-family tier-down (R8's data point supports it; the open cheap-brawn
question keeps logging per-tier judge outcomes on future runs).

## Deliverables (vertical slices; tidy-first split applied)

1. `v51-grill` — dispatch.md grill template: add D3's three checks;
   structural only (template text), existing greps untouched.
2. `v51-dispatch-text` — dispatch.md: codex-judge template, sanctioned-
   substitutions table, issue-mirror reality note (D5, D7).
3. `v51-skill-preflight` — SKILL.md: backend canary step, factory-branch +
   freeze→push→dispatch ordering with worktree verification (D1, D2).
4. `v51-loop-monitor` — loop.md + architect-monitor def: spawn semantics
   and stand-down mechanics (D6).
5. `v51-rulings` — SKILL.md/loop.md/dispatch.md one-paragraph each +
   builder/judge defs: the rulings-file convention (D4). Touches multiple
   files other slices own → runs AFTER 1–4 (blocking edges), or is folded
   into a single serialized wave if the run is executed as one batch.
6. Docs debt: DESIGN.md §12 addendum (v5.1 evidence), README only if user-
   visible behavior changes (canary preflight message).

Size guard: combined skill text currently 632/800 non-blank; these edits
add an estimated 60–90 lines — budget each lane so the total stays ≤780.

## Testing seams

Gates are grep/validator-based as in the v5 run (the machinery now exists):
presence of the three new grill checks; presence of the codex-judge
template markers; substitution-table entries; monitor-lifecycle wording;
rulings-file convention named in all three files; validator green; size
guard. The real acceptance test is the NEXT factory run on a real project
(benchstack candidate): its epic must show canary evidence, zero stale-
snapshot blockers, and zero ad hoc ruling prose in judge blocks.

## Assumptions (human-vetoable)

- A1. The rulings file lives at `docs/lanes/<slug>-rulings.md` (not under
  docs/gates/) so the gates-tamper check stays byte-clean.
- A2. Monitor stays in the design despite zero detections this run — its
  value case is long test suites and silent hangs, which this run's small
  text lanes never exercised.
- A3. No new tooling/scripts for issue mirroring (D7 simplicity ruling).
- A4. The D12 upstream bug report (shell-strip, 5/5 reproduction, evidence
  in docs/solutions/) is worth filing but is OUT of this spec's scope.
- A5. gh 2.94 upgrade remains a standing precondition; the GraphQL
  fallback stays documented but is not built into skill text (one-time
  machine state, not a design).

## Out of scope

Upstream filings (D12, worktree stale snapshot); Agent Teams substrate
migration (revisit when stable + worktree-isolated); mirror tooling;
changes to the v5 stage structure itself (intake/gate/factory shape is
validated and frozen).
