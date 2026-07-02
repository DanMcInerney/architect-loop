# Gates — slice `v3-loop`

Frozen BEFORE dispatch. Read-only for everyone, builders included — any edit
to this file is an automatic slice FAIL regardless of results. PRD:
`docs/prd/v3-loop.md` (wins all conflicts) + `docs/prd/v3-loop-stall-prevention.md`
(Part A, as amended by PRD §4.4).

## Frozen cross-lane interface contracts

Lanes implement against THESE, never against another lane's files.

### C1 — Sentinel protocol

`docs/HANDOFF.md` carries exactly one line matching `^LOOP:`, written by the
architect session as its last act. The three legal forms:

```
LOOP: CONTINUE
LOOP: WAIT <minutes>            # optional trailing parenthesized note
LOOP: WAIT 20 (2 lanes in flight)
LOOP: STOP (<reason>)           # reason REQUIRED
```

Accept regex (POSIX ERE, whole line):
`^LOOP: (CONTINUE|WAIT [0-9]+( \(.+\))?|STOP \(.+\))$`

Fail-safe: no `LOOP:` line, an unparseable line, or a handoff file untouched
since the previous iteration ⇒ treated as STOP.

### C2 — Config file format

Flat `key = value` lines; `#` starts a comment; unknown keys warn, never fail.
Keys: `brain`, `brawn`. Values: `<cli>/<model-spec>[:<effort>]` with `<cli>`
∈ {claude, codex}. Resolution order (first hit wins, per role):
repo `.architect/config` → user `~/.architect/config` (`$HOME` /
`%USERPROFILE%`) → defaults (brain = the running session; brawn = tier-down
per the alias table).

### C3 — Alias table

`skills/architect/dispatch.md` hosts one markdown table under the exact
heading `## Model alias table`. Required rows (Alias column, exact strings):
`codex/best`, `claude/best`, `codex/tier-down`, `claude/tier-down`. Every
Flags cell non-empty. Row content per PRD §3C.3 (codex tier-down =
effort-down on gpt-5.5, claude tier-down = model-down at effort high).

### C4 — Driver CLI contract

`bin/architect-loop.sh` (bash) and `bin/architect-loop.ps1` (PowerShell 5.1+
compatible). Zero required flags. Optional flags exactly: `--max-iters N`
(default 50), `--max-hours H`, `--permissions <mode>`, `--brain <str>`,
`--brawn <str>`. Kill switch: `docs/STOP` (checked before every invocation).
Child sessions get `ARCHITECT_LOOP=1`. Logs:
`.architect/loop/<n>-<timestamp>.log` per iteration + one index line appended
to `.architect/loop/loop.log`. Circuit breaker: 3 consecutive no-progress
iterations OR 5 consecutive nonzero exits ⇒ STOP with diagnostics; progress =
HEAD moved OR sentinel line changed OR any `--json` lane event file under
`.architect/` grew. Missing `docs/HANDOFF.md` at preflight = warning, not a
block. Never uses `--max-turns`.

## Declared timeout ceilings (graduated policy, PRD §4.4)

| Command | Ceiling |
|---|---|
| `uv run tests/validate_skills.py` | 120s |
| `bash -n bin/architect-loop.sh` | 60s |
| PowerShell parser check (G3) | 120s |
| git commands | 120s |
| anything not declared above | 600s (default) |

On timeout: record it; one retry with a doubled ceiling ONLY if output showed
forward progress; else report as a stall. Never blind retry loops.

## Gates

Verdicts are architect-run in a later session. Per-lane, builders run what the
sandbox permits and record verbatim output; failures caused ONLY by another
lane's not-yet-merged files are expected in-lane and recorded as such.

**G1 — Validation suite.** `uv run tests/validate_skills.py` exits 0 on the
integration branch with all lanes merged. (Machine note: bare `python` is not
on PATH here; `uv run` is the canonical invocation. `uv python find` →
cpython-3.12.4. If `uv` misbehaves under the sandbox, record the exact
failure and skip — the architect runs this gate outside the sandbox.)

