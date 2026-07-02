# Lane report: research-loop-docs-01

Slice: research-loop-docs. Freeze SHA: ded508c. Branch:
slice/research-loop-docs. Executor for all commands below: Bash (Git Bash),
except QG1's second invocation which is PowerShell invoked from Git Bash as
the gate specifies. Lane identity: research-loop-docs-01, sole builder.

## PHASE 0 disagreements

None that required a ruling. Checked before concluding the spec sound:

1. Verified the freeze/lane/merge SHAs (`1b2fd90`/`3f46f09`/`e39d0f4`) and
   the exact grill-defect wording ("RG1 PS exit-code vacuity; RG7
   unenumerable touch set") against `docs/HANDOFF.md:107-140`.
2. The spec's claim that `research-loop`'s grill was the "third consecutive
   catch" was not fully narrated in the current HANDOFF bullets alone (only
   two prior grill uses are described there: `loop-hardening` and
   `research-loop`). Checked `git log --oneline` for the missing middle
   instance and found commit `47a0f84` ("v4-docs: freeze gates MG1-MG4 ...
   post-grill: 8 draft defects fixed") — `v4-docs` ran a grill too, between
   `loop-hardening` (1st, 5 defects) and `research-loop` (3rd, 2 blocking +
   4 sharpenings). Spec's count confirmed correct; no ruling needed.
3. Confirmed `docs/research/agent-pipeline-patterns.md`'s commit is
   `b2a7766` via `git log --oneline -- docs/research/agent-pipeline-patterns.md`.
4. Confirmed `D9` lives in DESIGN.md `## 9.` (line 623 pre-edit), so the new
   §11 D12 paragraph cross-references "§9" for the desktop-strip comparison,
   not "§10".
5. Confirmed DESIGN.md had no `## 11.` before this lane (last heading `##
   10.` at line 680, file ended at line 768) and every numbered section is
   preceded by a `---` separator; followed that convention for §11.
6. Confirmed `tests/validate_skills.py`'s `check_skill_text_size()` only
   sums `skills/architect/{SKILL.md,loop.md,dispatch.md}` non-blank lines
   (per the `research-loop` lane report's own PHASE-0 finding, reused here),
   so README/DESIGN edits cannot trip that guard.
7. Confirmed the README FAQ "Why is research a separate skill?" answer
   (cost rationale only) does not contradict the new `/architect-research`
   prose — left untouched per the spec's "only if it contradicts" clause.

No rulings requested.

## QG1 — validator green in both shells

Git Bash:
```
$ uv run tests/validate_skills.py; echo "EXIT:$?"
OK - 2 skills validated, v4 contracts clean
EXIT:0
```

PowerShell (via Git Bash per the gate's exact invocation):
```
$ powershell -NoProfile -ExecutionPolicy Bypass -Command 'uv run tests/validate_skills.py; exit $LASTEXITCODE'; echo "EXIT:$?"
OK - 2 skills validated, v4 contracts clean
EXIT:0
```
QG1: PASS.

## QG2 — README section (Q1)

```
$ grep -n "research handoff" README.md
157:committed report is the research handoff — a later session resumes from its

$ grep -n "same brain/brawn config" README.md
150:parallel researchers — resolved from the same brain/brawn config as the
```
Read check: `/architect-research` section (README.md:144-158) keeps the
heading and `![research flow](assets/research-flow.png)` image; the
rewritten paragraph, in the file's existing plain-English voice, now
conveys: researchers resolved from the same brain/brawn config as the build
loop (no hardcoded model); explicit tool-call budgets; compact findings
capped around 2,500 tokens with every claim cited and each source listed
once in a numbered source list; a post-wave-1 skeleton draft whose thin/empty
sections steer the follow-up round; and the committed report as the research
handoff that a later session resumes from via its open questions instead of
starting over. No other README section restructured (verified via
`git diff --stat -- README.md` below: single hunk in the `/architect-research`
section only). QG2: PASS.

## QG3 — DESIGN.md §11 (Q2)

```
$ grep -n "## 11\." DESIGN.md
771:## 11. Research-loop evidence (A1-A4 + config parity, verified 2026-07-02)

$ grep -n "D12" DESIGN.md
804:**D12 — intermittent, def-asymmetric CLI subagent tool strip.** Same

$ grep -n "e39d0f4" DESIGN.md
773:Slice `research-loop` (freeze `1b2fd90`, lane `3f46f09`, merge `e39d0f4`)

$ grep -n "agent-pipeline-patterns" DESIGN.md
775:`docs/research/agent-pipeline-patterns.md` (commit `b2a7766`), plus
```
Read check: `## 11.` (DESIGN.md:771-812) covers (a) the r2 evidence base
`docs/research/agent-pipeline-patterns.md` @ `b2a7766` with KEEP (K1-K4)/ADD
(A1-A4)/DON'T-ADD (D1-D2) verdicts and the field-consensus finding; (b) the
human amendment to ~2,500 tokens measured on this repo's own r2 lanes
(2,000-3,600 tokens with citations; URLs alone 138-966 tokens;
double-citation waste removed by single per-lane source lists); (c) the
grill's third consecutive catch (2 blocking defects: PS exit-code vacuity
RG1, unenumerable touch set RG7, plus 4 sharpenings), with the
`loop-hardening` (1st) / `v4-docs` (2nd) precedent named; (d) D12
(intermittent, def-asymmetric CLI subagent tool strip: builder spawn held
both shells, two consecutive judge spawns lost both, first/last positional
pattern falsified) and the composite-judgment precedent (cross-family codex
judge at workspace-write with post-hoc tree audit, plus a cold headless
`claude -p` session for the gate the codex sandbox cannot run — Git Bash
dies with Win32 error 5 under the codex sandbox on this machine); (e) freeze
`1b2fd90` / lane `3f46f09` / merge `e39d0f4` SHAs, all in the opening
paragraph. §§1-10 untouched (verified: `git diff --stat -- DESIGN.md` below
shows one hunk, a pure append after the existing `## 10.` section's closing
line). QG3: PASS.

## Diff stat

```
$ git diff --stat -- README.md DESIGN.md
 DESIGN.md | 47 +++++++++++++++++++++++++++++++++++++++++++++++
 README.md | 15 ++++++++++-----
 2 files changed, 57 insertions(+), 5 deletions(-)

$ git diff --shortstat -- README.md DESIGN.md
 2 files changed, 57 insertions(+), 5 deletions(-)

$ git status --short
 M DESIGN.md
 M README.md
```
Total changed lines on README.md+DESIGN.md (insertions+deletions): 62.
Spec target ~120, gate cap 200 — well under both. Touch set matches
BOUNDARIES exactly (README.md, DESIGN.md, plus this lane report);
`docs/gates/` untouched (not opened for write this session; confirmed by
`git status --short` showing no `docs/gates/` entry).

QG4/QG5 (touch-set + size, `git diff <freeze-sha>..HEAD`) are the
architect's post-flight per the dispatch block; not run here as instructed.

STATUS: COMPLETE
