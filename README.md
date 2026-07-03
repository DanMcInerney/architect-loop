# architect-loop

Turn one AI chat session into a small dev team that checks its own work.

The model you're talking to, Claude or Codex, acts as the **orchestrator**: it
understands the goal, writes the spec, cuts the work into issues, answers
blockers, and judges results. Disposable **builder** agents write the code in
isolated worktrees. A separate **judge** agent has to pass the work against
checks that were locked in before the code existed, and the orchestrator is not
allowed to overrule a failing verdict.

GitHub is the issue tracker and the audit trail. The approved spec becomes
a tracking issue with sub-issues and native blocked-by links; rulings, blocker
answers, judge verdicts, and the end-of-run digest all land as issue
comments, so you can follow a run from GitHub alone. Git keeps the approved
specs and frozen checks; job reports keep raw command output. A later
session can recover from the tracker and the repo instead of depending on
chat history.

You intervene exactly once: approving the spec. From there the factory
creates the issues, dispatches parallel builders, answers their blockers,
judges every result, and merges what passes — an autonomous software
factory that only interrupts you for a hard stop or the closing digest.

## How a run unfolds

![architect flow](assets/architect-flow.png)

You open your repo in Claude Code or Codex and type `/architect`. Then:

1. **Intake.** The orchestrator reads the repo and asks at most about five questions
   in one batch. A question has to matter: the answer would change
   implementation or validation. Everything else becomes a recorded
   assumption in the spec.
2. **Spec approval.** You review one document under `docs/spec/`. You can edit
   assumptions, veto them, or approve the plan. Approval authorizes the whole
   factory run.
3. **Factory loop.** The orchestrator turns the approved spec into a GitHub issue
   plan: one tracking issue, sub-issues, and native blocked-by links. It freezes each
   issue's checks under `docs/checks/`, dispatches the ready issues, and
   keeps going until the plan is closed or a hard stop fires.

The factory can run up to five builder jobs at once, plus one cheap
detection-only monitor. The monitor checks for stalled jobs every roughly
10 minutes using output growth, process activity, and repeated-command tails.
It never kills or nudges anything; it exits with evidence, and the orchestrator
decides what to do.

On a passing issue, the orchestrator records the judge verdict on the issue and
merges. On a blocker, the builder job stops, the orchestrator answers on the issue,
and a fresh job is respawned with the answer in its starting context. On a
check failure, the orchestrator diagnoses the input and respawns at the same tier;
failures are treated as spec, context, or architecture problems, not as a
signal to automatically change models.

Why all the fresh agents: an agent reviewing its own work in the same
conversation measurably misses more. Every review role here runs in a separate
context that has never seen the discussion, so nobody grades their own work.
Sources and design evidence are in [DESIGN.md](DESIGN.md).

## Everything the loop does for you

| Feature | What it means in practice |
|---|---|
| Materiality-tested intake | The orchestrator asks only the few questions that can change the build or validation plan |
| One spec approval | You review one spec document, then the factory is authorized to run |
| GitHub issue plan | Tracking issue, sub-issues, and native blocked-by links are the durable coordination state |
| Ready issue dispatch | The orchestrator runs only issues whose blockers are closed, up to five jobs |
| Frozen checks | Acceptance commands live in `docs/checks/` and cannot be changed after dispatch |
| Fresh judge owns the merge | A failing verdict cannot be talked around by anyone |
| Detection-only monitor | Stalls wake the orchestrator with evidence; the monitor never kills or decides |
| Builder boundaries | Each job gets a may-touch and must-not-touch set, then reports raw evidence |
| Builders can't commit | Nothing reaches a branch until the orchestrator verifies and the judge rules |
| Failure-masking ban | No silent fallbacks or unrequested compatibility shims; broken code fails loudly |
| Docs debt | One final docs job updates product docs and records reusable lessons |
| `docs/STOP` | Drop the kill switch in the repo and the factory halts before its next dispatch |
| Size guard | The skill text itself is tested to stay small enough for models to follow |

## Preconditions

The build loop uses GitHub as its tracker. Before `/architect` can run the
factory, the repo needs:

- a GitHub remote;
- `gh auth status` passing;
- `gh` version 2.94.0 or newer, for native sub-issue and dependency flags.

Preflight also runs a backend canary before dispatch so the factory records a
working builder backend instead of switching mid-wave.

If any precondition is missing, the skill fails loudly instead of falling back
to a local tracker.

## Install (30 seconds)

```bash
git clone https://github.com/DanMcInerney/architect-loop
cd architect-loop && ./install.sh        # Windows: .\install.ps1
npm i -g @openai/codex@latest            # optional: Codex CLI (>= 0.133)
```