**G2 — Bash driver parses.** `bash -n bin/architect-loop.sh` exits 0.

**G3 — PowerShell driver parses.** Exit 0 from:
`powershell -NoProfile -Command "$t=$null;$e=$null;[void][System.Management.Automation.Language.Parser]::ParseFile('bin/architect-loop.ps1',[ref]$t,[ref]$e); if($e.Count){$e|ForEach-Object{Write-Output $_.Message}; exit 1}"`

**G4 — Tests cover the frozen contracts.** `tests/validate_skills.py` gains
checks that: (a) `skills/architect/loop.md` exists with balanced fences;
(b) the C1 sentinel regex accepts all three frozen forms and rejects
`LOOP: MAYBE`, `LOOP: WAIT` (no number), `LOOP: STOP` (no reason), and
input with no LOOP line; (c) dispatch.md's `## Model alias table` exists with
the four C3 aliases and non-empty Flags cells; (d) both drivers exist;
(e) a config example somewhere in the repo parses under C2. Verified by
reading the test source and by G1's run.

**G5 — Evidence lands in DESIGN.md.** DESIGN.md contains: rewritten §7
(loop mode as the productized extension) citing F1–F5; a new "Model roles"
section citing F6–F11 (incl. arXiv:2410.21819, goose#4036, aider issues,
opusplan, z.ai); "Stalled unattended runs" row updated + new "Runaway loop"
row in the failure-mode table; corrections for the Agent-SDK-credits pause
(F4d) and codex-only `.git` protection (F8); the standing rule "no feature
ships without its evidence recorded in DESIGN.md". Architect reads the file
against PRD §4.6.

**G6 — SKILL.md stays thin.** Net addition to `skills/architect/SKILL.md`
≤ ~20 lines; flattened frontmatter description ≤ 1024 chars (existing check).

**G7 (architect-run, post-integration, this machine) — Loop canary.**
PRD §5.2: driver launched detached from inside a Claude Code session survives
session end; iteration 1 is a fresh `claude -p` that loads /architect
(transcript shows grounding, not resumed context); env-strip prevents the
nested hang — 10 launches, 0 hangs.

**G8 (architect-run) — Three-iteration dry run.** PRD §5.3 verbatim,
including: WAIT session runs on the tier-down brain and never judges; three
distinct session IDs; `docs/STOP` mid-run kills the loop; a healthy in-flight
lane does NOT trip the breaker across 3 WAIT ticks.

**G9 (architect-run) — Sentinel fail-safe live.** PRD §5.4: delete the
`LOOP:` line → driver stops.

**G10 (architect-run) — Config resolution, defaults, degradation.**
PRD §5.5 + §5.6 (a)(b)(c) verbatim.

**G11 (architect-run) — Claude-as-brawn + allowlist bootstrap canaries.**
PRD §5.7 + §5.8 verbatim, including the DENIED `git commit` visible in
stream-json output.

**G12 — Part A carry-over.** PRD §5.9: dispatch blocks declare per-command
ceilings for known commands, 600s only for undeclared ones (this slice's own
blocks are the first evidence — see `docs/lanes/v3-loop-block-*.md`); worst-
case stall detection ≤ one WAIT interval.

**Pending-canary items (PRD §6) are verifications, not assumptions:**
`claude --bg` env-strip interaction, `$skill`-in-exec (prompt must inline the
skill text until verified), and the codex `--ask-for-approval` omission
(re-confirmed by this slice's own `codex exec` dispatches starting cleanly).
Lane deliverables mark these PENDING-CANARY where referenced; G7–G11 close
them.

Merge to main requires: G1–G6 PASS on the integration branch AND G7–G11 PASS
on this machine. G12 is confirmed against the next real dispatch after merge.
