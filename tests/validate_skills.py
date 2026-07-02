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
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
MAX_DESC = 1024
REQUIRED_SIBLINGS = {
    "architect": ["dispatch.md", "research.md", "HANDOFF.template.md", "loop.md"],
    "architect-research": ["lanes.md"],
}
errors: list[str] = []
notes: list[str] = []


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
                   "PLAN.md", "MEMORY.md", "README.md", "GEMINI.md"):
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


SENTINEL_RE = re.compile(r"^LOOP: (CONTINUE|WAIT [0-9]+( \(.+\))?|STOP \(.+\))$")


def check_loop_sentinel_regex() -> None:
    accepted = [
        "LOOP: CONTINUE",
        "LOOP: WAIT 20 (2 lanes in flight)",
        "LOOP: STOP (goal met)",
    ]
    rejected = [
        "LOOP: MAYBE",
        "LOOP: WAIT",
        "LOOP: STOP",
        "no LOOP line here",
    ]
    for line in accepted:
        if not SENTINEL_RE.fullmatch(line):
            errors.append(f"C1 sentinel regex rejected valid form: {line}")
    for line in rejected:
        loop_lines = [candidate for candidate in line.splitlines() if candidate.startswith("LOOP:")]
        if loop_lines and any(SENTINEL_RE.fullmatch(candidate) for candidate in loop_lines):
            errors.append(f"C1 sentinel regex accepted invalid form: {line}")
        if not loop_lines and SENTINEL_RE.search(line):
            errors.append(f"C1 sentinel regex accepted input with no LOOP line: {line}")


def markdown_cells(row: str) -> list[str]:
    return [cell.strip() for cell in row.strip().strip("|").split("|")]


def markdown_cell_value(cell: str) -> str:
    return cell.strip().strip("`").strip()


def check_model_alias_table() -> None:
    dispatch = SKILLS / "architect" / "dispatch.md"
    if not dispatch.exists():
        errors.append("architect: required file dispatch.md missing")
        return
    lines = dispatch.read_text(encoding="utf-8").splitlines()
    try:
        start = lines.index("## Model alias table")
    except ValueError:
        errors.append("skills/architect/dispatch.md: missing ## Model alias table")
        return
    section: list[str] = []
    for line in lines[start + 1:]:
        if line.startswith("## "):
            break
        if line.strip():
            section.append(line)
    table = [line for line in section if line.lstrip().startswith("|")]
    if len(table) < 3:
        errors.append("skills/architect/dispatch.md: Model alias table missing rows")
        return
    headers = markdown_cells(table[0])
    try:
        alias_idx = headers.index("Alias")
        flags_idx = headers.index("Flags")
    except ValueError:
        errors.append("skills/architect/dispatch.md: Model alias table needs Alias and Flags columns")
        return
    found: dict[str, str] = {}
    for row in table[2:]:
        cells = markdown_cells(row)
        if len(cells) <= max(alias_idx, flags_idx):
            continue
        found[markdown_cell_value(cells[alias_idx])] = markdown_cell_value(cells[flags_idx])
    for alias in ("codex/best", "claude/best", "codex/tier-down", "claude/tier-down"):
        if alias not in found:
            errors.append(f"skills/architect/dispatch.md: Model alias table missing {alias}")
        elif not found[alias].strip():
            errors.append(f"skills/architect/dispatch.md: Model alias table has empty Flags for {alias}")


def check_drivers() -> None:
    sh_driver = ROOT / "bin" / "architect-loop.sh"
    ps_driver = ROOT / "bin" / "architect-loop.ps1"
    if not sh_driver.exists():
        errors.append("bin/architect-loop.sh missing")
    if not ps_driver.exists():
        errors.append("bin/architect-loop.ps1 missing")
    bash = shutil.which("bash")
    if bash and sh_driver.exists():
        result = subprocess.run([bash, "-n", str(sh_driver)], text=True, capture_output=True)
        if result.returncode != 0:
            output = (result.stdout + result.stderr).strip()
            errors.append(f"bash -n bin/architect-loop.sh failed ({result.returncode}): {output}")
    else:
        notes.append("SKIP bash -n bin/architect-loop.sh: bash not on PATH")
    shell = shutil.which("powershell") or shutil.which("pwsh")
    if shell and ps_driver.exists():
        parser = (
            "$t=$null;$e=$null;"
            "[void][System.Management.Automation.Language.Parser]::ParseFile("
            "'bin/architect-loop.ps1',[ref]$t,[ref]$e); "
            "if($e.Count){$e|ForEach-Object{Write-Output $_.Message}; exit 1}"
        )
        result = subprocess.run([shell, "-NoProfile", "-Command", parser], cwd=ROOT, text=True, capture_output=True)
        if result.returncode != 0:
            output = (result.stdout + result.stderr).strip()
            errors.append(f"PowerShell parser check failed ({result.returncode}): {output}")
    else:
        notes.append("SKIP PowerShell parser check: powershell/pwsh not on PATH")


CONFIG_LINE_RE = re.compile(r"^(brain|brawn)\s*=\s*(claude|codex)/[^\s/#]+(:[^\s/#]+)?$")


def check_loop_config_example() -> None:
    loop_md = SKILLS / "architect" / "loop.md"
    if not loop_md.exists():
        errors.append("skills/architect/loop.md: missing config example for C2")
        return
    text = loop_md.read_text(encoding="utf-8")
    blocks = re.findall(r"```[^\n]*\n(.*?)```", text, re.DOTALL)
    target = None
    for block in blocks:
        if any(line.strip().startswith(("brain =", "brawn =")) for line in block.splitlines()):
            target = block
            break
    if target is None:
        errors.append("skills/architect/loop.md: no fenced C2 config example with brain/brawn")
        return
    for line in target.splitlines():
        clean = line.split("#", 1)[0].strip()
        if not clean:
            continue
        if not CONFIG_LINE_RE.fullmatch(clean):
            errors.append(f"skills/architect/loop.md: invalid C2 config example line: {line}")


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
    check_loop_sentinel_regex()
    check_model_alias_table()
    check_drivers()
    check_loop_config_example()
    for note in notes:
        print(note)
    if errors:
        print(f"FAIL — {len(errors)} problem(s):")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(f"OK — {len(skill_dirs)} skills validated, README/DESIGN links + fences clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
