# Job report: skill-library/s11-wording-reconciliation-01

Job: reconcile the five Pocock-derived stage skills to `docs/spec/skill-library.md`
`## Wording policy`. Builder: architect-builder (job skill-library/s11-01).
Worktree fast-forwarded to freeze commit 7bf8fae before work
(`git merge --ff-only` output recorded in session; ancestry check exit 0).

Sources: all nine originals fetched 2026-07-05 from
`raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/`
(`codebase-design/{SKILL,DEEPENING,DESIGN-IT-TWICE}.md`, `tdd/{SKILL,tests,mocking}.md`,
`to-prd/SKILL.md`, `to-issues/SKILL.md`, `code-review/SKILL.md`) into
`.architect/tmp/pocock/` — all HTTP 200. Executor for every RUN item below:
Git Bash via the Bash tool (the check's preferred executor).

PHASE 0 posted: issue #114 comment 4888807378 (plan + 3 interpretation notes:
omissions-vs-conciseness resolution, attribution replacement not duplication,
validator-pinned wordings in tests/validate_skills.py:103-136).

## Line-count evidence (non-blank, `grep -c '[^[:space:]]'`)

| Skill | Files | Before | After | Delta |
|---|---|---|---|---|
| codebase-design | SKILL+DEEPENING+DESIGN-IT-TWICE | 79+25+25 = 129 | 78+25+25 = 128 | -1 |
| tdd | SKILL+tests+mocking | 46+70+43 = 159 | 47+70+42 = 159 | 0 |
| to-spec | SKILL | 62 | 62 | 0 |
| to-issues | SKILL | 68 | 67 | -1 |
| cohesion-review | SKILL | 57 | 57 | 0 |

No skill's net non-blank count increased. Diffstat: 9 files, 87 insertions,
88 deletions; `git status --porcelain` shows only the five skill dirs modified.

## Divergence tables

Classification: workflow-necessity | evidence:<tag> | reverted. "Reverted"
rows were changed in this job to Pocock's wording (verbatim or minimally
adjusted: US spelling, bullet reflow). Pocock line refs are to the fetched
originals in `.architect/tmp/pocock/`.

### skills/codebase-design/SKILL.md (vs codebase-design_SKILL.md)

| Location | Classification | Rationale |
|---|---|---|
| frontmatter description | workflow-necessity | names factory context/trigger surface (s1 judge item); [G4] front-load trigger words |
| :13 attribution comment | workflow-necessity | MIT attribution ruling, spec `## Open human decisions`; s1 RUN 3 |
| :17-20 opening para | reverted | restored his "placed at a clean seam"/"The aim is..." (Pocock :8); kept "or a factory issue" clause (workflow); behaviour->behavior spelling adjusted |
| :24-26 glossary intro | reverted + workflow-necessity | restored his "Use these terms exactly — don't substitute..."/"Consistent language is the whole point" (Pocock :12); ban-list phrasing must match validator exemption strings (tests/validate_skills.py:103-110, out of boundary); factory bans (issue, frozen check) kept |
| :30-37 design entries one-line | evidence:[G1] | same content as Pocock :14-28, shorter; conciseness tiebreak |
| :30 Module "whole vertical slice" | workflow-necessity | factory slice vocabulary replaces his "tier-spanning slice" |
| :39-56 factory glossary block | workflow-necessity | spec one-vocabulary constraint; s1 RUN 5 greps these exact terms |
| `## Deep vs. shallow` prose (no ASCII diagrams) | evidence:[G1],[F1] | diagrams+question list (Pocock :32-58) said same thing longer; s1 caps combined file at 240 lines |
| Principles: depth-property bullet | evidence:[G1] | compression of Pocock :62, same meaning |
| Principles: deletion test | reverted | now his "imagine deleting... pass-through... reappears across N callers... earning its keep" (Pocock :63) |
| Principles: test surface | reverted | now his "If you want to test past the interface, the module is probably the wrong shape" (Pocock :64) |
| Principles: one adapter | reverted | now his "One adapter means a hypothetical seam; two adapters means a real one. Don't introduce a seam unless..." (Pocock :65) |
| Testability bullets | reverted + evidence:[G1] | lead phrases restored to his "Accept dependencies, don't create them"/"Return results, don't produce side effects"/"Small surface area: fewer methods = fewer tests needed..." (Pocock :71,83,95); code blocks stay inlined as prose (shorter, same examples) |
| `## Relationships` omitted | evidence:[F1] | enumerated restatement of the glossary; prescriptive scaffolding Fable does unprompted; budget |
| `## Rejected framings` omitted | evidence:[F1] | design-history prose, not steering; budget |
| Going deeper bullet 1 | reverted | now his "dependency categories, seam discipline, and replace-don't-layer testing" (Pocock :113) |
| Going deeper bullet 2 | reverted | now his "design the interface several radically different ways, then compare on depth, locality, and seam placement" (Pocock :114); "dispatch parallel subagents" kept (factory dispatch vocabulary) |

