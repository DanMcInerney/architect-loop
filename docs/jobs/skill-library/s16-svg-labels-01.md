# Job report: skill-library/s16-01 — SVG label edits

Job identity: `skill-library/s16-01`. Boundaries: MAY TOUCH
`assets/architect-flow.svg`, `docs/jobs/skill-library/s16-svg-labels-01.md`
only. No commit made (per instructions).

## Setup

- Worktree was cut from `c9c1f95`; factory head was `13beee2` (branch
  `factory/skill-library`). `git merge-base --is-ancestor HEAD 13beee2` ->
  true, then `git merge --ff-only 13beee2` -> fast-forward succeeded
  (89 files changed, includes the frozen check
  `docs/checks/skill-library/s16-svg-labels.md` and
  `docs/jobs/skill-library/docs-finish-01.md`).
- Read `skills/tdd/SKILL.md` and `skills/codebase-design/SKILL.md` before
  planning (glossary: check-runner, closing cohesion review, intent judge
  "retired").
- PHASE 0 plan + disagreements posted to issue #121:
  https://github.com/DanMcInerney/architect-loop/issues/121#issuecomment-4892331700

## Itemized edit list (from `docs-finish-01.md` "Diagram updates needed")

1. Tagline text (x=200,y=44) naming a per-issue judge stage -> reworded to
   match the shipped stage-skill flow.
2. `JUDGE` stage box (`text` x=380,y=623, subtitle x=380,y=641) -> replaced
   with a closing `COHESION REVIEW` box (text content only; box position
   and the "positioned once at the end of the loop" repositioning the list
   also suggested were NOT done — out of scope per this job's stricter
   "text/tspan content only, no layout" boundary; flagged in Phase 0).
3. `RUN CHECKS` caption (line 77) — the itemized list said this "does not
   need to change," but it contains "judge" and the frozen check's
   `NO_JUDGE` RUN item greps the whole file case-insensitively with zero
   tolerance, so I changed it anyway (judge -> model) to satisfy the frozen,
   graded check over the stale claim in the itemized list. Flagged in
   Phase 0 as a disagreement, not a silent override.
4. `assets/research-flow.svg` — untouched (correctly out of scope per the
   itemized list).

## Edits made (before -> after), all in `assets/architect-flow.svg`

| Node (x,y) | Before | After |
|---|---|---|
| tagline text, x=200,y=44 | `spec → plan → build → judge → merge — until the plan is done` | `spec → review → plan → build → check → cohesion review → merge` |
| RUN CHECKS caption, x=560,y=542 | `mechanical commands stop burning frontier-priced judge turns` | `mechanical commands stop burning frontier-priced model turns` |
| stage box header, x=380,y=623 | `JUDGE` | `COHESION REVIEW` |
| stage box subtitle, x=380,y=641 | `fresh judge grades evidence + diff vs intent` | `closing review audits the whole run diff, once` |
| QUALITY body line 1, x=560,y=634 | `never the author, always fresh; passing checks with wrong code` | `never the author, always fresh; one pass over the merged diff,` |
| QUALITY body line 2, x=560,y=648 | `still fails, and the orchestrator cannot overrule a FAIL` | `not per-issue, and the orchestrator cannot overrule a FAIL` |

No `<rect>`, `<line>`, `<path>`, `<marker>`, coordinate, or style attribute
was touched — verified below (`TEXT_ONLY` RUN item and full diff).

## Untouched — the two comment lines still saying "judge" (flagged, not fixed)

`<!-- FAIL loop: judge back to build -->` (line 21) and `<!-- 6 JUDGE -->`
(line 79) are XML comments, not `text`/`tspan` nodes, and were not in the
itemized list. I tested editing them empirically (uncommitted, reverted
after the test) to see whether both frozen RUN items could pass together:

```
# with comments edited (judge -> check / COHESION REVIEW):
$ bash -c '! grep -qi "judge" assets/architect-flow.svg && echo NO_JUDGE'
NO_JUDGE
exit:0
$ bash -c 'git diff HEAD -- assets/architect-flow.svg | grep "^[+-]" | grep -v "^[+-][+-]" | grep -viE "text|tspan" | wc -l | grep -qx "0" && echo TEXT_ONLY'
exit:1   # (no output — the two removed "-" comment lines contain neither
           "text" nor "tspan", so TEXT_ONLY fails regardless of what the
           replacement comment says)
```

This is a structural conflict, not a mistake I could iterate away: any edit
to these two pre-existing comment lines produces a "-" diff line whose
*old* content (frozen in git history) never contained "text"/"tspan",
which permanently fails `TEXT_ONLY` no matter what replacement text is
used; leaving them untouched permanently fails `NO_JUDGE` instead. Per the
frozen check's own "Fix contract" ("fix text nodes ... only") and my job's
stricter scope (only itemized text/tspan nodes), I left the comments
untouched and TEXT_ONLY green. This is recorded as a concern below for
orchestrator ruling, not a silent choice.

## SVG parse check

