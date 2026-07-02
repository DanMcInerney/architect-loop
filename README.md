# architect-loop

**Claude Fable handles planning and review; GPT-5.5 Codex handles
implementation and research.** Two Claude Code skills wire that split into a
repo-centered loop: specs and gates are written first, Codex works in fresh
contexts, and Fable reviews the evidence before anything is integrated. It runs
on the subscriptions you already have — no API keys required by default.

## Install (30 seconds)

```bash
git clone https://github.com/DanMcInerney/architect-loop
cd architect-loop && ./install.sh        # Windows: .\install.ps1
npm i -g @openai/codex@latest            # the builder (Codex CLI >= 0.133)
```

`./install.sh --project` installs to the current repo only instead of
globally. You need [Claude Code](https://claude.com/claude-code) on any paid
plan and the Codex CLI signed into a ChatGPT plan.

## Use (two commands)

```
/architect                                      # the build loop
/architect-research <what you're considering>   # the research loop
```

`/architect` runs one work block: judge the last run, spec the next slice,
dispatch builders. `/architect-research` is for when you're still deciding
*what* to build — its cited report feeds the build loop's PRD.

## Run it as a loop

From a repo, run:

```bash
architect-loop
```

Each iteration starts a fresh architect session, grounds in the repo, reads the
handoff, then either judges completed lanes, dispatches the next slice, or runs
the WAIT fast path while builders are still in flight. The driver's terminal is
the visible surface; per-iteration logs live under `.architect/loop/`.

Stop mechanisms:

- `docs/STOP` stops before the next invocation.
- `LOOP: STOP (<reason>)` in `docs/HANDOFF.md` stops after the current
  iteration.
- The circuit breaker stops after 3 no-progress iterations or 5 nonzero exits.
- `--max-iters` defaults to 50; WAIT iterations count.
- `--max-hours` adds a wall-clock bound.

Quota note: loop cost is `N` iterations times grounding cost. WAIT fast-path
iterations run automatically on the tier-down brain and never judge, but they
still consume quota.

## Choosing your models

Zero-config defaults:

| Harness you launched | Brain | Brawn |
|---|---|---|
| Claude Code | the Claude session you launched | `claude/sonnet` |
| Codex | the Codex session you launched | `gpt-5.5` at `high` effort |

To override, add flat `key = value` lines to `.architect/config` in the repo or
`~/.architect/config` for the user. Repo config wins; first hit wins per key.

```ini
brawn = codex/best
```

The review gate spends cross-family diversity by default: if the other supported
CLI is on PATH for a high-stakes slice, review runs there; otherwise it logs a
same-family caveat and proceeds.

UNVERIFIED gray-zone recipe: Claude Code can be pointed at z.ai's
Anthropic-compatible GLM endpoint with `ANTHROPIC_BASE_URL` and
`ANTHROPIC_AUTH_TOKEN`. z.ai supports the route; Anthropic does not bless
non-Claude routing. Canary it with your own key before relying on it.

## /architect

![/architect flow](assets/architect-flow.png)

One short Fable session per work block — judgment only, it never writes code:

- **Spec + gates first.** Fable specs a one-PR slice, splits it into 1–4
  lanes whose file sets are checked for overlap, and commits the acceptance gates to
  `docs/gates/` *before* any builder starts. Gates are read-only; a builder
  edit to a gate file fails the slice automatically.
- **Parallel isolated builders.** One fresh `codex exec` (xhigh) per lane,
  each in its own git worktree. Builders must argue with the spec before
  building (silent compliance = defect), build only their declared files,
  and report raw results — they do not have commit access in the sandbox.
- **Fable judges and integrates.** It runs the gate commands itself (builder
  claims are hearsay), reads the diff against the spec's intent (passing
  tests ≠ mergeable work), then commits and merges passing lanes. Judgment
  happens in a fresh session because the cited evidence favors fresh-context
  review.
- **The repo is the only memory.** `docs/HANDOFF.md` (a short table of
  contents, pruned every session), `docs/gates/`, `docs/lanes/`, git
  history. Not in the repo = didn't happen.
- **Supervision built in.** Liveness checks on dispatched runs, stall triage
  (diagnose the child process tree, kill the narrowest thing), explicit
  timeouts on every long command.

## /architect-research