### skills/codebase-design/DEEPENING.md (vs codebase-design_DEEPENING.md)

| Location | Classification | Rationale |
|---|---|---|
| numbered list replaces ### subsections | evidence:[G1] | same four categories, fewer lines |
| :12 category 2 | reverted | restored his "local test stand-in (PGLite for Postgres, ...)"/"Deepenable if the stand-in exists" (Pocock :15) |
| category 3 "Recommendation shape" quote omitted | evidence:[F1] | canned response template = prescriptive scaffolding |
| seam discipline: "single-adapter seam is just indirection" omitted | evidence:[G1] | rule already stated in the same bullet; conciseness tiebreak |
| `## Testing across the seam` heading + first two bullets | workflow-necessity | s1 judge item requires tying each dependency category to testing strategy across the seam |
| old-tests bullet | reverted | now his "Old unit tests on shallow modules become waste once tests at the deepened module's interface exist" (Pocock :34) |
| final bullet | reverted | now his "observable outcomes through the interface, not internal state"/"has to change when the implementation changes" (Pocock :36-37, two bullets merged) |

### skills/codebase-design/DESIGN-IT-TWICE.md (vs codebase-design_DESIGN-IT-TWICE.md)

| Location | Classification | Rationale |
|---|---|---|
| user-facing steps removed (show user, present sequentially, recommendation-for-user) | workflow-necessity | orchestrator-invoked mid-run, no user interview surface; s1 judge item names this rewording |
| :3-4 "your first idea is unlikely to be the best" | reverted | his sentence restored (Pocock :3) |
| CONTEXT.md-vocabulary brief instruction omitted | workflow-necessity | factory has no CONTEXT.md convention; codebase-design glossary is the shared vocabulary |
| two ## sections replace ## Process + 3 ### steps | evidence:[G1] | same process, fewer lines |
| constraint list (minimize/flexibility/common case/ports) | evidence:[G1] | compression of his agent briefs (Pocock :26-28), same four constraints |
| "contrast by depth (…), locality (…), and seam placement" | reverted | his verb + axes restored (Pocock :42); our unevidenced "never on line count or style" addition dropped |
| "a menu of options is not a decision" | workflow-necessity | replaces his user-facing "the user wants a strong read, not a menu" (no user present) |

### skills/tdd/ (SKILL.md, tests.md, mocking.md vs tdd_*)

