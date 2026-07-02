# HANDOFF — architect-loop (the skill's own source repo)

> Repo memory for the Architect Loop. The builder (Codex) updates this after
> every run; the architect (Claude) writes rulings and verdicts here.
> Raw evidence only in builder sections — tables, numbers, commit SHAs, test
> output. No interpretation, no "promising". Every claim must be backed by a
> command result from the run that wrote it.
> Not in this file = didn't happen.

## TL;DR (keep current — next session must grok this in under a minute)

- Goal: implement the v3 plan (`docs/prd/v3-loop.md`). **DONE and merged to
  main** 2026-07-02: G1–G6 PASS (earlier sessions), EG1–EG4 PASS (D5 eol fix),
  and the paid live canaries **G7, G8, G9, G10, G11 all PASS** against the
  fixed driver (raw evidence below). G12 stays open by design — confirmed
  against the next real dispatch.
- Live canaries surfaced three NEW doc-level defects (**D6** missing
  `--verbose` in the claude-backend template, **D7** workspace-trust
  prerequisite undocumented, **D8** lane self-misidentification — no
  lane-identity/self-stream clause). Driver and tests are untouched by them.
- Fix slice `v3-loop-docs` (D6–D8, doc text only) spec'd this session; gates
  frozen at `docs/gates/v3-loop-docs.md`; lane 01 dispatched on
  `slice/v3-loop-docs` (brawn codex/tier-down).
- Next action: fresh /architect session judges HG1–HG5 per
  `docs/gates/v3-loop-docs.md` (report: `docs/lanes/v3-loop-docs-01.md`),
  then merges `slice/v3-loop-docs` → main on PASS. PRD §6 watch items
  (gpt-5.6 alias recheck, billing-pause reversal, GLM recipe) remain open.

LOOP: WAIT 20 (v3-loop-docs lane 01 in flight)

## Project goal

The v3 plan lands in this repo: Part A builder-stall prevention (as amended
by PRD §4.4), Part B outer loop driver + `LOOP:` sentinel protocol, Part C
brain/brawn model configuration. Scope final: Claude Code and Codex only
(human decision 2026-07-02). v3 core is merged to main; remaining work is
doc-defect cleanup (D6–D8) and PRD §6 follow-ups.

## Verification gate (exact commands)

```
uv run tests/validate_skills.py     # bare `python` is NOT on PATH here
bash -n bin/architect-loop.sh
powershell -NoProfile -Command "...Parser::ParseFile check — see gate G3 in docs/gates/v3-loop.md"
powershell -NoProfile -ExecutionPolicy Bypass -File tests/driver-canary.ps1
```

Gotcha: run the G3 parser one-liner via Git Bash so `$t`/`$e` pass literally.
PowerShell 5.1 `>`/`*>`/`Tee-Object` write UTF-16; read logs encoding-aware
(plain `grep` on them silently misses).

## Frozen contracts

- `docs/gates/v3-loop.md` — parent gates + interface contracts C1–C4.
- `docs/gates/v3-loop-fixes.md` — FG1–FG4 + defect record D1–D4.
- `docs/gates/v3-loop-eol.md` — EG1–EG4 + D5.
- `docs/gates/v3-loop-docs.md` — HG1–HG5 + D6–D8 (current slice).
- `docs/prd/v3-loop.md` — the plan (wins all conflicts);
  `docs/prd/v3-loop-stall-prevention.md` — Part A source, amended by §4.4.

## Closed slices (detail lives in the judgment commits)

| Slice | Verdict | Judgment commit |
|-------|---------|-----------------|
| `v3-loop` (3 lanes) | G1–G6 PASS, G9 PASS, G10 partial; D1–D4 found via stub-brain canaries | b1acc42 |
| `v3-loop-fixes` | FG2–FG4 PASS; FG1 FAIL → D5 | 1b8ada1 |
| `v3-loop-eol` | gates-integrity + EG1–EG4 all PASS | this commit |

## Gate verdicts — parent `v3-loop` G7–G12 (architect, 2026-07-02, fresh session, this machine)

