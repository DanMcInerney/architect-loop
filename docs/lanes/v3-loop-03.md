# v3-loop-03 lane report

## Files changed / line deltas

Command:

```powershell
git diff --numstat -- DESIGN.md README.md; git diff --stat -- DESIGN.md README.md; git status --short
```

Output:

```text
84	4	DESIGN.md
53	0	README.md
 DESIGN.md | 88 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++---
 README.md | 53 ++++++++++++++++++++++++++++++++++++++
 2 files changed, 137 insertions(+), 4 deletions(-)
 M DESIGN.md
 M README.md
warning: in the working copy of 'DESIGN.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'README.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'DESIGN.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'README.md', LF will be replaced by CRLF the next time Git touches it
```

## Frozen contracts C1-C4

Source: `docs/gates/v3-loop.md`.

| Contract | Frozen text summary |
|---|---|
| C1 | `docs/HANDOFF.md` carries exactly one `^LOOP:` line. Legal forms: `LOOP: CONTINUE`; `LOOP: WAIT <minutes>` with optional parenthesized note, example `LOOP: WAIT 20 (2 lanes in flight)`; `LOOP: STOP (<reason>)` reason required. Accept regex: `^LOOP: (CONTINUE|WAIT [0-9]+( \(.+\))?|STOP \(.+\))$`. Missing, unparseable, or untouched handoff => STOP. |
| C2 | Flat `key = value`; `#` comments; unknown keys warn. Keys: `brain`, `brawn`. Values: `<cli>/<model-spec>[:<effort>]`, `<cli>` in `{claude, codex}`. First hit wins per role: repo `.architect/config` -> user `~/.architect/config` -> defaults. |
| C3 | `skills/architect/dispatch.md` hosts `## Model alias table`. Required aliases: `codex/best`, `claude/best`, `codex/tier-down`, `claude/tier-down`. Every Flags cell non-empty. |
| C4 | Drivers: `bin/architect-loop.sh`, `bin/architect-loop.ps1`. Zero required flags. Optional flags exactly `--max-iters N`, `--max-hours H`, `--permissions <mode>`, `--brain <str>`, `--brawn <str>`. Kill switch `docs/STOP`. Children get `ARCHITECT_LOOP=1`. Logs under `.architect/loop/`. Circuit breaker: 3 no-progress or 5 nonzero exits. Progress = HEAD moved OR sentinel changed OR event file grew. Missing `docs/HANDOFF.md` warns, not blocks. Never uses `--max-turns`. |

## Gate output

Command:

```powershell
$env:UV_CACHE_DIR = (Resolve-Path .architect/tmp/uv-cache).Path; uv run tests/validate_skills.py
```

Output:

```text
FAIL — 2 problem(s):
  - README.md: link 'skills/architect/loop.md' -> skills/architect/loop.md doesn't exist
  - README.md: link 'bin/architect-loop.sh' -> bin/architect-loop.sh doesn't exist
```

Cross-lane labels:

| Missing target | Lane status |
|---|---|
| `skills/architect/loop.md` | cross-lane file |
| `bin/architect-loop.sh` | cross-lane file |

## Whitespace check

Command:

```powershell
git diff --check -- DESIGN.md README.md
```

Output:

```text
warning: in the working copy of 'DESIGN.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'README.md', LF will be replaced by CRLF the next time Git touches it
```

## Pattern audit

Command:

```powershell
rg -n "Model roles|Stalled unattended runs|Runaway loop|No feature ships|Not context reuse|Not a GUI-terminal spawner|Not an autonomous infinite loop|Agent SDK credits split|Codex `workspace-write`|Run it as a loop|Choosing your models|docs/STOP|LOOP: STOP|--max-iters|--max-hours|WAIT fast-path|brawn = codex/best|UNVERIFIED gray-zone|skills/architect/loop.md|bin/architect-loop.sh|arXiv:2410.21819|goose#4036|docs.z.ai|aider issues|F1/F2|F3|F4/F5|F6|F7|F8|F9|F10|F11|F12|F13" DESIGN.md README.md
```

Output:

