# Rulings: skill-library/s8-orchestrator (append-only, orchestrator-owned)

RULING 2026-07-05 (post-BLOCKED, boundary amendment): RUN item 9's validator
failure is a cross-slice integration defect, not an s8 defect —
`skills/frozen-checks/SKILL.md:19` (merged from s4, present at pristine
de7ec47) references `dispatch.md` as a bare backticked filename, which
`check_siblings()` treats as a missing sibling of the frozen-checks skill.
s4's checkrun never ran the validator, so it stayed latent until s8's check
did. Fix belongs in the skill text, not the validator: the reference is
genuinely ambiguous prose.
BOUNDARY AMENDMENT: s8 MAY additionally TOUCH `skills/frozen-checks/SKILL.md`
for exactly one change — qualify the line-19 reference to
`skills/architect/dispatch.md`. Nothing else in that file. s4's frozen RUN
items must stay green after the change (line budget ≤100 unchanged; no
asserted substring is removed). All other s8 boundaries unchanged.
