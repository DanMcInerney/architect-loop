# HANDOFF — architect-loop (the skill's own source repo)

> Repo memory for the Architect Loop. The builder (Codex) updates this after
> every run; the architect (Claude) writes rulings and verdicts here.
> Raw evidence only in builder sections — tables, numbers, commit SHAs, test
> output. No interpretation, no "promising". Every claim must be backed by a
> command result from the run that wrote it.
> Not in this file = didn't happen.

## TL;DR (keep current — next session must grok this in under a minute)

- Goal: implement the v3 plan (`docs/prd/v3-loop.md`). **DONE and merged to
  main** 2026-07-02: G1–G6 PASS, EG1–EG4 PASS (D5 eol fix), paid live canaries
  **G7–G11 all PASS**, and the doc-defect cleanup slice **`v3-loop-docs`
  (D6–D8) judged HG1–HG5 all PASS and merged to main** 2026-07-02. G12 stays
  open by design — confirmed against the next real dispatch.
- The three doc defects are closed: **D6** `--verbose` now in the claude
  backend template (`dispatch.md:58`); **D7** workspace-trust step + both
  remedies in `loop.md`'s checklist; **D8** lane-identity/self-stream rule +
  PS 5.1 UTF-16 note in `dispatch.md`, evidence row in `DESIGN.md`. Driver and
  tests untouched (HG5b/HG5e diffs empty).
- **v4 REFACTOR UNDERWAY** (human-approved via grilled PRD, 2026-07-02):
  the loop moves in-session — orchestrator brain + cold-context builder and
  judge subagents, no external drivers, works in Claude Code & Codex, CLI &
  desktop apps. PRD: `docs/prd/v4-orchestrator-loop.md` (§6 rulings binding);
  ADR 0001; glossary: `CONTEXT.md`. PR #8 (all of v3) merged to origin/main
  first per ruling 6 (merge commit fe5462f).
- Current slice `v4-core` (1 of 3): **JUDGED 2026-07-02: gates-integrity +
  VG1–VG7 + VG9 all PASS; VG8 (HUMAN desktop canary) = FAIL → NO MERGE.**
  Slice call: CONTINUE via a fix slice; slice/v4-core stays unmerged until
  VG8 passes on re-run.
