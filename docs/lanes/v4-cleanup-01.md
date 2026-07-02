# Lane report — v4-cleanup-01

Slice: `v4-cleanup`. Gates: `docs/gates/v4-cleanup.md` (freeze `9c670b5` on
`slice/v4-cleanup`). Lane shape: ship. Single lane, no other builder.

## PHASE 0 (recorded before any edit)

Read before touching anything: `docs/gates/v4-cleanup.md`,
`docs/prd/v4-orchestrator-loop.md` §§2-4, `docs/adr/0001-in-session-loop-replaces-external-driver.md`,
`docs/HANDOFF.md` (TL;DR + Decisions log 2026-07-02 entries), `CONTEXT.md`,
`DESIGN.md`, `README.md`, `install.sh`, `install.ps1`, `tests/validate_skills.py`,
`skills/architect/dispatch.md`, `skills/architect/SKILL.md`, `skills/architect/loop.md`,
`tests/driver-canary.ps1`, `docs/gates/v4-core.md`, `docs/gates/v4-desktop.md`,
`docs/gates/v4-desktop2.md`, `docs/gates/v4-codex.md`, and the live evidence at
`.architect/tmp/codex-spawn-canary/{events.jsonl,prompt.md}`.

Two factual corrections found, not disagreements with intent:

1. The spec's line numbers for the install-script driver blocks were stale
   (spec: install.sh ~19-28, install.ps1 ~18-27). Actual blocks were at
   `install.sh:36-45` (`BIN_ROOT`/`DRIVER_DEST` + PATH warning) and
   `install.ps1:35-44` (`$driverSrc`/`$driverDest` + PATH warning). Identified
   and removed by content, not line number.
2. Checked `tests/validate_skills.py` end-to-end for any reference to the
   deleted files (`bin/`, `driver-canary.ps1`) before editing — found none.
   Item 4 of the fix contract needed only the Pyright guard; no additional
   validator adjustment was required.

No other disagreements with the spec.

## Files changed

| File | Change |
|---|---|
| `bin/architect-loop.ps1` | deleted (`git rm`) |
| `bin/architect-loop.sh` | deleted (`git rm`) |
| `tests/driver-canary.ps1` | deleted (`git rm`) |
| `install.sh` | removed driver-copy block (`BIN_ROOT`/`DRIVER_DEST`, PATH warning); kept Claude + Codex skill-copy sections and codex version check |
| `install.ps1` | removed driver-copy block (`$driverSrc`/`$driverDest`, PATH warning); kept Claude + Codex skill-copy sections and codex version check |
| `README.md` | replaced "Run it as a loop" driver section with one-session usage + three-role description + desktop caveat; updated `/architect` bullets and "What's in the box" table to the in-session cold-subagent model (also fixed a leftover sentinel/WAIT/driver reference in the dispatch.md table row, caught while proofing against DG2); noted optional Codex install path; light FAQ updates |
| `DESIGN.md` | appended `## 9. v4 evidence` section (five items from the fix contract, sourced) after the existing `## 8. Sources`; no existing section rewritten |
| `tests/validate_skills.py` | `frontmatter()`: `elif current:` -> `elif current is not None:` (explicit None-guard for the type checker; no behavior change) |
| `skills/architect/dispatch.md` | added one parenthetical on the `wait_agent` row of the per-harness delegation table noting the live collab event stream names the tool `wait` |
| `docs/lanes/v4-cleanup-01.md` | new (this file) |

## Gate commands (sequential, verbatim)

**1. `UV_CACHE_DIR=.architect/tmp/uv-cache uv run tests/validate_skills.py` — Git Bash**

```
OK - 2 skills validated, v4 contracts clean
EXIT=0
```

**1b. Same command — PowerShell (`$env:UV_CACHE_DIR = ".architect/tmp/uv-cache"; uv run tests/validate_skills.py`)**

```
OK - 2 skills validated, v4 contracts clean
EXIT=0
```

Executor: `uv` (bare `python` not on PATH), invoked once via Bash tool, once
via PowerShell tool, per DG1's both-shells requirement.

**2. `git ls-files bin tests/driver-canary.ps1` — Git Bash**

```
(no output)
EXIT=0
```

Empty, as required — the three files are no longer tracked.

**3. `grep -n "architect-loop" install.sh install.ps1 README.md` — Git Bash (`grep`, not `rg`)**

```
README.md:1:# architect-loop
README.md:13:git clone https://github.com/DanMcInerney/architect-loop
README.md:14:cd architect-loop && ./install.sh        # Windows: .\install.ps1
README.md:203:about using Fable with Codex subagents. I built architect-loop because I couldn't
EXIT=0 (grep found matches)
```

