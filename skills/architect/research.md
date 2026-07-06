# Research fan-out reference

Read this only when a research trigger fires (see SKILL.md step 3). The fan-out
uses Codex as parallel web-research subagents — read-only, live search, on the
flat-rate subscription — and the architect keeps all judgment: it verifies the
load-bearing claims and writes the spec itself.

## Fan out

Resolve the researcher model as builders, same order as `/architect`: repo
`.architect/config`, then user `~/.architect/config`, then the `codex/best`
default in `skills/architect/dispatch.md`.

Decompose the question into 3–10 narrow, NON-OVERLAPPING research questions.
Cover different angles, not the same angle five times — typical split:
official docs/reference, changelog/breaking changes, community failure reports,
alternatives/comparisons, security/operational constraints.

One fresh `codex exec` per question, all launched in parallel, up to 10
CLI-launched researchers — codex/tier-down shown; the builders default is `codex/best`
(`dispatch.md` `## Model resolution and dispatch rules`):

```bash
codex exec -C <repo-root> --sandbox read-only -c web_search="live" \
  -m gpt-5.5 -c model_reasoning_effort="high" \
  -o .architect/research/<NN>-<topic>.md \
  - < .architect/research/<NN>-<topic>.prompt.md
```

Write each research block to a `.prompt.md` file and pass it via stdin (`-`),
never as a shell argument — quote-mangling shells make codex hang waiting on
stdin otherwise.

- `--sandbox read-only`: researchers never write to the repo.
- `-c web_search="live"`: web search is on by default in current Codex
  (cached mode); `"live"` forces fresh results. Version ladder if the canary
  complains: `--enable web_search` (0.13x, now deprecation-warned) →
  `-c tools.web_search=true` (< 0.133). `--search` is TUI-only — exec rejects
  it. Launch ONE canary researcher and confirm it starts cleanly before
  fanning out — these flags have churned three times in 2026 alone.
- If resolved builders is a claude row, or Codex is unavailable, run the
  fan-out as read-only Claude subagents with web search, respecting the
  built-in harness cap (currently 5) — the research block works verbatim.
- Effort `high`, not `xhigh` — research is coverage work; xhigh buys nothing
  here. Synthesis happens on the architect's side.
- Scope each researcher to ≤5 subjects and put hard context rules in the
  block (snippet over page; quote ≤2 sentences; stop the moment you can
  answer) — a researcher that fills its context window dies without writing
  its output file. Bisect and re-dispatch dead researchers; don't re-run as-is.
- Optionally pin `[tools.web_search] allowed_domains` in config for
  prompt-injection-sensitive repos.

## Research block template

```
You are a web research agent. Answer ONE question. Do not write code, do not
make recommendations — judgment belongs to the architect who reads your output.

QUESTION: <one narrow question>

OUTPUT FORMAT — a markdown report, ≤ ~2,500 tokens (~10 KB) total:
- Findings as bullets. EVERY finding carries: a source tag (e.g. `[S3]`),
  source date (if shown), the exact figure or a short direct quote, and a
  confidence tag (high = primary source / med = reputable secondary / low =
  single blog or forum post).
- Prefer primary sources (official docs, changelogs, release notes, source
  code) over blog posts. Record exact version numbers and dates.
- When sources disagree, report the disagreement — do not resolve it.
- If you cannot find evidence for something, write NOT FOUND — never infer or
  fill gaps from prior knowledge without flagging it as such.
- End with a numbered source list — every source URL appears EXACTLY ONCE,
  numbered `[S1]`, `[S2]`, ... — then the 2-3 findings most likely to change
  an implementation decision.
```

## Gather (architect — this is your work, not another agent's)

1. Read every findings file in `.architect/research/`.
2. Identify the **load-bearing claims** — facts the spec will depend on
   (an API shape, a version constraint, a limit, a deprecation). Adversarially
   verify each: cross-check against a second independent source or the live
   dependency itself. Discard single-source low-confidence claims or mark them
   as open questions.
3. Write `docs/spec/<slice>.md`: problem, decision + why, requirements,
   non-goals, verified facts **with citations**, open questions for the human.
   You write it — researchers gather, the architect judges and decides.
4. Commit the spec. Raw findings stay in `.architect/research/` (gitignored) —
   only the distilled, cited spec is repo memory.
5. The slice spec references this spec instead of restating it; the builder's
   PHASE 0 is expected to challenge the spec's claims like anything else.
