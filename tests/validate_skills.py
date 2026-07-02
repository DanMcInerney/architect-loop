#!/usr/bin/env python3
"""Sanity checks for the architect-loop skill repo. Stdlib only.

Catches the failure modes we've actually hit:
- SKILL.md frontmatter description > 1024 chars -> Codex refuses to load the
  skill.
- A skill file referencing a sibling file that doesn't exist.
- README/DESIGN relative links pointing at deleted/moved files.
- Unbalanced ``` fences.
- v4 architect contracts: model aliases, dispatch-rules examples, fixed judge
  template, and Claude agent definition constraints.

Run: python tests/validate_skills.py   (exit 0 = pass)
"""

from __future__ import annotations

import re
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


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def frontmatter(path: Path) -> dict[str, str] | None:
    text = read_text(path)
    m = re.match(r"---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        return None
    fields: dict[str, str] = {}
    current: str | None = None
    for raw_line in m.group(1).splitlines():
        if not raw_line.strip():
            continue
        if not raw_line.startswith((" ", "\t")) and ":" in raw_line:
            key, value = raw_line.split(":", 1)
            current = key.strip()
            fields[current] = value.strip()
        elif current:
            fields[current] = f"{fields[current]} {raw_line.strip()}".strip()
    return fields


def split_csv(value: str) -> list[str]:
    return [item.strip().strip("'\"") for item in value.split(",") if item.strip()]


def check_frontmatter(skill_dir: Path) -> None:
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        errors.append(f"{skill_dir.name}: missing SKILL.md")
        return
    fm = frontmatter(skill_md)
    if fm is None:
        errors.append(f"{skill_dir.name}: SKILL.md has no frontmatter block")
        return
    if fm.get("name") != skill_dir.name:
        errors.append(f"{skill_dir.name}: frontmatter name != directory name")
    desc = fm.get("description")
    if not desc:
        errors.append(f"{skill_dir.name}: frontmatter has no description")
    else:
        flat = re.sub(r"\s+", " ", desc).strip(" >")
        if len(flat) > MAX_DESC:
            errors.append(
                f"{skill_dir.name}: description {len(flat)} chars > {MAX_DESC} "
                "(Codex refuses to load the skill)"
            )


def check_siblings(skill_dir: Path) -> None:
    for sibling in REQUIRED_SIBLINGS.get(skill_dir.name, []):
        if not (skill_dir / sibling).exists():
            errors.append(f"{skill_dir.name}: required file {sibling} missing")
    skill_md = read_text(skill_dir / "SKILL.md")
    repo_files = {
        "AGENTS.md",
        "CLAUDE.md",
        "CONTEXT.md",
        "CONVENTIONS.md",
        "DESIGN.md",
        "GEMINI.md",
        "HANDOFF.md",
        "MEMORY.md",
        "PLAN.md",
        "README.md",
        "SKILL.md",
    }
    for ref in re.findall(r"`([\w][\w.-]*\.md)`", skill_md):
        if ref in repo_files:
            continue
        if re.match(r"(docs|lane|gate|prd|research)", ref):
            continue
        if not (skill_dir / ref).exists():
            errors.append(f"{skill_dir.name}: SKILL.md references `{ref}` which doesn't exist")


def check_fences(path: Path) -> None:
    if read_text(path).count("```") % 2 != 0:
        errors.append(f"{path.relative_to(ROOT)}: odd number of ``` fences")


def check_local_links(path: Path) -> None:
    text = read_text(path)
    for label, target in re.findall(r"\[([^\]]+)\]\(([^)#\s]+)\)", text):
        if target.startswith(("http://", "https://", "mailto:")):
            continue
        if not (ROOT / target).exists():
            errors.append(f"{path.name}: link '{label}' -> {target} doesn't exist")


def markdown_cells(row: str) -> list[str]:
    return [cell.strip() for cell in row.strip().strip("|").split("|")]


def markdown_cell_value(cell: str) -> str:
    return cell.strip().strip("`").strip()


def check_model_alias_table() -> None:
    dispatch = SKILLS / "architect" / "dispatch.md"
    if not dispatch.exists():
        errors.append("architect: required file dispatch.md missing")
        return
    lines = read_text(dispatch).splitlines()
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


ROLE_CONFIG_RE = re.compile(r"^(brain|brawn)\s*=\s*(claude|codex)/[^\s/#]+(:[^\s/#]+)?$")
DISPATCH_RULE_RE = re.compile(
    r"^when\s+.+\s+->\s+(claude|codex)/[^\s/#]+(:[^\s/#]+)?(\s+#\s*.+)?$"
)


def check_config_example() -> None:
    candidates = [SKILLS / "architect" / "loop.md", SKILLS / "architect" / "dispatch.md"]
    blocks: list[str] = []
    for path in candidates:
        if path.exists():
            blocks.extend(re.findall(r"```[^\n]*\n(.*?)```", read_text(path), re.DOTALL))
    target = None
    for block in blocks:
        lines = [line.strip() for line in block.splitlines()]
        if any(line.startswith(("brain =", "brawn =", "when ")) for line in lines):
            target = block
            break
    if target is None:
        errors.append("skills/architect: no fenced C2/C2' config example with brain/brawn or dispatch rules")
        return
    saw_dispatch_rule = False
    for line in target.splitlines():
        clean = line.strip()
        if not clean or clean.startswith("#"):
            continue
        if clean.startswith("when "):
            saw_dispatch_rule = True
            if not DISPATCH_RULE_RE.fullmatch(clean):
                errors.append(f"skills/architect: invalid C2' dispatch-rules example line: {line}")
            continue
        role_line = clean.split("#", 1)[0].strip()
        if not ROLE_CONFIG_RE.fullmatch(role_line):
            errors.append(f"skills/architect: invalid C2 config example line: {line}")
    if not saw_dispatch_rule:
        errors.append("skills/architect: C2' config example missing a dispatch-rules line")


def check_judge_template() -> None:
    dispatch = SKILLS / "architect" / "dispatch.md"
    text = read_text(dispatch)
    m = re.search(
        r"<!-- architect-judge-template:start -->\n```text\n(.*?)\n```\n<!-- architect-judge-template:end -->",
        text,
        re.DOTALL,
    )
    if not m:
        errors.append("skills/architect/dispatch.md: missing C5 fixed judge template block")
        return
    block = m.group(1)
    for required in (
        "Frozen gate file path:",
        "Freeze commit SHA:",
        "Branch to judge:",
        "Verdict format:",
        "Gates integrity:",
        "Diff vs intent:",
        "Per gate:",
    ):
        if required not in block:
            errors.append(f"skills/architect/dispatch.md: C5 judge template missing {required}")
    if "must not add slice-specific prose" not in text:
        errors.append("skills/architect/dispatch.md: C5 template does not forbid slice-specific prose")


def check_agent_definitions() -> None:
    builder = ROOT / ".claude" / "agents" / "architect-builder.md"
    judge = ROOT / ".claude" / "agents" / "architect-judge.md"
    for path in (builder, judge):
        if not path.exists():
            errors.append(f"{path.relative_to(ROOT)} missing")
            continue
        fm = frontmatter(path)
        if fm is None:
            errors.append(f"{path.relative_to(ROOT)}: frontmatter missing or invalid")
            continue
        for key in ("name", "description", "tools", "model"):
            if key not in fm or not fm[key]:
                errors.append(f"{path.relative_to(ROOT)}: missing frontmatter field {key}")
    if builder.exists():
        fm = frontmatter(builder) or {}
        disallowed = set(split_csv(fm.get("disallowedTools", "")))
        if "Bash(git commit *)" not in disallowed:
            errors.append(".claude/agents/architect-builder.md: missing disallowedTools Bash(git commit *)")
        if "Bash(git push *)" not in disallowed:
            errors.append(".claude/agents/architect-builder.md: missing disallowedTools Bash(git push *)")
        if fm.get("isolation") != "worktree":
            errors.append(".claude/agents/architect-builder.md: isolation must be worktree")
        if fm.get("model") != "inherit":
            errors.append(".claude/agents/architect-builder.md: model must be inherit")
    if judge.exists():
        fm = frontmatter(judge) or {}
        tools = set(split_csv(fm.get("tools", "")))
        disallowed = set(split_csv(fm.get("disallowedTools", "")))
        if "Edit" in tools or "Write" in tools:
            errors.append(".claude/agents/architect-judge.md: tools must not include Edit or Write")
        if "Edit" not in disallowed or "Write" not in disallowed:
            errors.append(".claude/agents/architect-judge.md: disallowedTools must include Edit and Write")
        if fm.get("model") != "inherit":
            errors.append(".claude/agents/architect-judge.md: model must be inherit")


def check_retired_loop_terms() -> None:
    for path in SKILLS.rglob("*.md"):
        text = read_text(path)
        if "sentinel" in text.lower():
            errors.append(f"{path.relative_to(ROOT)}: contains retired term sentinel")
        if re.search(r"^LOOP:", text, re.MULTILINE):
            errors.append(f"{path.relative_to(ROOT)}: contains retired LOOP line")


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
    check_model_alias_table()
    check_config_example()
    check_judge_template()
    check_agent_definitions()
    check_retired_loop_terms()
    if errors:
        print(f"FAIL - {len(errors)} problem(s):")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(f"OK - {len(skill_dirs)} skills validated, v4 contracts clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
