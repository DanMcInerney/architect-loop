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
docs/gates/v3-loop.md contracts C1–C4. Implement against those exactly.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in BOUNDARIES. You
are one of several parallel lane agents working in isolated worktrees; files
outside your lane belong to other agents — touching them fails your lane.
No placeholder implementations — search the codebase before implementing;
full implementations only. Verify your work by running the lane's gate
commands and record the verbatim output. Do NOT commit — the sandbox protects
.git by design; the architect commits and merges after verification. Do NOT
delete lock files or escalate privileges if a git command fails; record the
exact error and continue. When done, write your lane report to
docs/lanes/v3-loop-01.md with RAW results only — tables, numbers, command
output — no interpretation, no "promising". Every status claim must be backed
by a command result from this run. Keep the report compact. End it with
exactly one status line:
STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED (exact
blocker + what you tried). Verdicts belong to the architect and the human.
Persist until your lane is fully handled end-to-end.

SANDBOX EXECUTION POLICY — All temp, basetemp, and cache paths MUST be inside
the workspace (`.architect/tmp/<purpose>`); never the system temp, never
C:\tmp (verified hang source under this sandbox, 2026-07-01). Run test/gate
commands SEQUENTIALLY — never two invocations in flight at once. Declared
timeout ceilings: `uv run tests/validate_skills.py` 120s; git commands 120s;
anything undeclared 600s. On timeout: record it; retry once with a doubled
ceiling ONLY if output showed forward progress, else report it as a stall.
A filesystem/sandbox error on a path is environmental: record the exact
failure and route around it — never retry the same path.

=== OBJECTIVE (and why) ===
Implement the skill-text half of the v3 plan: PRD §4.1, §4.3, §4.4, §4.5
(docs/prd/v3-loop.md — read it in full first, plus
docs/prd/v3-loop-stall-prevention.md which §4.4 amends). This repo is the
source for the installed ~/.claude/skills/architect skill — these four files
ARE the product. Deliverables:

