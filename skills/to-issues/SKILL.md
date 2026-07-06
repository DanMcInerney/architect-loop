---
name: to-issues
description: >
  Use when decomposing an approved spec into tracker issues: cutting
  tracer-bullet vertical slices through every layer, ordering structural work
  first with blocking edges, maximizing the disjoint parallel frontier,
  publishing producer/consumer interface contracts, and attaching a compact
  change-skeleton to each issue. Orchestrator-invoked only, after spec
  approval — never left to description-trigger discovery.
disable-model-invocation: true
---

<!-- Adapted from mattpocock/skills (MIT). -->

# To Issues

Turn the approved spec into dispatch-ready issues under the tracking issue.
Approval already covers the whole plan — this stage does not re-quiz the
human; a hard stop or an oddity escalation is the only thing that reopens a
question here.

## 1. Read before you cut

Load the spec and the map pointer, then hold the codebase-design vocabulary
exactly: module, interface, implementation, seam, adapter, depth, leverage,
locality for design; run, tracking issue, issue, slice, frozen check,
check-runner, builder, intent judge, orchestrator, factory branch, worktree,
job report, verdict, ruling, digest, hard stop for the factory. Never
substitute component/service/boundary/API for module/interface, or
task/ticket for issue — that drift is a defect, not a style choice.

Look for prefactoring while you read: make the change easy, then make the
easy change.

## 2. Structural before behavioral

Structural (prefactoring) issues land first, with blocking edges into the
behavioral issues they unblock. A structural issue's checks prove existing
behavior stays green — it changes shape, not outcome.

Oddity rule while scoping: a local wart gets a local patch note, not its own
issue. A variation that recurs gets a structural issue blocking the
behavioral one. One adapter is a hypothetical seam; two adapters make it
real — write the structural issue. Three failed fixes on the same point
means stop and escalate the design question instead of cutting a fourth fix.

## 3. Cut tracer-bullet vertical slices

Each issue is a tracer-bullet vertical slice: a narrow but complete path
through every layer the change touches, demoable or verifiable on its own —
never a horizontal slice of one layer.

Avoid specific file paths or code snippets in issue prose — they go stale
fast. Exception: a prototype snippet that encodes a decision more precisely
than prose can (state machine, schema, type shape); trim to the
decision-rich parts.

## 4. Maximize the disjoint parallel frontier

Compute readiness from each issue's file-touch set, not only its blocking
edges. Issues dispatched in the same wave share no files, migrations,
lockfiles, generated artifacts, config, schemas, or other mutable runtime
state. A shared-file collision is a decomposition failure — split or
resequence; never hand-merge it later.

## 5. Interface contracts, not future-code citations

An issue that produces a surface another issue consumes publishes an
interface contract block: names, parameters, return types, and behavior.
Consumer issues cite that block; they never cite the producer's
not-yet-written implementation.

## 6. Body shape

Every issue carries: acceptance criteria; MAY TOUCH / MUST NOT TOUCH file
sets; its check path; its raw job-report path; blocked-by and parent edges;
a compact change-skeleton (≤30 lines — files, signatures, data flow,
invariants; a contract, not a line mandate). Close every issue body with the
run marker comment: `<!-- architect-run: <run> -->`.

## 7. Publish in dependency order

Publish structural issues, then behavioral issues, blockers before the
issues that cite them, so every blocked-by ID names a real, already-open
issue — never a forward reference.

Done when the whole plan is issues on the tracker, structural-first,
frontier-maxed, and every blocked-by ID resolves to a real issue.
