# architect-loop

Turn one AI chat session into a small dev team that checks its own work.

The model you're talking to (Claude Fable, or Codex) acts as the **manager**:
it plans the work and reviews the results, but never writes the code itself.
Disposable **builder** agents write the code. An independent **judge** agent
has to pass the work against tests that were locked in *before the code
existed* — and the manager is not allowed to overrule a failing verdict.
Everything important is written to files in your repo, so any future session
can pick up exactly where the last one stopped.

It runs on the subscriptions you already have. No API keys.

![how a run unfolds](assets/architect-flow.png)

## How a run unfolds

You open your repo in Claude Code (terminal) or Codex and type `/architect`.
Then:

1. **Ground.** The session reads the repo's diary — `docs/HANDOFF.md` — to
   see what's done, what's in flight, and what was decided before. If the
   diary and the actual git state disagree, it trusts git and fixes the diary.
2. **Spec.** It picks the next small chunk of work (a *slice* — roughly one
   pull request, ideally under ~400 changed lines) and writes the pass/fail
   tests for it first. Those tests (the *gates*) are exact commands with
   exact expected outputs.
3. **Grill.** Before the gates are locked, a fresh agent tries to break
   them: it runs the gate commands, checks that every file the spec mentions
   actually exists, and attacks anything vague or untestable. Defects caught
   here cost seconds; the same defect caught later costs a full build-and-
   judge round-trip. (On by default for unfamiliar repos and risky work;
   skipped for trivial chores.)
4. **Freeze.** The fixed gates are committed to `docs/gates/`. From this
   moment they are read-only for everyone — if a builder touches them, the
   slice fails automatically. Nobody gets to move the goalposts after seeing
   results.
5. **Build.** One fresh builder agent per *lane* (lanes never share files, so
   they can run in parallel) gets written instructions: what to build, which
   files it may touch, which commands verify it. Builders must argue with
   the spec before coding — staying silent about a flaw they noticed counts
   as a defect. They report raw evidence (command output, exit codes), and
   they physically cannot commit, push, or edit the gates. They're also
   banned from writing code that hides failure: no silent fallbacks, no
   "just in case" backwards-compatibility shims — code fails loudly or the
   lane fails.
6. **Judge.** The manager fact-checks the builder's report against git, then
   commits the work and hands it to a fresh judge agent. The judge gets only
   the frozen gate file, the freeze commit, and the branch — none of the
   conversation. It runs every gate command itself, reads the diff against
   the spec's intent (passing tests on unmergeable code is still a FAIL),
   and returns a verdict with evidence.
7. **Merge — or don't.** On PASS the manager merges, writes the verdict to
   the diary, notes any documentation the change will need (*docs debt*),
   and moves to the next slice. On FAIL it re-specs or asks you. If the
   session crashes or you close the laptop, nothing is lost: the next
   session reads the diary and continues.

Why all the fresh agents: an agent reviewing its own work in the same
conversation measurably misses more (and repeated self-review makes it
*worse* — sources in [DESIGN.md](DESIGN.md)). Every review role here runs in
a separate context that has never seen the discussion, so nobody grades
their own work.

## Everything the loop does for you

| Feature | What it means in practice |
|---|---|
| Gates freeze before code exists | Acceptance tests can't be bent to fit the result |
| Pre-freeze grill | A fresh agent falsifies the spec while defects are still free to fix |
| Cold judge owns the merge | A failing verdict cannot be talked around — by anyone |
| Disjoint lanes | Parallel builders provably never touch the same files |
| Builders can't commit | Nothing reaches a branch until the manager verifies and the judge rules |
| Failure-masking ban | No silent fallbacks or unrequested compat shims — broken code fails loudly |
| Repo as memory | `docs/HANDOFF.md` + `docs/gates/` + `docs/lanes/` + git survive any crash |
| Docs debt | Shipped slices queue one-line doc reminders; one docs lane pays them all at the PR boundary |
| Stall detection | A lane that goes silent — or loops the same command — is killed and re-dispatched, not rescued |
| Tier-up on failure | A failed lane retries on a stronger model, not the same one twice |
| `docs/STOP` | Drop this file in the repo and the loop halts before its next dispatch |
| Size guard | The skill text itself is tested to stay small enough for models to actually follow |

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

## Use (one interactive session)

```
/architect                                      # the build loop
/architect-research <what you're considering>   # the research loop
```

That's the whole interface. No daemons, no driver scripts, no extra windows —
builders and judges are subagents living inside the session you're looking
at, and you can watch them work in the same transcript.

