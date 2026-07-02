Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them. NOTE: the PRD (docs/prd/v3-loop.md) is adversarially
reviewed and evidence-closed — disagreements must cite real files in this
repo; do not re-litigate the researched decisions (model defaults, the
Claude Code + Codex scope cut, the outer-driver loop architecture) without
new file-based evidence.

PHASE 1 — Freeze shared contracts (schemas/interfaces) in docs/ first. After
freeze they are read-only for everyone including you. The files under
docs/gates/ are read-only at all times — editing them fails the slice
regardless of results. For this slice the shared contracts are ALREADY frozen:
docs/gates/v3-loop.md contracts C1–C4. Describe them exactly as frozen.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in BOUNDARIES. You
are one of several parallel lane agents working in isolated worktrees; files
outside your lane belong to other agents — touching them fails your lane.
No placeholder implementations — search the codebase before implementing;
full implementations only. Verify your work by running the lane's gate
commands and record the verbatim output. Do NOT commit — the sandbox protects
.git by design; the architect commits and merges after verification. Do NOT
delete lock files or escalate privileges if a git command fails; record the
exact error and continue. When done, write your lane report to
docs/lanes/v3-loop-03.md with RAW results only — tables, numbers, command
output — no interpretation, no "promising". Every status claim must be backed
by a command result from this run. Keep the report compact. End it with
exactly one status line:
STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED (exact
blocker + what you tried). Verdicts belong to the architect and the human.
Persist until your lane is fully handled end-to-end.

SANDBOX EXECUTION POLICY — All temp, basetemp, and cache paths MUST be inside
the workspace (`.architect/tmp/<purpose>`); never the system temp, never
C:\tmp (verified hang source under this sandbox, 2026-07-01). Run test/gate
commands SEQUENTIALLY. Declared timeout ceilings:
`uv run tests/validate_skills.py` 120s; git commands 120s; anything
undeclared 600s. On timeout: record it; retry once with a doubled ceiling
ONLY if output showed forward progress, else report it as a stall. A
filesystem/sandbox error on a path is environmental: record the exact
failure and route around it — never retry the same path.

=== OBJECTIVE (and why) ===
Land the evidence half of the v3 plan: PRD §4.6 (DESIGN.md) and §4.7's
README sections (docs/prd/v3-loop.md — read it in full first, especially
§1's F1–F13 findings, which you will cite). The project's standing rule —
this slice makes it official — is that no feature ships without its
evidence recorded in DESIGN.md; this lane writes that evidence for Parts
A/B/C. Sources and findings come from the PRD; do NOT invent citations —
every URL you cite must appear in the PRD or the stall-prevention file.

1. `DESIGN.md` (PRD §4.6):
   - Rewrite §7 "What this deliberately is not": human-between-blocks stays
     the default; loop mode is the productized extension the old §7 already
     anticipated; state the autonomy trade explicitly (loop mode removes
     the human from between blocks; arbitration defaults to the architect
     unless marked human-only; `LOOP: STOP` is the guard — PRD §6 last
     bullet). Cite F1–F5's sources.
   - NEW "Model roles" section: brain/brawn configurability; inherit-brain
     + tier-down-brawn defaults (opusplan precedent + human decision
     2026-07-02, with the quota-concentration tradeoff stated); cross-family
     diversity spent at the review gate, not the build default (F10,
     arXiv:2410.21819); degradation policy and the single alias table as
     the owned rot point. Cite F6–F11 (incl. goose#4036, the aider issues,
     opusplan docs, z.ai docs).
   - Failure-mode table (§6): update "Stalled unattended runs" row to the
     driver WAIT cycle + Part A's root-cause chain (cite the stall plan's
     verified mechanics); ADD a "Runaway loop" row (fail-safe sentinel,
     iteration caps, circuit breaker, docs/STOP kill file).
   - Corrections: §7's stale claim that `claude -p` "draws on separate
     Agent SDK credits from June 15, 2026" → the billing split is PAUSED,
     `claude -p` currently draws normal subscription quota, with a dated
     recheck note (F4d); wherever DESIGN.md asserts sandbox `.git`
     protection, note it is verified for Codex workspace-write ONLY (F8) —
     the claude builder backend uses permission-deny rules + a post-flight
     check instead (F12).
   - Append the standing rule, stated as policy: "No feature ships without
     its evidence recorded in DESIGN.md — a PR adding behavior without a
     DESIGN.md entry is incomplete by definition." (SKILL.md's mirror of
     this rule is lane 01's job — do not touch SKILL.md.)
