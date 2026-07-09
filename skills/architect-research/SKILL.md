---
name: architect-research
description: >
  Run discovery-scale local research with GPT-5.5 Codex researchers: scout when
  useful, design topic-specific researcher assignments from source-class
  tactics, verify load-bearing claims, and synthesize a decision report under
  .scratch/architect-loop/research. Use for broad uncertain questions, state of
  the art, technology choices, or feature discovery.
effort: high
---

# Architect Research

You are the research orchestrator. Researchers gather; **you** design the
decomposition, verify claims, and synthesize the decision report. Judgment never
delegates. The source-class tactics library is in `tactics.md` next to this
file; read it when designing researcher assignments.

All artifacts stay local under `.scratch/architect-loop/research/<topic>/`.
Do not commit reports or raw findings unless the human gives a separate
explicit instruction after the report is produced.

## Scale Before Anything

A tool call is one search or one page fetch.

- **Simple fact-find:** answer directly or use 1 researcher, 3-10 tool calls.
- **Comparison / focused question:** 2-4 researchers on distinct perspectives,
  10-15 tool calls each, no scout if the terrain is already known.
- **Brainstorm / SOTA survey / technology choice:** scout first, then 4-6
  designed researchers, 15-25 tool calls each.

## Procedure

### 1. Scope To Brief

If the question is ambiguous, ask at most 2-3 clarifying questions. Then write a
research brief under `.scratch/architect-loop/research/<topic>/brief.md`:
question, decision it informs, constraints, and what "answered" means.

### 2. Scout, Then Design Researchers

Design researcher assignments per topic, not from a fixed taxonomy.

**Scout for brainstorm-scale work:** dispatch one cheap researcher, about 10
searches, to map terminology, the 5-10 load-bearing systems/papers/repos,
named people, rich versus empty source classes, and natural fault lines. The
scout returns a map, not findings. Skip the scout for quick fact-finds and
focused comparisons.

**Design from the scout or known terrain:** decompose into 3-6 sub-questions
along the topic's own fault lines. For each assignment choose the source-class
tactics it needs from `tactics.md`; one researcher may mix tactics. Scope each
researcher to no more than 5 subjects and give an explicit tool-call budget.
Reserve expert opinion as a second-wave researcher whose roster comes from the
first wave.

State the researcher plan briefly and proceed unless the user redirects.

### 3. Fan Out

Researchers use the same executor family as `/architect`: GPT-5.5 through
`codex exec`. Use `xhigh` for deep synthesis-sensitive research only when the
brief warrants it; otherwise `high` is usually enough for gathering.

```bash
REPO=<repo-root>
TOPIC=<topic-slug>
mkdir -p "$REPO/.scratch/architect-loop/research/$TOPIC"

codex exec -C "$REPO" --sandbox read-only -c web_search="live" \
  -m gpt-5.5 -c model_reasoning_effort="high" \
  -o ".scratch/architect-loop/research/$TOPIC/<NN>-<researcher>.md" \
  - < ".scratch/architect-loop/research/$TOPIC/<NN>-<researcher>.prompt.md"
```

Write each researcher block to a `.prompt.md` file and pass it via stdin. If
Codex is unavailable, stop and report the blocker; do not fall back to Claude
subagents.

Every researcher block carries:

- Objective and output format.
- Search/tool-call budget: simple 5, standard 15, deep 25.
- Saturation rule: two consecutive searches yielding no new load-bearing facts
  means return what you have.
- Findings discipline: every finding uses a source tag, date, exact figure or
  short quote, and confidence tag. NOT FOUND beats inference.
- Return cap: about 2,500 tokens / 10 KB. Every source URL appears exactly once
  in a numbered source list, and findings cite `[S#]`.
- No recommendations. Researchers gather; the orchestrator concludes.

### 4. Gap Round

After wave one, write a skeleton draft at
`.scratch/architect-loop/research/<topic>/REPORT.draft.md`. Mark each section
`SUPPORTED`, `THIN`, or `EMPTY` against the brief.

Design gap researchers from `THIN` and `EMPTY` sections. Carry every prior
`NOT FOUND` into a do-not-rechase list so later researchers do not spend budget
on dead ends. Dispatch the expert-opinion researcher here if useful. Hard stop
after two refinement rounds.

### 5. Verify

- Extract load-bearing claims.
- Require at least two independent sources per factual load-bearing claim.
- Tag claims `VERIFIED`, `UNVERIFIED`, `DISPUTED`, or `SUSPICIOUS`.
- Run adversarial searches for the top claims: criticism, problems, and
  alternatives.
- Cite only URLs fetched this session. Spot-check load-bearing citations.
- Put expert opinions in an expert-position map; opinions do not count as
  factual corroboration.

### 6. Synthesize

Parallelize gathering, never synthesis. Write:

```text
.scratch/architect-loop/research/<topic>/REPORT.md
```

Report shape:

- Answer first.
- Brief, restated.
- Major findings with confidence, implication for the decision, and what
  evidence would change the conclusion.
- Disputes with both positions.
- Expert positions map.
- Open questions with the search or experiment that would resolve each.
- Dated citations with source tier.

### 7. Hand Off

If this feeds `/architect`, distill the report into
`.scratch/architect-loop/planning/<feature-slug>/SPEC.md` or
`.scratch/architect-loop/state/<slice>/research.md`. Raw findings stay in
`.scratch/architect-loop/research/<topic>/`.
