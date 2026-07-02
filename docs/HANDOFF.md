# HANDOFF — architect-loop (the skill's own source repo)

> Repo memory for the Architect Loop. The builder (Codex) updates this after
> every run; the architect (Claude) writes rulings and verdicts here.
> Raw evidence only in builder sections — tables, numbers, commit SHAs, test
> output. No interpretation, no "promising". Every claim must be backed by a
> command result from the run that wrote it.
> Not in this file = didn't happen.

## TL;DR (keep current — next session must grok this in under a minute)

- Goal: implement the v3 plan (`docs/prd/v3-loop.md`) — stall prevention +
  loop driver/sentinel + brain/brawn config (Claude Code & Codex only).
- 2026-07-02 judgment session: **G1–G6 PASS** on `slice/v3-loop`; driver
  canaries **found 3 defects** (D1 suite-vs-WSL-bash, D2 wrong-CLI warning,
  D3 breaker false-trip — a healthy ps1 loop dies at iteration 5). G9/G10
  mechanics otherwise verified. **G7/G8/G11 DEFERRED** — running paid
  session canaries against a driver that must change would pay twice.
- Slice verdict: **CONTINUE.** Fix slice `v3-loop-fixes` spec'd, gates frozen
  at `docs/gates/v3-loop-fixes.md`, one codex lane dispatched.
- Next action: fresh /architect session judges `v3-loop-fixes` (FG1–FG4),
  integrates, then runs the parent G7–G11 canaries against the fixed driver;
  merge `slice/v3-loop` → main only after those PASS.

LOOP: WAIT 20 (v3-loop-fixes lane in flight; fresh session judges on return)

## Project goal

The v3 plan lands in this repo: Part A builder-stall prevention (as amended
by PRD §4.4 graduated timeouts), Part B outer loop driver + `LOOP:` sentinel
protocol, Part C brain/brawn model configuration. Done = all PRD §5 gates
(frozen at `docs/gates/v3-loop.md`) PASS and the work is merged to main.
Scope is final: Claude Code and Codex only (human decision 2026-07-02).

## Verification gate (exact commands)

```
uv run tests/validate_skills.py     # bare `python` is NOT on PATH here
bash -n bin/architect-loop.sh
powershell -NoProfile -Command "...Parser::ParseFile check — see gate G3"
powershell -NoProfile -ExecutionPolicy Bypass -File tests/driver-canary.ps1   # after v3-loop-fixes
```

## Frozen contracts

- `docs/gates/v3-loop.md` — gates + frozen interface contracts C1–C4.
- `docs/gates/v3-loop-fixes.md` — fix-slice gates FG1–FG4 + defect record.
- `docs/prd/v3-loop.md` — the plan (wins all conflicts);
  `docs/prd/v3-loop-stall-prevention.md` — Part A source, amended by §4.4.

## Gate verdicts — slice `v3-loop` (architect, 2026-07-02, this machine)

