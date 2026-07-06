# Job report: skill-library/s1-01 (ship) - skills/codebase-design/

Issue: #104. Job identity: skill-library/s1-01. Shape: ship.
Boundaries honored: only `skills/codebase-design/**` and this report were
touched. `docs/checks/**` was not written to (see PHASE 0 comment on #104
for why the frozen check content was read via `git show` instead of a
worktree file).

## PHASE 0

Posted to issue #104: https://github.com/DanMcInerney/architect-loop/issues/104#issuecomment-4888438697

Summary of what was verified before building (raw commands below):
- Fetched all three mattpocock/skills source URLs live (200 OK each).
- Fetched mattpocock/skills LICENSE live (200 OK): MIT.
- Confirmed the frozen check file does not exist in this worktree's HEAD
  (c9c1f95) because 3 later commits on `factory/skill-library`
  (1bb9cb3, 7d800b4, 3f56e7c) were not yet in this worktree; read its
  content via `git show` instead of merging/checking out (no commit
  authority in this job).
- Flagged (not fixed, out of boundary): `tests/validate_skills.py` enforces
  a 1024-char description cap on every `skills/*/SKILL.md`, tighter than
  the issue's cited 1,536-char harness cap; targeted <=1024 to satisfy both.
- Flagged (not fixed, out of boundary): `CONTEXT.md` lists "Slice / block"
  as a retired v4 term superseded by "issue", while this issue's interface
  contract requires "slice" as a live glossary term; defined per the issue
  (frozen contract) and noted the drift.

## Source verification (raw command output)

```
$ curl -s -o /tmp/mp_skill.md -w "%{http_code}\n" https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/codebase-design/SKILL.md
200
$ curl -s -o /tmp/mp_deepening.md -w "%{http_code}\n" https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/codebase-design/DEEPENING.md
200
$ curl -s -o /tmp/mp_design2x.md -w "%{http_code}\n" https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/codebase-design/DESIGN-IT-TWICE.md
200
$ curl -s -o /tmp/mp_license.txt -w "%{http_code}\n" https://raw.githubusercontent.com/mattpocock/skills/main/LICENSE
200
$ head -5 /tmp/mp_license.txt
MIT License

Copyright (c) 2026 Matt Pocock

Permission is hereby granted, free of charge, to any person obtaining a copy
```

## Frozen check retrieval (worktree lacked the file)

```
$ git merge-base --is-ancestor 3f56e7c HEAD && echo "IS ANCESTOR" || echo "NOT ANCESTOR"
NOT ANCESTOR
$ git log --all --oneline -- docs/checks/skill-library/
3f56e7c run skill-library: freeze checks s1-s9 (post stress-test amendments)
```

Retrieved check text via `git show factory/skill-library:docs/checks/skill-library/s1-codebase-design.md` (full content reproduced in the PHASE 0 comment context, not repeated here; RUN items executed below are copied verbatim from that retrieval).

## Files created

```
$ ls -la skills/codebase-design/
total 20
drwxr-xr-x 1 danhm 197610    0 Jul  5 21:47 .
drwxr-xr-x 1 danhm 197610    0 Jul  5 21:46 ..
-rw-r--r-- 1 danhm 197610 2020 Jul  5 21:46 DEEPENING.md
-rw-r--r-- 1 danhm 197610 1542 Jul  5 21:47 DESIGN-IT-TWICE.md
-rw-r--r-- 1 danhm 197610 5810 Jul  5 21:46 SKILL.md
$ wc -l skills/codebase-design/SKILL.md skills/codebase-design/DEEPENING.md skills/codebase-design/DESIGN-IT-TWICE.md
  96 skills/codebase-design/SKILL.md
  33 skills/codebase-design/DEEPENING.md
  33 skills/codebase-design/DESIGN-IT-TWICE.md
 162 total
```

## Frozen check RUN items (executed from worktree root via Bash / Git Bash)

RUN 1: `test -f skills/codebase-design/SKILL.md -a -f skills/codebase-design/DEEPENING.md -a -f skills/codebase-design/DESIGN-IT-TWICE.md`
```
EXIT:0
```
Expected exit:0 -> PASS

RUN 2: `grep -F -q "name: codebase-design" skills/codebase-design/SKILL.md`
```
EXIT:0
```
Expected exit:0 -> PASS