| Location | Classification | Rationale |
|---|---|---|
| SKILL.md description | workflow-necessity | factory builder trigger (ship job, pre-agreed seams); [G4] |
| SKILL.md:6 attribution | workflow-necessity | MIT ruling; s5 RUN 3 |
| SKILL.md intro compressed | evidence:[G1] | drops his mid-sentence section enumeration (Pocock :8), same instruction |
| CONTEXT.md/ADR line omitted | workflow-necessity | no CONTEXT.md convention; glossary preloaded via codebase-design |
| `## Seams are pre-agreed, not interviewed` | workflow-necessity | replaces his "confirm them with the user"/"Ask:" (Pocock :22-24); seams live in issue body + spec; s5 judge item |
| frozen-checks paragraph (SKILL.md:21-24) | workflow-necessity | docs/checks/ read-only, distinct from builder's own tests; s5 judge item |
| "through the seam" for "public interfaces" | workflow-necessity | glossary cohesion (seam/interface vocabulary) |
| anti-pattern bullets compressed | evidence:[G1] | same three anti-patterns as Pocock :28-30, shorter |
| Rules: Red before green | reverted | his full sentence restored: "only enough code to pass it. Don't anticipate future tests or add speculative features." (Pocock :34) |
| Rules: One slice at a time | reverted | his "per cycle" restored (Pocock :35) |
| Rules: "Never refactor while RED" | workflow-necessity | s5 judge anchor phrase; his pointer to a `code-review` skill (Pocock :36) targets a skill that does not exist in this library |
| Rules: "Mock at system boundaries only" bullet | workflow-necessity | s5 judge item; one-line summary of his mocking.md at the point of use |
| `## Report only what you proved` | evidence:[F2] | Anthropic evidence-grounded progress claims; s5 judge item |
| tests.md:1 attribution | workflow-necessity | MIT ruling |
| tests.md seam substitutions (headings, characteristics, comments, paymentService->paymentModule) | workflow-necessity | glossary bans API/service substitutes; validator lint + cohesion contract |
| tests.md "// GOOD: tests observable behavior" | reverted | our "through the public seam" suffix dropped; his comment restored (Pocock tests :8) |
| tests.md "Survives internal refactors" | reverted | his "internal" restored (Pocock tests :21) |
| tests.md "Test breaks when refactoring without behavior change" | reverted | his red-flag wording restored (Pocock tests :43) |
| tests.md tautological intro | reverted | our "— it can never disagree with the code" tail dropped; his shorter form (Pocock tests :63) |
| tests.md `## Factory seams` section | workflow-necessity | issue-body seams; frozen checks are read-only grading, never fixtures |
| mocking.md:1 attribution | workflow-necessity | MIT ruling |
| mocking.md "Mock at **system boundaries** only:" | reverted | our defining clause dropped; his line restored (Pocock mocking :3) |
| mocking.md "External third-party systems" | workflow-necessity | his "External APIs" uses the banned API substitute |
| mocking.md "prefer a real test DB" / "Time/randomness" / "File system (sometimes)" / "Anything you control" | reverted | his shorter bullets restored (Pocock mocking :6-8,14) |
| mocking.md "Your own modules" | evidence:[G1] | shorter than his "Your own classes/modules"; module covers both per glossary |
| mocking.md "design interfaces that are easy to mock" | reverted | his sentence restored (Pocock mocking :18) |
| mocking.md "**1. Use dependency injection**" + lead sentence + code comments | reverted | his heading, sentence, and bare "// Easy to mock"/"// Hard to mock" comments restored (Pocock mocking :20-30) |
| mocking.md heading 2 "one function per external operation over a generic fetcher" | evidence:[G1] | merges his heading + explanation sentence (Pocock mocking :37-39) into one line |
| mocking.md `const external` identifier | workflow-necessity | his `const api` uses the banned API substitute |
| mocking.md GOOD/BAD comments in fetcher example | reverted | his "each function is independently mockable"/"mocking requires conditional logic inside the mock" restored (Pocock mocking :42,49) |
| mocking.md closing sentence | evidence:[G1] | his four bullets (Pocock mocking :55-59) compressed to one sentence; TS-specific "type safety per endpoint" dropped |

### skills/to-spec/SKILL.md (vs to-prd_SKILL.md)

| Location | Classification | Rationale |
|---|---|---|
| name/description | workflow-necessity | stage skill of the factory (spec not PRD, orchestrator-invoked at intake) |
| :10 attribution | reverted-to-canonical | replaced variant "Shape adapted..." line with the exact line the frozen s11 RUN 1 greps |
| opening synthesize/do-not-interview | workflow-necessity | his rule kept in substance (Pocock :7); sources renamed to grounding/intake/research; s2 RUN 5 anchors present |
| step 1 (map + codebase-design vocabulary) | workflow-necessity | replaces his repo-exploration + domain-glossary/ADR line; one-vocabulary constraint |
| step 2 seams | reverted (partial) | "Existing seams are preferred to new ones, at the highest point possible; the ideal number is one" restored from Pocock :15; recording under `## Implementation decisions` kept (workflow); his "Check with the user" dropped (workflow: timed rulings only) |
| step 3 paths/snippets | reverted | his to-prd wording restored: "Do not include specific file paths or code snippets... outdated very quickly... encodes a decision more precisely than prose can... came from a prototype. Trim to the decision-rich parts." (Pocock :55-57) |
| step 4 timed-ruling routing | workflow-necessity | open questions go through the timed-ruling protocol, never direct interview |
| step 5 tracking issue + approve-by-comment forms | workflow-necessity | replaces his tracker publish + ready-for-agent label; factory approval protocol |
| template sections (`## Goal` ... `## Approval record`) | workflow-necessity | load-bearing spec template, frozen s2/s11 RUN greps; replaces his PRD template (Problem Statement/User Stories/...) |
| his "LONG, numbered list of user stories" omitted | evidence:[F1] | volume-mandating scaffolding; the factory spec shape has no user-story section |
| template intro "names are load-bearing... keep them exact" | evidence:[G2] | explicit success criterion for the approval/decomposition consumers |