| Gate | Verdict | Decisive evidence |
|------|---------|-------------------|
| gates-integrity | PASS | `git diff 77f5037..HEAD -- docs/gates/` empty |
| G1 | PASS (defect D1 logged) | exit 0 from Git Bash (`OK — 2 skills validated`); exit 1 from PowerShell is D1 (WSL bash + backslash path), not a product failure — driver itself parses (G2) |
| G2 | PASS | `bash -n bin/architect-loop.sh` exit 0 |
| G3 | PASS | Parser::ParseFile command verbatim, exit 0 |
| G4 | PASS | test source covers (a)–(e): loop.md+fences, sentinel accept/reject incl. `LOOP: MAYBE`/bare WAIT/bare STOP/no-line, alias table 4 aliases + non-empty Flags, drivers exist, C2 config example |
| G5 | PASS | DESIGN.md: §7 loop-as-productized-extension w/ F1–F5; Model roles w/ F6–F11 (arXiv:2410.21819, goose#4036, aider, opusplan, z.ai); both failure rows; F4d + F8 corrections; standing evidence rule verbatim |
| G6 | PASS | SKILL.md +27/−16 = net +11 lines since freeze; desc ≤1024 in suite |
| G9 | PASS (driver level) | deleted line / `LOOP: MAYBE` / untouched handoff → correct STOPs |
| G10 | PARTIAL | §5.5 PASS (repo `codex/best` beat user config, audit line says so; user wins after repo removed); §5.6(a) PASS (defaults → `claude/sonnet:high`; unknown key warns); §5.6(b) FAIL = D2 (fallback right, warning names wrong CLI) |
| G7, G8, G11 | DEFERRED | blocked by D3: any driver change invalidates paid canaries; run against fixed driver |
| G12 | OPEN | fix-slice dispatch block declares per-command ceilings (evidence continues to accrue) |

**Slice call: CONTINUE** — foundation sound (bash driver fully clean, ps1
defects localized), three fixes + re-canary needed before main.

## Raw results (architect-run driver canaries, 2026-07-02, stub-brain harness)

Real `bin/architect-loop.ps1`, toy repo, stub `claude` on controlled PATH,
fake USERPROFILE. Parent env had `CLAUDECODE=1`, `CLAUDE_CODE_ENTRYPOINT=cli`;
stub echo showed both stripped and `ARCHITECT_LOOP=1` set. Alias resolution
observed: `claude/best`→`--model opus --effort xhigh --permission-mode dontAsk`;
WAIT flipped next iteration to `--model sonnet --effort high`.

```
delete-loop  → STOP: missing or unparseable LOOP sentinel
LOOP: MAYBE  → STOP: missing or unparseable LOOP sentinel
untouched    → STOP: docs/HANDOFF.md untouched after iteration
docs/STOP    → STOP: docs/STOP present: canary kill   (preflight, no brain spawn)
no-progress  → STOP: 3 consecutive no-progress iterations
event-growth → no-progress breaker did NOT trip (growing .architect/lane.jsonl)
HEALTHY 8-iter loop (all exits 0, sentinel changing) →
  STOP: 5 consecutive nonzero exits   ← D3 false trip; only 4 iterations logged
audit line:  exit=STUB-CLAUDE invoked args: ... 0   ← D3 corrupt exit field
degradation: WARNING: brawn CLI 'claude' not on PATH; falling back to
  claude/sonnet:high   ← D2: requested CLI was codex
config precedence audits: brawn=codex/best (repo wins) / brawn=claude/best
  (user, repo removed) / brawn=claude/sonnet:high (no config)
```

`claude --version` 2.1.198; `--effort`, `--permission-mode`, `-p`, `--model`
all real flags (D4: loop.md table omits `--effort`).
Merged v3-loop lanes: 01 a793eed, 02 0efd589 + follow-up, 03 b78f103.

## Current slice — `v3-loop-fixes`

- Spec + defect record: `docs/gates/v3-loop-fixes.md` (frozen before dispatch)
- One lane, main checkout, brawn `codex/best` (xhigh — PS pipeline-semantics
  subtlety is exactly what bit us; not tier-down material)
- MAY TOUCH: `bin/architect-loop.ps1`, `tests/validate_skills.py`,
  `tests/driver-canary.ps1` (new), `skills/architect/loop.md` (≤3 net lines),
  `docs/lanes/v3-loop-fixes-01.md`
- Report: `docs/lanes/v3-loop-fixes-01.md`

## Open disagreements (builder writes; architect rules)

| # | Builder's position | Spec's position | Evidence (real files) | Ruling |
|---|--------------------|-----------------|------------------------|--------|

## Decisions log (architect + human)

| Date | Decision | Why |
|------|----------|-----|
| 2026-07-02 | G7/G8/G11 deferred until D3 fixed; canaries run once, against the fixed driver | any driver change invalidates paid session canaries; don't pay twice |
| 2026-07-02 | Defects D1–D4 logged (see docs/gates/v3-loop-fixes.md); fix slice dispatched instead of architect hand-edit | hard rule 1: anything that must change goes in a slice spec |
| 2026-07-02 | Driver-mechanics gates (G9, G10 driver-level, breaker) measured via stub-brain harness; harness to be committed as tests/driver-canary.ps1 | deterministic, model-free measurement of pure driver logic; repeatable next session |
| 2026-07-02 | Scope: Claude Code + Codex only (human, final) | F13: only safe-builder CLIs |
| 2026-07-02 | Part A adopted AS AMENDED by PRD §4.4 (graduated timeouts) | blanket cap turns slow-healthy commands into false failures |
| 2026-07-01 | .gitignore: `/docs/` → `/docs/*` + exceptions; docs/STOP stays ignored | committed gates + lane reports required; kill file never committed |
| 2026-07-01 | One slice `v3-loop`, 3 disjoint lanes; interfaces frozen as C1–C4 | lanes build to spec, not to each other |
| 2026-07-01 | Both plan files committed to docs/prd/ verbatim | builders ground in-repo |
| 2026-07-01 | Lane 03 effort high (01/02 xhigh) | doc transcription tightly specified |
| 2026-07-01 | Environment canary satisfied: codex 0.139 on this machine | one-canary-per-environment rule |
| 2026-07-01 | Per-lane validate failures on other lanes' files expected; full pass is integration gate | tests span lanes |
| 2026-07-02 | C3 ambiguity ruling (MODIFY): backtick-tolerant alias test via lane-02 follow-up | spec-precision defect owned by architect |
| 2026-07-02 | Gate specs prescribe `UV_CACHE_DIR=.architect/tmp/uv-cache` for sandboxed `uv run` | AppData cache write-denial under workspace-write |
| 2026-07-02 | `bash -n` architect-run only on this machine — Git Bash dies under codex sandbox (Win32 error 5) | environment limitation |

## Next slice (builder may propose; architect decides)

After `v3-loop-fixes` integrates: fresh session runs parent G7–G11 canaries
(PRD §5.2–§5.8) against the fixed driver, then merge to main. Post-merge
follow-ups live in PRD §6 (gpt-5.6 alias recheck, billing-pause reversal,
GLM recipe canary). Watch item: `mapfile` in the sh driver needs bash ≥4
(macOS stock bash is 3.2) — no gate pins macOS; revisit only if a POSIX-Mac
environment enters scope.

## Session log

| Date | Role | Slice | Commits | Gates P/F | Notes |
|------|------|-------|---------|-----------|-------|
| 2026-07-01 | Architect (Claude Fable, Claude Code) | v3-loop | freeze + dispatch | — | Froze gates 77f5037; dispatched 3 lanes |
| 2026-07-01/02 | Builders (codex exec gpt-5.5) | v3-loop | a793eed / 0efd589+f/u / b78f103 | — | 3 lanes COMPLETE(_WITH_CONCERNS); PHASE 0 concerns environmental |
| 2026-07-02 | Architect (same session as dispatch) | v3-loop | merges on slice/v3-loop | smoke green | Post-flight ×4 clean; C3 ruling; judgment deferred per hard rule 4 |
| 2026-07-02 | Architect (Claude Fable, fresh session) | v3-loop → v3-loop-fixes | freeze docs/gates/v3-loop-fixes.md + dispatch | G1–G6 P, G9 P, G10 partial, G7/G8/G11 deferred | Found D1–D4 via stub-brain driver canaries; CONTINUE; brawn codex/gpt-5.5:xhigh, 1 lane |