1. NEW `skills/architect/loop.md` (PRD §4.1): all Part B mechanics —
   sentinel protocol exactly per gate contract C1; the WAIT fast path
   (PRD 3B.2, including "WAIT sessions never judge"); driver usage + safety
   rails (3B.3 / contract C4); the harness invocation table (3B.4: claude
   `-p "/architect" --model <brain> --permission-mode dontAsk` + repo
   allowlist bootstrap in `.claude/settings.json`; codex
   `exec --sandbox danger-full-access` with the prompt inlining the skill
   text; env-strip rule; `--permissions bypass` caveats incl. bug #17544);
   chained-fallback commands verbatim with caveats (F3/F4: Start-Process /
   tmux new-session -d / setsid / claude --bg); one-time setup checklist
   (interactive --dangerously-skip-permissions acceptance); the codex-brain
   runs-unsandboxed caveat (PRD §6). Include ONE fenced config example that
   parses under contract C2 (lane 02's tests will parse loop.md for it).
   Mark PENDING-CANARY inline: claude --bg env-strip interaction;
   $skill-in-exec. Include the dated F4d billing-pause recheck note.
2. `skills/architect/SKILL.md` (PRD §4.3): ≤ ~20 net lines added (gate G6).
   Step 0: resolve brain/brawn per 3C.2; detect harness; the 3C.5
   warn/advise rule; if `ARCHITECT_LOOP=1`, check the WAIT fast path (point
   to loop.md). Step 4 Tool guidance: the stall-plan §3.3 spec-writing rule
   (name known-bad patterns as forbidden with evidence; exact command forms,
   not examples). Step 5: stall rule points at the loop WAIT cycle (loop
   mode) or the dispatch.md rescue ladder (manual). New final step: write
   the `LOOP:` sentinel (loop mode) or tell the human the exact next action.
   Hard rule 8: in loop mode, stop = `LOOP: STOP (reason)`, never a silent
   exit. Maintenance: append the standing rule "no feature ships without its
   evidence recorded in DESIGN.md" (DESIGN.md's mirror is lane 03's job).
3. `skills/architect/dispatch.md` (PRD §4.4). Part A (as amended): extend
   "Known sandbox hang sources" with out-of-workspace temp paths using the
   verified signature text (stall plan §3.1); add the SANDBOX EXECUTION
   POLICY paragraph to the builder-block template implementing the
   GRADUATED timeout policy (spec declares realistic ceilings for the
   repo's known-long commands; 600s only as the default for undeclared
   commands; timeout → record, one doubled-ceiling retry iff forward
   progress; never-retry-same-path stays scoped to sandbox/filesystem
   errors); codify the 3-rung rescue ladder + a rescue-block template with
   the verified mechanics (stall plan §3.5, incl. the flags-before-`resume`
   gotcha and system-wide child search by command signature); the §3.6
   timeout-cap investigation — verify against `codex --help` /
   `codex exec --help` output locally; if the config reference is
   unreachable offline, state the gap as a known owned risk, do not assert
   from memory. Part C: a "Builder backends" section (3C.6 contract; the
   verified codex template; the claude template verbatim from PRD 3C.6
   with its F12 rationale; these are the ONLY two backends — record the
   F13 exclusions as rationale); the `## Model alias table` exactly per
   gate contract C3 with rows per PRD 3C.3 (incl. both tier-down rows and
   the general tier-down rule + its cited economics); resolution order +
   degradation policy (3C.4); the audit-trail requirement (3C.7); recast
   the hardcoded `-m gpt-5.5` dispatch as the `codex/best` alias resolved
   from the table (still print explicit pinned flags in every command —
   the pin's SOURCE becomes the table). Keep the PRD §6 gpt-5.6 watch note
   on the codex rows.
4. `skills/architect/HANDOFF.template.md` (PRD §4.5): add the `LOOP:` line
   to the TL;DR (all three C1 forms + the fail-safe note) and Brain/Brawn
   columns to the Session log table.

=== OUTPUT FORMAT ===
docs/lanes/v3-loop-01.md: files changed w/ line deltas; verbatim
`uv run tests/validate_skills.py` output; SKILL.md net-line count evidence
(`git diff --stat`); the C1/C2/C3 conformance of your files shown by quoting
the relevant lines; PENDING-CANARY items listed; PHASE 0 disagreements +
resolutions; STATUS line.

=== TOOL GUIDANCE ===
- `uv run tests/validate_skills.py` (bare `python` is NOT on this machine's
  PATH; uv is). Expected in YOUR worktree: it may flag nothing new (the
  current tests don't know about loop.md) — record whatever it prints.
- `codex --version` / `codex exec --help` for the §3.6 flag verification.
- Read before writing: docs/prd/v3-loop.md (whole), docs/prd/
  v3-loop-stall-prevention.md, docs/gates/v3-loop.md, the four target files.

=== BOUNDARIES (may touch / must not touch / out of scope) ===
MAY TOUCH (only): skills/architect/SKILL.md, skills/architect/dispatch.md,
skills/architect/HANDOFF.template.md, skills/architect/loop.md (new),
docs/lanes/v3-loop-01.md (your report), .architect/tmp/** (scratch).
MUST NOT TOUCH: docs/gates/**, docs/prd/**, docs/HANDOFF.md, tests/**,
bin/**, install.sh, install.ps1, README.md, DESIGN.md, .gitignore,
skills/architect/research.md, skills/architect-research/**.
OUT OF SCOPE: driver implementation (lane 02), README/DESIGN content
(lane 03), any support for gemini/pi/opencode/agy, refactors beyond the task.

=== DISAGREEMENT RULINGS (from last session) ===
None — first slice in this repo. Raise PHASE 0 disagreements in your lane
report; the next architect session rules on them.

=== ACCEPTANCE GATES (frozen at docs/gates/v3-loop.md — read-only) ===
Read that file in full. Your lane is judged chiefly against G1 (integration),
G4's C1/C3 contract conformance of YOUR files, G5 (SKILL.md half of the
standing rule), G6 (SKILL.md thinness), and G12 (the template's graduated-
timeout text).
