# hardening-skill-core-01

## Phase 0

MIRROR: ORCHESTRATOR

Plan:

| Step | Files |
|---|---|
| Verify freeze commit and frozen check file | `git log -1 --oneline`; `docs/checks/hardening-skill-core.md` |
| Compare issue against cited sources | `docs/spec/ops-hardening.md`; `docs/research/factory-hardening-evidence.md`; `docs/checks/hardening-skill-core.md`; `skills/architect/SKILL.md` |
| Edit approval/intake/decompose/watchdog wording | `skills/architect/SKILL.md` |
| Run frozen checks sequentially | `docs/checks/hardening-skill-core.md` |
| Write report | `docs/jobs/hardening-skill-core-01.md` |

Disagreements: none.

Checked before concluding the issue is sound:

```text
git log -1 --oneline
27b1fc2 re-freeze: stress-test amendments (WA2 quoting, DB3 scope exclusion, DD4 base-commit form, D scope consistency)
```

```text
Test-Path -LiteralPath 'docs/checks/hardening-skill-core.md'; if (Test-Path -LiteralPath 'docs/checks/hardening-skill-core.md') { Get-Item -LiteralPath 'docs/checks/hardening-skill-core.md' | Select-Object -ExpandProperty FullName }
True
C:\Users\danhm\architect-loop\.architect\wt\hardening-skill-core-01\docs\checks\hardening-skill-core.md
```

```text
git grep -n -A3 "Approval strings" -- docs/spec/ops-hardening.md
docs/spec/ops-hardening.md:74:**Approval strings** (SKILL.md + tracking-issue template): approval comment
docs/spec/ops-hardening.md-75-is exactly `APPROVE`, optionally `APPROVE with edits: <text>`; rejection is
docs/spec/ops-hardening.md-76-`REJECT <reason>`. Park posts `AWAITING APPROVAL` on the tracking issue.
docs/spec/ops-hardening.md-77-
```

```text
git grep -n -A6 "Design consequence.*approval" -- docs/research/factory-hardening-evidence.md
docs/research/factory-hardening-evidence.md:66:**Design consequence:** approval has exactly two explicit forms —
docs/research/factory-hardening-evidence.md-67-in-session, or an `APPROVE` comment on the tracking issue (phone-friendly,
docs/research/factory-hardening-evidence.md-68-GH-mobile precedent) — plus a pre-approval fast path recorded verbatim from
docs/research/factory-hardening-evidence.md-69-the invocation (Copilot assign-is-authorization precedent). Absent human →
docs/research/factory-hardening-evidence.md-70-park with scheduled polling, bounded at 7 days, then fail-safe stop
docs/research/factory-hardening-evidence.md-71-(GH-style). Inferred approval is banned (OWASP).
docs/research/factory-hardening-evidence.md-72-
```

## SC1

```text
git grep -c "APPROVE with edits:" -- skills/architect/SKILL.md
skills/architect/SKILL.md:2
```

```text
git grep -cE "^\s*.*REJECT" -- skills/architect/SKILL.md
skills/architect/SKILL.md:3
```

```text
git grep -c "AWAITING APPROVAL" -- skills/architect/SKILL.md
skills/architect/SKILL.md:1
```

```text
git grep -ci "verbatim" -- skills/architect/SKILL.md
skills/architect/SKILL.md:1
```

```text
git grep -n -A1 "Prior conversation is never approval" -- skills/architect/SKILL.md
skills/architect/SKILL.md:125:Prior conversation is never approval unless it is an explicit authorization
skills/architect/SKILL.md-126-quoted in the approval record; the fail-safe default is no approval.
```

```text
git grep -n -A1 "After 7 days without approval" -- skills/architect/SKILL.md
skills/architect/SKILL.md:132:After 7 days without approval, post a fail-safe closing digest on the tracking
skills/architect/SKILL.md-133-issue and stop.
```

## SC2

```text
git grep -n -A3 "Done when the spec contains goal" -- skills/architect/SKILL.md
skills/architect/SKILL.md:104:Done when the spec contains goal, non-goals, assumptions, validation strategy,
skills/architect/SKILL.md-105-domain language, preflight evidence, any open human decisions, and the tracking
skills/architect/SKILL.md-106-issue exists with the spec pointer, assumptions digest, and approve-by-comment
skills/architect/SKILL.md-107-instructions.
```

```text
git grep -in "tracking issue" -- skills/architect/SKILL.md
skills/architect/SKILL.md:91:then, record the substitution and canary evidence on the tracking issue, and resolve
skills/architect/SKILL.md:99:At the end of intake, before approval, create the tracking issue. Its body
skills/architect/SKILL.md:114:tracking issue digest or hard stops.
skills/architect/SKILL.md:121:- Tracking-issue approval: the repo owner comments on the tracking issue with
skills/architect/SKILL.md:128:If the human is absent, PARK: post `AWAITING APPROVAL` on the tracking issue
skills/architect/SKILL.md:146:- Add sub-issues under the existing tracking issue, which is the dashboard and
skills/architect/SKILL.md:183:result, and dispatch-ready issues are recorded on the tracking issue and
skills/architect/SKILL.md:229:the tracking issue with shipped issues, skipped work, residual risks, and
skills/architect/SKILL.md:232:Done when docs debt is consumed, the PR is ready, the tracking issue digest is posted,
```

## SC3

```text
git grep -ci "watchdog" -- skills/architect/SKILL.md
skills/architect/SKILL.md:3
```

```text
git grep -c "## Monitor dispatch" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
```

```text
git grep -nE "dispatch\.md section|loop\.md section|dispatch\.md` `##|loop\.md` `##" -- skills/architect/SKILL.md
skills/architect/SKILL.md:21:- dispatch.md section `## Model alias table`
skills/architect/SKILL.md:22:- dispatch.md section `## Issue conventions`
skills/architect/SKILL.md:23:- dispatch.md section `## Monitor dispatch`
skills/architect/SKILL.md:24:- dispatch.md section `## Respawn-with-answer template`
skills/architect/SKILL.md:25:- loop.md section `## Factory block procedure`
```

```text
git grep -c "## Model alias table" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
```

```text
git grep -c "## Issue conventions" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
```

```text
git grep -c "## Monitor dispatch" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
```

```text
git grep -c "## Respawn-with-answer template" -- skills/architect/dispatch.md
skills/architect/dispatch.md:1
```

```text
git grep -c "## Factory block procedure" -- skills/architect/loop.md
skills/architect/loop.md:1
```

## SC4

```text
git grep -inwE "gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag" -- skills/architect/SKILL.md
```

```text
Get-Content -LiteralPath 'skills/architect/SKILL.md' -TotalCount 5
---
name: architect
description: >
  Use when the user asks to architect, run or continue the autonomous software
  factory, turn a goal into a spec-approved GitHub issue plan, dispatch builder
```

```text
(Get-Content -LiteralPath 'skills/architect/SKILL.md' | Where-Object { $_.Trim().Length -gt 0 }).Count
206
```

STATUS: COMPLETE