One installer, both ecosystems: it copies the same skill text to Claude
Code's skills directory and to Codex's `.agents/skills`, so `/architect`
works in whichever you open. Use `./install.sh --project` (or
`.\install.ps1 -Project`) to install into the current repo only. You need
[Claude Code](https://claude.com/claude-code) on any paid plan; the Codex
CLI on a ChatGPT plan is optional.

## Use

```
/architect                                      # the build factory
/architect-research <what you're considering>   # the research loop
```

That's the whole interface. No daemons, no driver scripts, no extra windows.
Builders, monitors, and judges are subagents living inside the session you're
looking at, with durable state mirrored through GitHub issues and repo files.

**Desktop app caveat:** the Claude Code desktop app has had shell-tool grant
limitations for subagents. Desktop is fine for planning and reviewing; run the
full factory from a terminal until your harness can give builder, judge, and
monitor agents the shell tools their checks require.

## Choosing your models

Zero-config defaults: the orchestrator is whatever session you launched; builders are
codex-first — GPT-5.5 at xhigh effort whenever the Codex CLI is installed,
falling back to Sonnet at high reasoning only when it isn't.

| Harness you launched | Codex CLI on PATH? | Orchestrator | Default builders |
|---|---|---|---|
| Claude Code | yes | your session's model | `codex/best` (gpt-5.5, xhigh) |
| Claude Code | no | your session's model | `claude/tier-down` (Sonnet, high) |
| Codex | — | your session's model | `codex/best` (gpt-5.5, xhigh) |

Override with flat `key = value` lines in `.architect/config` (repo) or
`~/.architect/config` (user); repo wins. Optional routing rules send task
classes to specific tiers:

```ini
# same-family default is used when this file is absent
orchestrator = claude/best

# cross-family example
builders = codex/best:xhigh

when trivial mechanical edit -> claude/haiku:low # cheap exact patch
when broad ambiguous refactor -> codex/best:xhigh # deeper search and edit budget
```

Tier is fixed at decomposition by config plus dispatch rules. The factory does
not automatically move a failed job to a stronger model; the orchestrator diagnoses
the failure and fixes the input or decomposition.

High-stakes slices get a cross-family review when the other CLI is installed,
because same-family review shares blind spots.

UNVERIFIED gray-zone recipe: Claude Code can be pointed at z.ai's
Anthropic-compatible GLM endpoint via `ANTHROPIC_BASE_URL` and
`ANTHROPIC_AUTH_TOKEN`. z.ai supports the route; Anthropic does not bless
non-Claude routing. Canary it with your own key before relying on it.

## /architect-research

![research flow](assets/research-flow.png)

For when you're still deciding *what* to build. A cheap scout maps the
topic; Fable designs 3-6 researchers along the topic's own fault lines;
parallel researchers, resolved from the same orchestrator/builders config as the
build loop, gather evidence under explicit tool-call budgets. Every finding
needs a URL, a date, and a quote; "NOT FOUND" beats a guess. After the first
wave, Fable sketches a skeleton draft; its thin or empty sections steer the
follow-up round instead of re-covering ground already found. The committed
report is the research handoff, and it feeds the build loop's specs.

## What's in the box

| File | What it is |
|---|---|
| [DESIGN.md](DESIGN.md) | Every design choice with its cited evidence |
| [skills/architect/SKILL.md](skills/architect/SKILL.md) | The orchestrator role: intake, spec approval, factory loop, and hard stops |
| [skills/architect/dispatch.md](skills/architect/dispatch.md) | Model aliases, issue conventions, builder/judge templates, monitor dispatch, and respawn rules |
| [skills/architect/loop.md](skills/architect/loop.md) | Factory event loop, monitor protocol, failure ladder, and safety rails |
| [skills/architect/research.md](skills/architect/research.md) | Slice-scale inline fact-check fan-out |
| [skills/architect-research/SKILL.md](skills/architect-research/SKILL.md) | Research orchestration: scout -> design -> fan out -> verify -> write |
| [skills/architect-research/tactics.md](skills/architect-research/tactics.md) | Source-class tactics library for researchers |
| `.claude/agents/architect-builder.md` / `architect-judge.md` / `architect-monitor.md` | The shipped builder, judge, and monitor agent definitions |
| [tests/validate_skills.py](tests/validate_skills.py) | Sanity suite: contracts, links, sizes; run `uv run --no-project python tests/validate_skills.py` |

## FAQ

**Do I need API keys?** No. Claude Code runs on your Claude plan; Codex CLI
on your ChatGPT plan.

**What does a run cost?** Orchestrator judgment is minutes of a frontier model;
building happens on the configured builder tier. A long multi-job run is a
meaningful fraction of a weekly plan quota, which is why the factory only
fans out when the plan is ready for it.

**What if a builder wrecks something?** It can't reach a branch: builders
have no commit access, their file boundaries are checked after every job,
and broken worktrees are discarded and respawned from the frozen check.

**Can I watch?** Yes. Builders, monitors, and judges run inside your open
session, and issue comments carry the durable progress trail.

**Why is research a separate skill?** Research fan-out costs far more tokens
than chat. It should be a deliberate act, not a side effect of building.

## Origin

The original idea came from [this X post by @jumperz](https://x.com/jumperz/status/2065454404623384859)
about using Fable with Codex subagents. I built architect-loop because I
couldn't find an easy way to run that pattern, and because the pattern gets
much stronger with a few operational rules: frozen checks, fresh review,
issue-backed coordination, and repo-resident evidence.

## License

MIT
