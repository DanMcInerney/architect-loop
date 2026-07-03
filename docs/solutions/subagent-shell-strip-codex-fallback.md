# Subagent Shell Strip and Codex Fallback

## Problem

During the 2026-07-02 v5 run, every Claude-backend subagent spawn that needed
shell execution lost both Bash and PowerShell. This was a D12 recurrence across
5+ occurrences: the grill judge and four builder lanes. Gates, validator runs,
and `gh` commands were unrunnable in those contexts.

## What Didn't Work

Assuming the agent definition's declared tools and isolation would survive
spawn. The affected agents could read and grep files, but could not execute the
frozen shell commands their gates required.

## Why This Works

Builders in this state exit BLOCKED-with-evidence instead of idling or
inventing gate output. The orchestrator substitutes Codex-backend lanes when a
shell-capable builder is required, using workspace-write and
orchestrator-created worktrees, and records the substitution on the epic.
Judges run through a Codex backend or through PowerShell same-pattern
substitutions, with the executor named per gate.

## Prevention

Preflight one canary spawn before fanning out. Keep the substitution rule in
gate files, and require reports to name the executor and exact missing-tool
evidence whenever a literal gate cannot run.