| Gate | Verdict | Decisive evidence |
|------|---------|-------------------|
| G7 | PASS | driver launched via detached Start-Process survived launcher-shell exit across 2 full runs (PID persisted; spawned iterations after launcher gone); iteration-1 log shows fresh grounding ("Grounded: read HANDOFF, gates, lane block…", sentinel was the frozen seed); 10/10 env-stripped nested `claude -p` launches completed 6.5–8.8 s, 0 hangs |
| G8 | PASS | run-2 audit trail: iter1 `brain=claude/best` dispatch→WAIT; iters2–4 `brain=claude/sonnet:high` WAIT ticks over in-flight lane (jsonl byte-identical ticks 3–4, breaker did NOT trip); iter5 sonnet `LOOP: CONTINUE` with explicit no-judge; iter6 `brain=claude/best` judged TG1–TG3 PASS → `LOOP: STOP (goal met)`; 7 distinct session IDs in the run window; separate committed-playbook run: docs/STOP dropped mid-iter-1 → `STOP: docs/STOP present: mid-run kill canary`, exactly 1 audit line, no iter-2 spawn |
| G9 | PASS | fixed-driver canary FG2c/FG2d (missing sentinel / untouched handoff → STOP); live: refused-handoff session → `STOP: docs/HANDOFF.md untouched after iteration`; live sentinel STOP honored twice |
| G10 | PASS | §5.5 re-measured on fixed driver: audit `brawn=codex/best` (repo wins), `brawn=claude/best` (user wins after repo removed); §5.6(a) defaults `brawn=claude/sonnet:high` + live session routed high-stakes review cross-family to `codex review --base main` (gpt-5.5) when codex present; §5.6(b) FG2f warning names requested CLI; §5.6(c) codex absent → session degraded to fresh same-CLI review AND logged the same-family bias caveat verbatim; C2 unknown-key warns, run continues |
| G11 | PASS (D7 logged) | §5.7: real sonnet lane in worktree — report raw + one STATUS line; jsonl grew live (35→66 KB in 20 s); `permission_denials` in result event records `git commit --allow-empty -m "builder-canary"` DENIED; `git log` = freeze only; deny-layer isolated: `--disallowedTools "Bash(git commit *)"` denies even with settings-allow + trusted workspace. §5.8: allowlist bootstrapped + logged in toy Decisions; judgment sessions ran TG1–TG3 gate commands under it without aborting — but ONLY after workspace trust was set (D7) |
| G12 | OPEN (by design) | eol + docs slices' dispatch blocks declare per-command ceilings; gate file: confirmed against next real dispatch after merge |

**Slice call: CONTINUE (v3 core MERGED TO MAIN).** Every mechanism the PRD
gates name was observed working on live sessions; the failures the canaries
did produce were all in doc text (D6–D8), and both loop fail-safes fired
correctly under real ambiguity (dead lane → tier-down session root-caused and
STOPped; suspicious uncommitted handoff rewrite → session flagged possible
instruction injection, refused, driver caught it as untouched-handoff).

## Raw results (architect-run live canaries, 2026-07-02, toy repos under `.architect/tmp/loop-canary/`)

```
run 2 loop.log (verbatim, paths trimmed):
  iteration=1 brain=claude/best        exit=0 sentinel="LOOP: WAIT 1 (lane 01 in flight)"
  iteration=2 brain=claude/sonnet:high exit=0 sentinel="LOOP: WAIT 1 (tick 2: jsonl at 1178772 bytes)"
  iteration=3 brain=claude/sonnet:high exit=0 sentinel="LOOP: WAIT 1 (tick 3: jsonl at 1254490 bytes)"
  iteration=4 brain=claude/sonnet:high exit=0 sentinel="LOOP: WAIT 1 (tick 4: jsonl at 1254490 bytes)"
  iteration=5 brain=claude/sonnet:high exit=0 sentinel="LOOP: CONTINUE"
  iteration=6 brain=claude/best        exit=0 sentinel="LOOP: STOP (goal met)"
stop-canary run: iteration=1 brain=claude/tier-down … sentinel="LOOP: WAIT 1 (stop-canary tick)"
  then: STOP: docs/STOP present: mid-run kill canary   (no iteration 2 spawned)
launches: 10/10 exit-complete 6.5–8.8s output "OK", hangs=0 (haiku, driver env-strip)
toy lane TG3 evidence: lane-01.jsonl permission_denials → git commit … DENIED
run 1 (archived .architect/tmp/loop-canary/run1-*): lane read its OWN stream-json file
  + iter-1's WAIT sentinel, inferred a duplicate worker, stopped with 0 artifacts (D8);
  iter-2 sonnet root-caused it, ran TG1–TG3 itself (all FAIL), wrote
  "LOOP: STOP (TG1/TG2/TG3 FAIL: builder never executed OBJECTIVE…)" — fail-safe correct
claude 2.1.198: --print --output-format stream-json REQUIRES --verbose (D6)
untrusted workspace: "Ignoring 10 permissions.allow entries … has not been trusted" (D7)
```