### skills/to-issues/SKILL.md (vs to-issues_SKILL.md)

| Location | Classification | Rationale |
|---|---|---|
| description | workflow-necessity + evidence:[G4] | trigger words for the factory decomposition stage; disable-model-invocation matches his |
| :13 attribution | reverted-to-canonical | variant "(MIT License) ... Wording below is original" replaced; the original-wording contract is superseded |
| intro (dispatch-ready under tracking issue; no re-quiz) | workflow-necessity | replaces his "### 4. Quiz the user" loop; approval already covers the plan, hard stop/oddity escalation only |
| §1 glossary hold | workflow-necessity | one-vocabulary constraint; ban-list phrasing pinned by validator exemption strings |
| §1 prefactoring line | evidence:[G1] | his quote kept verbatim ("Make the change easy..."), lead-in compressed (Pocock :23) |
| §2 structural-before-behavioral + blocking edges | workflow-necessity | spec Target flow 5; his "Any prefactoring should be done first" generalized into the factory ordering rule |
| §2 oddity rule (wart/variation/three-strike) | workflow-necessity | factory escalation ladder + adapter-count rule from codebase-design; s3 judge item |
| §3 slice definition | reverted | his vertical-slice-rules wording restored: "narrow but complete path through every layer... demoable or verifiable on its own — never a horizontal slice of one layer" (Pocock :27-34); our defect-remedy sentence dropped |
| §3 paths/snippets | reverted | his wording restored: "Avoid specific file paths or code snippets in issue prose — they go stale fast... trim to the decision-rich parts" (Pocock :68) |
| §4 disjoint parallel frontier | workflow-necessity | file-disjoint dispatch; spec design constraint (shared-file parallelism halves pass rates) |
| §5 interface contracts | workflow-necessity | producer/consumer slices build in isolation; no Pocock equivalent |
| §6 body shape (checks path, MAY/MUST NOT TOUCH, skeleton, run marker) | workflow-necessity | replaces his issue-template; every field is a frozen-check or dispatch dependency; s3 RUN 3 greps them |
| §7 publish order | workflow-necessity | his blockers-first rule (Pocock :57) extended with structural-first + real-ID rule |
| §7 "Done when..." line | evidence:[G2] | explicit stopping rule for a long-running decomposition |
| his "Do NOT close or modify any parent issue" omitted | workflow-necessity | the factory orchestrator maintains the tracking issue as the run dashboard; the rule would be false here |

### skills/cohesion-review/SKILL.md (vs code-review_SKILL.md)

| Location | Classification | Rationale |
|---|---|---|
| name/description | workflow-necessity | closing whole-run review, one fresh orchestrator-model subagent, explicit invocation (spec Target flow 8) |
| :12 attribution added | workflow-necessity | s11 directive; two-axis shape is adapted from his code-review |
| Standards axis (+ Fowler smell baseline) replaced by Cohesion axis | workflow-necessity | spec inventory: "two-axis output shape (cohesion / spec) after Pocock /code-review"; the factory's failure mode is isolated-parallel-work defects, not standards drift |
| his fixed-point pinning / spec-source discovery / parallel sub-agent spawn steps dropped | workflow-necessity | orchestrator supplies pre-run-sha, spec path, and dispatch; reviewer is itself the fresh subagent |
| intro ("review a finished run cold") | workflow-necessity + evidence:[F3] | fresh-context verifier framing; compressed one line this job to offset the attribution line |
| `## Cohesion` checklist | workflow-necessity | six isolated-parallel defect classes from the spec; s7 judge item |
| `## Spec` paragraph | reverted | his Spec sub-agent brief wording restored: "requirements that are missing or partial; behavior the spec never asked for (scope creep); requirements that look implemented but where the implementation looks wrong" (Pocock :72) |
| `## Reporting` | reverted | his wording restored: "Do not merge or rerank findings — the two axes are deliberately separate... worst finding within each axis; never a single winner across axes" (Pocock :78-80) |
| calibration line | workflow-necessity | frozen s7 RUN 5 greps it verbatim; Anthropic steering block adopted at s7 |
| `## Why two axes` omitted | evidence:[G1] | rationale prose; the operative rule survives in `## Reporting` |
| `## Edit discipline` | workflow-necessity | green-or-discard edit-in-worktree rules by pointer; s7 judge item; pointer paragraph compressed one line this job |
| `## Glossary contract` | workflow-necessity | one-vocabulary constraint; ban-list phrasing pinned by validator exemption strings |