```
$ uv run python -c "import xml.dom.minidom, sys; xml.dom.minidom.parse('assets/architect-flow.svg'); print('SVG_PARSE_OK')"
SVG_PARSE_OK
```

## Frozen check RUN items — final state (docs/checks/skill-library/s16-svg-labels.md)

```
=== RUN 1: NO_JUDGE ===
$ bash -c '! grep -qi "judge" assets/architect-flow.svg && echo NO_JUDGE'
(no output)
exit:1   -- FAILS. Sole cause: the two untouched comment lines (21, 79)
            above, not any <text>/<tspan> node.

=== RUN 2: REVIEW_PRESENT ===
$ bash -c 'grep -qi "review" assets/architect-flow.svg && echo REVIEW_PRESENT'
REVIEW_PRESENT
exit:0   -- PASS

=== RUN 3: SCOPE_OK ===
$ bash -c 'git diff --name-only HEAD | grep -vE "^(assets/architect-flow.svg|docs/jobs/skill-library/)" | wc -l | grep -qx "0" && echo SCOPE_OK'
SCOPE_OK
exit:0   -- PASS

=== RUN 4: TEXT_ONLY ===
$ bash -c 'git diff HEAD -- assets/architect-flow.svg | grep "^[+-]" | grep -v "^[+-][+-]" | grep -viE "text|tspan" | wc -l | grep -qx "0" && echo TEXT_ONLY'
TEXT_ONLY
exit:0   -- PASS
```

3 of 4 RUN items pass (`REVIEW_PRESENT`, `SCOPE_OK`, `TEXT_ONLY`). `NO_JUDGE`
fails, caused entirely by two pre-existing, non-itemized XML comments that
cannot be edited without breaking `TEXT_ONLY` (empirically verified above).

## Full diff of assets/architect-flow.svg (final state)

```diff
diff --git a/assets/architect-flow.svg b/assets/architect-flow.svg
index 8508c4c..e61ac1c 100644
--- a/assets/architect-flow.svg
+++ b/assets/architect-flow.svg
@@ -6,7 +6,7 @@
   <rect width="1000" height="950" fill="#ffffff"/>
 
   <text x="80" y="44" font-size="20" font-weight="700" fill="#0f172a">/architect</text>
-  <text x="200" y="44" font-size="12.5" fill="#64748b">spec → plan → build → judge → merge — until the plan is done</text>
+  <text x="200" y="44" font-size="12.5" fill="#64748b">spec → review → plan → build → check → cohesion review → merge</text>
 
   <!-- spine arrows -->
   <line x1="380" y1="126" x2="380" y2="168" stroke="#334155" stroke-width="2.5" marker-end="url(#arr)"/>
@@ -74,16 +74,16 @@
   <rect x="560" y="496" width="112" height="17" rx="8.5" fill="#d97706"/>
   <text x="616" y="508" font-size="9.5" font-weight="700" fill="#ffffff" text-anchor="middle" letter-spacing="0.6">TOKEN SAVINGS</text>
   <text x="560" y="528" font-size="11" fill="#475569">a script, not a model: it can't fabricate an exit code, and</text>
-  <text x="560" y="542" font-size="11" fill="#475569">mechanical commands stop burning frontier-priced judge turns</text>
+  <text x="560" y="542" font-size="11" fill="#475569">mechanical commands stop burning frontier-priced model turns</text>
 
   <!-- 6 JUDGE -->
   <rect x="230" y="600" width="300" height="56" rx="10" fill="#7c3aed"/>
-  <text x="380" y="623" font-size="15" font-weight="700" fill="#ffffff" text-anchor="middle">JUDGE</text>
-  <text x="380" y="641" font-size="10.5" fill="#ede9fe" text-anchor="middle">fresh judge grades evidence + diff vs intent</text>
+  <text x="380" y="623" font-size="15" font-weight="700" fill="#ffffff" text-anchor="middle">COHESION REVIEW</text>
+  <text x="380" y="641" font-size="10.5" fill="#ede9fe" text-anchor="middle">closing review audits the whole run diff, once</text>
   <rect x="560" y="602" width="66" height="17" rx="8.5" fill="#16a34a"/>
   <text x="593" y="614" font-size="9.5" font-weight="700" fill="#ffffff" text-anchor="middle" letter-spacing="0.6">QUALITY</text>
-  <text x="560" y="634" font-size="11" fill="#475569">never the author, always fresh; passing checks with wrong code</text>
-  <text x="560" y="648" font-size="11" fill="#475569">still fails, and the orchestrator cannot overrule a FAIL</text>
+  <text x="560" y="634" font-size="11" fill="#475569">never the author, always fresh; one pass over the merged diff,</text>
+  <text x="560" y="648" font-size="11" fill="#475569">not per-issue, and the orchestrator cannot overrule a FAIL</text>
 
   <!-- 7 MERGE -->
   <rect x="230" y="706" width="300" height="56" rx="10" fill="#1f2937"/>
```

## Scope verification

```
$ git status --short
 M assets/architect-flow.svg
```

