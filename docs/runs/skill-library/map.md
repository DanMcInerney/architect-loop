# Run map: skill-library

Scouted at commit de69e13 (2026-07-05). Planning-time input for spec,
decomposition, and stress test. EXPIRES at first factory-branch merge:
after that, worktree reality is truth and this map is history. Builders
do not receive this map; issues carry change-skeletons and interface
contracts instead (ruling 2026-07-05, in-session).

**Skill / Reference Inventory**

- `skills/architect/SKILL.md:10` 280 lines; sections: Architect, Hard Rules `:28`, Procedure `:54`, Ground `:56`, Intake `:78`, Spec Approval `:118`, Decompose `:176`, Factory Loop `:214`, Finish `:253`, Hard Stops `:261`, Maintenance `:274`.
- `skills/architect/dispatch.md:1` 686 lines; load sections: Contents `:3`, Model alias table `:36`, dispatch rules `:51`, per-harness delegation `:96`, judge templates `:121`/`:143`, check-runner `:169`, scout `:178`, pre/postflight `:257`, issue conventions `:338`, monitor `:396`, status `:427`, respawn `:526`, builder block `:605`.
- `skills/architect/loop.md:1` 142 lines; sections: Contents `:3`, Factory block procedure `:19`, Monitor protocol `:47`, Verdict comments `:70`, Failure ladder `:90`, Escalation digest `:106`, Hard Stops `:118`, Context discipline `:135`.
- `skills/architect/tracker.md:1` 86 lines; sections: Config `:3`, Markdown issue format `:9`, Comments `:25`, TSV emission `:43`, Preflight per mode `:59`, Finish per mode `:68`, Command mapping `:75`.
- `skills/architect/research.md:1` 89 lines; sections: Fan out `:8`, Research block template `:52`, Gather `:75`.
- `skills/architect-research/SKILL.md:13` 176 lines; sections: Scale `:20`, Procedure `:34`, Scope `:36`, Scout/design `:44`, Fan out `:68`, Gap round `:110`, Verify `:125`, Synthesize `:152`, Hand off `:171`.
- `skills/architect-research/tactics.md:1` 203 lines; sections: Contents `:3`, Researcher 0 `:46`, Academic `:58`, Popular repos `:88`, Cutting-edge repos `:107`, Production patterns `:127`, General web `:156`, Expert opinion `:169`.

**Load-Bearing Pointers**

- `skills/architect/SKILL.md:21` points to `dispatch.md` sections `## Model alias table`, `## Issue conventions`, `## Scout dispatch`, `## Monitor dispatch`, `## Respawn-with-answer template`.
- `skills/architect/SKILL.md:25` points to `loop.md` `## Factory block procedure` and `research.md` fan-out.
- `skills/architect/SKILL.md:26` points to `tracker.md` `## Preflight per mode`, `## Finish per mode`, `## Command mapping`.
- `skills/architect/SKILL.md:87` makes `docs/runs/<run>/map.md` a committed scout artifact cited by spec and issues.
- `skills/architect/loop.md:28` is the central typed flow pointer: check-runner exit 0/2/5, judge dispatch, then postflight exit 0/2/3/5.
- `skills/architect/dispatch.md:125` and `skills/architect/dispatch.md:147` are marker-delimited fixed judge templates validated by tests.
- `skills/architect/dispatch.md:171` defines graded RUN grammar: first backtick command, `-> exit:<n>`, optional `match:"<substring>"`, fixed substring semantics.
- `skills/architect/dispatch.md:176` defines check-runner config fields: `check_file`, `workdir`, `freeze_sha`, `evidence_out`, `executor`, `max_output_lines`.
- `skills/architect/dispatch.md:266` defines preflight JSON; `skills/architect/dispatch.md:278` defines postflight JSON.
- `skills/architect/dispatch.md:398` defines watchdog config and launch ownership.
- `skills/architect/dispatch.md:648` requires builder reports under `docs/jobs/<run>/<issue-slug>-01.md` with RAW evidence and terminal STATUS.

**Script Pairs**

- `skills/architect/check-runner.ps1:1` / `skills/architect/check-runner.sh:10`; entry config path; parses RUN expectations at `check-runner.ps1:131` / `check-runner.sh:27`; emits summary at `check-runner.ps1:248` / `check-runner.sh:204`; exits 0 green `check-runner.ps1:259`, 2 failed RUNs `check-runner.ps1:258`, 5 grammar/config error `check-runner.ps1:23`.
- `skills/architect/preflight.ps1:1` / `skills/architect/preflight.sh:40`; config requires `repo_root`, `freeze_sha`, `worktree`, `job_branch` at `preflight.ps1:61`; verifies freeze/worktree/required files `preflight.ps1:73`; exits 0 `PREFLIGHT: OK` at `preflight.ps1:95`, 5 `PREFLIGHT: FAIL` at `preflight.ps1:44`.
- `skills/architect/postflight.ps1:1` / `skills/architect/postflight.sh:42`; config reads `repo_root`, `factory_branch`, `job_branch`, `freeze_sha`, `merge_message`, `worktree` at `postflight.ps1:66`; audits `may_touch`/`exempt` at `postflight.ps1:72`; exits 0 OK `postflight.ps1:157`, 2 violation `postflight.ps1:116`, 3 conflict `postflight.ps1:126`, 5 error `postflight.ps1:32`.
- `skills/architect/watchdog.ps1:1` / `skills/architect/watchdog.sh:8`; config path entry; exits 0 all done `watchdog.ps1:99`, 2 integrated `watchdog.ps1:72`, 3 stall `watchdog.ps1:83`, 4 repeat `watchdog.ps1:92`.
- `skills/architect/status.ps1:1` / `skills/architect/status.sh:9`; entry accepts repo/run args; manifest/run validation at `status.ps1:126` and `status.sh:115`; `NOOPENRUN` handling at `status.sh:211`; watchdog summary prints at `status.ps1:315`.
- `skills/architect/trigger-eval.ps1:1` / `skills/architect/trigger-eval.sh:98`; fixture parser entry; fixture grammar exits 2 on malformed blocks `trigger-eval.sh:102`; miss count exits 1/0 at `trigger-eval.ps1:273`.