```text
README.md:32:## Run it as a loop
README.md:47:- `docs/STOP` stops before the next invocation.
README.md:48:- `LOOP: STOP (<reason>)` in `docs/HANDOFF.md` stops after the current
README.md:51:- `--max-iters` defaults to 50; WAIT iterations count.
README.md:52:- `--max-hours` adds a wall-clock bound.
README.md:54:Quota note: loop cost is `N` iterations times grounding cost. WAIT fast-path
README.md:58:## Choosing your models
README.md:71:brawn = codex/best
README.md:78:UNVERIFIED gray-zone recipe: Claude Code can be pointed at z.ai's
README.md:80:`ANTHROPIC_AUTH_TOKEN`. z.ai supports the route; Anthropic does not bless
README.md:159:| [skills/architect/loop.md](skills/architect/loop.md) | Loop contract, sentinel protocol, WAIT fast path, driver behavior |
README.md:164:| [bin/architect-loop.sh](bin/architect-loop.sh) / `bin/architect-loop.ps1` | Cross-platform loop drivers |
DESIGN.md:87:(F8/F12/F13; developers.openai.com/codex/agent-approvals-security,
DESIGN.md:90:## Model roles
DESIGN.md:97:subprocesses (F6; code.claude.com/docs/en/cli-reference).
DESIGN.md:105:brain and brawn share a model family unless the user opts out (F9; aider issues
DESIGN.md:106:#3087/#3085/#3287/#3543, block/goose#4036, Claude Code `opusplan` docs).
DESIGN.md:112:same-family caveat instead of blocking work (F10; arXiv:2410.21819,
DESIGN.md:120:with the F10 caveat. The single alias table is the owned rot point: it maps
DESIGN.md:123:through specs (F9/F11; superpowers audit-trail precedent).
DESIGN.md:130:chat-completions endpoints need a translating gateway (F7; docs.z.ai,
DESIGN.md:486:| Stalled unattended runs | The driver WAIT cycle schedules liveness by construction: if lanes are still in flight, the next loop iteration runs the fast path, checks event-file growth, and applies the rescue ladder. The root cause chain it prevents is out-of-workspace temp/cache paths (`C:\tmp`), parallel gate execution, missing timeout ceilings, and no scheduled return (Part A; `docs/prd/v3-loop-stall-prevention.md`). |
DESIGN.md:487:| Runaway loop | Fail-safe sentinel parsing treats missing, unparseable, or untouched `LOOP:` state as STOP; `--max-iters` defaults to 50, optional `--max-hours` bounds wall time, the circuit breaker stops after 3 no-progress iterations or 5 nonzero exits, and `docs/STOP` is checked before every invocation (F5; docs/gates/v3-loop.md C1/C4). |
DESIGN.md:495:- **Not context reuse disguised as automation.** Loop mode is an outer driver
DESIGN.md:500:  (F1/F2; aihero.dev/why-the-anthropic-ralph-plugin-sucks, ghuntley.com/ralph,
DESIGN.md:503:- **Not a GUI-terminal spawner.** The productized loop keeps one persistent
DESIGN.md:507:  reliable primitive (F3; developers.openai.com/codex/concepts/sandboxing,
DESIGN.md:513:- **Not an autonomous infinite loop.** The human sits between work blocks by
DESIGN.md:518:  normal subscription quota while the June 2026 Agent SDK credits split is
DESIGN.md:523:  decision human-only; `LOOP: STOP` is the guard for completion, hard-rule
DESIGN.md:524:  stops, and human-only arbitration (F4/F5; code.claude.com/docs/en/agent-view,
DESIGN.md:535:No feature ships without its evidence recorded in DESIGN.md - a PR adding
```

## PRD bullet checklist