RUN 3: `grep -F -q "Adapted from mattpocock/skills (MIT)" skills/codebase-design/SKILL.md`
```
EXIT:0
```
Expected exit:0 -> PASS

RUN 4: `grep -F -q "## Glossary" skills/codebase-design/SKILL.md`
```
EXIT:0
```
Expected exit:0 -> PASS

RUN 5: `bash -c 'for t in module interface seam adapter depth leverage locality "frozen check" check-runner "intent judge" orchestrator builder worktree; do grep -qi "$t" skills/codebase-design/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo ALL_TERMS'`
```
ALL_TERMS
EXIT:0
```
Expected exit:0 match:"ALL_TERMS" -> PASS

RUN 6: `bash -c 'for f in skills/codebase-design/SKILL.md skills/codebase-design/DEEPENING.md skills/codebase-design/DESIGN-IT-TWICE.md; do test -f "$f" || { echo "MISSING: $f"; exit 3; }; done; n=$(cat skills/codebase-design/SKILL.md skills/codebase-design/DEEPENING.md skills/codebase-design/DESIGN-IT-TWICE.md | wc -l); test "$n" -le 240 && echo "LINES_OK $n"'`
```
LINES_OK 162
EXIT:0
```
Expected exit:0 match:"LINES_OK" -> PASS

RUN 7: `bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/codebase-design/*.md && echo NO_ECHO'`
```
NO_ECHO
EXIT:0
```
Expected exit:0 match:"NO_ECHO" -> PASS

**All 7 RUN items: PASS (7/7). Executor: Git Bash (Bash tool), the check's preferred executor.**

## Informational sanity check (not a frozen RUN item; repo-wide validator, read-only run)

```
$ uv run python tests/validate_skills.py
OK - 3 skills validated, v4 contracts clean
```

Confirms `skills/codebase-design/SKILL.md` frontmatter (`name` matches dir,
description well under the validator's 1024-char cap at 440 chars) doesn't
regress the existing generic skill validator, and that `DEEPENING.md` /
`DESIGN-IT-TWICE.md` sibling references resolve.

Description length check (flattened, informational):
```
flattened description: Shared vocabulary for designing deep modules and for naming factory concepts consistently. Load before writing a spec, decomposing issues, freezing checks, or reviewing a diff - anywhere "module," "interface," "issue," or "frozen check" need to mean the same thing to every skill, builder, and judge. Also covers dependency categories for deepening and the parallel design-it-twice pattern for exploring interfaces before committing to one.
char count: 440
```

## Boundary / cleanliness check

```
$ git status --porcelain
?? skills/codebase-design/
$ git diff --stat
(empty - only new untracked files, no tracked file modified)
```

## Judge-only intent items (self-report, not self-graded - for the fresh intent judge to verify)

- Glossary (`skills/codebase-design/SKILL.md` `## Glossary`) defines all 8
  design terms (module, interface, implementation, depth, seam, adapter,
  leverage, locality) with Pocock-faithful meanings reworded, plus all 16
  factory terms (run, tracking issue, issue, slice, frozen check,
  check-runner, builder, intent judge, orchestrator, factory branch,
  worktree, job report, verdict, ruling, digest, hard stop) one line each,
  with an explicit exact-use rule and the three named banned-substitute
  groups (component/service/boundary/API; task/ticket; test file).
- `DEEPENING.md` carries the four dependency categories (in-process,
  local-substitutable, remote-owned ports & adapters, true-external mock)
  and ties each category to a testing strategy across the seam in its own
  `## Testing across the seam` section.
- `DESIGN-IT-TWICE.md` is reworded for an orchestrator dispatching
  subagents (not an end-user-facing pattern): "Dispatch 3 or more fresh
  subagents in parallel" with distinct constraints per subagent, compared
  on depth, locality, and seam placement.
- No instruction anywhere asks a model to echo/show its reasoning (RUN 7
  confirms this mechanically).
- Prose is brief imperative steering (short paragraphs / one-line glossary
  bullets), not enumerated behavior checklists, per the style contract.

## Concerns / notes for the orchestrator

- The worktree assigned to this job was 3 commits behind
  `factory/skill-library` at dispatch time (missing the approval-record,
  license-resolution, and check-freeze commits). This job worked around it
  by reading the frozen check via `git show` rather than by merging or
  committing in this worktree. If other s1-family jobs in this run hit the
  same staleness, they may need the same workaround or a worktree refresh
  from the orchestrator.

STATUS: COMPLETE
