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
docs/lanes/v3-loop-02.md with RAW results only — tables, numbers, command
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
timeout ceilings: `uv run tests/validate_skills.py` 120s;
`bash -n bin/architect-loop.sh` 60s; the PowerShell parser check (gate G3)
120s; git commands 120s; anything undeclared 600s. On timeout: record it;
retry once with a doubled ceiling ONLY if output showed forward progress,
else report it as a stall. A filesystem/sandbox error on a path is
environmental: record the exact failure and route around it — never retry
the same path.

=== OBJECTIVE (and why) ===
Implement the executable half of the v3 plan: PRD §4.2 reference loop
drivers, installer updates, and the §4.7 test additions
(docs/prd/v3-loop.md — read it in full first; §3B is the loop contract).
The driver is what turns "open a new tab and run /architect" into an actual
loop; the tests are what keep the frozen contracts from rotting.

1. NEW `bin/architect-loop.sh` (bash) + `bin/architect-loop.ps1`
   (Windows PowerShell 5.1-compatible: no `&&`/`||` pipeline chains, no
   ternary; ~80 lines each is the target, correctness beats hitting the
   number). Both implement gate contract C4 exactly and PRD §4.2's loop
   shape:
   - Preflight: resolved brain CLI on PATH; `docs/STOP` absent (present →
     exit with its contents); missing `docs/HANDOFF.md` is a WARNING, not a
     block (first iteration bootstraps it; the C1 fail-safe still stops the
     loop if that session writes no sentinel).
   - Resolve brain/brawn per contract C2 (repo `.architect/config` → user
     `~/.architect/config` → defaults). `--brain`/`--brawn` flags override
     the chain. The brain string's CLI part selects the harness — no
     separate harness flag.
   - Invoke one-shot per iteration (PRD 3B.4): claude →
     `claude -p "/architect" --model <model> --permission-mode dontAsk`,
     env-stripping `CLAUDECODE` and `CLAUDE_CODE_ENTRYPOINT` when set
     (issue #26190; `env -u` on POSIX, `Remove-Item env:` in PS);
     `--permissions bypass` → use `--dangerously-skip-permissions` INSTEAD
     OF `--permission-mode` (never combined — bug #17544). codex →
     `codex exec -C <repo> --sandbox danger-full-access - < <promptfile>`
     where the prompt file inlines the architect skill text (resolve from
     `<repo>/skills/architect/SKILL.md` if present, else
     `~/.claude/skills/architect/SKILL.md`; mark PENDING-CANARY in a
     comment — `$skill` invocation in exec is unverified). Child env gets
     `ARCHITECT_LOOP=1`. NEVER pass `--max-turns`.
   - Log stdout+stderr to `.architect/loop/<n>-<timestamp>.log`; append one
     index line to `.architect/loop/loop.log`.
   - Parse the `LOOP:` sentinel from `docs/HANDOFF.md` per contract C1;
     missing/unparseable/file-untouched → STOP (fail-safe).
   - WAIT n → sleep n minutes, then relaunch automatically on the
     tier-down brain (no flag): claude fable/opus → sonnet, sonnet → haiku;
     codex → same model, `model_reasoning_effort="high"`. WAIT iterations
     count toward --max-iters.
   - Circuit breaker per C4 (3 no-progress OR 5 consecutive nonzero exits;
     progress = HEAD moved OR sentinel line changed OR any `--json` event
     file under `.architect/` grew). STOP prints the reason + last log tail.
   - Optional flags exactly: `--max-iters N` (default 50), `--max-hours H`,
     `--permissions <mode>`, `--brain <str>`, `--brawn <str>`.
2. `install.sh` / `install.ps1`: also install the drivers — copy
   `bin/architect-loop.sh` to `$HOME/.local/bin/architect-loop` (chmod +x)
   and `bin/architect-loop.ps1` to `%USERPROFILE%\.local\bin\` on Windows;
   print the destination and warn if it is not on PATH. Keep the existing
   skill-copy behavior untouched. If you have file-based reasons for a
   different destination, raise it in PHASE 0.
3. `tests/validate_skills.py` (§4.7 + gate G4; stays stdlib-only):
   (a) `skills/architect/loop.md` exists + balanced fences — add `loop.md`
   to REQUIRED_SIBLINGS["architect"]; (b) sentinel regex round-trip: embed
   the C1 regex; assert it accepts the three frozen forms and rejects
   `LOOP: MAYBE`, `LOOP: WAIT` (no number), `LOOP: STOP` (no reason), and
   no-LOOP-line input; (c) dispatch.md contains `## Model alias table` with
   the four C3 aliases (`codex/best`, `claude/best`, `codex/tier-down`,
   `claude/tier-down`) and non-empty Flags cells; (d) both drivers exist;
   run `bash -n` on the .sh IF bash is on PATH (else print a skip note) and
   the G3 Parser check on the .ps1 IF powershell/pwsh is on PATH (else skip
   note); (e) the first fenced block in `skills/architect/loop.md`
   containing a line starting `brain =` or `brawn =` parses under contract
   C2 (every non-comment, non-blank line matches `key = value` with known
   keys and `<cli>/<model-spec>[:<effort>]`, cli in {claude, codex}).

=== OUTPUT FORMAT ===
docs/lanes/v3-loop-02.md: files changed w/ line counts; verbatim output of
`bash -n bin/architect-loop.sh`, the G3 PowerShell parser command, and
`uv run tests/validate_skills.py` (in YOUR worktree the new checks
referencing lane 01's files — loop.md, alias table — WILL fail: expected,
record verbatim and label them cross-lane); a table mapping each C4 contract
item → the implementing line numbers in each driver; PHASE 0 disagreements;
STATUS line.

=== TOOL GUIDANCE ===
- `uv run tests/validate_skills.py` (bare `python` is NOT on PATH here; uv
  is; `uv python find` → cpython 3.12.4).
- G3 parser command verbatim from docs/gates/v3-loop.md.
- Verify live before coding around them: `claude --help` and
  `codex exec --help` flag spellings if the CLIs are runnable in your
  sandbox; if not runnable, note NOT VERIFIED per flag in the report rather
  than assuming.
- Windows PowerShell 5.1 is the compatibility floor for the .ps1.

=== BOUNDARIES (may touch / must not touch / out of scope) ===
MAY TOUCH (only): bin/architect-loop.sh (new), bin/architect-loop.ps1 (new),
install.sh, install.ps1, tests/validate_skills.py,
docs/lanes/v3-loop-02.md (your report), .architect/tmp/** (scratch).
MUST NOT TOUCH: skills/**, docs/gates/**, docs/prd/**, docs/HANDOFF.md,
README.md, DESIGN.md, .gitignore.
OUT OF SCOPE: loop.md content (lane 01), README/DESIGN docs (lane 03),
support for any CLI other than claude and codex, daemonization/service
wrappers, refactors beyond the task.

=== DISAGREEMENT RULINGS (from last session) ===
None — first slice in this repo. Raise PHASE 0 disagreements in your lane
report; the next architect session rules on them.

=== ACCEPTANCE GATES (frozen at docs/gates/v3-loop.md — read-only) ===
Read that file in full. Your lane is judged chiefly against G2, G3, G4 (all
sub-items), the C2/C4 contract conformance of the drivers, and G1 on the
integration branch. G7–G11 are architect-run canaries of YOUR drivers on
this machine — build for them (they are PRD §5.2–5.8 verbatim).