**This gate does not come back empty as literally frozen.** `install.sh` and
`install.ps1` have zero matches (the driver-copy blocks are fully removed,
confirming the deletion side of DG2). All four README.md matches are the
repo's own proper name: the H1 title, the `git clone` URL, the `cd` command
in the install snippet, and one prose mention in the Origin section ("I built
architect-loop because..."). None reference the deleted driver binary, the
`architect-loop` CLI invocation, `bin/architect-loop.sh`/`.ps1`, or any
driver/loop-command usage instructions — verified by reading each matched
line above. Renaming the repo itself to avoid this string is out of this
lane's boundaries (README.md content rewrite only) and was not asked for by
the fix contract's actual README requirements (one-session statement, Codex
install path, desktop caveat, no driver/sentinel *usage* instructions — all
of which are satisfied). Recording this as a DG2 gate defect for the judge
rather than silently treating the gate as passed.

**4. `grep -ni "sentinel" README.md` — Git Bash**

```
(no output)
EXIT=1 (grep: no match found)
```

Empty, as required.

**5. `bash -n install.sh` — Git Bash**

```
EXIT=0
```

**6. PowerShell ParseFile check on `install.ps1` — PowerShell tool**

Command: `$t=$null;$e=$null;[System.Management.Automation.Language.Parser]::ParseFile('install.ps1',[ref]$t,[ref]$e)|Out-Null;$e.Count`

```
0
```

0 parse errors, as required.

**7. `git status --porcelain` and `git diff --numstat` (staged + unstaged) — Git Bash**

```
--- git status --porcelain ---
 M DESIGN.md
 M README.md
D  bin/architect-loop.ps1
D  bin/architect-loop.sh
 M install.ps1
 M install.sh
 M skills/architect/dispatch.md
D  tests/driver-canary.ps1
 M tests/validate_skills.py
--- git diff --numstat (unstaged) ---
77	0	DESIGN.md
71	57	README.md
0	11	install.ps1
0	11	install.sh
1	1	skills/architect/dispatch.md
1	1	tests/validate_skills.py
--- git diff --numstat --staged ---
0	254	bin/architect-loop.ps1
0	237	bin/architect-loop.sh
0	322	tests/driver-canary.ps1
```

Touch set is exactly the nine declared paths (6 modified + 3 deleted) plus
the new lane report — matches DG5's declared file set. Not committed, per
instructions.

**DG5 bounded-diff check (additional, as specified in the frozen gate):**
`git diff 9c670b5..HEAD -- docs/gates/ docs/prd/ docs/adr/ CONTEXT.md
skills/architect/SKILL.md skills/architect/loop.md
skills/architect/HANDOFF.template.md .claude/`

```
(no output)
EXIT=0
```

Empty. Note: this command diffs against `HEAD`, which is unchanged from the
freeze commit because this lane does not commit — so this check is
necessarily empty regardless of working-tree edits. The stronger evidence is
`git status --porcelain` above, which independently confirms none of those
excluded paths appear in the working-tree diff either.

## Final `git status --porcelain`

```
 M DESIGN.md
 M README.md
D  bin/architect-loop.ps1
D  bin/architect-loop.sh
 M install.ps1
 M install.sh
 M skills/architect/dispatch.md
D  tests/driver-canary.ps1
 M tests/validate_skills.py
?? docs/lanes/v4-cleanup-01.md
```

(`docs/lanes/v4-cleanup-01.md` shows untracked here because this snapshot was
taken before `git add`; it is the new file this report itself is, per
BOUNDARIES.)

## Not done / out of scope (per BOUNDARIES)

- Did not commit or push.
- Did not touch `docs/gates/**`, `docs/HANDOFF.md`, `docs/prd/**`,
  `docs/adr/**`, `CONTEXT.md`, `skills/architect/SKILL.md`,
  `skills/architect/loop.md`, `skills/architect/HANDOFF.template.md`,
  `skills/architect/research.md`, `skills/architect-research/**`, `.claude/**`.
- Did not rewrite DESIGN.md's existing v3 sections — only appended `## 9`.
- Did not touch `.gitignore`.

STATUS: COMPLETE_WITH_CONCERNS (DG2 as literally frozen — `grep -n "architect-loop" install.sh install.ps1 README.md` — cannot return empty while README.md correctly retains the repo's own proper name in its title, clone URL, and Origin prose; install.sh and install.ps1 are clean with zero matches, and no driver-specific reference of any kind remains in README.md, verified line-by-line above. All other gates (DG1 both shells, deletions tracked-empty, sentinel-empty, bash -n exit 0, ParseFile 0 errors, bounded diff empty) pass as run this session.)
