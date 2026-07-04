# Frozen checks: loop-hygiene-docs-finish (#78)

Purpose: verify the product-docs update (sync judges, recovery ladder,
close-out, parallel reads, native edges, cross-platform support), the
citation rewrite that makes the end-of-run docs/ deletion safe, and the
DESIGN.md evidence entries for this run.
Spec pointer: docs/spec/loop-hygiene.md (goals 4-6; assumptions A2, A7).
Fix contract: on FAIL, the orchestrator fixes issue #78's text or context and
respawns a fresh builder at the same tier; builders never edit this file.

Executor: powershell

- RUN: `git grep -c "](docs/" -- README.md DESIGN.md CONTEXT.md` -> exit 1, count 0 (no markdown links into docs/ remain; deletion-safe)
- RUN: `git grep -c "synchronous" -- README.md` -> exit 0, count >= 1 (sync judge behavior documented)
- RUN: `git grep -ci "recovery ladder" -- README.md DESIGN.md` -> exit 0, at least one file reports count >= 1
- RUN: `git grep -c -e "--parent" -- README.md` -> exit 0, count >= 1 (native edges documented; scoped to README because DESIGN.md already matched pre-build — grill finding)
- RUN: `git grep -ci "macOS" -- README.md` -> exit 0, count >= 1 (cross-platform statement)
- RUN: `git grep -c "superseded by the 2026-07-04" -- DESIGN.md` -> exit 0, count >= 1 (concurrent-judges supersession recorded; exact phrase required because bare "superseded" collides with the pre-existing tier-up entry — grill finding)
- RUN: `git grep -c "git history" -- DESIGN.md` -> exit 0, count >= 1 (deletion note pointing at git history)
- RUN: `$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run --no-project python tests/validate_skills.py` -> exit 0, output "OK" (link checker green after rewrite; bare `python` is a Store stub on this host)

Judge-only items:

- J1: DESIGN.md contains evidence entries for all four areas: (a) judge-hang
  diagnosis + sync-dispatch fix with the 2026-07-04 canary facts, (b)
  close-out discipline, (c) xplat parity summary sourced from #77's report,
  (d) native-edge fix rationale (status emitter reads `--json
  parent,blockedBy`; text edges invisible). Quote one line each.
- J2: Working-convention docs/ path mentions (future-run output locations
  such as "checks live in docs/checks/") are preserved in README/DESIGN
  where they describe the loop's behavior — the rewrite removed only
  links/references to files being deleted. Cite examples.
- J3: .gitignore docs/ carve-out block unchanged (or the report records why
  a change was required); the job report contains the verification.
- J4: Diff vs intent against issue #78: only README.md, DESIGN.md,
  CONTEXT.md, .gitignore touched; existing voice and diagrams amended, not
  rewritten wholesale.
