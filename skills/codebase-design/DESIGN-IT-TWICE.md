# Design It Twice

Use this when a deepening candidate has more than one plausible interface
shape. Based on "Design It Twice" (Ousterhout) - your first idea is unlikely
to be the best. Assumes the vocabulary in `SKILL.md` - module, interface,
seam, adapter, leverage - and the dependency categories in `DEEPENING.md`.

## Frame the problem, then fan out

Before dispatching, write the constraints any interface must satisfy, the
dependency category it relies on, and a rough sketch just to make the
constraints concrete - not a proposal.

Dispatch 3 or more fresh subagents in parallel, each with the same
technical brief (files, coupling, dependency category, what sits behind
the seam) plus one distinct constraint, so the shapes diverge on purpose:

- minimize the interface: 1-3 entry points, maximum leverage per entry point.
- maximize flexibility: support many callers and future extension.
- optimize for the common case: make the default caller trivial.
- (a fourth, if the category calls for it) design around ports and
  adapters for the cross-seam dependency.

Each subagent returns: the interface (types, methods, invariants, error
modes), a usage example, what sits behind the seam, its adapter strategy,
and where its leverage is thin.

## Compare and decide

Read the sketches side by side and contrast by depth (leverage at the
interface), locality (where change concentrates), and seam placement. Then
commit to one shape, or a hybrid if elements from different sketches combine
well; a menu of options is not a decision.
