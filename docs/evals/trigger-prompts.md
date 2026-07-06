# Trigger Eval Prompts

Purpose: lightweight fixture for checking whether Claude Code routes prompts to
the architect, architect-research, and seven stage skills (codebase-design,
to-spec, to-issues, frozen-checks, tdd, adversarial-review, cohesion-review).
Run: `skills/architect/trigger-eval.ps1 -Limit 4` or
`skills/architect/trigger-eval.sh --limit 4`; add `-Bare` or `--bare` if
local hooks fail in a sandbox.

- PROMPT: /architect continue the factory run for issue #82 and dispatch the next ready builder.
  SKILL: architect
  EXPECT: trigger

- PROMPT: Use the architect skill to turn this goal into a spec-approved tracker issue plan.
  SKILL: architect
  EXPECT: trigger

- PROMPT: Continue the factory after the builder report lands and judge the completed job.
  SKILL: architect
  EXPECT: trigger

- PROMPT: The watchdog found a stalled builder; diagnose the blocker and decide whether to respawn.
  SKILL: architect
  EXPECT: trigger

- PROMPT: We have an approved spec and frozen checks; dispatch builders for the ready issues.
  SKILL: architect
  EXPECT: trigger

- PROMPT: Convert this loose product goal into approved tracker issues with frozen checks.
  SKILL: architect
  EXPECT: trigger

- PROMPT: A job report says BLOCKED because docs/STOP exists; record the blocker and stop the factory.
  SKILL: architect
  EXPECT: trigger

- PROMPT: How is the factory going? Show the current status tree from the run artifacts.
  SKILL: architect
  EXPECT: trigger

- PROMPT: Change the CSS button color in src/App.tsx and run the relevant tests.
  SKILL: architect
  EXPECT: no-trigger

- PROMPT: Explain what this Python helper returns; no factory, tracker, or issue planning is needed.
  SKILL: architect
  EXPECT: no-trigger

- PROMPT: /architect-research research the state of the art for browser automation agents in 2026.
  SKILL: architect-research
  EXPECT: trigger

- PROMPT: Use architect-research to map the literature on skill invocation evals and cite sources.
  SKILL: architect-research
  EXPECT: trigger

- PROMPT: Do deep research on best practices for routing agent skills and summarize the evidence.
  SKILL: architect-research
  EXPECT: trigger

- PROMPT: What is the state of the art in autonomous software factory orchestration?
  SKILL: architect-research
  EXPECT: trigger

- PROMPT: Build a discovery-scale source map across Reddit, arXiv, GitHub, and vendor docs for prompt routing failures.
  SKILL: architect-research
  EXPECT: trigger

- PROMPT: Before we spec this new platform, fan out researchers to compare approaches and verify claims.
  SKILL: architect-research
  EXPECT: trigger

- PROMPT: Create a source-class tactics plan for investigating current model eval harness designs.
  SKILL: architect-research
  EXPECT: trigger

- PROMPT: Find what practitioners and papers say about skill overtriggering in the last year.
  SKILL: architect-research
  EXPECT: trigger

- PROMPT: In docs/checks/trigger-evals.md, what does TE4 count?
  SKILL: architect-research
  EXPECT: no-trigger

- PROMPT: Does .gitignore currently ignore docs/evals/trigger-prompts.md? Check this repo only.
  SKILL: architect-research
  EXPECT: no-trigger

- PROMPT: Ground the factory run: load the codebase-design skill for the glossary and deepening vocabulary before writing anything.
  SKILL: codebase-design
  EXPECT: trigger

- PROMPT: Help me center a div with flexbox in this stylesheet.
  SKILL: codebase-design
  EXPECT: no-trigger

- PROMPT: Intake is done; run the to-spec stage skill to synthesize the run's evidence into docs/spec/payments.md for approval.
  SKILL: to-spec
  EXPECT: trigger

- PROMPT: Write a short blog post announcing our new payments feature.
  SKILL: to-spec
  EXPECT: no-trigger

- PROMPT: The spec is approved; use the to-issues skill to decompose it into tracer-bullet slices under tracking issue #103.
  SKILL: to-issues
  EXPECT: trigger

- PROMPT: List the open issues in this repo sorted by age.
  SKILL: to-issues
  EXPECT: no-trigger

- PROMPT: Decomposition is done; invoke the frozen-checks skill to write per-issue graded checks under docs/checks/payments/ before any builder dispatch.
  SKILL: frozen-checks
  EXPECT: trigger

- PROMPT: Add a unit test for the date parser in src/utils.
  SKILL: frozen-checks
  EXPECT: no-trigger

- PROMPT: You are a builder on issue #41; work test-first with the tdd skill at the seams named in the issue body and report raw evidence.
  SKILL: tdd
  EXPECT: trigger

- PROMPT: Rename this variable across the file and fix the imports.
  SKILL: tdd
  EXPECT: no-trigger

- PROMPT: You are a fresh reviewer; run adversarial-review against the draft spec and return FALSIFIED or HOLDS findings with file:line evidence.
  SKILL: adversarial-review
  EXPECT: trigger

- PROMPT: Proofread this README paragraph for typos.
  SKILL: adversarial-review
  EXPECT: no-trigger

- PROMPT: Every issue in the run is closed; run the cohesion-review skill over the whole run diff from the factory branch head.
  SKILL: cohesion-review
  EXPECT: trigger

- PROMPT: Summarize what changed in the last commit.
  SKILL: cohesion-review
  EXPECT: no-trigger
