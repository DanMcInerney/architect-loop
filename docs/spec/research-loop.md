# Spec: research-loop — calibrations A1–A4 + brain/brawn config parity

Date: 2026-07-02. Evidence base: `docs/research/agent-pipeline-patterns.md`
(committed b2a7766; keep/add/drop table, all VERIFIED claims). Human approved
A1–A4 2026-07-02 with two amendments: (1) the researcher return cap is
~2,500 tokens, not ~1,500 — measured on this repo's own r2 lanes
(2,000–3,600 tokens each with citations; URLs alone cost 138–966 tokens;
worst file double-cited every URL); (2) /architect-research must resolve
brain/brawn from the SAME config as /architect instead of hardcoding a
model.

## Problem

/architect-research's shape is field consensus (report K1–K4) but three
calibrations are unnumbered or implicit, one loop property is unnamed, and
the skill hardcodes `gpt-5.5` where /architect resolves models from config.

## Requirements

**R1 (A1 revised) — researcher return contract.** The researcher preamble in
`skills/architect-research/lanes.md`, the findings-discipline text in
`skills/architect-research/SKILL.md` step 3, and the research block template
in `skills/architect/research.md` gain a numeric cap: the findings
file must be ≤ ~2,500 tokens (~10 KB). Each source URL appears EXACTLY ONCE,
in a numbered source list at the end of the findings file; findings
reference sources by tag (e.g. `[S3]`). Evidence rationale one line: workers
may spend tens of thousands of tokens but return a distilled artifact
(Anthropic contract; Argus small-collector).

**R2 (A2) — draft-as-state gap round.** SKILL.md step 4 (gap round) is
rewritten around explicit state: after reading wave-1 findings the
orchestrator writes a skeleton draft of the final report at
`.architect/research/<topic>.draft.md` (gitignored working state) — an
answer-first outline where every section carries SUPPORTED / THIN / EMPTY
status. Gap lanes are designed from the THIN/EMPTY sections (the holes in
the draft generate the queries). Every NOT FOUND from prior lanes is copied
into a do-not-rechase list that gap-lane blocks must include. The 2-round
hard cap stays.

**R3 (A3) — budgets calibrated in tool calls + cost envelope.** SKILL.md's
scale tiers and lane search budgets gain tool-call calibration (tool call =
one search OR one page fetch): simple fact-find -> 1 researcher, 3–10 tool
calls; comparison/focused -> 2–4 researchers, 10–15 tool calls each;
brainstorm/SOTA survey -> scout + 4–6 researchers, 15–25 tool calls each.
One line of external calibration: Google's published envelope (~80 searches
~= $1–3/task standard; ~160 ~= $3–7 max) brackets the survey tier.

**R4 (A4) — the research handoff.** SKILL.md steps 6–7: name the committed
report the RESEARCH HANDOFF — its Open-questions section is the next
round's input; a later session RESUMES by reading the committed report and
dispatching gap lanes against its open questions instead of restarting the
harness. One sentence; repo is the memory.

**R5 — brain/brawn config parity with /architect.** In
`skills/architect-research/SKILL.md` step 3 and `skills/architect/research.md`:
researcher model resolves per role `brawn` in the same order as /architect
(repo `.architect/config`, then `~/.architect/config`, then the defaults in
`skills/architect/dispatch.md` — tier-down). The example command keeps the
resolved DEFAULT pins (`-m gpt-5.5 -c model_reasoning_effort="high"` =
codex/tier-down) and is labeled as the default-brawn example. If resolved
brawn is a claude row (or codex is absent), run lanes as read-only Claude
subagents — extend the existing fallback sentence in
`skills/architect-research/SKILL.md`, and add an equivalent fallback
sentence to `skills/architect/research.md` (which has none today). No new
config keys; no duplication of the alias table (pointer to dispatch.md only).

## Non-goals

- No new coordination layers, no citation subagent, no cache machinery
  (report D1/D2).
- No changes to `skills/architect/SKILL.md`, dispatch.md, loop.md, agent
  defs, installers, tests, README, or DESIGN.md (product-doc updates go to
  docs debt per P7).
- No renumbering/restructuring of SKILL.md steps beyond what R1–R5 name.

## Verification

`uv run tests/validate_skills.py` exit 0 from Git Bash AND PowerShell
(ceiling 120s each). Gate greps per `docs/gates/research-loop.md`.

## Lane plan

One `ship` lane. Touch set (exactly): `skills/architect-research/SKILL.md`,
`skills/architect-research/lanes.md`, `skills/architect/research.md`.
Target diff ≤ ~200 changed lines. Brawn: claude/tier-down (sonnet:high) —
routine, tightly specified prose edits (standing ruling: sonnet builds).