2. `README.md` (PRD §4.7):
   - NEW "Run it as a loop" section: quick start (bare `architect-loop` in
     a repo), what an iteration does, every stop mechanism (`docs/STOP`,
     `LOOP: STOP`, circuit breaker, `--max-iters` default 50,
     `--max-hours`), the quota-burn note (WAIT fast path runs on the
     tier-down brain automatically; N iterations × grounding cost).
   - NEW "Choosing your models" section: zero-config defaults table for the
     two harnesses (brain = the session you launched; brawn = same family
     one step down: Claude Code → claude/sonnet, Codex → gpt-5.5 at high);
     the two-key config file (`.architect/config` repo /
     `~/.architect/config` user, first hit wins) with a one-line override
     example `brawn = codex/best`; the cross-family review-gate default;
     the GLM-in-Claude-Code recipe marked UNVERIFIED + gray-zone
     (Anthropic-unblessed, z.ai-supported).
   - Update the "What's in the box" table: add rows for
     `skills/architect/loop.md` and `bin/architect-loop.sh` / `.ps1`.
   - Keep the existing tone (plain, evidence-pointing, no hype). Links to
     `skills/architect/loop.md` and `bin/architect-loop.sh` are CORRECT to
     add even though those files are other lanes' deliverables and do not
     exist in YOUR worktree.

=== OUTPUT FORMAT ===
docs/lanes/v3-loop-03.md: files changed w/ line deltas; verbatim
`uv run tests/validate_skills.py` output (the link checks for
loop.md/bin/architect-loop.sh WILL fail in your worktree — expected,
label them cross-lane); a checklist mapping each PRD §4.6/§4.7 bullet to
the section/heading that implements it; the list of citations used, each
traced to its PRD finding (F-number); PHASE 0 disagreements; STATUS line.

=== TOOL GUIDANCE ===
- `uv run tests/validate_skills.py` (bare `python` is NOT on PATH; uv is).
- Read before writing: docs/prd/v3-loop.md (whole file),
  docs/prd/v3-loop-stall-prevention.md, docs/gates/v3-loop.md, DESIGN.md,
  README.md.
- No network needed and none assumed: cite URLs exactly as they appear in
  the PRD.

=== BOUNDARIES (may touch / must not touch / out of scope) ===
MAY TOUCH (only): DESIGN.md, README.md, docs/lanes/v3-loop-03.md (your
report), .architect/tmp/** (scratch).
MUST NOT TOUCH: skills/**, bin/**, tests/**, install.sh, install.ps1,
docs/gates/**, docs/prd/**, docs/HANDOFF.md, .gitignore, LICENSE, assets/**.
OUT OF SCOPE: skill-text changes (lane 01), drivers/tests (lane 02),
restructuring DESIGN.md beyond the named sections, new diagrams, changing
the Origin/License/FAQ sections except where §4.7 requires.

=== DISAGREEMENT RULINGS (from last session) ===
None — first slice in this repo. Raise PHASE 0 disagreements in your lane
report; the next architect session rules on them.

=== ACCEPTANCE GATES (frozen at docs/gates/v3-loop.md — read-only) ===
Read that file in full. Your lane is judged chiefly against G5 (architect
reads DESIGN.md against PRD §4.6) and G1 on the integration branch
(README/DESIGN fences + links).
