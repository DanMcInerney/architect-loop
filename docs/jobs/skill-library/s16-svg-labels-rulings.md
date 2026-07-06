# Rulings: skill-library/s16-svg-labels (append-only, orchestrator-owned)

RULING 2026-07-06 (post-report): the frozen check's NO_JUDGE and TEXT_ONLY
RUN items structurally conflict on two pre-existing XML comments
(`<!-- FAIL loop: judge back to build -->`, `<!-- 6 JUDGE -->`) — verified
empirically by the builder. Check-authoring defect, orchestrator-owned.
Resolution: XML comments are annotation, not artwork — updating them serves
the check's purpose (label text matches the shipped flow). The builder is
AUTHORIZED to edit exactly those two comment lines. Grading: NO_JUDGE is
graded mechanically (must pass); TEXT_ONLY is graded by its intent — no
path/shape/coordinate/style change — with the two enumerated comment lines
as the sole recorded exception to its mechanical form.