![/architect-research flow](assets/research-flow.png)

Scout-first, like the production deep-research systems — no fixed lane
taxonomy:

- **A cheap Codex scout maps the topic** (~10 searches): canonical
  terminology, the load-bearing systems and papers, the named people, the
  topic's natural fault lines. Skipped for comparisons and fact-finds.
- **Fable designs 3–6 topic-specific lanes** from the scout's map, drawing
  per-source-class tactics from a library (academic citation snowballing,
  dependents-not-stars repo evidence, emerging-vs-hype gating, production
  pattern mining, expert tracking) — checked for overlap and gaps before
  dispatch.
- **Parallel Codex researchers** run under hard budgets: search caps, ≤5
  subjects per lane, saturation stop, strict findings discipline (URL + date
  + quote + confidence tag; NOT FOUND beats inference; no recommendations).
  Expert opinion runs as a second wave, roster-seeded by the first.
- **Fable verifies and writes.** ≥2 independent sources per load-bearing
  claim, adversarial falsification searches, citations only from URLs
  actually fetched — then one author writes one decision-oriented report.
  Gathering parallelizes; synthesis never does.

## Why this shape

Each design choice is source-backed (full citations in
[DESIGN.md](DESIGN.md)):

- Weak planners hurt more than weak executors — so the architect model does
  the design, and builders get explicit specs.
- Manager + worktree-isolated workers is a well-supported topology for
  shared-artifact software work; naive shared-file coordination collapses
  throughput.
- Frozen external gates beat trusting the agent — but agents game visible
  tests and their passing PRs are frequently unmergeable, so the architect
  also reads the diff.
- Memory files rot — so the handoff stays a short map, and detail lives in
  linked gate/lane files.
- The surveyed production deep-research systems use planner-designed
  decomposition rather than fixed lanes — so research lanes are designed per
  topic, after a scout pass.

## What's in the box

| File | What it is |
|---|---|
| [DESIGN.md](DESIGN.md) | The design document — 12 enforced rules, failure-mode table, cited sources |
| [skills/architect/SKILL.md](skills/architect/SKILL.md) | The architect role: hard rules + procedure |
| [skills/architect/dispatch.md](skills/architect/dispatch.md) | Verified `codex exec` commands, builder block, worktree fan-out, stall triage |
| [skills/architect/loop.md](skills/architect/loop.md) | Loop contract, sentinel protocol, WAIT fast path, driver behavior |
| [skills/architect/research.md](skills/architect/research.md) | Slice-scale inline fact-check fan-out |
| [skills/architect/HANDOFF.template.md](skills/architect/HANDOFF.template.md) | The repo-memory file |
| [skills/architect-research/SKILL.md](skills/architect-research/SKILL.md) | Research orchestration: scout → design → fan out → verify → write |
| [skills/architect-research/lanes.md](skills/architect-research/lanes.md) | Scout block + source-class tactics library with verified endpoints |
| [bin/architect-loop.sh](bin/architect-loop.sh) / `bin/architect-loop.ps1` | Cross-platform loop drivers |
| [tests/validate_skills.py](tests/validate_skills.py) | Repo sanity checks (frontmatter limits, links, fences) |

## FAQ

**Do I need API keys?** No. Claude Code runs on your Claude plan; Codex CLI
on your ChatGPT plan.

**What does a run cost?** Builder/researcher runs draw on your ChatGPT
plan's 5-hour and weekly quotas; a multi-hour run is a meaningful fraction
of a weekly window. Fable's architect sessions are minutes, not hours.

**What if a builder wrecks things?** Nothing reaches a branch until the
architect's tamper, boundary, and gate checks pass — worktrees are
discarded and re-dispatched from the freeze commit.

**Can I watch a run?** Yes — every dispatch prints the builder block, so you
can paste it into an interactive `codex` session with `/goal` instead.

**Why two skills?** Research-grade fan-out costs ~15× chat-level tokens — it
should be a deliberate act, not a side-effect of the build loop.

## Origin

The original idea came from [this X post by @jumperz](https://x.com/jumperz/status/2065454404623384859)
about using Fable with Codex subagents. I built architect-loop because I couldn't
find an easy way to run that pattern, and because it seemed useful to add a few
extra operational best practices on top of what Fable can already do when calling
Codex subagents.

## License

MIT
