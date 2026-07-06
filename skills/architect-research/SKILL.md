---
name: architect-research
description: >
  Use when the user asks for discovery-scale research that informs a decision:
  brainstorming a project or feature, choosing a technology, or requests like
  "research X", "what's the state of the art", or "deep research". Use this
  skill to turn broad, uncertain questions into sourced decision evidence and
  a reusable research handoff. For narrow slice-level fact checks inside the
  build loop, /architect handles those inline.
effort: high
---

# Architect Research

You are the research orchestrator. Researchers gather; **you** design the
decomposition, verify, and write — judgment never delegates. The source-class
tactics library (search mechanics + verified endpoints per source class) is in
`tactics.md` next to this file; read it when you design researcher assignments.

## Scale before anything

A tool call is one search OR one page fetch.

- **Simple fact-find** → answer directly or 1 researcher, 3-10 tool calls.
  Don't run a harness on a question one search answers.
- **Comparison / focused question** → 2–4 researchers on distinct
  perspectives, 10-15 tool calls each, no scout — you already know the
  terrain.
- **Brainstorm / SOTA survey / technology choice** → scout first, then a
  designed fan-out of 4–10 researchers, 15-25 tool calls each. Google's
  published research envelope brackets this tier: ~80 searches ≈ $1–3/task
  standard, ~160 ≈ $3–7 max.

## Procedure

### 1. Scope → brief

If the question is ambiguous, ask at most 2–3 clarifying questions, then
compress everything into a **research brief**: the question, the decision it
informs, constraints, and what "answered" looks like. The brief is the north
star — every later step is checked against it, and it's restated at the top of
the final report so the reader can audit scope drift.

### 2. Scout, then design the researchers

Design researcher assignments per topic, not from a fixed taxonomy.

**Scout (brainstorm scale only):** dispatch ONE cheap researcher (~10
searches, same codex command as step 3) to map the terrain: canonical
terminology, the 5–10 load-bearing systems/papers/repos, the named people,
which source classes look rich vs empty, and the topic's natural fault lines.
The scout returns a map, not findings. Skip the scout when you already know the
terrain (comparisons, fact-finds).

**Design (you, from the scout report):** decompose into 3–10 sub-questions
along the topic's own fault lines — distinct perspectives, never keyword
variants of one query. For each researcher assignment pick the source-class tactics it needs
from `tactics.md` (academic snowballing, dependents-not-stars repo evidence,
production-grade pattern mining, general web, expert tracking) — one researcher may
mix tactics; most topics don't need every source class. Scope each researcher to
≤5 subjects and give every researcher assignment an explicit search budget. Reserve **expert
opinion** as a second-wave researcher: its roster (survey authors, maintainers,
recurring names) comes from the first wave's findings.

Review the researcher set for overlap AND for gaps against the brief before
dispatch. State the plan in a few lines; proceed unless the user redirects.

### 3. Fan out

Resolve the researcher model as builders, same order as `/architect`: repo
`.architect/config`, then user `~/.architect/config`, then the
config-resolved default in `skills/architect/dispatch.md` — `codex/best`
(gpt-5.5 at xhigh) via the codex CLI; the Claude-native rows
(`builders = claude/...`) are the config-selected alternative. One fresh
researcher per assignment, up to 10 in parallel for CLI launches — this is the
default codex/best form:

```bash
codex exec --sandbox read-only -c web_search="live" \
  -m gpt-5.5 -c model_reasoning_effort="xhigh" \
  -o .architect/research/<NN>-<researcher>.md \
  - < .architect/research/<NN>-<researcher>.prompt.md
```

Write each researcher block to a `.prompt.md` file and pass it via stdin (`-`) —
never as a shell argument; quote-mangling shells make codex hang on stdin.

(Web search is on by default in current Codex; `"live"` forces fresh results.
Older CLIs: `--enable web_search` (0.13x) or `-c tools.web_search=true`
(< 0.133); `--search` is TUI-only — exec rejects it. Launch ONE canary researcher
and confirm it starts cleanly before fanning out. If resolved builders is a
claude row, or Codex is unavailable, run researchers as read-only Claude
subagents with web search, respecting the built-in harness cap (currently 5) —
the researcher blocks work verbatim.)

