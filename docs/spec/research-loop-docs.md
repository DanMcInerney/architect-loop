# Spec: research-loop-docs — consume the research-loop docs-debt row

Date: 2026-07-02. This is the dedicated product-docs lane required by the P7
docs-debt convention before the next PR boundary. Debt row (docs/HANDOFF.md
Docs debt table): slice `research-loop` (merge e39d0f4) shipped A1-A4
research calibrations + brain/brawn config parity; README's research-skill
description and a DESIGN.md evidence section need to reflect it.

## Problem

README's `/architect-research` section (lines ~144-154) predates the
research-loop slice: it does not mention tool-call budgets, the compact
cited-findings return contract, the draft-guided gap round, resumability
(the research handoff), or that research resolves models from the same
brain/brawn config as the build loop. DESIGN.md ends at §10; the
research-loop slice's evidence (research report, grill catch, D12,
composite-judgment precedent) is recorded only in the handoff.

## Requirements

**Q1 — README `/architect-research` section update.** Rewrite the section's
paragraph (keep the image, heading, and the file's plain-English voice) so
it now also conveys, in prose, not a spec dump: researchers run under
explicit tool-call budgets and return compact findings (about 2,500 tokens)
with every claim cited and each source listed once in a numbered source
list; after the first wave the orchestrator writes a skeleton draft whose
gaps steer the follow-up round; the committed report is the research
handoff — a later session resumes from its open questions instead of
starting over; and research uses the same brain/brawn config as the build
loop. The exact ASCII strings "research handoff" and
"same brain/brawn config" must appear. Update the FAQ "Why is research a
separate skill?" answer only if it contradicts the above (it does not
appear to); do not restructure other sections.

**Q2 — DESIGN.md §11 evidence section.** Append `## 11. Research-loop
evidence (A1-A4 + config parity, verified 2026-07-02)` after §10, in §10's
evidence-prose style, covering: (a) the r2 research report
`docs/research/agent-pipeline-patterns.md` (commit b2a7766) as the evidence
base — keep/add/drop verdicts, field-consensus finding, D1/D2 rejections;
(b) the human amendment raising the return cap to ~2,500 tokens, measured
on this repo's own r2 lanes (2,000-3,600 tokens with citations; URLs alone
138-966 tokens; single-listing source lists remove double-citation waste);
(c) the pre-freeze grill's third consecutive catch (2 blocking gate defects:
vacuous PowerShell exit-code check; unenumerable touch set); (d) defect D12
— intermittent, def-asymmetric CLI subagent tool strip (builder spawn held
both shells; two consecutive judge spawns lost both; first/last positional
pattern falsified) and the composite-judgment precedent that resolved it
(cross-family codex judge at workspace-write with post-hoc tree audit, plus
a cold headless `claude -p` session for gates the codex sandbox cannot run
— Git Bash dies with Win32 error 5 under the codex sandbox on this
machine); (e) slice SHAs: freeze 1b2fd90, lane 3f46f09, merge e39d0f4. The
exact ASCII strings "## 11." , "D12", "e39d0f4", and
"agent-pipeline-patterns" must appear in DESIGN.md.

## Non-goals

No changes to skills/**, tests/**, agent defs, installers, docs/gates/**,
docs/spec/** (other than this file pre-freeze), assets. No new diagrams. No
restructuring of README sections other than the named one. History sections
of DESIGN.md (§1-§10) untouched.

## Verification

`uv run tests/validate_skills.py` exit 0 from Git Bash AND via
`powershell -NoProfile -ExecutionPolicy Bypass -Command 'uv run tests/validate_skills.py; exit $LASTEXITCODE'`
(run from Git Bash; single quotes load-bearing). Gate greps per
`docs/gates/research-loop-docs.md`.

## Lane plan

One `ship` lane. Touch set (exactly): `README.md`, `DESIGN.md`, plus the
lane report `docs/lanes/research-loop-docs-01.md`. Target diff <= ~120
changed lines on README+DESIGN; gate cap 200. Brawn: claude/tier-down
(sonnet) — routine, tightly specified doc edits.