**Installers / Locations**

- `install.ps1:3` sources `skills`; installs Claude skills to cwd `.claude\skills` or user `.claude\skills` at `install.ps1:5`; installs Codex skills to cwd `.agents\skills` or user `.agents\skills` at `install.ps1:18`.
- `install.sh:4` sources `skills`; installs Claude skills to `.claude/skills` or `$HOME/.claude/skills` at `install.sh:6`; installs Codex skills to `.agents/skills` or `$HOME/.agents/skills` at `install.sh:19`.
- `.claude/agents/architect-builder.md:1` defines builder agent frontmatter; worktree isolation/background at `.claude/agents/architect-builder.md:7`; docs/checks read-only at `.claude/agents/architect-builder.md:23`; never commit/push at `.claude/agents/architect-builder.md:48`.
- `.claude/agents/architect-judge.md:1` defines read-only judge; disallows Edit/Write at `.claude/agents/architect-judge.md:5`.

**Docs Conventions**

- `README.md:242` maps run artifacts: specs `docs/spec/`, manifest `docs/runs/<run>/manifest.md`, checks `docs/checks/<run>/`, reports/evidence `docs/jobs/<run>/`, markdown issues `docs/issues/<run>/`, solutions `docs/solutions/`.
- `docs/spec/multi-run.md:43` defines manifest pinning with greppable frontmatter and run marker.
- `docs/spec/multi-run.md:76` namespaces checks/jobs/issues by run.
- `docs/spec/multi-run.md:95` defines `docs/STOP` global stop and `docs/runs/<run>/STOP` per-run stop.
- `CONTEXT.md:62` defines frozen checks as read-only after freeze.
- `CONTEXT.md:67` defines scout map as committed `docs/runs/<run>/map.md` with file:line anchors.
- `CONTEXT.md:75` defines rulings file as orchestrator-owned append-only post-freeze intent.
- `skills/architect/SKILL.md:278` anchors trigger-eval fixture path `docs/evals/trigger-prompts.md`.

**Testing Seams**

- `tests/validate_skills.py:36` freezes required sibling files for `architect` and `architect-research`.
- `tests/validate_skills.py:181` validates `dispatch.md` model alias table structure and required aliases.
- `tests/validate_skills.py:307` validates check-runner/preflight/postflight dispatch contracts and marker blocks.
- `tests/validate_skills.py:430` enforces architect combined text budget; `tests/validate_skills.py:459` enforces architect-research combined budget.
- `tests/validate_skills.py:548` validates watchdog contract; `tests/validate_skills.py:570` validates status contract.
- `tests/validate_skills.py:755` creates postflight lane/no-op fixtures; `tests/validate_skills.py:901` runs check-runner fixtures for both executors.
- `tests/validate_skills.py:966` validates status run pinning against GitHub and markdown fixture repos.
- `tests/fixtures/checkrun/config-ps.json:1` and `tests/fixtures/checkrun/config-bash.json:1` are passing runner configs; quoted/missing configs anchor fail/error paths at `tests/fixtures/checkrun/config-quoted-ps.json:1` and `tests/fixtures/checkrun/config-missing.json:1`.
- `tests/fixtures/orchscripts/make-fixture.ps1:86` and `tests/fixtures/orchscripts/make-fixture.sh:67` generate preflight/postflight config fixtures.

**Gotchas**

- `skills/architect/dispatch.md:100` says Claude CLI builder spawns can run unisolated despite `isolation: worktree`; Claude-backend jobs must not pre-create `.architect/wt/...`.
- `skills/architect/postflight.ps1:59` hard-codes `docs/checks/` as violation regardless of configured globs.
- `skills/architect/dispatch.md:137` marks missing/stale checkrun evidence INVALID, not FAIL.
- `skills/architect/dispatch.md:307` says postflight exit 5 is the only typed path to manual fallback; exit 2/3 are rulings.
- `docs/solutions/preflight-relative-worktree-cwd-drift.md:17` records `evidence_out` resolution as runner cwd/repo-root based, not config-workdir-relative.
- `tests/validate_skills.py:5` records Codex SKILL frontmatter description >1024 chars as load failure.