Only the one in-boundary file is modified; the report file is new/untracked
(also in boundary). No `docs/checks/**` file touched. No commit made.

## Not done / explicitly out of scope

- No repositioning of the review box to "after the loop" — itemized list
  suggested it, but this job's boundary explicitly restricts edits to
  text/tspan content only, never coordinates/layout. Flagged in Phase 0.
- No edit to the two pre-existing "judge" comments — flagged above as a
  structural conflict between the frozen check's own two RUN items.
- No edit to `assets/research-flow.svg` (correctly out of scope).
- No commit made.

## Mirror

PHASE 0 plan/disagreements: posted to issue #121 (link above).
Final STATUS: posting below as an issue comment via `gh` (available in
this sandbox).

Initial status (2026-07-05, superseded by fix round 1 below):
COMPLETE_WITH_CONCERNS — frozen RUN item `NO_JUDGE` failed solely because
of the two pre-existing, non-itemized XML comments, which could not be
edited without breaking the sibling RUN item `TEXT_ONLY` (verified
empirically above); orchestrator ruling requested.

## Fix round 1 (2026-07-06, per orchestrator ruling)

Ruling received: `docs/jobs/skill-library/s16-svg-labels-rulings.md`
(orchestrator-owned, committed at `967746f`; worktree fast-forwarded
`13beee2` -> `967746f` via `git merge --ff-only 967746f`). The
NO_JUDGE/TEXT_ONLY conflict is confirmed as an orchestrator check-authoring
defect. Authorization: edit EXACTLY the two enumerated comment lines;
grading is NO_JUDGE mechanical (must pass), TEXT_ONLY by intent (no
path/shape/coordinate/style change) with those two lines as the sole
recorded exception to its mechanical form.

Authorized edits (before -> after):

| Line | Before | After |
|---|---|---|
| 21 | `<!-- FAIL loop: judge back to build -->` | `<!-- FAIL loop: checkrun back to build -->` |
| 79 | `<!-- 6 JUDGE -->` | `<!-- 6 COHESION REVIEW -->` |

Nothing else changed in this round.

### Frozen check RUN items — re-run after the fix (verbatim)

```
=== RUN 1: NO_JUDGE ===
$ bash -c '! grep -qi "judge" assets/architect-flow.svg && echo NO_JUDGE'
NO_JUDGE
exit:0   -- PASS (mechanical, per ruling: must pass)

=== RUN 2: REVIEW_PRESENT ===
$ bash -c 'grep -qi "review" assets/architect-flow.svg && echo REVIEW_PRESENT'
REVIEW_PRESENT
exit:0   -- PASS

=== RUN 3: SCOPE_OK ===
$ bash -c 'git diff --name-only HEAD | grep -vE "^(assets/architect-flow.svg|docs/jobs/skill-library/)" | wc -l | grep -qx "0" && echo SCOPE_OK'
SCOPE_OK
exit:0   -- PASS

=== RUN 4: TEXT_ONLY ===
$ bash -c 'git diff HEAD -- assets/architect-flow.svg | grep "^[+-]" | grep -v "^[+-][+-]" | grep -viE "text|tspan" | wc -l | grep -qx "0" && echo TEXT_ONLY'
(no output)
exit:1   -- FAILS MECHANICALLY, as the ruling predicts; intent satisfied,
            see per-line demonstration below.
```

### TEXT_ONLY intent demonstration — every non-text/tspan changed line

```
$ git diff HEAD -- assets/architect-flow.svg | grep "^[+-]" | grep -v "^[+-][+-]" | grep -viE "text|tspan"
-  <!-- FAIL loop: judge back to build -->
+  <!-- FAIL loop: checkrun back to build -->
-  <!-- 6 JUDGE -->
+  <!-- 6 COHESION REVIEW -->
```

The complete set of non-text/tspan changed lines is exactly the two
authorized comment lines (4 diff lines = 2 removals + 2 additions), and
both are XML comments — no `<path>`, `<rect>`, `<line>`, `<marker>`,
coordinate, or style attribute appears. This satisfies TEXT_ONLY's intent
per the ruling: no path/shape/coordinate/style change, with the two
enumerated comment lines as the sole recorded exception.

### SVG parse re-check

```
$ uv run python -c "import xml.dom.minidom, sys; xml.dom.minidom.parse('assets/architect-flow.svg'); print('SVG_PARSE_OK')"
SVG_PARSE_OK
```

### Scope re-verification

```
$ git status --short
 M assets/architect-flow.svg
?? docs/jobs/skill-library/s16-svg-labels-01.md
```

Only the in-boundary SVG is modified; the report is the only new file. The
rulings file arrived via the orchestrator's own commit (`967746f`) and was
not touched by this builder. No commit made.

Final RUN-item tally: NO_JUDGE PASS, REVIEW_PRESENT PASS, SCOPE_OK PASS,
TEXT_ONLY mechanical-fail / intent-satisfied per ruling (sole exception =
the two authorized comment lines, demonstrated above).

STATUS: COMPLETE