Every researcher block carries the full contract — objective, output format, source
guidance, boundaries — plus:

- **Search budget** by tier: simple 5, standard 15, deep 25 searches.
- **Saturation rule**: two consecutive searches yielding no new load-bearing
  facts → return what you have.
- **Findings discipline**: every finding has a source tag + date + exact
  figure or short quote + confidence tag (high = primary source / med =
  reputable secondary / low = single blog or forum). NOT FOUND beats
  inference. Disagreements between sources are reported, never resolved. No
  recommendations — judgment is the orchestrator's. The findings file is
  capped at ≤ ~2,500 tokens (~10 KB): every source URL appears EXACTLY ONCE,
  in a numbered source list at the end of the file, and findings cite
  sources by tag (e.g. `[S3]`).

### 4. Gap round (max 2 extra rounds, usually 1)

After reading wave-1 findings, write (or update, on round 2) a skeleton draft
of the final report at `.architect/research/<topic>.draft.md` (gitignored
working state) — an answer-first outline where every section carries a
**SUPPORTED / THIN / EMPTY** status against the brief. Gap researchers are designed
from the THIN/EMPTY sections — the holes in the draft generate the queries,
not a coverage score kept in your head. Every NOT FOUND from prior researchers
carries forward into a **do-not-rechase list** that every gap-researcher block must
include, so gap researchers don't re-spend budget chasing a dead end. This is
also where the **expert-opinion researcher** dispatches: extract the expert roster
from the first wave (survey authors, maintainers, recurring names) and send a
targeted researcher after them. Hard stop after two refinement rounds —
past that you're chasing nonexistent information.

### 5. Verify (your work, against raw sources)

- Extract the **load-bearing claims** — the facts the decision depends on.
- Require **≥2 independent sources** per load-bearing claim. Independent means
  independent *origin* — two articles rewriting the same press release are one
  source.
- Tag each: **VERIFIED** (≥2 independent agree) / **UNVERIFIED** (<2, no
  contradiction) / **DISPUTED** (sources disagree — report both positions and
  *why* they differ: date, method, definition) / **SUSPICIOUS** (contradicts
  available evidence).
- **Adversarial pass** on the top claims: search "<claim> criticism",
  "<X> problems", "<X> vs <alternative>" — actively try to falsify.
- **Citations are only URLs fetched this session.** Never cite from memory —
  even search-grounded agents fabricate 3–13% of URLs. Spot-check the
  load-bearing ones by fetching them yourself.
- **Recency discipline**: every quantitative or current-state claim carries a
  source date; prefer the most recent authoritative treatment; date-restrict
  searches on fast-moving topics. Anything that smells like training-data
  leakage gets re-verified or cut.
- **Source hierarchy**: primary (papers, official docs, changelogs, first-party
  engineering blogs) > reputable secondary > SEO listicles (pointers only,
  never citations).
- **Opinion ≠ fact.** Expert opinions are reported as positions — quoted,
  dated, conflict-of-interest flagged — and never count toward the ≥2-source
  rule for factual claims. Expert *disagreements* are first-class findings:
  they mark the genuinely open questions.

### 6. Synthesize (one pass, one author — you)

Parallelize gathering, never synthesis. Write `docs/research/<topic>.md`:

- **Answer first** (BLUF), then evidence, then method.
- The brief, restated.
- Per major finding: the claim + confidence tag + **what it implies for the
  decision** + **what evidence would change this conclusion**.
- Disputes surfaced with both positions — never silently averaged.
- **Expert positions map**: who believes what (quoted, dated,
  conflict-of-interest flagged), and where credible experts disagree.
- **Open questions**: each UNVERIFIED/DISPUTED item with the specific search
  or experiment that would resolve it (this doubles as the next round's input).
- Citations dated and tier-labeled: `[primary, 2026-04]`.

Commit the report — this is the **research handoff**: its Open-questions
section is the next round's input, and the repo is the memory. Raw findings
stay in `.architect/research/` (gitignored).

### 7. Hand off

A later session resumes work by reading the committed research handoff and
dispatching gap researchers against its Open-questions section instead of
restarting the harness. If this feeds the build loop: distill the report
into `docs/spec/<slice>.md` per `/architect` and continue there.
