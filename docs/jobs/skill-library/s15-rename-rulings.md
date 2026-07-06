# Rulings: skill-library/s15-rename (append-only, orchestrator-owned)

RULING (auto, 5m silence, 2026-07-06): rename `cohesion-review` →
`code-review` as directed; the shadowing of Claude Code's bundled
/code-review skill in installed trees was surfaced and stands accepted by
the default. SUPERSESSION MAP — the following frozen graded RUN items
reference the old path/name and are superseded by the s15 check's
same-content items at the new path; closing review 2 grades the run's items
with this map applied (superseded items are satisfied by their replacements,
never silently skipped):

- s7-cohesion-review.md: ALL RUN items (path-based) → s15 RUN 1–4.
- s14-cohesion-upgrade.md: ALL RUN items (path-based) → s15 RUN 1–6.
- s8-orchestrator.md STAGES_OK ("cohesion-review" in architect SKILL.md) →
  s15 RUN 7 (all nine names incl. code-review).
- s9-validator-evals.md INVENTORY_OK + EVALS_OK ("cohesion-review" in
  validator / fixture) → s15 RUN 8–9.
- s10-trigger-allowlist.md SH/PS_ALLOWLIST_OK ("cohesion-review" in both
  scripts) → s15 RUN 10.
- s11-wording-reconciliation.md ATTRIB item for the old path + S7_ANCHORS →
  s15 RUN 2–3.
All other frozen items across the run are unaffected and still graded
directly.

RULING APPEND (2026-07-06, closing review 2): docs-finish.md README_OK also
greps the old hyphenated name in README and is superseded by s15 RUN 9
under the map's stated principle; its non-name clause (to-spec in README)
was re-verified directly by the reviewer. Recorded residual, deliberately
frozen: `skills/architect/SKILL.md:6` description still says "judge
completed jobs" — frontmatter is pinned by s12/s13 intent items and
load-bearing for trigger-fixture prompt 3; re-baseline belongs to the next
trigger-eval generation, not this run.
