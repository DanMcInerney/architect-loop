# Checkrun: os-docs-checkrun
generated: 2026-07-04T22:19:21.3696800Z  runner: ps1  config: C:/Users/danhm/tools/architect-loop/.architect/checkrun-os-docs.json
check_file: docs/checks/os-docs.md  freeze_sha: 4ebe337a65e0fe616eb4d3310a307c8eba3c8179
Executor: powershell; `uv` uses fresh cache `.architect/tmp/uv-cache-os`.
executor_config: powershell
integrity: check_file_matches_freeze=true head=8354cbc742021eb7e14fa025282c0cae9380ef04
changed_files: 33 listed below; docs_checks_touched=true
DESIGN.md
README.md
docs/checks/os-checkrun-fix.md
docs/jobs/os-checkrun-fix-01.md
docs/jobs/os-checkrun-fix-checkrun.md
docs/jobs/os-docs-01.md
docs/jobs/os-scripts-01.md
docs/jobs/os-scripts-checkrun.md
docs/jobs/os-scripts-rulings.md
docs/jobs/os-validator-01.md
docs/jobs/os-validator-02.md
docs/jobs/os-validator-checkrun.md
docs/jobs/os-validator-rulings.md
docs/jobs/os-wiring-01.md
docs/jobs/os-wiring-checkrun.md
docs/jobs/os-wiring-rulings.md
docs/solutions/orchestrator-mechanics-offload.md
docs/spec/orchestrator-scripts.md
skills/architect/SKILL.md
skills/architect/check-runner.ps1
skills/architect/dispatch.md
skills/architect/loop.md
skills/architect/postflight.ps1
skills/architect/postflight.sh
skills/architect/preflight.ps1
skills/architect/preflight.sh
tests/fixtures/checkrun/config-quoted-bash.json
tests/fixtures/checkrun/config-quoted-ps.json
tests/fixtures/checkrun/fixture-checks-quoted-bash.md
tests/fixtures/checkrun/fixture-checks-quoted-ps.md
tests/fixtures/orchscripts/make-fixture.ps1
tests/fixtures/orchscripts/make-fixture.sh
tests/validate_skills.py

## OD1 — README names the scripts in the factory-flow description line 12
$ git grep -c "postflight" -- README.md
exit: 0  ms: 789  bytes: 12
README.md:1

## OD2 — DESIGN.md records the evidence line 16
$ git grep -c "postflight" -- DESIGN.md
exit: 0  ms: 562  bytes: 12
DESIGN.md:2

## OD2 — DESIGN.md records the evidence line 17
$ git grep -c "typed-exit" -- DESIGN.md
exit: 0  ms: 476  bytes: 12
DESIGN.md:1

## OD3 — solutions debt consumed line 21
$ Test-Path docs/solutions/orchestrator-mechanics-offload.md
exit: 0  ms: 483  bytes: 6
True

## OD3 — solutions debt consumed line 22
$ git grep -c "2026-07-04" -- docs/solutions/orchestrator-mechanics-offload.md
exit: 0  ms: 492  bytes: 51
docs/solutions/orchestrator-mechanics-offload.md:1

## OD4 — validator still green line 26
$ $env:UV_CACHE_DIR='.architect/tmp/uv-cache-os'; uv run --no-project python tests/validate_skills.py
exit: 0  ms: 503  bytes: 45
OK - 2 skills validated, v4 contracts clean