| PRD bullet | Implemented at |
|---|---|
| DESIGN.md section 7 rewrite: human-between-blocks default; loop mode productized extension; autonomy trade; `LOOP: STOP`; cite F1-F5 | `DESIGN.md` section `## 7. What this deliberately is not` |
| DESIGN.md new Model roles section: brain/brawn configurability, inherit brain, tier-down brawn, quota tradeoff, cross-family review gate, degradation, alias table | `DESIGN.md` section `## Model roles` |
| DESIGN.md failure-mode table: update Stalled unattended runs row | `DESIGN.md` section `## 6. Failure modes -> mechanical mitigations`, row `Stalled unattended runs` |
| DESIGN.md failure-mode table: add Runaway loop row | `DESIGN.md` section `## 6. Failure modes -> mechanical mitigations`, row `Runaway loop` |
| DESIGN.md correction: Agent SDK credits split paused | `DESIGN.md` section `## 7. What this deliberately is not` |
| DESIGN.md correction: `.git` protection verified for Codex workspace-write only; Claude builder uses deny rules + post-flight | `DESIGN.md` section `## 2. Roles` / `## Model roles` preface |
| DESIGN.md standing rule | `DESIGN.md` section `## Standing evidence rule` |
| README Run it as a loop: quick start | `README.md` section `## Run it as a loop` |
| README Run it as a loop: iteration behavior | `README.md` section `## Run it as a loop` |
| README Run it as a loop: stop mechanisms | `README.md` section `## Run it as a loop` |
| README Run it as a loop: quota burn note | `README.md` section `## Run it as a loop` |
| README Choosing your models: defaults table | `README.md` section `## Choosing your models` |
| README Choosing your models: two-key config + override | `README.md` section `## Choosing your models` |
| README Choosing your models: cross-family review default | `README.md` section `## Choosing your models` |
| README Choosing your models: GLM recipe UNVERIFIED + gray-zone | `README.md` section `## Choosing your models` |
| README What's in the box: `skills/architect/loop.md` | `README.md` section `## What's in the box` |
| README What's in the box: `bin/architect-loop.sh` / `.ps1` | `README.md` section `## What's in the box` |

## Citations used

| Finding | Citation strings used |
|---|---|
| F1 | `aihero.dev/why-the-anthropic-ralph-plugin-sucks`; `ghuntley.com/ralph`; `humanlayer.dev/blog/brief-history-of-ralph`; `code.claude.com/docs/en/cli-reference` |
| F2 | `ghuntley.com/ralph`; `humanlayer.dev/blog/brief-history-of-ralph` |
| F3 | `developers.openai.com/codex/concepts/sandboxing`; `codex.danielvaughan.com` |
| F4 | `code.claude.com/docs/en/agent-view`; `code.claude.com/docs/en/headless`; `support.claude.com/en/articles/15036540` |
| F5 | `docs/gates/v3-loop.md C1/C4`; `LOOP: STOP`; `docs/STOP`; circuit breaker; iteration caps |
| F6 | `code.claude.com/docs/en/cli-reference` |
| F7 | `docs.z.ai`; `ANTHROPIC_BASE_URL`; `ANTHROPIC_AUTH_TOKEN` |
| F8 | `developers.openai.com/codex/agent-approvals-security` |
| F9 | `aider issues #3087/#3085/#3287/#3543`; `block/goose#4036`; `opusplan` |
| F10 | `arXiv:2410.21819`; `NeurIPS 2024 SafeGenAI`; `Panickssery et al. 2024` |
| F11 | `superpowers` audit-trail precedent |
| F12 | `code.claude.com/docs/en/headless` |
| F13 | `developers.openai.com/codex/agent-approvals-security` |
| Part A | `docs/prd/v3-loop-stall-prevention.md`; `C:\tmp`; `.architect/tmp/<purpose>` |

## PHASE 0 disagreements

| Item | File evidence | Result |
|---|---|---|
| README links to cross-lane files fail local validation until other lanes merge | `tests/validate_skills.py` checks README/DESIGN local links; `rg --files` showed no `bin/` and no `skills/architect/loop.md`; validator output above has 2 missing links | Recorded as cross-lane |
| uv cache must be routed inside workspace | `uv python find` output before edits: `uv 0.9.10 (44f5a14f4 2025-11-17)` then `error: failed to open file C:\Users\danhm\AppData\Local\uv\cache\sdists-v9\.git: Access is denied. (os error 5)` | Gate command used `.architect/tmp/uv-cache` |

STATUS: COMPLETE_WITH_CONCERNS (uv validation fails on expected cross-lane missing links: `skills/architect/loop.md`, `bin/architect-loop.sh`)
