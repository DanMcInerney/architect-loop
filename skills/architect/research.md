# Slice-Scale Research Reference

Read this only when a build slice depends on current external APIs, libraries,
versions, narrow facts, or operational constraints not already verified.
Discovery-scale research belongs to `/architect-research`.

The fan-out uses GPT-5.5 Codex researchers: read-only, live search, local
`.scratch` outputs, and no repo writes outside `.scratch`.

## Fan Out

Decompose the question into 3-5 narrow, non-overlapping questions. Cover
different angles: official docs/reference, changelog or breaking changes,
community failure reports, alternatives/comparisons, and security/operational
constraints.

One fresh `codex exec` per question:

```bash
REPO=<repo-root>
SLICE=<slice>
mkdir -p "$REPO/.scratch/architect-loop/research/$SLICE"

codex exec -C "$REPO" --sandbox read-only -c web_search="live" \
  -m gpt-5.5 -c model_reasoning_effort="high" \
  -o ".scratch/architect-loop/research/$SLICE/<NN>-<topic>.md" \
  - < ".scratch/architect-loop/research/$SLICE/<NN>-<topic>.prompt.md"
```

Use `high` for gathering by default. Use `xhigh` only if the research output
itself is synthesis-heavy and record why.

If Codex is unavailable, stop and report the blocker; do not fall back to
Claude subagents.

## Research Block Template

```text
You are a web research agent. Answer ONE question. Do not write code and do not
make recommendations; judgment belongs to the architect.

QUESTION: <one narrow question>

OUTPUT FORMAT:
- Markdown findings, <= ~2,500 tokens / 10 KB.
- Every finding carries a source tag, source date if shown, exact figure or
  short quote, and confidence tag (high = primary source, med = reputable
  secondary, low = single blog/forum).
- Every source URL appears exactly once in a numbered source list at the end.
- Prefer primary sources: official docs, changelogs, release notes, source code.
- Record exact versions and dates.
- When sources disagree, report the disagreement; do not resolve it.
- If you cannot find evidence, write NOT FOUND. Never infer.
- End with the 2-3 findings most likely to change implementation.
```

## Gather

1. Read findings under `.scratch/architect-loop/research/<slice>/`.
2. Identify load-bearing claims: API shape, version constraint, limit,
   deprecation, security constraint, or operational behavior.
3. Verify each against a second independent source or the live dependency.
4. Discard single-source low-confidence claims or mark them open.
5. Write distilled decisions into:
   - `.scratch/architect-loop/planning/<feature-slug>/PRD.md` for feature/product scope; or
   - `.scratch/architect-loop/state/<slice>/research.md` for slice-local facts.
6. Do not commit research files, PRDs, raw findings, or reports.
