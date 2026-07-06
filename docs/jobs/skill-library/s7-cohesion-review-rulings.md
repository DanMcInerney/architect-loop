# Rulings: skill-library/s7-cohesion-review (append-only, orchestrator-owned)

RULING 2026-07-05 (post-judge-FAIL): the issue body contained a genuine
contradiction — its Source-material paragraph required the closing-review
mechanics stay pointer-only to `skills/architect/SKILL.md` `### 5. Finish`,
while its Edit-discipline bullet spelled the same mechanics out as content.
The pointer reading governs: it is the spec's single-source-of-truth
constraint, and restating orchestrator-owned mechanics inside a stage skill
recreates the dual-maintenance drift this library exists to kill. Input
defect acknowledged as the orchestrator's.
Fix required: condense `## Edit discipline` to cohesion-review-specific
content plus one pointer line to `### 5. Finish` for the run-green /
discard mechanics. Constraint: the literal term `green-or-discard` must
remain in the file (frozen RUN item 4 greps for it) — use it inside the
pointer sentence. The job report's self-claim must be corrected to match
the file. All 7 frozen RUN items stay green.