## Open disagreements (builder writes; architect rules)

| # | Builder's position | Spec's position | Evidence (real files) | Ruling |
|---|--------------------|-----------------|------------------------|--------|

## Decisions log (architect + human)

| Date | Decision | Why |
|------|----------|-----|
| 2026-07-02 | G7–G11 measured on live paid sessions this session; toy-repo evidence archived under `.architect/tmp/loop-canary/` (git-ignored, local) | handoff records the evidence; toys are throwaway |
| 2026-07-02 | Workspace trust for headless loop brains set via `projects[<path>].hasTrustDialogAccepted` in `~/.claude.json` (toy repos only; entries removed after) | claude -p ignores repo allowlist in untrusted workspaces (D7); the error message itself names this workaround |
| 2026-07-02 | D6–D8 fixed via builder slice `v3-loop-docs`, not architect hand-edit | hard rule 1 |
| 2026-07-02 | v3 core merged to main after G7–G11 PASS; doc defects don't block (no frozen gate covers template prose) | gate file's merge rule satisfied verbatim |
| 2026-07-02 | Scope: Claude Code + Codex only (human, final) | F13: only safe-builder CLIs |
| 2026-07-02 | Part A adopted AS AMENDED by PRD §4.4 (graduated timeouts) | blanket cap turns slow-healthy commands into false failures |
| 2026-07-01 | .gitignore: `/docs/*` + exceptions; docs/STOP stays ignored | committed gates + lane reports required; kill file never committed |
| 2026-07-02 | Gate specs prescribe `UV_CACHE_DIR=.architect/tmp/uv-cache` for sandboxed `uv run` | AppData cache write-denial under workspace-write |
| 2026-07-02 | `bash -n` architect-run only on this machine — Git Bash dies under codex sandbox (Win32 error 5) | environment limitation |
| 2026-07-02 | `v3-loop-docs` brawn = codex/tier-down (gpt-5.5 high) | routine, tightly specified doc edits |

## Next slice (builder may propose; architect decides)

After `v3-loop-docs` merges: PRD §6 watch items (gpt-5.6 alias recheck,
billing-pause reversal note, GLM recipe canary), and the standing `mapfile`
bash≥4 watch (no macOS gate). G12 confirms against the first real dispatch
after this one.

## Session log

| Date | Role | Slice | Commits | Gates P/F | Notes |
|------|------|-------|---------|-----------|-------|
| 2026-07-01/02 | Architect + builders | v3-loop / v3-loop-fixes / v3-loop-eol | freezes 77f5037, b1acc42, 1b8ada1; judgments b1acc42, 1b8ada1, this commit | G1–G6 P; FG2–4 P, FG1 F→D5; EG1–4 P | detail in judgment commits |
| 2026-07-02 | Architect (Claude Fable, fresh session) | v3-loop-eol judgment + G7–G11 live canaries | this commit + merge to main + v3-loop-docs freeze | EG1–4 P; G7–G11 P | 10/10 no-hang launches; 6-iter live loop arc; docs/STOP mid-run kill; cross-family + same-family review canaries; found D6–D8; dispatched v3-loop-docs lane 01 (codex/tier-down) |
