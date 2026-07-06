#!/usr/bin/env python3
"""Sanity checks for the architect-loop skill repo. Stdlib only.

Catches the failure modes we've actually hit:
- SKILL.md frontmatter description > 1024 chars -> Codex refuses to load the
  skill (observed live: "invalid description: exceeds maximum length").
- A skill file referencing a sibling file that doesn't exist.
- README/DESIGN relative links pointing at deleted/moved files.
- Unbalanced ``` fences (breaks the builder-block templates when pasted).

Run: python tests/validate_skills.py   (exit 0 = pass)
"""

from __future__ import annotations

import re
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
MAX_DESC = 1024
REQUIRED_SIBLINGS = {
    "architect": [
        "dispatch.md",
        "research.md",
        "loop.md",
        "check-runner.sh",
        "watchdog.sh",
        "status.sh",
    ],
    "architect-research": ["tactics.md"],
}
errors: list[str] = []


def check_frontmatter(skill_dir: Path) -> None:
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        errors.append(f"{skill_dir.name}: missing SKILL.md")
        return
    text = skill_md.read_text(encoding="utf-8")
    m = re.match(r"---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        errors.append(f"{skill_dir.name}: SKILL.md has no frontmatter block")
        return
    fm = m.group(1)
    name = re.search(r"^name:\s*(\S+)", fm, re.MULTILINE)
    if not name or name.group(1) != skill_dir.name:
        errors.append(f"{skill_dir.name}: frontmatter name != directory name")
    desc = re.search(r"^description:\s*>?\s*\n?(.*?)(?=^\w+:|\Z)", fm, re.MULTILINE | re.DOTALL)
    if not desc:
        errors.append(f"{skill_dir.name}: frontmatter has no description")
    else:
        flat = re.sub(r"\s+", " ", desc.group(1)).strip()
        if len(flat) > MAX_DESC:
            errors.append(
                f"{skill_dir.name}: description {len(flat)} chars > {MAX_DESC} "
                "(Codex refuses to load the skill)"
            )


def check_siblings(skill_dir: Path) -> None:
    for sibling in REQUIRED_SIBLINGS.get(skill_dir.name, []):
        if not (skill_dir / sibling).exists():
            errors.append(f"{skill_dir.name}: required file {sibling} missing")
    skill_md = (skill_dir / "SKILL.md").read_text(encoding="utf-8")
    for ref in re.findall(r"`([\w][\w.-]*\.md)`", skill_md):
        if ref in ("SKILL.md", "AGENTS.md", "CLAUDE.md", "HANDOFF.md", "CONVENTIONS.md",
                   "PLAN.md", "MEMORY.md", "README.md", "GEMINI.md", "verdict.md"):
            continue  # repo-of-use files, not siblings of the skill
        if ref == "DESIGN.md" and (ROOT / "DESIGN.md").exists():
            continue  # lives at the skill repo root, referenced as such
        if re.match(r"(docs|lane|gate|prd|research)", ref):
            continue
        if not (skill_dir / ref).exists():
            errors.append(f"{skill_dir.name}: SKILL.md references `{ref}` which doesn't exist")


def check_fences(path: Path) -> None:
    if path.read_text(encoding="utf-8").count("```") % 2 != 0:
        errors.append(f"{path.relative_to(ROOT)}: odd number of ``` fences")


def check_local_links(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    for label, target in re.findall(r"\[([^\]]+)\]\(([^)#\s]+)\)", text):
        if target.startswith(("http://", "https://", "mailto:")):
            continue
        if not (ROOT / target).exists():
            errors.append(f"{path.name}: link '{label}' -> {target} doesn't exist")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def check_local_architect_contract() -> None:
    architect_files = [
        SKILLS / "architect" / "SKILL.md",
        SKILLS / "architect" / "dispatch.md",
        SKILLS / "architect" / "loop.md",
        SKILLS / "architect" / "research.md",
        ROOT / "README.md",
        ROOT / "DESIGN.md",
    ]
    combined = "\n".join(read(p) for p in architect_files if p.exists())
    if "Fable" in combined or "fable" in combined:
        errors.append("local architect contract must not reference Fable")
    for required in (
        "Opus 4.8",
        "gpt-5.5",
        'model_reasoning_effort="xhigh"',
        ".scratch/architect-loop",
        "final.patch",
        "worktree add --detach",
        "does not create issues, branches, commits",
        "no default Claude builder fallback",
    ):
        if required not in combined:
            errors.append(f"local architect contract missing {required!r}")
    forbidden = (
        "gh issue create",
        "docs/issues",
        "docs/runs",
        "factory/<run>",
        "git switch -c",
        "git checkout -b",
        "git commit -F",
        "git add -A",
        ".scratch/<feature-slug>",
    )
    for needle in forbidden:
        if needle in combined:
            errors.append(f"local architect contract contains forbidden upstream pattern {needle!r}")


def check_research_contract() -> None:
    skill = SKILLS / "architect-research" / "SKILL.md"
    tactics = SKILLS / "architect-research" / "tactics.md"
    text = read(skill) + "\n" + read(tactics)
    if "lanes.md" in text:
        errors.append("architect-research still references lanes.md")
    for required in (
        "source tag",
        "numbered source list",
        "do-not-rechase",
        ".scratch/architect-loop/research",
    ):
        if required not in text:
            errors.append(f"architect-research contract missing {required!r}")


def check_script_contracts() -> None:
    for name in ("check-runner.sh", "watchdog.sh", "status.sh"):
        path = SKILLS / "architect" / name
        if not path.exists():
            errors.append(f"architect: missing {name}")
            continue
        if not os.access(path, os.X_OK):
            errors.append(f"architect/{name}: not executable")
    check_runner = read(SKILLS / "architect" / "check-runner.sh")
    for required in (
        "frozen_check_file",
        "CHECKRUN SUMMARY",
        "check_file_matches_frozen",
        "exit 2",
        "exit 5",
    ):
        if required not in check_runner:
            errors.append(f"check-runner.sh missing {required!r}")
    watchdog = read(SKILLS / "architect" / "watchdog.sh")
    for required in ("WATCHDOG: ALL_DONE", "WATCHDOG: STALL", "WATCHDOG: REPEAT", "WATCHDOG: INTEGRATED"):
        if required not in watchdog:
            errors.append(f"watchdog.sh missing {required!r}")
    status = read(SKILLS / "architect" / "status.sh")
    if "gh " in status or "docs/runs" in status:
        errors.append("status.sh must stay local-only; found gh or docs/runs")


def check_runner_fixture() -> None:
    script = SKILLS / "architect" / "check-runner.sh"
    if not script.exists():
        return
    temp = Path(tempfile.mkdtemp(prefix="architect-checkrun-"))
    try:
        gates = temp / "gates.md"
        frozen = temp / "frozen.md"
        evidence = temp / "evidence.md"
        cfg = temp / "cfg.json"
        gates.write_text(
            '- RUN: `printf ok` -> exit:0 match:"ok"\n'
            '- RUN: `sh -c "exit 1"` -> exit:1\n',
            encoding="utf-8",
        )
        shutil.copyfile(gates, frozen)
        cfg.write_text(
            json.dumps(
                {
                    "check_file": str(gates),
                    "frozen_check_file": str(frozen),
                    "workdir": str(ROOT),
                    "base_sha": "",
                    "evidence_out": str(evidence),
                    "executor": "bash",
                    "max_output_lines": 20,
                }
            ),
            encoding="utf-8",
        )
        result = subprocess.run(
            ["bash", str(script), str(cfg)],
            cwd=ROOT,
            text=True,
            capture_output=True,
            timeout=20,
        )
        if result.returncode != 0:
            errors.append(
                "check-runner fixture expected exit 0 "
                f"got {result.returncode}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
            )
            return
        text = evidence.read_text(encoding="utf-8")
        if "CHECKRUN SUMMARY: run_items=2 pass=2 fail=0" not in text:
            errors.append("check-runner fixture missing passing summary")
        if "integrity: check_file_matches_frozen=true" not in text:
            errors.append("check-runner fixture missing integrity true")
    finally:
        shutil.rmtree(temp, ignore_errors=True)


def main() -> int:
    skill_dirs = sorted(d for d in SKILLS.iterdir() if d.is_dir())
    if not skill_dirs:
        errors.append("no skill directories found under skills/")
    for d in skill_dirs:
        check_frontmatter(d)
        check_siblings(d)
        for md in d.glob("*.md"):
            check_fences(md)
    for doc in ("README.md", "DESIGN.md"):
        p = ROOT / doc
        if p.exists():
            check_fences(p)
            check_local_links(p)
        else:
            errors.append(f"{doc} missing")
    check_local_architect_contract()
    check_research_contract()
    check_script_contracts()
    check_runner_fixture()
    if errors:
        print(f"FAIL — {len(errors)} problem(s):")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(f"OK — {len(skill_dirs)} skills validated, README/DESIGN links + fences clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
