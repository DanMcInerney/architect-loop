# Research fan-out reference

Read only when a research trigger fires. The fan-out uses parallel
read-only web-research subagents; the orchestrator keeps all judgment and
verifies the load-bearing claims.

## Fan out

Resolve the researcher model as builders (repo config, user config, then
the `codex/best` default in `dispatch.md`). Decompose the question into
3–10 narrow, NON-OVERLAPPING questions — different angles, not the same
angle five times: official docs, changelog/breaking changes, community
failure reports, alternatives, security/operational constraints.

One fresh `codex exec` per question, launched in parallel, up to 10:

```bash
codex exec -C <repo-root> --sandbox read-only -c web_search="live" \
  -m gpt-5.5 -c model_reasoning_effort="high" \
  -o .architect/research/<NN>-<topic>.md \
  - < .architect/research/<NN>-<topic>.prompt.md
```

Write each research block to a `.prompt.md` file and pass it via stdin —
quote-mangling shells make codex hang otherwise.

- `--sandbox read-only`: researchers never write to the repo.
- `-c web_search="live"` forces fresh results. Version ladder if the canary
  complains: `--enable web_search` -> `-c tools.web_search=true` (< 0.133);
  `--search` is TUI-only. Launch ONE canary researcher before fanning out —
  these flags churn.
- If builders resolve to a claude row or Codex is unavailable, run the
  fan-out as read-only Claude subagents with web search (harness cap 5);
  the research block works verbatim.
- Effort `high`, not `xhigh` — research is coverage work.
- Scope each researcher to ≤5 subjects with hard context rules in the block
  (snippet over page; quote ≤2 sentences; stop when you can answer) — a
  researcher that fills its context dies without writing its file. Bisect
  and re-dispatch dead researchers.
- Optionally pin `[tools.web_search] allowed_domains` for
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

## Gather (orchestrator work, not another agent's)

1. Read every findings file in `.architect/research/`.
2. Adversarially verify each load-bearing claim (API shape, version
   constraint, limit, deprecation) against a second independent source or
   the live dependency; discard or mark open single-source low-confidence
   claims.
3. Feed the verified, cited findings into the consuming stage — the spec
   strategist's dispatch context at intake, or the amended issue/check text
   during re-planning. Raw findings stay in `.architect/research/`
   (gitignored); only distilled, cited claims become repo memory.
4. Builders' PHASE 0 execution-conflict check is expected to challenge
   research claims like anything else.