## Verbatim RUN output (this session, Git Bash executor)

### s11 frozen check (docs/checks/skill-library/s11-wording-reconciliation.md)

```
=== s11 RUN 1 (attribution) ===
ATTRIB_ALL
exit=0
=== s11 RUN 2 (validator tail) ===
OK - 9 skills validated, v4 contracts clean
exit=0
=== s11 RUN 3 (S2 anchors) ===
S2_ANCHORS
exit=0
=== s11 RUN 4 (S7 anchors) ===
S7_ANCHORS
exit=0
=== s11 RUN 5 (S137 anchors) ===
S137_ANCHORS
exit=0
=== s11 RUN 6 (NO_ECHO) ===
NO_ECHO
exit=0
```

(RUN 2 re-run after the final mocking.md tweak: `OK - 9 skills validated,
v4 contracts clean`, exit=0 — the transcript above shows the rerun value.)

### Prior-slice RUN items (every graded item, in check order)

```
=== s1 RUN 1 ===
exit=0
=== s1 RUN 2 ===
exit=0
=== s1 RUN 3 ===
exit=0
=== s1 RUN 4 ===
exit=0
=== s1 RUN 5 ===
ALL_TERMS
exit=0
=== s1 RUN 6 ===
LINES_OK 161
exit=0
=== s1 RUN 7 ===
NO_ECHO
exit=0
=== s2 RUN 1 ===
exit=0
=== s2 RUN 2 ===
exit=0
=== s2 RUN 3 ===
ALL_SECTIONS
exit=0
=== s2 RUN 4 ===
LINES_OK 70
exit=0
=== s2 RUN 5 ===
RULE_0
exit=0
=== s2 RUN 6 ===
NO_ECHO
exit=0
=== s3 RUN 1 ===
exit=0
=== s3 RUN 2 ===
exit=0
=== s3 RUN 3 ===
ALL_RULES
exit=0
=== s3 RUN 4 ===
LINES_OK 88
exit=0
=== s3 RUN 5 ===
STRUCT_OK
exit=0
=== s3 RUN 6 ===
NO_ECHO
exit=0
=== s5 RUN 1 ===
exit=0
=== s5 RUN 2 ===
exit=0
=== s5 RUN 3 ===
exit=0
=== s5 RUN 4 ===
ALL_TERMS
exit=0
=== s5 RUN 5 ===
LINES_OK 206
exit=0
=== s5 RUN 6 ===
BUILDER_WIRED
exit=0
=== s5 RUN 7 ===
JUDGE_WIRED
exit=0
=== s5 RUN 8 ===
NO_ECHO
exit=0
=== s7 RUN 1 ===
exit=0
=== s7 RUN 2 ===
exit=0
=== s7 RUN 3 ===
AXES_OK
exit=0
=== s7 RUN 4 ===
CHECKLIST_OK
exit=0
=== s7 RUN 5 ===
exit=0
=== s7 RUN 6 ===
LINES_OK 75
exit=0
=== s7 RUN 7 ===
NO_ECHO
exit=0
```

Post-tweak re-verification (s5 terms + tdd budget after the `test DB` revert):

```
ALL_TERMS
exit=0
LINES_OK 206
exit=0
```

### Boundary evidence

```
 M skills/codebase-design/DEEPENING.md
 M skills/codebase-design/DESIGN-IT-TWICE.md
 M skills/codebase-design/SKILL.md
 M skills/cohesion-review/SKILL.md
 M skills/tdd/SKILL.md
 M skills/tdd/mocking.md
 M skills/tdd/tests.md
 M skills/to-issues/SKILL.md
 M skills/to-spec/SKILL.md
```

`skills/frozen-checks/`, `skills/adversarial-review/`, `skills/architect/`,
`tests/`, `docs/evals/`, `docs/checks/` untouched. Not committed (per job
contract). Superseded s2/s3/s7 "original wording" intent items not applied,
per the frozen s11 check's judge-only note.

STATUS: COMPLETE
