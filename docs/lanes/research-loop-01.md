# Lane report: research-loop-01

Slice: research-loop. Freeze SHA: 1b2fd90. Branch: slice/research-loop.
Executor for all commands below: Bash (Git Bash), except RG1's second
invocation which is PowerShell as the gate specifies.

## PHASE 0 disagreements

None that required a ruling. Checked before concluding the spec sound:

1. RG4's exact-string requirement uses ASCII hyphens ("3-10 tool calls" etc.)
   where the spec prose itself uses en-dashes ("3–10 searches"). Resolved by
   writing the three gate-required phrases with ASCII hyphens verbatim
   (confirmed against `docs/gates/research-loop.md` lines 60-62) while
   leaving surrounding prose in the files' existing en-dash voice.
2. Confirmed `skills/architect/dispatch.md:28-57` already contains the
   brain/brawn resolution-order language (repo `.architect/config`, then
   `~/.architect/config`, then dispatch.md tier-down defaults) to point to
   without duplicating the alias table.
3. Confirmed `skills/architect-research/lanes.md` had an existing single
   Codex-unavailable fallback sentence to extend (R5), and
   `skills/architect/research.md` had none (R5's "add an equivalent"
   instruction, not "extend", matches what was actually in the file).
4. Confirmed `tests/validate_skills.py` `check_skill_text_size()` only sums
   `skills/architect/{SKILL.md,loop.md,dispatch.md}` non-blank lines against
   an 800-line ceiling — none of my three lane files are in that guard.

No rulings requested.

## RG1 — validator green in both shells

Git Bash:
```
$ uv run tests/validate_skills.py; echo "EXIT:$?"
OK - 2 skills validated, v4 contracts clean
EXIT:0
```

PowerShell (via Git Bash per the gate's exact invocation):
```
$ powershell -NoProfile -ExecutionPolicy Bypass -Command 'uv run tests/validate_skills.py; exit $LASTEXITCODE'
OK - 2 skills validated, v4 contracts clean
EXIT:0
```
RG1: PASS.

## RG2 — return contract (R1)

```
$ grep -n "2,500 tokens" skills/architect-research/lanes.md
17:without writing anything). OUTPUT: markdown findings, ≤ ~2,500 tokens

$ grep -n "2,500 tokens" skills/architect-research/SKILL.md
110:  capped at ≤ ~2,500 tokens (~10 KB): every source URL appears EXACTLY ONCE,

$ grep -n "numbered source list" skills/architect-research/lanes.md
24:without flagging it. End with a numbered source list — every source URL

$ grep -n "numbered source list" skills/architect/research.md
70:- End with a numbered source list — every source URL appears EXACTLY ONCE,
```
Read check: lanes.md line 24 ("every source URL appears EXACTLY ONCE") and
SKILL.md lines 109-112 ("every source URL appears EXACTLY ONCE, in a
numbered source list ... findings cite sources by tag"); cap phrased as
"≤ ~2,500 tokens (~10 KB)" — a ceiling, not a target — in both files.
RG2: PASS.

## RG3 — draft-as-state gap round (R2)

```
$ grep -n "draft.md" skills/architect-research/SKILL.md
117:of the final report at `.architect/research/<topic>.draft.md` (gitignored

$ grep -n "do-not-rechase" skills/architect-research/SKILL.md
122:carries forward into a **do-not-rechase list** that every gap-lane block must

$ grep -n "SUPPORTED / THIN / EMPTY" skills/architect-research/SKILL.md
119:**SUPPORTED / THIN / EMPTY** status against the brief. Gap lanes are designed
```
Read check: SKILL.md step 4 (lines 114-127) — orchestrator writes/updates
the skeleton draft after wave 1 ("write (or update, on round 2)"); gap lanes
designed from THIN/EMPTY sections; gap-lane blocks carry the do-not-rechase
list; heading retains "(max 2 extra rounds, usually 1)" and body retains
"Hard stop after two refinement rounds". RG3: PASS.

## RG4 — tool-call budgets (R3)

```
$ grep -n "3-10 tool calls" skills/architect-research/SKILL.md
26:- **Simple fact-find** → answer directly or 1 researcher, 3-10 tool calls.

$ grep -n "10-15 tool calls" skills/architect-research/SKILL.md
29:  perspectives, 10-15 tool calls each, no scout — you already know the

$ grep -n "15-25 tool calls" skills/architect-research/SKILL.md
32:  designed fan-out of 4–6 researchers, 15-25 tool calls each. Google's
```
Read check: SKILL.md line 24 defines a tool call ("one search OR one page
fetch"); line 33-34 brackets the survey tier ("Google's published research
envelope brackets this tier: ~80 searches ≈ $1–3/task standard, ~160 ≈
$3–7 max"). RG4: PASS.

## RG5 — brain/brawn config parity (R5)

```
$ grep -n "~/.architect/config" skills/architect-research/SKILL.md
77:`.architect/config`, then user `~/.architect/config`, then the tier-down

$ grep -n "~/.architect/config" skills/architect/research.md
11:`.architect/config`, then user `~/.architect/config`, then the tier-down

$ grep -n "dispatch.md" skills/architect-research/SKILL.md
78:defaults in `skills/architect/dispatch.md`. One fresh researcher per lane,

$ grep -n "default-brawn example" skills/architect-research/SKILL.md
79:all parallel, in the background — this is the default-brawn example

$ grep -n "default-brawn example" skills/architect/research.md
20:background — this is the default-brawn example (codex/tier-down):
```
Read check: both files state resolution order as repo `.architect/config`,
then user `~/.architect/config`, then `skills/architect/dispatch.md`
tier-down defaults; the codex command in both files is labeled "the
default-brawn example (codex/tier-down)", not a pin; both files carry a
claude-fallback sentence covering a configured claude brawn ("If resolved
brawn is a claude row") as well as codex-absent ("or Codex is unavailable" /
"Codex is unavailable"). RG5: PASS.

## RG6 — research handoff (R4)

```
$ grep -in "research handoff" skills/architect-research/SKILL.md
171:Commit the report — this is the **research handoff**: its Open-questions
177:A later session resumes work by reading the committed research handoff and
```
Read check: step 6 (line 171-173) names the committed report the research
handoff and its Open-questions section as the next round's input; step 7
(lines 175-181) states a later session resumes by reading the committed
research handoff and dispatching gap lanes against its Open-questions
section instead of restarting the harness. RG6: PASS.

## Diff stat (working tree, uncommitted — builder does not commit)

```
$ git diff --stat -- skills/
 skills/architect-research/SKILL.md | 66 +++++++++++++++++++++++++-------------
 skills/architect-research/lanes.md | 18 ++++++-----
 skills/architect/research.md       | 23 +++++++++----
 3 files changed, 70 insertions(+), 37 deletions(-)

$ git diff --shortstat
 3 files changed, 70 insertions(+), 37 deletions(-)

$ git status --short
 M skills/architect-research/SKILL.md
 M skills/architect-research/lanes.md
 M skills/architect/research.md
```
Total changed lines (insertions+deletions): 107. Spec target ~200; gate
RG8 cap 400 — well under both. Touch set matches BOUNDARIES exactly (three
files listed plus this report); `docs/gates/` untouched (confirmed by not
opening it for write and by `git status --short` showing no gates/ entry).

RG7/RG8 are the architect's post-flight per the dispatch block; not run
here as instructed.

STATUS: COMPLETE