- **VG8 FAIL root cause (D9):** the desktop harness denies Bash to BOTH
  architect subagents at runtime ("No such tool available: Bash. Bash exists
  but is not enabled in this context") even though both defs list Bash —
  builder couldn't self-verify, judge returned INVALID (correctly). Same defs
  get full Bash (pattern-denies enforced per-command) from the CLI on this
  machine same day. **D10:** the desktop Agent harness auto-creates its own
  worktree (`.claude/worktrees/agent-<id>`) and ignores an orchestrator
  pre-made lane worktree; dispatch.md's Claude-backend worktree mechanics
  assume otherwise. Evidence: `.architect/tmp/v4-canary/VG8-FINDING.md` +
  toy2 under `.claude/worktrees/goofy-kalam-d02c1f/` (freeze effc321, lane
  15433ed, gates diff clean, bye.py byte-exact).
- VG7 bonus evidence: the cold judge correctly FAILed its first invocation
  (lane branch had gate-passing but UNCOMMITTED files) — fail-safe works.
  Lesson: orchestrator commits the lane BEFORE dispatching the judge.
- Next action: root-cause D9 (research in flight: is it cowork-mode, a
  fail-closed pattern-disallowedTools on desktop, or a desktop subagent
  limitation?), spec fix slice `v4-desktop`, re-run VG8. Then v4-codex,
  v4-cleanup per PRD §4. v3 watch items (gpt-5.6 alias, GLM recipe,
  mapfile/macOS) carry over unchanged.

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
- `docs/gates/v3-loop-docs.md` — HG1–HG5 + D6–D8 (closed).
- `docs/gates/v4-core.md` — VG1–VG9 + contracts C2'/C5/C6 (CURRENT slice).
- `docs/prd/v4-orchestrator-loop.md` — the v4 plan (wins all conflicts;
  §6 grill rulings binding); ADR 0001; `CONTEXT.md` glossary.
- v3 history: `docs/prd/v3-loop.md` + `docs/prd/v3-loop-stall-prevention.md`.

## Closed slices (detail lives in the judgment commits)

| Slice | Verdict | Judgment commit |
|-------|---------|-----------------|
| `v3-loop` (3 lanes) | G1–G6 PASS, G9 PASS, G10 partial; D1–D4 found via stub-brain canaries | b1acc42 |
| `v3-loop-fixes` | FG2–FG4 PASS; FG1 FAIL → D5 | 1b8ada1 |
| `v3-loop-eol` | gates-integrity + EG1–EG4 all PASS | 9872d5b |
| `v3-loop-docs` | HG1–HG5 all PASS (D6–D8 doc fixes); merged to main | this commit |

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

## Gate verdicts — `v4-core` (architect, 2026-07-02, fresh session, this machine)

Judged on `slice/v4-core` @ e53adbc; freeze 0f6442d; builder lane commit beb4d83.

| Gate | Verdict | Decisive evidence |
|------|---------|-------------------|
| gates-integrity | PASS | `git diff 0f6442d..HEAD -- docs/gates/` empty |
| VG1 | PASS | validator exit 0 from Git Bash AND PowerShell, both run this session ("OK - 2 skills validated, v4 contracts clean") |
| VG2 | PASS | SKILL.md read vs PRD §3.1: orchestrator never builds/judges (hard rules 1,4); judge cold at brain tier (rule 4); builders cold + worktree + never commit (rules 7, §3, §7); description length enforced by validator (VG1 green) |
| VG3 | PASS | both agent defs meet C6 verbatim (builder disallowedTools has `Bash(git commit *)`+`Bash(git push *)`, isolation worktree; judge tools Read/Glob/Grep/Bash only, no Edit/Write, model inherit); validate_skills.py gains check_agent_definitions/check_judge_template/check_config_example/check_retired_loop_terms — test source read this session |
| VG4 | PASS | C5 template verbatim in dispatch.md between markers with gate path/freeze SHA/branch/verdict-format; "must not add slice-specific prose" present and machine-checked |
| VG5 | PASS | `grep -ri sentinel skills/` and `grep -rn "^LOOP:" skills/` both empty (architect-run, Git Bash) |
| VG6 | PASS | HANDOFF.template.md has judgment ledger, slice counter, heartbeat cadence, reconcile-on-ground checklist, escalation digest; no sentinel |
| VG7 | PASS | live in-session canary, toy `.architect/tmp/v4-canary/toy` (freeze 000c043): cold architect-builder subagent built lane in toy worktree, nothing committed by builder (git log = freeze only; only declared files in status); cold architect-judge #1 FAILed uncommitted branch (correct); orchestrator committed 76b6358; cold judge #2 PASS on TG1–TG3 + integrity + intent; merge e711423, TG1 smoke on master exit 0, worktree removed. Zero new windows / driver processes / headless `claude -p` |
| VG8 | **FAIL** (human-run 2026-07-02, desktop app) | Measured as specified: human drove `/architect` toy slice `bye` on desktop. Orchestrator stages all worked (freeze effc321 → cold builder → post-flight → lane commit 15433ed → cold judge with C5 template). BOTH subagents denied Bash at runtime ("Bash exists but is not enabled in this context"); judge returned INVALID — cold-judge-runs-gates invariant unmet on desktop (defect D9). Harness also auto-worktrees and ignores pre-made lane worktrees (D10). Merge gate held closed; artifact itself byte-correct (orchestrator observation, not a verdict). Evidence: `.architect/tmp/v4-canary/VG8-FINDING.md` |
| VG9 | PASS | builder commit beb4d83 = exactly the 8 declared files; out-of-scope diff (`bin/ DESIGN.md README.md docs/gates/ docs/prd/ docs/adr/ CONTEXT.md`) empty; only other change is orchestrator's own handoff consolidation e53adbc (procedure-mandated) |

**Slice call: CONTINUE via fix slice — NO MERGE on VG8 FAIL.** Every
architect-runnable gate passed on first measurement; VG7's judge #1 FAIL was
an orchestrator sequencing error the judge correctly caught. VG8 failed for a
specific, fixable cause (D9: desktop denies Bash to subagents; D10:
auto-worktree supersedes pre-made lane worktrees) — the skill text and role
separation held everywhere, including on desktop, so KILL is not warranted.
slice/v4-core stays unmerged; fix slice `v4-desktop` addresses D9/D10 and
VG8 re-runs (human) before any merge to main.

## Open disagreements (builder writes; architect rules)

| # | Builder's position | Spec's position | Evidence (real files) | Ruling |
|---|--------------------|-----------------|------------------------|--------|

## Decisions log (architect + human)

| Date | Decision | Why |
|------|----------|-----|
| 2026-07-02 | v4 direction approved by human through a 6-question grill; rulings recorded in PRD §6 (judge=brain tier no new key; delete all v3 loop machinery; unattended=pointer-only; dispatch rules optional; VG8 desktop canary HUMAN-RUN merge gate; PR #8 merged first) | grilled plan > open-ended plan; rulings are binding |
| 2026-07-02 | ADR 0001 records why the externally-verified v3 driver is deleted hours after shipping | hard-to-reverse + surprising + real trade-off |
| 2026-07-02 | `v4-core` brawn = codex/best (gpt-5.5 xhigh), 1 lane, main checkout on slice/v4-core | large interlocking skill-text rewrite; not routine, no disjoint split |
| 2026-07-02 | v4-core does NOT delete bin/** or driver tests; deletion is v4-cleanup's job | suite must stay green at every merge; rewrite and delete are separable risks |
| 2026-07-02 | `v3-loop-docs` judged HG1–HG5 all PASS by fresh architect session → merged to main (no-ff); doc defects D6–D8 closed | gates run and read verbatim this session; diff matches spec intent; doc-only, no code/gate surface |
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
| 2026-07-02 | Allowlist bootstrapped at `.claude/settings.json` permissions.allow (Read/Edit/Write/Glob/Grep, `Bash(uv run:*)`, `bash -n`, powershell, grep, git status/diff/log/show/ls-files/add/commit/merge/checkout/branch) for driver-run loop brains; file left untracked — committing it is a call for a future slice. Workspace trust verified true. | loop.md one-time setup checklist + D7; first driver run on this repo is next |

## Next slice (builder may propose; architect decides)

After `v4-core`: `v4-codex` (.agents/skills packaging, spawn_agent guidance),
then `v4-cleanup` (delete drivers/canary/sentinel files, DESIGN.md v4
evidence, README rewrite). v3 watch items (gpt-5.6 alias recheck,
billing-pause reversal note, GLM recipe canary, `mapfile` bash≥4 / no-macOS
gate) carry over. `.claude/settings.json` commit decision still deferred.

## Session log

| Date | Role | Slice | Commits | Gates P/F | Notes |
|------|------|-------|---------|-----------|-------|
| 2026-07-01/02 | Architect + builders | v3-loop / v3-loop-fixes / v3-loop-eol | freezes 77f5037, b1acc42, 1b8ada1; judgments b1acc42, 1b8ada1, this commit | G1–G6 P; FG2–4 P, FG1 F→D5; EG1–4 P | detail in judgment commits |
| 2026-07-02 | Architect (Claude Fable, fresh session) | v3-loop-eol judgment + G7–G11 live canaries | 9872d5b judgment+freeze; 9c4aad8 merge to main | EG1–4 P; G7–G11 P | 10/10 no-hang launches; 6-iter live loop arc; docs/STOP mid-run kill; cross-family + same-family review canaries; found D6–D8; dispatched v3-loop-docs lane 01 (codex/tier-down) |
| 2026-07-02 | Builder (codex exec gpt-5.5 high, thread 019f2195) | v3-loop-docs | lane 01 working tree | — | COMPLETE_WITH_CONCERNS (known sandbox bash -n skip, E_ACCESSDENIED); PHASE 0 verified D6 at dispatch.md:58, checklist at loop.md:123, DESIGN table at :473 before editing |
| 2026-07-02 | Architect (dispatch session, post-flight only) | v3-loop-docs | lane commit on slice/v3-loop-docs | — | Post-flight clean ×4; judgment deferred to fresh session per hard rule 4 |
| 2026-07-02 | Architect (Claude Opus 4.8, fresh session) | v3-loop-docs judgment | merge slice/v3-loop-docs → main (no-ff) | HG1–HG5 P | Gates run this session: --verbose grep non-empty; loop.md/dispatch.md/DESIGN.md text read verbatim vs gate; validator exit 0 Git Bash AND PowerShell; bin/tests + gates diffs empty; builder touch set = 4 files; net +20 ≤ 45. Diff-vs-intent clean (doc-only). Post-merge smoke: validator PASS on main. LOOP: CONTINUE |
| 2026-07-02 | Architect (Claude Fable, same session as v3 judgment canaries) | v4 planning + v4-core freeze + dispatch | PR #8 merge fe5462f; plan da064a1; freeze 0f6442d | — | 4 research lanes + 2 capability canaries + 2 source teardowns (PaulSolt thread via browser, firstmate); PRD grilled with human (6 rulings); v4-core lane 01 dispatched codex/best |
| 2026-07-02 | Builder (codex exec gpt-5.5 xhigh, thread 019f232c) | v4-core | lane 01 working tree | — | COMPLETE_WITH_CONCERNS (sandbox bash blocked E_ACCESSDENIED; grep absent in PS, rg fallback clean; VG7/VG8 not builder-runnable); suite exit 0 PS ("v4 contracts clean"); frontmatter fields verified vs official subagent docs; ±line-neutral rewrite (+635/−617) |
| 2026-07-02 | Architect (dispatch session, post-flight only) | v4-core | beb4d83 on slice/v4-core | — | Post-flight clean: touch set exactly 8 declared files, gates diff 0 bytes, out-of-scope diff empty, raw-only report, judge def hardens beyond C6 minimum. Judgment (VG1–VG7) deferred to fresh session; VG8 awaits human desktop canary |
| 2026-07-02 | Architect (Claude Fable, fresh judgment session) | v4-core judgment | 57dc420 on slice/v4-core; toy commits 000c043/76b6358/e711423 | integrity+VG1–VG7+VG9 P; VG8 pending | All gates run/read this session. VG7 in-session canary: cold builder subagent (commit-denied) + cold judge subagents via shipped agent defs; judge #1 correctly FAILed uncommitted lane; judge #2 PASS after orchestrator commit; integrated + smoked. Lesson: commit lane before judging. Awaiting human VG8 before merge to main |
| 2026-07-02 | Human + desktop orchestrator (Claude Code desktop app) | VG8 canary (toy2 `bye`) | toy2 effc321 freeze, 15433ed lane (inside `.claude/worktrees/goofy-kalam-d02c1f`) | VG8 F | Desktop session ran full loop; both architect subagents denied Bash at runtime → judge INVALID → no merge (correct). Defects D9 (desktop subagent Bash denial) + D10 (harness auto-worktree ignores pre-made lane worktree). Finding preserved at `.architect/tmp/v4-canary/VG8-FINDING.md` |
| 2026-07-02 | Architect (same Fable session, VG8 recording) | v4-core VG8 verdict | this commit | VG8 F recorded | Audited toy2 evidence on disk (freeze/lane SHAs, clean gates diff, byte-exact artifact) before recording. Slice call: CONTINUE via fix slice `v4-desktop`; no merge. claude-code-guide research dispatched on D9 root cause |
