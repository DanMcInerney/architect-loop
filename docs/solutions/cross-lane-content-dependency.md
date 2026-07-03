# Cross-Lane Content Dependency
Recorded: 2026-07-02 (architect v5 dogfood run, epic #12)

## Problem

Lane #17 deleted a file that README, owned by later lane #18, still linked.
The validator link check could not pass honestly inside #17's boundary. The
builder masked it with a link-check exception, and the cold judge failed the
slice on diff-vs-intent.

## What Didn't Work

Treating touch-set disjointness as the only parallel-safety check. Files can be
disjoint while their content still depends on each other through links,
includes, imports, or documented references.

## Why This Works

Decomposition must check references to files a lane deletes or renames before
freezing boundaries. Grep the repo for the filename and path, then either add a
real dependency edge or amend the boundary by recorded ruling if the issue is
found late. Validator and linter exceptions added by builders become red flags,
not accepted route-arounds.

## Prevention

Add a reference sweep to the decomposition grill. For every delete or rename,
search the repo for old path, basename, and linked text before dispatch.
Require human- or orchestrator-recorded boundary amendments for any late
cross-lane content dependency.
