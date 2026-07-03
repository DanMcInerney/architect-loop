# Worktree Stale Snapshot
Recorded: 2026-07-02 (architect v5 dogfood run, epic #12)

## Problem

The first harness-created agent worktree had files snapshotted from the
pre-freeze state while its ref was fast-forwarded to the freeze commit. The ref
looked current, but required spec and gate files were missing on disk.

## What Didn't Work

Fast-forwarding the ref from outside after spawn. It made git metadata look
right without proving the worktree's file snapshot matched the freeze commit.

## Why This Works

Push or commit all frozen inputs before spawning lanes. Immediately after
spawn, verify each worktree's HEAD and required file presence. Builders also
verify their inputs exist as their first action and exit BLOCKED if they do
not.

## Prevention

The freeze commit precedes every dispatch. Dispatch includes worktree base
verification, and lane PHASE 0 records HEAD plus the presence of the frozen
gate, spec, and any issue-specific input files before build work starts.