**Desktop app caveat:** the Claude Code desktop app currently strips shell
tools from subagents (an app limitation, not something this skill controls),
so builders and judges can't run tests there. Desktop is fine for planning
and reviewing; the full loop needs the terminal. The shipped agent
definitions already carry PowerShell as a second executor, so desktop starts
working the moment the app fixes subagent tool grants.

## Choosing your models

Zero-config defaults — the manager is whatever session you launched; the
builders run one tier down:

| Harness you launched | Manager ("brain") | Builders ("brawn") |
|---|---|---|
| Claude Code | your session's model | `claude/sonnet` |
| Codex | your session's model | `gpt-5.5` at `high` effort |

Override with flat `key = value` lines in `.architect/config` (repo) or
`~/.architect/config` (user); repo wins. Optional routing rules send task
classes to specific tiers:

```ini
brawn = codex/best
when trivial mechanical edit -> claude/haiku:low
```

High-stakes slices get a cross-family review when the other CLI is installed
(e.g. Codex reviewing Claude's work), because same-family review shares
blind spots.

UNVERIFIED gray-zone recipe: Claude Code can be pointed at z.ai's
Anthropic-compatible GLM endpoint via `ANTHROPIC_BASE_URL` and
`ANTHROPIC_AUTH_TOKEN`. z.ai supports the route; Anthropic does not bless
non-Claude routing. Canary it with your own key before relying on it.

## /architect-research

![research flow](assets/research-flow.png)

For when you're still deciding *what* to build. A cheap scout maps the
topic; Fable designs 3–6 research lanes along the topic's own fault lines;
parallel researchers — resolved from the same brain/brawn config as the
build loop, no hardcoded model — gather evidence under explicit tool-call
budgets (every finding needs a URL, a date, and a quote — "NOT FOUND" beats
a guess) and return compact findings, capped around 2,500 tokens, with every
claim cited and each source listed once in a numbered source list. After the
first wave, Fable sketches a skeleton draft; its thin or empty sections
steer the follow-up round instead of re-covering ground already found. The
committed report is the research handoff — a later session resumes from its
open questions instead of starting the research over. That report feeds the
build loop's specs.

## What's in the box

| File | What it is |
|---|---|
| [DESIGN.md](DESIGN.md) | Every design choice with its cited evidence |
| [skills/architect/SKILL.md](skills/architect/SKILL.md) | The manager role: hard rules + procedure |
| [skills/architect/dispatch.md](skills/architect/dispatch.md) | Builder/judge/grill delegation templates, model table, stall triage |
| [skills/architect/loop.md](skills/architect/loop.md) | Block procedure, judgment ledger, safety rails |
| [skills/architect/research.md](skills/architect/research.md) | Slice-scale inline fact-check fan-out |
| [skills/architect-research/SKILL.md](skills/architect-research/SKILL.md) | Research orchestration: scout → design → fan out → verify → write |
| [skills/architect-research/lanes.md](skills/architect-research/lanes.md) | Source-class tactics library for research lanes |
| `.claude/agents/architect-builder.md` / `architect-judge.md` | The shipped builder and judge agent definitions |
| [tests/validate_skills.py](tests/validate_skills.py) | Sanity suite: contracts, links, sizes — run `uv run tests/validate_skills.py` |

## FAQ

**Do I need API keys?** No. Claude Code runs on your Claude plan; Codex CLI
on your ChatGPT plan.

**What does a run cost?** Manager judgment is minutes of a frontier model;
building happens on the cheaper tier. A long multi-lane run is a meaningful
fraction of a weekly plan quota — parallel agents burn roughly an order of
magnitude more tokens than chat, which is why the loop doesn't fan out by
default.

**What if a builder wrecks something?** It can't reach a branch: builders
have no commit access, their file boundaries are checked after every lane,
and broken worktrees are discarded and re-dispatched from the freeze commit
rather than repaired.

**Can I watch?** Yes. Builders and judges run inside your open session;
their progress shows in the same transcript.

**Why is research a separate skill?** Research fan-out costs ~15× chat-level
tokens — it should be a deliberate act, not a side effect of building.

## Origin

The original idea came from [this X post by @jumperz](https://x.com/jumperz/status/2065454404623384859)
about using Fable with Codex subagents. I built architect-loop because I
couldn't find an easy way to run that pattern, and because the pattern gets
much stronger with a few operational rules — frozen gates, cold review,
repo-as-memory — layered on top.

## License

MIT
