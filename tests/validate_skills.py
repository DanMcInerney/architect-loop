#!/usr/bin/env python3
"""Sanity checks for the architect-loop skill repo. Stdlib only.

Catches the failure modes we've actually hit:
- SKILL.md frontmatter description > 1024 chars -> Codex refuses to load the
  skill.
- A skill file referencing a sibling file that doesn't exist.
- README/DESIGN relative links pointing at deleted/moved files.
- Unbalanced ``` fences.
- v4 architect contracts: model aliases, dispatch-rules examples, fixed judge
  template, v5 handoff-retirement guard, and Claude agent definition
  constraints.

Run: python tests/validate_skills.py   (exit 0 = pass)
"""

from __future__ import annotations

import json
import re
import os
import shutil
import subprocess
import stat
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
MAX_DESC = 1024
# s9 ruling (docs/jobs/skill-library/s9-validator-evals-rulings.md): BOTH
# frontmatter caps hold - `description` alone <= MAX_DESC (1024, Codex
# loader limit) AND `description` + `when_to_use` combined <= 1536 (Claude
# skill-listing cap).
MAX_DESC_PLUS_WHEN_TO_USE = 1536
ARCHITECT_SKILL_TEXT_MAX_NON_BLANK = 989
ARCHITECT_RESEARCH_TEXT_MAX_NON_BLANK = 500
SKILL_BODY_TOKEN_PROXY_MAX = 5_000
SKILL_BODY_TOKEN_PROXY_FACTOR = 1.33
REFERENCE_TOC_NON_BLANK_THRESHOLD = 100
REQUIRED_SIBLINGS = {
    "architect": [
        "dispatch.md",
        "research.md",
        "loop.md",
        "run-job.ps1",
        "run-job.sh",
        "kill-job.ps1",
        "kill-job.sh",
        "watchdog.ps1",
        "watchdog.sh",
        "status.ps1",
        "status.sh",
        "check-runner.ps1",
        "check-runner.sh",
        "preflight.ps1",
        "preflight.sh",
        "postflight.ps1",
        "postflight.sh",
        "tracker.md",
    ],
    "architect-research": ["tactics.md"],
}
# s9 library inventory: the seven stage skills shipped by the skill-library
# run, each mapped to the sibling files its SKILL.md relies on. Also carries
# the architect-fast loop skill.
LIBRARY_SKILLS = {
    "codebase-design": ["DEEPENING.md", "DESIGN-IT-TWICE.md"],
    "to-spec": [],
    "to-issues": [],
    "frozen-checks": [],
    "tdd": ["tests.md", "mocking.md"],
    "adversarial-review": [],
    "final-review": [],
    "integrate": [],
    "architect-fast": [],
}
# s9 per-skill non-blank-line budgets, caps named in each stage skill's
# frozen check (docs/checks/skill-library/). The architect entry (SKILL.md
# <= 220) is the post-s8 re-baseline; the pre-existing five-file combined
# guard (ARCHITECT_SKILL_TEXT_MAX_NON_BLANK) was left unchanged through s9-s12
# because check_design_guard_cap pins its cap to the number stated in
# DESIGN.md, and no build slice was scoped to touch that doc sentence.
# docs-finish (issue #116) re-baselined both together to the measured
# post-s12 combined total (989 non-blank lines across the five files).
LIBRARY_LINE_BUDGETS = {
    "codebase-design": (("SKILL.md", "DEEPENING.md", "DESIGN-IT-TWICE.md"), 240),
    "to-spec": (("SKILL.md",), 100),
    "to-issues": (("SKILL.md",), 110),
    "frozen-checks": (("SKILL.md",), 100),
    "tdd": (("SKILL.md", "tests.md", "mocking.md"), 220),
    "adversarial-review": (("SKILL.md",), 110),
    "final-review": (("SKILL.md",), 110),
    "integrate": (("SKILL.md",), 90),
    "architect": (("SKILL.md",), 220),
    "architect-fast": (("SKILL.md",), 160),
}
# License ruling (docs/spec/skill-library.md `## Open human decisions`):
# adapted skills carry a one-line attribution naming the source repo + MIT.
# s11 (`## Wording policy`) made Pocock's text the baseline for five skills
# and added the attribution to to-spec, to-issues, and final-review; the
# guard covers all five (was two, a pre-s11 baseline - closing review fix).
LIBRARY_ATTRIBUTION = "Adapted from mattpocock/skills (MIT)"
LIBRARY_ATTRIBUTED_SKILLS = (
    "codebase-design",
    "tdd",
    "to-spec",
    "to-issues",
    "final-review",
)
# s9 glossary cohesion lint scope: the seven stage-skill SKILL.md files plus
# skills/architect/SKILL.md. Sibling reference files (tdd/tests.md,
# tdd/mocking.md, codebase-design/DEEPENING.md, ...) are adapted Pocock
# source material and stay out of scope - the lint must not false-positive
# on quoted source material (spec, `Validation strategy`).
GLOSSARY_LINT_SKILLS = tuple(LIBRARY_SKILLS) + ("architect",)
# Lines that NAME a banned substitute while banning it (the glossary's own
# ban lists) are mentions, not uses-as-terms; without this exemption the
# lint would fail on its own definition text at codebase-design/SKILL.md:24-25,
# to-spec/SKILL.md:22-23, to-issues/SKILL.md:28-29,
# adversarial-review/SKILL.md:77-78, and final-review/SKILL.md:105-106.
GLOSSARY_BAN_LIST_MENTIONS = (
    "component/service/boundary/API",
    "component, service, boundary, or API",
    "service, boundary, or API",
    "never substitute component",
    "task or ticket for issue",
    "task/ticket for issue",
)
# Fixed phrases in which boundary/boundaries is not a module/interface
# substitute. The first three come from the spec; MAY TOUCH / MUST NOT
# TOUCH and `Boundary`/`Boundaries` headings are exempted line-level in
# check_glossary_cohesion. The rest are documented exemptions found on
# already-merged skill text (skill text is out of s9's boundary; each is
# reported as a finding in docs/jobs/skill-library/s9-validator-evals-01.md):
#   "boundary amendment"          - factory glossary term, defined in the
#                                   Ruling entry (codebase-design/SKILL.md:54;
#                                   used at architect/SKILL.md:187).
#   "block boundary"              - process-phase edge, not a module
#                                   substitute (architect/SKILL.md:52).
#   "finish boundary"             - process-phase edge (architect/SKILL.md:201).
#   "public boundary you test at" - tdd seam-definition apposition; the same
#                                   sentence resolves it to "the interface"
#                                   (tdd/SKILL.md:15).
#   "owning job's boundary"       - the MAY TOUCH / MUST NOT TOUCH file-set
#                                   concept the spec itself exempts
#                                   (adversarial-review/SKILL.md:51).
GLOSSARY_BOUNDARY_FIXED_PHRASES = (
    "system boundaries",
    "boundary amendment",
    "block boundary",
    "finish boundary",
    "public boundary you test at",
    "owning job's boundary",
)
GLOSSARY_BOUNDARY_RE = re.compile(r"\b[Bb]oundar(?:y|ies)\b")
GLOSSARY_BOUNDARY_HEADING_RE = re.compile(r"^#{1,6}\s+Boundar(?:y|ies)\s*$")
# Case-sensitive word matches per the spec; each maps to the glossary term
# the substitute displaces.
GLOSSARY_BANNED_WORDS = {
    "component": ("module or interface", re.compile(r"\bcomponent\b")),
    "ticket": ("issue", re.compile(r"\bticket\b")),
}
ARCHITECT_HANDOFF_FREE_FILES = [
    SKILLS / "architect" / "SKILL.md",
    SKILLS / "architect" / "loop.md",
    SKILLS / "architect" / "dispatch.md",
]
errors: list[str] = []
BASH_FLAVOR_CACHE: str | None = None
BASH_INNER_PATH_CACHE: str | None = None


def bash_flavor() -> str:
    global BASH_FLAVOR_CACHE
    if BASH_FLAVOR_CACHE is not None:
        return BASH_FLAVOR_CACHE
    bash = shutil.which("bash")
    if not bash:
        BASH_FLAVOR_CACHE = ""
        return BASH_FLAVOR_CACHE
    probe = (
        "if command -v cygpath >/dev/null 2>&1; then echo msys; "
        "elif [ -d /mnt/c ]; then echo wsl; "
        "else echo posix; fi"
    )
    try:
        result = subprocess.run(
            [bash, "-lc", probe],
            text=True,
            capture_output=True,
            timeout=5,
        )
        BASH_FLAVOR_CACHE = result.stdout.strip() if result.returncode == 0 else "posix"
    except Exception:
        BASH_FLAVOR_CACHE = "posix"
    return BASH_FLAVOR_CACHE


def bash_path(path: Path | str) -> str:
    text = str(path)
    if os.name == "nt" and re.match(r"^[A-Za-z]:\\", text):
        rest = text[3:].replace(os.sep, "/")
        if bash_flavor() == "msys":
            return f"/{text[0].lower()}/{rest}"
        if bash_flavor() == "wsl":
            return f"/mnt/{text[0].lower()}/{rest}"
    return text


def bash_inner_executable() -> str:
    global BASH_INNER_PATH_CACHE
    if BASH_INNER_PATH_CACHE is not None:
        return BASH_INNER_PATH_CACHE
    bash = shutil.which("bash")
    if not bash:
        BASH_INNER_PATH_CACHE = "bash"
        return BASH_INNER_PATH_CACHE
    try:
        result = subprocess.run(
            [bash, "-lc", "command -v bash"],
            text=True,
            capture_output=True,
            timeout=5,
        )
        BASH_INNER_PATH_CACHE = result.stdout.strip() if result.returncode == 0 else "bash"
    except Exception:
        BASH_INNER_PATH_CACHE = "bash"
    return BASH_INNER_PATH_CACHE


def bash_command_exists(command: str) -> bool:
    bash = shutil.which("bash")
    if not bash:
        return False
    result = subprocess.run(
        [bash, "-lc", f"command -v {command} >/dev/null 2>&1"],
        text=True,
        capture_output=True,
        timeout=5,
    )
    return result.returncode == 0


def rmtree_with_writable_retry(path: Path) -> None:
    def clear_readonly_and_retry(func, failed_path, _excinfo):
        os.chmod(failed_path, stat.S_IWRITE)
        func(failed_path)

    shutil.rmtree(path, onexc=clear_readonly_and_retry)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def non_blank_line_count(path: Path) -> int:
    return sum(1 for line in read_text(path).splitlines() if line.strip())


def skill_body(path: Path) -> str:
    text = read_text(path)
    m = re.match(r"---\n.*?\n---\n", text, re.DOTALL)
    if m:
        return text[m.end() :]
    return text


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
        elif current is not None:
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
    flat = ""
    if not desc:
        errors.append(f"{skill_dir.name}: frontmatter has no description")
    else:
        flat = re.sub(r"\s+", " ", desc).strip(" >")
        if len(flat) > MAX_DESC:
            errors.append(
                f"{skill_dir.name}: description {len(flat)} chars > {MAX_DESC} "
                "(Codex refuses to load the skill)"
            )
    flat_when = re.sub(r"\s+", " ", fm.get("when_to_use", "")).strip(" >")
    combined = len(flat) + len(flat_when)
    if combined > MAX_DESC_PLUS_WHEN_TO_USE:
        errors.append(
            f"{skill_dir.name}: description + when_to_use {combined} chars > "
            f"{MAX_DESC_PLUS_WHEN_TO_USE} (Claude skill-listing cap; both caps "
            "per docs/jobs/skill-library/s9-validator-evals-rulings.md)"
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
        "MEMORY.md",
        "PLAN.md",
        "README.md",
        "SKILL.md",
    }
    for ref in re.findall(r"`([\w][\w.-]*\.md)`", skill_md):
        if ref in repo_files:
            continue
        if re.match(r"(docs|job|check|spec|research)", ref):
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


ROLE_CONFIG_RE = re.compile(r"^(strategist|builders)\s*=\s*(claude|codex)/[^\s/#]+(:[^\s/#]+)?$")
TRACKER_CONFIG_RE = re.compile(r"^tracker\s*=\s*(github|markdown)(\s+#\s*.*)?$")
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
        if any(line.startswith(("strategist =", "builders =", "when ")) for line in lines):
            target = block
            break
    if target is None:
        errors.append("skills/architect: no fenced C2/C2' config example with strategist/builders or dispatch rules")
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
        if clean.startswith("tracker "):
            if not TRACKER_CONFIG_RE.fullmatch(clean):
                errors.append(f"skills/architect: invalid tracker config example line: {line}")
            continue
        role_line = clean.split("#", 1)[0].strip()
        if not ROLE_CONFIG_RE.fullmatch(role_line):
            errors.append(f"skills/architect: invalid C2 config example line: {line}")
    if not saw_dispatch_rule:
        errors.append("skills/architect: C2' config example missing a dispatch-rules line")


def check_loop_hygiene_contract() -> None:
    loop = SKILLS / "architect" / "loop.md"
    if not loop.exists():
        errors.append("skills/architect/loop.md: missing (required for loop hygiene contract)")
        return
    text = read_text(loop)
    for required in ("run_in_background: false", "close-out"):
        if required not in text:
            errors.append(f"skills/architect/loop.md: missing {required}")


def check_check_runner_dispatch_contract() -> None:
    dispatch = SKILLS / "architect" / "dispatch.md"
    if not dispatch.exists():
        errors.append("skills/architect/dispatch.md: missing (required for check-runner dispatch contract)")
        return
    text = read_text(dispatch)
    if "## Check-runner dispatch" not in text.splitlines():
        errors.append("skills/architect/dispatch.md: missing ## Check-runner dispatch")
    if "## Preflight and postflight dispatch" not in text.splitlines():
        errors.append("skills/architect/dispatch.md: missing ## Preflight and postflight dispatch")
    marker_blocks: dict[str, str] = {}
    for marker in (
        "architect-monitor-fallback-template",
    ):
        start = f"<!-- {marker}:start -->"
        end = f"<!-- {marker}:end -->"
        start_at = text.find(start)
        end_at = text.find(end, start_at + len(start))
        if start_at == -1 or end_at == -1:
            errors.append(f"skills/architect/dispatch.md: missing {marker} marker block")
            continue
        marker_blocks[marker] = text[start_at + len(start) : end_at]


PADDED_TOOLS = ("Bash", "Read", "PowerShell")


def check_tools_pad(rel_path: str, tools_list: list[str]) -> None:
    """D9 regression guard: claude-code #60237 drops the first and last
    `tools:` entries at subagent spawn; Bash, Read, and PowerShell (the
    desktop Bash-strip fallback executor) must sit elsewhere."""
    missing = [t for t in PADDED_TOOLS if t not in tools_list]
    if missing:
        errors.append(f"{rel_path}: tools must include {', '.join(missing)}")
        return
    if tools_list[0] in PADDED_TOOLS or tools_list[-1] in PADDED_TOOLS:
        errors.append(
            f"{rel_path}: Bash, Read, and PowerShell must not be first or "
            "last in tools (D9, claude-code #60237)"
        )


def check_agent_definitions() -> None:
    # .claude/ is untracked local dev config (2026-07-06): the agent defs
    # exist only on machines that use the Claude-native builder fallback.
    # Validate their contracts when present; a fresh clone without them
    # passes clean.
    builder = ROOT / ".claude" / "agents" / "architect-builder.md"
    judge = ROOT / ".claude" / "agents" / "architect-judge.md"
    for path in (builder, judge):
        if not path.exists():
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
        shell_patterns = [d for d in disallowed if d.startswith("Bash(") or d.startswith("PowerShell(")]
        if shell_patterns:
            errors.append(
                ".claude/agents/architect-builder.md: disallowedTools must not contain "
                f"Bash(...)/PowerShell(...) patterns {sorted(shell_patterns)} - the harness "
                "collapses a pattern-scoped shell deny into removal of the whole tool "
                "(D14, verified 2026-07-04); commit/push bans live in prose + postflight audit"
            )
        if "Never commit" not in read_text(builder):
            errors.append(".claude/agents/architect-builder.md: body must carry the Never commit prose ban (replaces deny patterns, D14)")
        if fm.get("isolation") != "worktree":
            errors.append(".claude/agents/architect-builder.md: isolation must be worktree")
        if fm.get("model") != "inherit":
            errors.append(".claude/agents/architect-builder.md: model must be inherit")
        check_tools_pad(".claude/agents/architect-builder.md", split_csv(fm.get("tools", "")))
    if judge.exists():
        fm = frontmatter(judge) or {}
        tools = set(split_csv(fm.get("tools", "")))
        disallowed = set(split_csv(fm.get("disallowedTools", "")))
        if "Edit" in tools or "Write" in tools:
            errors.append(".claude/agents/architect-judge.md: tools must not include Edit or Write")
        if "Edit" not in disallowed or "Write" not in disallowed:
            errors.append(".claude/agents/architect-judge.md: disallowedTools must include Edit and Write")
        shell_patterns = [d for d in disallowed if d.startswith("Bash(") or d.startswith("PowerShell(")]
        if shell_patterns:
            errors.append(
                ".claude/agents/architect-judge.md: disallowedTools must not contain "
                f"Bash(...)/PowerShell(...) patterns {sorted(shell_patterns)} - the harness "
                "collapses a pattern-scoped shell deny into removal of the whole tool "
                "(D14, verified 2026-07-04); mutation bans live in prose + tree/postflight audits"
            )
        if fm.get("model") != "inherit":
            errors.append(".claude/agents/architect-judge.md: model must be inherit")
        check_tools_pad(".claude/agents/architect-judge.md", split_csv(fm.get("tools", "")))


def check_skill_text_size() -> None:
    """P5/G4 instruction-budget guard: the evidence cliff is
    exhaustive/comprehensive content and skill count (SkillsBench v4), not a
    200-line target. Compaction reattach economics are the binding constraint:
    first 5,000 tokens per invoked skill, 25,000 combined. FAIL if the
    combined NON-BLANK line count of the five architect files exceeds the
    approved cap."""
    paths = [
        SKILLS / "architect" / "SKILL.md",
        SKILLS / "architect" / "dispatch.md",
        SKILLS / "architect" / "loop.md",
        SKILLS / "architect" / "tracker.md",
        SKILLS / "architect" / "research.md",
    ]
    total = 0
    for path in paths:
        if not path.exists():
            errors.append(f"{path.relative_to(ROOT)}: missing (required for skill-text size guard)")
            continue
        total += non_blank_line_count(path)
    if total > ARCHITECT_SKILL_TEXT_MAX_NON_BLANK:
        errors.append(
            f"skills/architect: combined non-blank line count {total} exceeds "
            f"{ARCHITECT_SKILL_TEXT_MAX_NON_BLANK} (A1 five-file guard; evidence: "
            "SkillsBench v4 exhaustive/comprehensive content and skill count cliff; "
            "compaction reattaches first 5,000 tokens per invoked skill, 25,000 combined)"
        )


def check_architect_research_text_size() -> None:
    paths = [
        SKILLS / "architect-research" / "SKILL.md",
        SKILLS / "architect-research" / "tactics.md",
    ]
    total = 0
    for path in paths:
        if not path.exists():
            errors.append(f"{path.relative_to(ROOT)}: missing (required for architect-research size guard)")
            continue
        total += non_blank_line_count(path)
    if total > ARCHITECT_RESEARCH_TEXT_MAX_NON_BLANK:
        errors.append(
            "skills/architect-research: combined SKILL.md + tactics.md non-blank "
            f"line count {total} exceeds {ARCHITECT_RESEARCH_TEXT_MAX_NON_BLANK} "
            "(A1 research pair guard; evidence: G4 guard-scope loophole fix)"
        )


def check_skill_body_token_budgets() -> None:
    for path in sorted(SKILLS.glob("*/SKILL.md")):
        # Deterministic local proxy per A4: estimated tokens = word count * 1.33.
        estimated_tokens = len(re.findall(r"\S+", skill_body(path))) * SKILL_BODY_TOKEN_PROXY_FACTOR
        if estimated_tokens >= SKILL_BODY_TOKEN_PROXY_MAX:
            errors.append(
                f"{path.relative_to(ROOT)}: SKILL.md body proxy token count "
                f"{estimated_tokens:.0f} >= {SKILL_BODY_TOKEN_PROXY_MAX} "
                "(A4 words x 1.33; compaction reattaches first 5,000 tokens per invoked skill)"
            )


def check_reference_tocs() -> None:
    for path in sorted(SKILLS.glob("*/*.md")):
        if path.name == "SKILL.md":
            continue
        non_blank = non_blank_line_count(path)
        if non_blank <= REFERENCE_TOC_NON_BLANK_THRESHOLD:
            continue
        if not any(line.strip() == "## Contents" for line in read_text(path).splitlines()):
            errors.append(
                f"{path.relative_to(ROOT)}: {non_blank} non-blank lines > "
                f"{REFERENCE_TOC_NON_BLANK_THRESHOLD} but missing ## Contents "
                "(official skill reference-file TOC rule)"
            )


def check_design_guard_cap() -> None:
    path = ROOT / "DESIGN.md"
    text = read_text(path)
    match = re.search(
        r"(?m)^- \*\*An? ([0-9][0-9,]*)-non-blank-line size guard is enforced by the validator \(P5\)\.\*\*$",
        text,
    )
    if not match:
        errors.append("DESIGN.md: missing non-blank-line size guard sentence for drift guard")
        return
    design_cap = int(match.group(1).replace(",", ""))
    if design_cap != ARCHITECT_SKILL_TEXT_MAX_NON_BLANK:
        errors.append(
            f"DESIGN.md: stated skill-text guard cap {design_cap} != validator cap "
            f"{ARCHITECT_SKILL_TEXT_MAX_NON_BLANK} (drift guard for 800-vs-900 class)"
        )


def check_architect_handoff_free() -> None:
    for path in ARCHITECT_HANDOFF_FREE_FILES:
        if not path.exists():
            errors.append(f"{path.relative_to(ROOT)}: missing (required for handoff guard)")
            continue
        if "handoff" in read_text(path).lower():
            errors.append(f"{path.relative_to(ROOT)}: contains retired handoff reference")


def check_codex_install_step() -> None:
    """Both installers must copy skills/ to a Codex .agents/skills location,
    single-source (no committed .agents/ duplicate) - v4-codex fix contract."""
    checks = {
        ROOT / "install.sh": ".agents/skills",
        ROOT / "install.ps1": ".agents\\skills",
    }
    for path, needle in checks.items():
        if not path.exists():
            errors.append(f"{path.name}: missing")
            continue
        text = read_text(path)
        if needle not in text or "codex" not in text.lower():
            errors.append(f"{path.name}: missing Codex skills copy step ({needle})")


def check_watchdog_contract() -> None:
    ps1 = SKILLS / "architect" / "watchdog.ps1"
    sh = SKILLS / "architect" / "watchdog.sh"
    dispatch = read_text(SKILLS / "architect" / "dispatch.md")
    loop = read_text(SKILLS / "architect" / "loop.md")
    for path in (ps1, sh):
        if not path.exists():
            errors.append(f"{path.relative_to(ROOT)}: missing watchdog file")
            continue
        text = read_text(path)
        for marker in (
            "WATCHDOG: ALL_DONE",
            "WATCHDOG: INTEGRATED",
            "WATCHDOG: STALL",
            "WATCHDOG: REPEAT",
            "WATCHDOG: DONE_FAILED",
            "WATCHDOG: LEGACY_UNWRAPPED",
            "WATCHDOG: REPORT_READY",
            "WATCHDOG: ORPHANED",
            "WATCHDOG: DEAD",
            "WATCHDOG: BLOCKED_ON_TOOL",
        ):
            if marker not in text:
                errors.append(f"{path.relative_to(ROOT)}: missing {marker}")
    if sh.exists() and not read_text(sh).startswith("#!"):
        errors.append("skills/architect/watchdog.sh: missing shebang")
    if ps1.exists() and "ConvertFrom-Json" not in read_text(ps1):
        errors.append("skills/architect/watchdog.ps1: missing ConvertFrom-Json")
    if ps1.exists() and "TrimStart([char]0xFEFF)" not in read_text(ps1):
        errors.append("skills/architect/watchdog.ps1: terminal STATUS check must tolerate BOM")
    if sh.exists() and r"\xEF\xBB\xBF" not in read_text(sh):
        errors.append("skills/architect/watchdog.sh: terminal STATUS check must tolerate UTF-8 BOM")
    if "Every dispatch event re-arms the watchdog" not in dispatch:
        errors.append("skills/architect/dispatch.md: watchdog must re-arm on every dispatch event")
    if "Codex backend from a Claude orchestrator" in dispatch:
        errors.append("skills/architect/dispatch.md: CLI dispatch must not be Claude-orchestrator-specific")
    for marker in (
        "`codex exec`, `claude -p`, or a",
        "Claude Code or Codex orchestrator",
        "long-lived Bash task",
        "wrapper-owned files",
    ):
        if marker not in dispatch:
            errors.append(f"skills/architect/dispatch.md: missing CLI watchdog contract marker {marker!r}")
    if not re.search(r"all\s+in-flight CLI-launched jobs at every dispatch event", loop):
        errors.append("skills/architect/loop.md: dispatch events must cover all in-flight CLI-launched jobs")
    banned_watchdog_terms = ("process_match", "Win32_Process", "Get-CimInstance", "Get-WmiObject", "CpuTotal", "cpu_sum", "/proc", "ps -eo")
    for path in (ps1, sh):
        if not path.exists():
            continue
        text = read_text(path)
        for term in banned_watchdog_terms:
            if term in text:
                errors.append(f"{path.relative_to(ROOT)}: process-list liveness term must stay out of watchdog: {term}")
    if "process activity" in dispatch or "process tree" in dispatch:
        errors.append("skills/architect/dispatch.md: watchdog liveness must not use process activity")
    codex_json_blocks = [
        block
        for block in re.findall(r"```bash\n(.*?)```", dispatch, re.DOTALL)
        if "codex exec" in block and "--json" in block
    ]
    if not codex_json_blocks:
        errors.append("skills/architect/dispatch.md: missing Codex --json dispatch examples")
    for i, block in enumerate(codex_json_blocks, start=1):
        if "run-job.sh" not in block or "--stdin-file" not in block:
            errors.append(
                "skills/architect/dispatch.md: Codex --json dispatch example "
                f"{i} must run through the wrapper with --stdin-file"
            )
        for pin in ('-c service_tier="fast"', "-c features.fast_mode=true"):
            if pin not in block:
                errors.append(
                    "skills/architect/dispatch.md: Codex dispatch example "
                    f"{i} missing Fast-mode pin {pin}"
                )
    if re.search(r"codex exec[\s\S]*?\|\s*tail", dispatch):
        errors.append("skills/architect/dispatch.md: Codex dispatch examples must not pipe through tail")
    if re.search(r"(?m)^\s+-\s*<\s+.+>\s+.+\.events\.jsonl", dispatch):
        errors.append("skills/architect/dispatch.md: wrapper, not the child command, must own event redirection")


def watchdog_executor_cases() -> list[tuple[str, list[str], str]]:
    cases: list[tuple[str, list[str], str]] = []
    powershell = shutil.which("powershell")
    if powershell:
        cases.append(
            (
                "powershell",
                [
                    powershell,
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    str(SKILLS / "architect" / "watchdog.ps1"),
                    "-Config",
                ],
                "ps1",
            )
        )
    bash = shutil.which("bash")
    if bash:
        cases.append(("bash", [bash, bash_path(SKILLS / "architect" / "watchdog.sh"), "-Config"], "sh"))
    return cases


def run_job_prefix(kind: str) -> list[str] | None:
    if kind == "ps1":
        powershell = shutil.which("powershell")
        if not powershell:
            return None
        return [
            powershell,
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(SKILLS / "architect" / "run-job.ps1"),
        ]
    bash = shutil.which("bash")
    if not bash:
        return None
    return [bash, bash_path(SKILLS / "architect" / "run-job.sh")]


def kill_job_prefix(kind: str) -> list[str] | None:
    if kind == "ps1":
        powershell = shutil.which("powershell")
        if not powershell:
            return None
        return [
            powershell,
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(SKILLS / "architect" / "kill-job.ps1"),
        ]
    bash = shutil.which("bash")
    if not bash:
        return None
    return [bash, bash_path(SKILLS / "architect" / "kill-job.sh")]


def write_watchdog_config(
    config: Path,
    job_dir: Path,
    workdir: Path,
    report: Path,
    sweep: int = 1,
    stall_after_min: float = 0.01,
    heartbeat_stale_sec: int = 5,
    report_ready_grace_sec: int = 1,
    path_for_config=lambda p: str(p),
) -> None:
    cfg = {
        "sweep_sec": sweep,
        "stall_after_min": stall_after_min,
        "heartbeat_stale_sec": heartbeat_stale_sec,
        "report_ready_grace_sec": report_ready_grace_sec,
        "jobs": [
            {
                "id": job_dir.name,
                "job_dir": path_for_config(job_dir),
                "events_file": path_for_config(job_dir / "events.jsonl"),
                "report_path": path_for_config(report),
                "worktree": path_for_config(workdir),
                "duration_hint_min": 0,
            }
        ],
    }
    write_fixture_file(config, json.dumps(cfg))


def watchdog_run(prefix: list[str], config: Path, label: str, expected_exit: int, needle: str) -> str:
    config_arg = bash_path(config) if prefix and Path(prefix[0]).name.lower().startswith("bash") else str(config)
    result = subprocess.run(
        [*prefix, config_arg],
        cwd=ROOT,
        text=True,
        capture_output=True,
        timeout=12,
    )
    stdout = result.stdout.replace("\r\n", "\n")
    stderr = result.stderr.replace("\r\n", "\n")
    if result.returncode != expected_exit:
        errors.append(
            f"watchdog fixture {label}: expected exit {expected_exit} got {result.returncode}\n"
            f"stdout:\n{stdout}\nstderr:\n{stderr}"
        )
    if needle not in stdout:
        errors.append(f"watchdog fixture {label}: missing {needle!r}\nstdout:\n{stdout}\nstderr:\n{stderr}")
    return stdout


def run_wrapped_fake(
    kind: str,
    job_dir: Path,
    workdir: Path,
    report: Path,
    fake: Path,
    behavior: str,
    detached: bool = False,
) -> subprocess.Popen[str]:
    prefix = run_job_prefix(kind)
    if prefix is None:
        raise RuntimeError(f"missing wrapper executor {kind}")
    if kind == "ps1":
        child = [sys.executable, str(fake), behavior, str(report)]
        command = [
            *prefix,
            "-JobDir",
            str(job_dir),
            "-Workdir",
            str(workdir),
            "-Backend",
            f"fake-{kind}",
            "-ReportPath",
            str(report),
            "-HeartbeatSec",
            "1",
            "-ArgvJson",
            json.dumps(child),
        ]
    else:
        bash = shutil.which("bash")
        if not bash:
            raise RuntimeError("missing bash")
        child = [bash_inner_executable(), bash_path(fake), behavior, bash_path(report)]
        if detached:
            if bash_command_exists("setsid"):
                child = ["setsid", *child]
            elif bash_command_exists("nohup"):
                child = ["nohup", *child]
        command = [
            *prefix,
            "--job-dir",
            bash_path(job_dir),
            "--workdir",
            bash_path(workdir),
            "--backend",
            f"fake-{kind}",
            "--report-path",
            bash_path(report),
            "--heartbeat-sec",
            "1",
            "--",
            *child,
        ]
    # Detached children survive the wrapper and would hold PIPE handles open,
    # deadlocking communicate() (the documented grandchild-holds-pipes class).
    stdio = subprocess.DEVNULL if detached else subprocess.PIPE
    return subprocess.Popen(command, cwd=ROOT, text=True, stdout=stdio, stderr=stdio)


def finish_wrapped_fake(proc: subprocess.Popen[str], label: str, timeout: int = 8) -> None:
    try:
        proc.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        proc.kill()
        try:
            proc.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            if os.name == "nt":
                subprocess.run(["taskkill", "/F", "/T", "/PID", str(proc.pid)], capture_output=True, text=True, timeout=5)
            else:
                proc.kill()
        errors.append(f"watchdog fixture {label}: wrapper did not finish")


def check_watchdog_determinism_fixture() -> None:
    cases = watchdog_executor_cases()
    if not cases:
        errors.append("watchdog fixture: no runnable executor found")
        return

    base = ROOT / ".architect" / "tmp" / "watchdog-determinism-fixture"
    if base.exists():
        rmtree_with_writable_retry(base)
    base.mkdir(parents=True)
    fake_py = base / "fake_cli.py"
    fake_sh = base / "fake_cli.sh"
    write_fixture_file(
        fake_py,
        "\n".join(
            [
                "import json, sys, time",
                "behavior, report = sys.argv[1], sys.argv[2]",
                "def emit(obj):",
                "    print(json.dumps(obj), flush=True)",
                "if behavior == 'phase0':",
                "    emit({'phase':'plan'})",
                "    open(report, 'w', encoding='utf-8').write('PHASE 0 plan only\\n')",
                "    sys.exit(0)",
                "if behavior == 'die':",
                "    emit({'phase':'mid-write'})",
                "    open(report, 'w', encoding='utf-8').write('partial\\n')",
                "    sys.exit(9)",
                "if behavior == 'hang':",
                "    time.sleep(4)",
                "    sys.exit(0)",
                "if behavior == 'kill-hang':",
                "    time.sleep(20)",
                "    sys.exit(0)",
                "if behavior == 'loop':",
                "    for _ in range(6):",
                "        emit({'command':'same-command'})",
                "        time.sleep(0.2)",
                "    time.sleep(3)",
                "    sys.exit(0)",
                "if behavior == 'happy':",
                "    emit({'command':'ok'})",
                "    open(report, 'w', encoding='utf-8').write('done\\nSTATUS: COMPLETE\\n')",
                "    sys.exit(0)",
                "if behavior == 'misreport':",
                "    open(report, 'w', encoding='utf-8').write('initialized\\nSTATUS: BLOCKED (report initialized)\\n')",
                "    for i in range(4):",
                "        emit({'command':f'working-{i}'})",
                "        time.sleep(0.8)",
                "    open(report, 'w', encoding='utf-8').write('done\\nSTATUS: COMPLETE\\n')",
                "    sys.exit(0)",
                "if behavior == 'blocked-tool':",
                "    emit({'type':'item.completed','item':{'id':'msg_0','type':'agent_message','text':'before'}})",
                "    emit({'type':'item.started','item':{'id':'call_1','type':'command_execution','command':'pytest -q','status':'in_progress'}})",
                "    time.sleep(6)",
                "    sys.exit(0)",
                "if behavior == 'orphan-live':",
                "    for i in range(20):",
                "        emit({'command':f'still-writing-{i}'})",
                "        time.sleep(0.5)",
                "    sys.exit(0)",
                "sys.exit(64)",
            ]
        )
        + "\n",
    )
    write_fixture_file(
        fake_sh,
        "\n".join(
            [
                "#!/usr/bin/env bash",
                "set -u",
                "behavior=$1",
                "report=$2",
                "emit(){ printf '%s\\n' \"$1\"; }",
                "case \"$behavior\" in",
                "  phase0)",
                "    emit '{\"phase\":\"plan\"}'",
                "    printf 'PHASE 0 plan only\\n' > \"$report\"",
                "    exit 0",
                "    ;;",
                "  die)",
                "    emit '{\"phase\":\"mid-write\"}'",
                "    printf 'partial\\n' > \"$report\"",
                "    exit 9",
                "    ;;",
                "  hang)",
                "    sleep 4",
                "    exit 0",
                "    ;;",
                "  kill-hang)",
                "    sleep 20",
                "    exit 0",
                "    ;;",
                "  loop)",
                "    i=0",
                "    while [ \"$i\" -lt 6 ]; do",
                "      emit '{\"command\":\"same-command\"}'",
                "      sleep 0.2",
                "      i=$((i+1))",
                "    done",
                "    sleep 3",
                "    exit 0",
                "    ;;",
                "  happy)",
                "    emit '{\"command\":\"ok\"}'",
                "    printf 'done\\nSTATUS: COMPLETE\\n' > \"$report\"",
                "    exit 0",
                "    ;;",
                "  blocked-tool)",
                "    emit '{\"type\":\"item.completed\",\"item\":{\"id\":\"msg_0\",\"type\":\"agent_message\",\"text\":\"before\"}}'",
                "    emit '{\"type\":\"item.started\",\"item\":{\"id\":\"call_1\",\"type\":\"command_execution\",\"command\":\"pytest -q\",\"status\":\"in_progress\"}}'",
                "    sleep 6",
                "    exit 0",
                "    ;;",
                "  misreport)",
                "    printf 'initialized\\nSTATUS: BLOCKED (report initialized)\\n' > \"$report\"",
                "    i=0",
                "    while [ \"$i\" -lt 4 ]; do",
                "      printf '{\"command\":\"working-%s\"}\\n' \"$i\"",
                "      sleep 0.8",
                "      i=$((i+1))",
                "    done",
                "    printf 'done\\nSTATUS: COMPLETE\\n' > \"$report\"",
                "    exit 0",
                "    ;;",
                "  orphan-live)",
                "    i=0",
                "    while [ \"$i\" -lt 20 ]; do",
                "      printf '{\"command\":\"still-writing-%s\"}\\n' \"$i\"",
                "      sleep 0.5",
                "      i=$((i+1))",
                "    done",
                "    exit 0",
                "    ;;",
                "esac",
                "exit 64",
            ]
        )
        + "\n",
    )
    try:
        fake_sh.chmod(fake_sh.stat().st_mode | stat.S_IXUSR)
    except OSError:
        pass

    for runner, watchdog_prefix, kind in cases:
        wrapper_prefix = run_job_prefix(kind)
        if wrapper_prefix is None:
            continue
        fake = fake_py if kind == "ps1" else fake_sh
        path_for_config = bash_path if kind == "sh" else (lambda p: str(p))
        for behavior, expected_exit, needle in (
            ("phase0", 9, "WATCHDOG: DONE_FAILED"),
            ("die", 9, "WATCHDOG: DONE_FAILED"),
            ("happy", 0, "WATCHDOG: ALL_DONE"),
        ):
            job_dir = base / f"{runner}-{behavior}"
            workdir = job_dir / "work"
            report = job_dir / "report.md"
            workdir.mkdir(parents=True)
            proc = run_wrapped_fake(kind, job_dir, workdir, report, fake, behavior)
            finish_wrapped_fake(proc, f"{runner} {behavior}")
            config = job_dir / "watchdog.json"
            write_watchdog_config(config, job_dir, workdir, report, path_for_config=path_for_config)
            output = watchdog_run(watchdog_prefix, config, f"{runner} {behavior}", expected_exit, needle)
            if behavior == "die" and "exit_code=9" not in output:
                errors.append(f"watchdog fixture {runner} die: missing exit_code=9\nstdout:\n{output}")

        job_dir = base / f"{runner}-misreport"
        workdir = job_dir / "work"
        report = job_dir / "report.md"
        workdir.mkdir(parents=True)
        proc = run_wrapped_fake(kind, job_dir, workdir, report, fake, "misreport")
        config = job_dir / "watchdog.json"
        write_watchdog_config(
            config,
            job_dir,
            workdir,
            report,
            stall_after_min=1,
            path_for_config=path_for_config,
        )
        deadline = time.time() + 5
        while time.time() < deadline and not (job_dir / "job.meta.json").exists():
            time.sleep(0.05)
        output = watchdog_run(watchdog_prefix, config, f"{runner} misreport", 0, "WATCHDOG: ALL_DONE")
        finish_wrapped_fake(proc, f"{runner} misreport")
        if "early_status_sec=" not in output:
            errors.append(f"watchdog fixture {runner} misreport: missing early_status_sec evidence\nstdout:\n{output}")
        if "WATCHDOG: REPORT_READY" in output:
            errors.append(f"watchdog fixture {runner} misreport: early STATUS was treated as report-ready\nstdout:\n{output}")

        for behavior, expected_exit, needle in (
            ("hang", 3, "WATCHDOG: STALL"),
            ("loop", 4, "WATCHDOG: REPEAT"),
            ("blocked-tool", 11, "command="),
        ):
            job_dir = base / f"{runner}-{behavior}"
            workdir = job_dir / "work"
            report = job_dir / "report.md"
            workdir.mkdir(parents=True)
            proc = run_wrapped_fake(kind, job_dir, workdir, report, fake, behavior)
            config = job_dir / "watchdog.json"
            write_watchdog_config(config, job_dir, workdir, report, path_for_config=path_for_config)
            deadline = time.time() + 5
            while time.time() < deadline and not (job_dir / "job.meta.json").exists():
                time.sleep(0.05)
            watchdog_run(watchdog_prefix, config, f"{runner} {behavior}", expected_exit, needle)
            finish_wrapped_fake(proc, f"{runner} {behavior}")

        job_dir = base / f"{runner}-kill-job"
        workdir = job_dir / "work"
        report = job_dir / "report.md"
        workdir.mkdir(parents=True)
        proc = run_wrapped_fake(kind, job_dir, workdir, report, fake, "kill-hang")
        deadline = time.time() + 5
        while time.time() < deadline and not (job_dir / "job.meta.json").exists():
            time.sleep(0.05)
        prefix = kill_job_prefix(kind)
        if prefix is None:
            errors.append(f"kill-job fixture {runner}: missing executor")
        else:
            arg = bash_path(job_dir) if kind == "sh" else str(job_dir)
            killed = subprocess.run([*prefix, arg], cwd=ROOT, text=True, capture_output=True, timeout=12)
            kout = killed.stdout.replace("\r\n", "\n")
            if killed.returncode != 0 or "KILLJOB: OK" not in kout:
                errors.append(
                    f"kill-job fixture {runner}: expected OK exit 0 got {killed.returncode}\n"
                    f"stdout:\n{kout}\nstderr:\n{killed.stderr}"
                )
        finish_wrapped_fake(proc, f"{runner} kill-job", timeout=10)
        if not (job_dir / "job.exit.json").exists():
            errors.append(f"kill-job fixture {runner}: wrapper did not write job.exit.json")

        job_dir = base / f"{runner}-orphan"
        workdir = job_dir / "work"
        report = job_dir / "report.md"
        workdir.mkdir(parents=True)
        write_fixture_file(job_dir / "job.meta.json", "{}")
        write_fixture_file(job_dir / "job.heartbeat", "old\n")
        os.utime(job_dir / "job.heartbeat", (1, 1))
        write_fixture_file(job_dir / "events.jsonl", '{"command":"still-growing"}\n')
        write_fixture_file(job_dir / "job.state.json", '{"last_size":0,"last_growth_epoch":1,"report_ready_epoch":0}\n')
        config = job_dir / "watchdog.json"
        write_watchdog_config(config, job_dir, workdir, report, path_for_config=path_for_config)
        watchdog_run(watchdog_prefix, config, f"{runner} orphan", 7, "WATCHDOG: ORPHANED")

        job_dir = base / f"{runner}-report-ready"
        workdir = job_dir / "work"
        report = job_dir / "report.md"
        workdir.mkdir(parents=True)
        write_fixture_file(job_dir / "job.meta.json", "{}")
        write_fixture_file(job_dir / "job.heartbeat", "old\n")
        write_fixture_file(job_dir / "events.jsonl", "")
        write_fixture_file(report, "done\nSTATUS: COMPLETE\n")
        write_fixture_file(job_dir / "job.state.json", '{"last_size":0,"last_growth_epoch":1,"report_ready_epoch":1}\n')
        os.utime(job_dir / "job.heartbeat", (1, 1))
        config = job_dir / "watchdog.json"
        write_watchdog_config(config, job_dir, workdir, report, path_for_config=path_for_config)
        watchdog_run(watchdog_prefix, config, f"{runner} report-ready", 6, "WATCHDOG: REPORT_READY")

        job_dir = base / f"{runner}-dead"
        workdir = job_dir / "work"
        report = job_dir / "report.md"
        workdir.mkdir(parents=True)
        write_fixture_file(job_dir / "job.meta.json", "{}")
        write_fixture_file(job_dir / "job.heartbeat", "old\n")
        write_fixture_file(job_dir / "events.jsonl", "quiet\n")
        for old_path in (job_dir / "job.meta.json", job_dir / "job.heartbeat", job_dir / "events.jsonl"):
            os.utime(old_path, (1, 1))
        config = job_dir / "watchdog.json"
        write_watchdog_config(config, job_dir, workdir, report, path_for_config=path_for_config)
        watchdog_run(watchdog_prefix, config, f"{runner} dead", 8, "WATCHDOG: DEAD")

        job_dir = base / f"{runner}-legacy"
        workdir = job_dir / "work"
        report = job_dir / "report.md"
        workdir.mkdir(parents=True)
        write_fixture_file(job_dir / "events.jsonl", "legacy output\n")
        config = job_dir / "watchdog.json"
        write_watchdog_config(config, job_dir, workdir, report, path_for_config=path_for_config)
        watchdog_run(watchdog_prefix, config, f"{runner} legacy", 10, "WATCHDOG: LEGACY_UNWRAPPED")

        job_dir = base / f"{runner}-missing-workdir"
        workdir = job_dir / "missing-work"
        report = job_dir / "report.md"
        proc = run_wrapped_fake(kind, job_dir, workdir, report, fake, "happy")
        finish_wrapped_fake(proc, f"{runner} missing-workdir")
        config = job_dir / "watchdog.json"
        write_watchdog_config(config, job_dir, workdir, report, path_for_config=path_for_config)
        output = watchdog_run(watchdog_prefix, config, f"{runner} missing-workdir", 9, "WATCHDOG: DONE_FAILED")
        if "LEGACY_UNWRAPPED" in output or "INTEGRATED" in output:
            errors.append(f"watchdog fixture {runner} missing-workdir: wrapper failure lost exit truth\nstdout:\n{output}")

        job_dir = base / f"{runner}-integrated-worktree"
        workdir = job_dir / "vanished-work"
        report = job_dir / "report.md"
        job_dir.mkdir(parents=True)
        write_fixture_file(job_dir / "job.meta.json", "{}")
        write_fixture_file(job_dir / "job.heartbeat", "fresh\n")
        write_fixture_file(job_dir / "events.jsonl", "evidence remains\n")
        config = job_dir / "watchdog.json"
        write_watchdog_config(config, job_dir, workdir, report, path_for_config=path_for_config)
        watchdog_run(watchdog_prefix, config, f"{runner} integrated-worktree", 2, "WATCHDOG: INTEGRATED")

        job_dir = base / f"{runner}-integrated-events"
        workdir = job_dir / "work"
        report = job_dir / "report.md"
        workdir.mkdir(parents=True)
        write_fixture_file(job_dir / "job.meta.json", "{}")
        write_fixture_file(job_dir / "job.heartbeat", "fresh\n")
        config = job_dir / "watchdog.json"
        write_watchdog_config(config, job_dir, workdir, report, path_for_config=path_for_config)
        watchdog_run(watchdog_prefix, config, f"{runner} integrated-events", 2, "WATCHDOG: INTEGRATED")

        if kind == "ps1":
            job_dir = base / f"{runner}-start-failure"
            workdir = job_dir / "work"
            report = job_dir / "report.md"
            workdir.mkdir(parents=True)
            prefix = run_job_prefix(kind) or []
            command = [
                *prefix,
                "-JobDir",
                str(job_dir),
                "-Workdir",
                str(workdir),
                "-Backend",
                "fake-start-failure",
                "-ReportPath",
                str(report),
                "-ArgvJson",
                json.dumps(["definitely-not-a-real-executable-architect-loop"]),
            ]
            proc = subprocess.Popen(command, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            finish_wrapped_fake(proc, f"{runner} start-failure")
            config = job_dir / "watchdog.json"
            write_watchdog_config(config, job_dir, workdir, report, path_for_config=path_for_config)
            output = watchdog_run(watchdog_prefix, config, f"{runner} start-failure", 9, "WATCHDOG: DONE_FAILED")
            if "LEGACY_UNWRAPPED" in output:
                errors.append(f"watchdog fixture {runner} start-failure: missing metadata on Start-Process failure\nstdout:\n{output}")


def check_status_contract() -> None:
    required = (
        ("MERGED", 0x2713, "[char]0x2713"),
        ("JUDGING", 0x25D0, "[char]0x25D0"),
        ("BLOCKED", 0x21, '"!"'),
        ("REPORTED", 0x25A3, "[char]0x25A3"),
        ("BUILDING", 0x25CF, "[char]0x25CF"),
        ("QUEUED", 0x2298, "[char]0x2298"),
        ("READY", 0x25CB, "[char]0x25CB"),
    )
    for name in ("status.ps1", "status.sh"):
        path = SKILLS / "architect" / name
        if not path.exists():
            errors.append(f"skills/architect/{name}: missing status script")
            continue
        text = read_text(path)
        for label, codepoint, ps_code in required:
            glyph = chr(codepoint)
            if glyph not in text and ps_code not in text:
                errors.append(f"skills/architect/{name}: missing {label} glyph marker")
        for marker in (
            "NO ACTIVE FACTORY RUN",
            "tracker: unavailable (local view)",
            "tracker: no open run",
            "STATUS_GH_STUB",
            "--jq",
            "blockedBy.nodes",
        ):
            if marker not in text:
                errors.append(f"skills/architect/{name}: missing {marker}")
        if "WATCHDOG: process=" in text or "watchdog.ps1" in text and "ps -eo" in text:
            errors.append(f"skills/architect/{name}: status must not report watchdog process visibility")
        if name == "status.sh" and not text.startswith("#!"):
            errors.append("skills/architect/status.sh: missing shebang")
        if name == "status.sh":
            if "stat -c %Y" not in text or "stat -f %m" not in text:
                errors.append("skills/architect/status.sh: NewestSpec must use mtime with stat -c/stat -f fallback")
            if re.search(r'find "\$root/docs/spec".*\|\s*sort', text):
                errors.append("skills/architect/status.sh: NewestSpec must not select spec by lexical sort")


def platform_status_command(repo_root: Path, run_slug: str | None) -> list[str]:
    if os.name == "nt":
        command = [
            "powershell",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(SKILLS / "architect" / "status.ps1"),
        ]
        if run_slug is not None:
            command.append(run_slug)
        command.extend(["-RepoRoot", str(repo_root)])
        return command
    command = ["sh", str(SKILLS / "architect" / "status.sh")]
    if run_slug is not None:
        command.append(run_slug)
    command.extend(["--repo-root", str(repo_root)])
    return command


def run_status_fixture(repo_root: Path, run_slug: str | None, env: dict[str, str]) -> str | None:
    command = platform_status_command(repo_root, run_slug)
    run_env = os.environ.copy()
    run_env.update(env)
    try:
        result = subprocess.run(
            command,
            cwd=ROOT,
            env=run_env,
            text=True,
            capture_output=True,
            timeout=20,
        )
    except Exception as exc:
        errors.append(f"status fixture: {' '.join(command)} raised {exc!r}")
        return None
    stdout = result.stdout.replace("\r\n", "\n")
    stderr = result.stderr.replace("\r\n", "\n")
    if result.returncode != 0:
        errors.append(
            "status fixture: command failed "
            f"{' '.join(command)} exit {result.returncode}\nstdout:\n{stdout}\nstderr:\n{stderr}"
        )
        return None
    return stdout


def git_fixture(repo_root: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["git", "-C", str(repo_root), *args],
        text=True,
        capture_output=True,
        timeout=30,
    )
    if check and result.returncode != 0:
        errors.append(
            "postflight fixture git failed "
            f"git -C {repo_root} {' '.join(args)} exit {result.returncode}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def write_fixture_file(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def configure_fixture_repo(repo_root: Path) -> str | None:
    repo_root.mkdir(parents=True, exist_ok=True)
    init = subprocess.run(
        ["git", "init", str(repo_root)],
        text=True,
        capture_output=True,
        timeout=30,
    )
    if init.returncode != 0:
        errors.append(
            "postflight fixture: git init failed "
            f"exit {init.returncode}\nstdout:\n{init.stdout}\nstderr:\n{init.stderr}"
        )
        return None
    git_fixture(repo_root, "config", "user.email", "postflight-fixture@example.invalid")
    git_fixture(repo_root, "config", "user.name", "Postflight Fixture")
    write_fixture_file(repo_root / "allowed.txt", "base\n")
    git_fixture(repo_root, "add", "allowed.txt")
    git_fixture(repo_root, "commit", "-m", "base")
    git_fixture(repo_root, "branch", "-M", "factory")
    freeze = git_fixture(repo_root, "rev-parse", "HEAD")
    if freeze.returncode != 0:
        return None
    return freeze.stdout.strip()


def platform_postflight_command(config: Path) -> list[str]:
    if os.name == "nt":
        return [
            "powershell",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(SKILLS / "architect" / "postflight.ps1"),
            "-Config",
            str(config),
        ]
    return ["sh", str(SKILLS / "architect" / "postflight.sh"), str(config)]


def run_postflight_fixture(config: Path, cwd: Path) -> subprocess.CompletedProcess[str] | None:
    command = platform_postflight_command(config)
    try:
        return subprocess.run(
            command,
            cwd=cwd,
            text=True,
            capture_output=True,
            timeout=45,
        )
    except Exception as exc:
        errors.append(f"postflight fixture: {' '.join(command)} raised {exc!r}")
        return None


def write_postflight_config(
    path: Path,
    repo_root: Path,
    freeze: str,
    job_branch: str,
    worktree: str | None,
) -> None:
    cfg: dict[str, object] = {
        "repo_root": str(repo_root),
        "factory_branch": "factory",
        "job_branch": job_branch,
        "freeze_sha": freeze,
        "merge_message": "Merge fixture job",
        "may_touch": ["allowed.txt"],
        "push": False,
    }
    if worktree is not None:
        cfg["worktree"] = worktree
    write_fixture_file(path, json.dumps(cfg, indent=2))


def check_postflight_lane_fixture() -> None:
    base = ROOT / ".architect" / "tmp" / "postflight-lane-fixture"
    if base.exists():
        rmtree_with_writable_retry(base)
    base.mkdir(parents=True)

    lane_repo = base / "lane" / "repo"
    lane_worktree = base / "lane" / "worktrees" / "job"
    elsewhere = base / "elsewhere"
    elsewhere.mkdir(parents=True)
    freeze = configure_fixture_repo(lane_repo)
    if freeze is None:
        return
    git_fixture(lane_repo, "worktree", "add", "-b", "job", str(lane_worktree), freeze)
    write_fixture_file(lane_worktree / "allowed.txt", "lane\n")
    lane_config = base / "configs" / "lane.json"
    write_postflight_config(lane_config, lane_repo, freeze, "job", "../worktrees/job")

    lane = run_postflight_fixture(lane_config, elsewhere)
    if lane is not None:
        stdout = lane.stdout.replace("\r\n", "\n")
        stderr = lane.stderr.replace("\r\n", "\n")
        if lane.returncode != 0:
            errors.append(
                "postflight fixture dirty lane: command failed "
                f"exit {lane.returncode}\nstdout:\n{stdout}\nstderr:\n{stderr}"
            )
        if "POSTFLIGHT: OK merge=" not in stdout:
            errors.append(f"postflight fixture dirty lane: missing OK line\nstdout:\n{stdout}")
        if lane_worktree.exists():
            errors.append("postflight fixture dirty lane: relative worktree was not removed")
        head = git_fixture(lane_repo, "rev-parse", "factory")
        if head.returncode == 0 and head.stdout.strip() == freeze:
            errors.append("postflight fixture dirty lane: factory head did not advance")
        log = git_fixture(lane_repo, "log", "--format=%s")
        if log.returncode == 0 and "Merge fixture job (lane)" not in log.stdout:
            errors.append("postflight fixture dirty lane: lane commit message missing")
        content = (lane_repo / "allowed.txt").read_text(encoding="utf-8")
        if content != "lane\n":
            errors.append("postflight fixture dirty lane: merged file content missing")

    noop_repo = base / "noop" / "repo"
    noop_elsewhere = base / "noop-elsewhere"
    noop_elsewhere.mkdir(parents=True)
    noop_freeze = configure_fixture_repo(noop_repo)
    if noop_freeze is None:
        return
    git_fixture(noop_repo, "branch", "job", noop_freeze)
    noop_config = base / "configs" / "noop.json"
    write_postflight_config(noop_config, noop_repo, noop_freeze, "job", None)
    noop = run_postflight_fixture(noop_config, noop_elsewhere)
    if noop is not None:
        stdout = noop.stdout.replace("\r\n", "\n")
        stderr = noop.stderr.replace("\r\n", "\n")
        if noop.returncode != 5:
            errors.append(
                "postflight fixture noop: expected exit 5 "
                f"got {noop.returncode}\nstdout:\n{stdout}\nstderr:\n{stderr}"
            )
        needle = "POSTFLIGHT: ERROR job branch has no commits beyond freeze"
        if needle not in stdout:
            errors.append(f"postflight fixture noop: missing {needle!r}\nstdout:\n{stdout}")


def check_runner_cases() -> list[tuple[str, list[str], dict[str, Path]]]:
    cases: list[tuple[str, list[str], dict[str, Path]]] = []
    powershell = shutil.which("powershell")
    if powershell:
        cases.append(
            (
                "powershell",
                [
                    powershell,
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    str(SKILLS / "architect" / "check-runner.ps1"),
                    "-Config",
                ],
                {
                    "pass": ROOT / "tests" / "fixtures" / "checkrun" / "config-ps.json",
                    "fail": ROOT / "tests" / "fixtures" / "checkrun" / "config-quoted-ps.json",
                    "missing": ROOT / "tests" / "fixtures" / "checkrun" / "config-missing.json",
                },
            )
        )
    bash = shutil.which("bash")
    if bash and os.name != "nt":
        cases.append(
            (
                "bash",
                [bash, str(SKILLS / "architect" / "check-runner.sh")],
                {
                    "pass": ROOT / "tests" / "fixtures" / "checkrun" / "config-bash.json",
                    "fail": ROOT / "tests" / "fixtures" / "checkrun" / "config-quoted-bash.json",
                    "missing": ROOT / "tests" / "fixtures" / "checkrun" / "config-missing-bash.json",
                },
            )
        )
    return cases


def run_check_runner_case(
    label: str,
    command_prefix: list[str],
    config: Path,
    expected_exit: int,
) -> tuple[subprocess.CompletedProcess[str] | None, str]:
    cfg = json.loads(read_text(config))
    evidence = ROOT / cfg["evidence_out"]
    evidence.unlink(missing_ok=True)
    command = [*command_prefix, str(config)]
    try:
        result = subprocess.run(
            command,
            cwd=ROOT,
            text=True,
            capture_output=True,
            timeout=45,
        )
    except Exception as exc:
        errors.append(f"check-runner fixture {label}: {' '.join(command)} raised {exc!r}")
        return None, ""
    stdout = result.stdout.replace("\r\n", "\n")
    stderr = result.stderr.replace("\r\n", "\n")
    if result.returncode != expected_exit:
        errors.append(
            f"check-runner fixture {label}: expected exit {expected_exit} "
            f"got {result.returncode}\nstdout:\n{stdout}\nstderr:\n{stderr}"
        )
    if expected_exit == 5:
        if evidence.exists():
            errors.append(f"check-runner fixture {label}: evidence file exists after exit 5")
        return result, ""
    if not evidence.exists():
        errors.append(f"check-runner fixture {label}: missing evidence file {evidence.relative_to(ROOT)}")
        return result, ""
    return result, read_text(evidence).replace("\r\n", "\n")


def require_checkrun_evidence(label: str, evidence: str, needle: str) -> None:
    if needle not in evidence:
        errors.append(f"check-runner fixture {label}: missing {needle!r}\nevidence:\n{evidence}")


def check_check_runner_fixture() -> None:
    cases = check_runner_cases()
    if not cases:
        errors.append("check-runner fixture: no runnable executor found")
        return
    for runner, command_prefix, configs in cases:
        _, pass_evidence = run_check_runner_case(
            f"{runner} pass",
            command_prefix,
            configs["pass"],
            0,
        )
        if pass_evidence:
            require_checkrun_evidence(
                f"{runner} pass",
                pass_evidence,
                "CHECKRUN SUMMARY: run_items=4 pass=4 fail=0",
            )
            require_checkrun_evidence(f"{runner} pass", pass_evidence, 'expected: exit:0 match:"')
            require_checkrun_evidence(f"{runner} pass", pass_evidence, 'expected: exit:0 match:"a*b?c"')
            require_checkrun_evidence(f"{runner} pass", pass_evidence, "expected: exit:1")
            require_checkrun_evidence(f"{runner} pass", pass_evidence, "verdict: PASS")
            if "verdict: FAIL" in pass_evidence:
                errors.append(f"check-runner fixture {runner} pass: unexpected FAIL verdict")

        _, fail_evidence = run_check_runner_case(
            f"{runner} fail",
            command_prefix,
            configs["fail"],
            2,
        )
        if fail_evidence:
            require_checkrun_evidence(
                f"{runner} fail",
                fail_evidence,
                "CHECKRUN SUMMARY: run_items=3 pass=1 fail=2",
            )
            require_checkrun_evidence(f"{runner} fail", fail_evidence, "expected: exit:1")
            require_checkrun_evidence(f"{runner} fail", fail_evidence, 'expected: exit:0 match:"a*b?c"')
            require_checkrun_evidence(f"{runner} fail", fail_evidence, "verdict: FAIL")

        missing_result, _ = run_check_runner_case(
            f"{runner} missing",
            command_prefix,
            configs["missing"],
            5,
        )
        if missing_result is not None:
            stdout = missing_result.stdout.replace("\r\n", "\n")
            if "CHECKRUN: ERROR missing RUN expectation" not in stdout:
                errors.append(
                    f"check-runner fixture {runner} missing: missing grammar error\nstdout:\n{stdout}"
                )


def ground_executor_cases() -> list[tuple[str, list[str], str]]:
    """(label, base command prefix, repo-root flag) per runnable executor -
    mirrors check_runner_cases' bash-only-off-Windows gate (Executor truth,
    dispatch.md `## Duration hints and liveness`)."""
    cases: list[tuple[str, list[str], str]] = []
    powershell = shutil.which("powershell")
    if powershell:
        cases.append(
            (
                "powershell",
                [
                    powershell,
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    str(SKILLS / "architect" / "ground.ps1"),
                ],
                "-RepoRoot",
            )
        )
    bash = shutil.which("bash")
    if bash and os.name != "nt":
        cases.append(("bash", [bash, str(SKILLS / "architect" / "ground.sh")], "--repo-root"))
    return cases


def build_ground_ok_fixture(repo_root: Path) -> str | None:
    """Markdown-tracker fixture: tracking issue #1 (OPEN) with one open,
    unblocked child #2, and docs/checks/fixrun/ committed with no further
    edits - a clean-state GROUND: OK, per the s1-ground ruling's clean-state
    demonstration pattern (docs/jobs/ground-scripts/s1-ground-rulings.md).
    docs/jobs/fixrun/ carries a PAIRED report (slice-a-01.md +
    slice-a-checkrun.md, the repo naming convention) so the OK case pins the
    ruling's matcher fix: a matcher that pairs <slug>-01.md with
    <slug>-01-checkrun.md instead of <slug>-checkrun.md regresses to DRIFT
    here (final-review falsifiability proof, ground-scripts run)."""
    repo_root.mkdir(parents=True, exist_ok=True)
    init = subprocess.run(
        ["git", "init", str(repo_root)],
        text=True,
        capture_output=True,
        timeout=30,
    )
    if init.returncode != 0:
        errors.append(
            "ground fixture: git init failed "
            f"exit {init.returncode}\nstdout:\n{init.stdout}\nstderr:\n{init.stderr}"
        )
        return None
    git_fixture(repo_root, "config", "user.email", "ground-fixture@example.invalid")
    git_fixture(repo_root, "config", "user.name", "Ground Fixture")
    write_fixture_file(
        repo_root / "docs" / "runs" / "fixrun" / "manifest.md",
        "---\n"
        "run: fixrun\n"
        "tracking-issue: 1\n"
        "factory-branch: factory/fixrun\n"
        "tracker: markdown\n"
        "spec: docs/spec/fixrun.md\n"
        "state: ACTIVE\n"
        "---\n",
    )
    write_fixture_file(
        repo_root / "docs" / "issues" / "fixrun" / "1.md",
        "---\n"
        "issue: 1\n"
        "title: Tracking\n"
        "state: OPEN\n"
        "parent: 0\n"
        "blocked-by: none\n"
        "---\n"
        "Tracking issue body.\n",
    )
    write_fixture_file(
        repo_root / "docs" / "issues" / "fixrun" / "2.md",
        "---\n"
        "issue: 2\n"
        "title: Child A\n"
        "state: OPEN\n"
        "parent: 1\n"
        "blocked-by: none\n"
        "---\n"
        "Child body.\n",
    )
    write_fixture_file(repo_root / "docs" / "checks" / "fixrun" / "dummy.md", "# Check\nplaceholder\n")
    write_fixture_file(
        repo_root / "docs" / "jobs" / "fixrun" / "slice-a-01.md",
        "# report\nSTATUS: COMPLETE\n",
    )
    write_fixture_file(
        repo_root / "docs" / "jobs" / "fixrun" / "slice-a-checkrun.md",
        "# checkrun\nverdict: PASS\n",
    )
    git_fixture(repo_root, "add", "-A")
    git_fixture(repo_root, "commit", "-m", "base")
    freeze = git_fixture(repo_root, "rev-parse", "HEAD")
    if freeze.returncode != 0:
        return None
    return freeze.stdout.strip()


def check_ground_contract() -> None:
    ps1 = SKILLS / "architect" / "ground.ps1"
    sh = SKILLS / "architect" / "ground.sh"
    for path in (ps1, sh):
        if not path.exists():
            errors.append(f"{path.relative_to(ROOT)}: missing ground script")
    if not ps1.exists() or not sh.exists():
        return

    cases = ground_executor_cases()
    if not cases:
        errors.append("ground fixture: no runnable executor found")
        return

    for label, prefix, _flag in cases:
        try:
            result = subprocess.run(prefix, cwd=ROOT, text=True, capture_output=True, timeout=20)
        except Exception as exc:
            errors.append(f"ground fixture {label} no-args: raised {exc!r}")
            continue
        stdout = result.stdout.replace("\r\n", "\n")
        if result.returncode != 5:
            errors.append(
                f"ground fixture {label} no-args: expected exit 5 got {result.returncode}\nstdout:\n{stdout}"
            )
        if "GROUND: ERROR" not in stdout:
            errors.append(f"ground fixture {label} no-args: missing 'GROUND: ERROR'\nstdout:\n{stdout}")

    base = ROOT / ".architect" / "tmp" / "ground-contract-fixture"
    if base.exists():
        rmtree_with_writable_retry(base)
    base.mkdir(parents=True)
    fixture_repo = base / "repo"
    freeze = build_ground_ok_fixture(fixture_repo)
    if freeze is None:
        return

    for label, prefix, flag in cases:
        command = [*prefix, "fixrun", flag, str(fixture_repo)]
        run_env = os.environ.copy()
        run_env.pop("CLAUDE_CODE_SUBAGENT_MODEL", None)
        try:
            result = subprocess.run(command, cwd=ROOT, env=run_env, text=True, capture_output=True, timeout=20)
        except Exception as exc:
            errors.append(f"ground fixture {label} ok: raised {exc!r}")
            continue
        stdout = result.stdout.replace("\r\n", "\n")
        stderr = result.stderr.replace("\r\n", "\n")
        if result.returncode != 0:
            errors.append(
                f"ground fixture {label} ok: expected exit 0 got {result.returncode}\n"
                f"stdout:\n{stdout}\nstderr:\n{stderr}"
            )
        if "FRONTIER:" not in stdout:
            errors.append(f"ground fixture {label} ok: missing 'FRONTIER:' line\nstdout:\n{stdout}")
        if "GROUND: OK" not in stdout:
            errors.append(f"ground fixture {label} ok: missing 'GROUND: OK' summary\nstdout:\n{stdout}")

        # Typed exit 2: the subagent-model env gate (spec: GROUND: STOP).
        stop_env = os.environ.copy()
        stop_env["CLAUDE_CODE_SUBAGENT_MODEL"] = "fixture-model"
        try:
            stop = subprocess.run(command, cwd=ROOT, env=stop_env, text=True, capture_output=True, timeout=20)
        except Exception as exc:
            errors.append(f"ground fixture {label} stop: raised {exc!r}")
            continue
        stop_stdout = stop.stdout.replace("\r\n", "\n")
        if stop.returncode != 2:
            errors.append(
                f"ground fixture {label} stop: expected exit 2 got {stop.returncode}\nstdout:\n{stop_stdout}"
            )
        if "GROUND: STOP subagent-model-env" not in stop_stdout:
            errors.append(
                f"ground fixture {label} stop: missing 'GROUND: STOP subagent-model-env'\nstdout:\n{stop_stdout}"
            )

        # Typed exit 3: an UNPAIRED report (no slice-b-checkrun.md) drifts.
        unpaired = fixture_repo / "docs" / "jobs" / "fixrun" / "slice-b-01.md"
        write_fixture_file(unpaired, "# report\nSTATUS: COMPLETE\n")
        try:
            drift = subprocess.run(command, cwd=ROOT, env=run_env, text=True, capture_output=True, timeout=20)
        except Exception as exc:
            errors.append(f"ground fixture {label} drift: raised {exc!r}")
            continue
        finally:
            unpaired.unlink(missing_ok=True)
        drift_stdout = drift.stdout.replace("\r\n", "\n")
        if drift.returncode != 3:
            errors.append(
                f"ground fixture {label} drift: expected exit 3 got {drift.returncode}\nstdout:\n{drift_stdout}"
            )
        if "UNGRADED: slice-b" not in drift_stdout:
            errors.append(f"ground fixture {label} drift: missing 'UNGRADED: slice-b'\nstdout:\n{drift_stdout}")
        if "GROUND: DRIFT" not in drift_stdout:
            errors.append(f"ground fixture {label} drift: missing 'GROUND: DRIFT'\nstdout:\n{drift_stdout}")

        # Typed exit 3, freeze rail: a recorded freeze SHA that resolves to no
        # commit must DRIFT with a typed line on BOTH executors - the
        # final-review of the ground-scripts run caught ground.ps1 dying with
        # an untyped exit 1 (unwrapped native git call, PS 5.1
        # NativeCommandError) while ground.sh exited 3 on the same state.
        tracking_md = fixture_repo / "docs" / "issues" / "fixrun" / "1.md"
        original_body = read_text(tracking_md)
        write_fixture_file(
            tracking_md,
            "---\n"
            "issue: 1\n"
            "title: Tracking\n"
            "state: OPEN\n"
            "parent: 0\n"
            "blocked-by: none\n"
            "---\n"
            "freeze: 1234567890abcdef1234 recorded.\n",
        )
        try:
            badfreeze = subprocess.run(command, cwd=ROOT, env=run_env, text=True, capture_output=True, timeout=20)
        except Exception as exc:
            errors.append(f"ground fixture {label} bad-freeze: raised {exc!r}")
            continue
        finally:
            write_fixture_file(tracking_md, original_body)
        bad_stdout = badfreeze.stdout.replace("\r\n", "\n")
        if badfreeze.returncode != 3:
            errors.append(
                f"ground fixture {label} bad-freeze: expected exit 3 got {badfreeze.returncode}\n"
                f"stdout:\n{bad_stdout}"
            )
        if "GROUND: DRIFT recorded freeze 1234567890abcdef1234 not resolvable" not in bad_stdout:
            errors.append(
                f"ground fixture {label} bad-freeze: missing resolvability DRIFT line\nstdout:\n{bad_stdout}"
            )


def run_isolation_executor_cases() -> list[tuple[str, list[str], str]]:
    return ground_executor_cases()


def build_ground_run_isolation_fixture(repo_root: Path) -> str | None:
    repo_root.mkdir(parents=True, exist_ok=True)
    init = subprocess.run(
        ["git", "init", str(repo_root)],
        text=True,
        capture_output=True,
        timeout=30,
    )
    if init.returncode != 0:
        errors.append(
            "ground isolation fixture: git init failed "
            f"exit {init.returncode}\nstdout:\n{init.stdout}\nstderr:\n{init.stderr}"
        )
        return None
    git_fixture(repo_root, "config", "user.email", "ground-fixture@example.invalid")
    git_fixture(repo_root, "config", "user.name", "Ground Fixture")
    write_fixture_file(
        repo_root / "docs" / "runs" / "isofix" / "manifest.md",
        "---\n"
        "run: isofix\n"
        "tracking-issue: 1\n"
        "factory-branch: factory/isofix\n"
        "tracker: markdown\n"
        "spec: docs/spec/isofix.md\n"
        "state: ACTIVE\n"
        "---\n",
    )
    write_fixture_file(
        repo_root / "docs" / "issues" / "isofix" / "1.md",
        "---\n"
        "issue: 1\n"
        "title: Tracking\n"
        "state: OPEN\n"
        "parent: 0\n"
        "blocked-by: none\n"
        "---\n"
        "Tracking issue body.\n",
    )
    write_fixture_file(
        repo_root / "docs" / "issues" / "isofix" / "2.md",
        "---\n"
        "issue: 2\n"
        "title: Marked Child\n"
        "state: OPEN\n"
        "parent: 1\n"
        "blocked-by: none\n"
        "---\n"
        "<!-- architect-run: isofix -->\n"
        "Marked child body.\n",
    )
    write_fixture_file(
        repo_root / "docs" / "issues" / "isofix" / "99.md",
        "---\n"
        "issue: 99\n"
        "title: Decoy Child\n"
        "state: OPEN\n"
        "parent: 0\n"
        "blocked-by: none\n"
        "---\n"
        "No run marker.\n",
    )
    write_fixture_file(repo_root / "docs" / "checks" / "isofix" / "dummy.md", "# Check\nplaceholder\n")
    git_fixture(repo_root, "add", "-A")
    git_fixture(repo_root, "commit", "-m", "base")
    freeze = git_fixture(repo_root, "rev-parse", "HEAD")
    if freeze.returncode != 0:
        return None
    return freeze.stdout.strip()


def check_run_isolation() -> None:
    # Github-mode marker scoping: the fixture below is markdown-tracker (no
    # gh available), and gh's --jq runs inside gh itself, so the github-mode
    # jq filter cannot be exercised by a fixture. Pin its two scoping clauses
    # - parent pinning AND the run-marker contains() - at the file level in
    # BOTH scripts instead; deleting either clause fails here (final-review
    # falsifiability proof, ground-scripts run: a marker-clause-deleting
    # mutant survived the fixture-only version of this test).
    for script in ("ground.sh", "ground.ps1"):
        path = SKILLS / "architect" / script
        if not path.exists():
            errors.append(f"skills/architect/{script}: missing (required for run isolation)")
            continue
        text = read_text(path)
        for clause in (".parent.number == ", 'contains("<!-- architect-run: '):
            if clause not in text:
                errors.append(
                    f"skills/architect/{script}: github-mode jq filter lost its "
                    f"{clause!r} scoping clause (run isolation, "
                    "docs/checks/ground-scripts/s5-ship-wiring.md reviewer intent)"
                )

    cases = run_isolation_executor_cases()
    if not cases:
        errors.append("ground isolation fixture: no runnable executor found")
        return

    base = ROOT / ".architect" / "tmp" / "ground-run-isolation-fixture"
    if base.exists():
        rmtree_with_writable_retry(base)
    base.mkdir(parents=True)
    fixture_repo = base / "repo"
    if build_ground_run_isolation_fixture(fixture_repo) is None:
        return

    for label, prefix, flag in cases:
        command = [*prefix, "isofix", flag, str(fixture_repo)]
        run_env = os.environ.copy()
        run_env.pop("CLAUDE_CODE_SUBAGENT_MODEL", None)
        try:
            result = subprocess.run(command, cwd=ROOT, env=run_env, text=True, capture_output=True, timeout=20)
        except Exception as exc:
            errors.append(f"ground isolation fixture {label}: raised {exc!r}")
            continue
        stdout = result.stdout.replace("\r\n", "\n")
        stderr = result.stderr.replace("\r\n", "\n")
        if result.returncode != 0:
            errors.append(
                f"ground isolation fixture {label}: expected exit 0 got {result.returncode}\n"
                f"stdout:\n{stdout}\nstderr:\n{stderr}"
            )
            continue
        scoped_lines = "\n".join(
            line for line in stdout.splitlines() if line.startswith(("ISSUE:", "FRONTIER:"))
        )
        if "ISSUE: 2 open blockedBy=none" not in scoped_lines:
            errors.append(f"ground isolation fixture {label}: missing marked issue #2\nstdout:\n{stdout}")
        if "FRONTIER: 2" not in scoped_lines:
            errors.append(f"ground isolation fixture {label}: missing marked frontier #2\nstdout:\n{stdout}")
        if re.search(r"(?m)^ISSUE: 99\b", scoped_lines):
            errors.append(f"ground isolation fixture {label}: decoy issue #99 leaked\nstdout:\n{stdout}")
        if re.search(r"(?m)^FRONTIER:.*\b99\b", scoped_lines):
            errors.append(f"ground isolation fixture {label}: decoy frontier #99 leaked\nstdout:\n{stdout}")


def ffcheck_executor_cases() -> list[tuple[str, list[str]]]:
    cases: list[tuple[str, list[str]]] = []
    powershell = shutil.which("powershell")
    if powershell:
        cases.append(
            (
                "powershell",
                [
                    powershell,
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    str(SKILLS / "architect" / "ffcheck.ps1"),
                ],
            )
        )
    bash = shutil.which("bash")
    if bash and os.name != "nt":
        cases.append(("bash", [bash, str(SKILLS / "architect" / "ffcheck.sh")]))
    return cases


def check_ffcheck_contract() -> None:
    ps1 = SKILLS / "architect" / "ffcheck.ps1"
    sh = SKILLS / "architect" / "ffcheck.sh"
    for path in (ps1, sh):
        if not path.exists():
            errors.append(f"{path.relative_to(ROOT)}: missing ffcheck script")
    if not ps1.exists() or not sh.exists():
        return

    cases = ffcheck_executor_cases()
    if not cases:
        errors.append("ffcheck fixture: no runnable executor found")
        return

    head = git_fixture(ROOT, "rev-parse", "HEAD")
    if head.returncode != 0:
        return
    head_sha = head.stdout.strip()

    for label, prefix in cases:
        bad = subprocess.run(
            [*prefix, "not-a-real-sha"], cwd=ROOT, text=True, capture_output=True, timeout=20
        )
        bad_stdout = bad.stdout.replace("\r\n", "\n")
        if bad.returncode != 5:
            errors.append(
                f"ffcheck contract {label} bad-sha: expected exit 5 got {bad.returncode}\nstdout:\n{bad_stdout}"
            )
        if "FFCHECK: ERROR" not in bad_stdout:
            errors.append(f"ffcheck contract {label} bad-sha: missing 'FFCHECK: ERROR'\nstdout:\n{bad_stdout}")

        ok = subprocess.run([*prefix, head_sha], cwd=ROOT, text=True, capture_output=True, timeout=20)
        ok_stdout = ok.stdout.replace("\r\n", "\n")
        if ok.returncode != 0:
            errors.append(
                f"ffcheck contract {label} at-head: expected exit 0 got {ok.returncode}\nstdout:\n{ok_stdout}"
            )
        if "FFCHECK: OK" not in ok_stdout:
            errors.append(f"ffcheck contract {label} at-head: missing 'FFCHECK: OK'\nstdout:\n{ok_stdout}")


def require_status_contains(label: str, output: str, needle: str) -> None:
    if needle not in output:
        errors.append(f"{label}: missing {needle!r}\noutput:\n{output}")


def require_status_excludes(label: str, output: str, needle: str) -> None:
    if needle in output:
        errors.append(f"{label}: unexpectedly contains {needle!r}\noutput:\n{output}")


def check_status_run_pinning_fixture() -> None:
    fixture = ROOT / "tests" / "fixtures" / "status-run-pinned"
    github_repo = fixture / "github-repo"
    markdown_repo = fixture / "markdown-repo"
    github_stub = fixture / "github-issues.tsv"
    for path in (github_repo, markdown_repo, github_stub):
        if not path.exists():
            errors.append(f"status fixture: missing {path.relative_to(ROOT)}")
            return

    github_env = {
        "NO_COLOR": "1",
        "STATUS_GH_STUB": str(github_stub),
        "STATUS_GH_LOGIN_STUB": "architect-user",
    }
    run_a = run_status_fixture(github_repo, "run-a", github_env)
    if run_a is not None:
        require_status_contains("status fixture run-a", run_a, "tracker: #10")
        require_status_contains("status fixture run-a", run_a, "#11 Run A Slice")
        require_status_excludes("status fixture run-a", run_a, "#12")
        require_status_excludes("status fixture run-a", run_a, "#999")
        require_status_excludes("status fixture run-a", run_a, "#1000")

    run_b = run_status_fixture(github_repo, "run-b", github_env)
    if run_b is not None:
        require_status_contains("status fixture run-b", run_b, "tracker: #20")
        require_status_contains("status fixture run-b", run_b, "#21 Run B Slice")
        require_status_excludes("status fixture run-b", run_b, "#11")
        require_status_excludes("status fixture run-b", run_b, "#999")

    multi = run_status_fixture(github_repo, None, github_env)
    if multi is not None:
        require_status_contains("status fixture multi-active", multi, "RUN run-a #10 ACTIVE")
        require_status_contains("status fixture multi-active", multi, "RUN run-b #20 ACTIVE")
        require_status_excludes("status fixture multi-active", multi, "tracker: #999")

    markdown = run_status_fixture(markdown_repo, "run-a", {"NO_COLOR": "1"})
    if markdown is not None:
        require_status_contains("status fixture markdown", markdown, "tracker: #10")
        require_status_contains("status fixture markdown", markdown, "#11 Markdown Child")
        require_status_excludes("status fixture markdown", markdown, "#12")
        require_status_excludes("status fixture markdown", markdown, "Wrong Run Markdown Child")

    markdown_default = run_status_fixture(markdown_repo, None, {"NO_COLOR": "1"})
    if markdown_default is not None:
        require_status_contains("status fixture markdown default", markdown_default, "tracker: #10")
        require_status_contains("status fixture markdown default", markdown_default, "#11 Markdown Child")


def check_tracker_contract() -> None:
    path = SKILLS / "architect" / "tracker.md"
    if not path.exists():
        errors.append("skills/architect/tracker.md: missing")
        return
    text = read_text(path)
    for marker in (
        "issue:",
        "title:",
        "state:",
        "parent:",
        "blocked-by:",
        "TRACK",
        "SUB",
        "NOOPENRUN",
        "push-if-remote-exists",
        "## Command mapping",
    ):
        if marker not in text:
            errors.append(f"skills/architect/tracker.md: missing {marker}")


def check_retired_loop_terms() -> None:
    for path in SKILLS.rglob("*.md"):
        text = read_text(path)
        if "sentinel" in text.lower():
            errors.append(f"{path.relative_to(ROOT)}: contains retired term sentinel")
        if re.search(r"^LOOP:", text, re.MULTILINE):
            errors.append(f"{path.relative_to(ROOT)}: contains retired LOOP line")


def check_library_inventory() -> None:
    """s9: each stage skill in the library exists with a well-formed SKILL.md
    (name matches the dir, nonempty description) and its required sibling
    files (docs/checks/skill-library/s9-validator-evals.md)."""
    for name, siblings in LIBRARY_SKILLS.items():
        skill_dir = SKILLS / name
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            errors.append(f"skills/{name}: missing SKILL.md (library inventory)")
            continue
        fm = frontmatter(skill_md)
        if fm is None:
            errors.append(f"skills/{name}: SKILL.md has no frontmatter block (library inventory)")
            continue
        if fm.get("name") != name:
            errors.append(f"skills/{name}: frontmatter name != directory name (library inventory)")
        if not fm.get("description", "").strip():
            errors.append(f"skills/{name}: frontmatter has no description (library inventory)")
        for sibling in siblings:
            if not (skill_dir / sibling).exists():
                errors.append(f"skills/{name}: required library file {sibling} missing")


def check_library_line_budgets() -> None:
    """s9 per-skill budgets: caps from each stage skill's frozen check; the
    architect entry is the post-s8 SKILL.md re-baseline (see the
    LIBRARY_LINE_BUDGETS comment for why the five-file combined guard keeps
    its DESIGN.md-pinned cap)."""
    for name, (files, cap) in LIBRARY_LINE_BUDGETS.items():
        total = 0
        complete = True
        for fname in files:
            path = SKILLS / name / fname
            if not path.exists():
                errors.append(f"skills/{name}/{fname}: missing (required for library line budget)")
                complete = False
                continue
            total += non_blank_line_count(path)
        if complete and total > cap:
            listing = " + ".join(files)
            errors.append(
                f"skills/{name}: non-blank line count {total} ({listing}) "
                f"exceeds {cap} (frozen per-skill cap, docs/checks/skill-library/)"
            )


def check_library_attribution() -> None:
    for name in LIBRARY_ATTRIBUTED_SKILLS:
        path = SKILLS / name / "SKILL.md"
        if not path.exists():
            errors.append(f"skills/{name}/SKILL.md: missing (required for attribution check)")
            continue
        if LIBRARY_ATTRIBUTION not in read_text(path):
            errors.append(
                f"skills/{name}/SKILL.md: missing attribution "
                f"'{LIBRARY_ATTRIBUTION}' (adapted skill; license ruling in "
                "docs/spec/skill-library.md)"
            )


def check_glossary_cohesion() -> None:
    """s9 glossary cohesion lint: the codebase-design glossary bans
    component/service/boundary/API for module/interface and task/ticket for
    issue. This lint flags the banned substitutes that grep cleanly -
    case-sensitive word matches for `component` and `ticket`, and
    `boundary`/`boundaries` outside fixed phrases - across the eight files
    in GLOSSARY_LINT_SKILLS. Exemption rationale lives on the
    GLOSSARY_BAN_LIST_MENTIONS and GLOSSARY_BOUNDARY_FIXED_PHRASES
    constants; keep the list conservative and documented."""
    for name in GLOSSARY_LINT_SKILLS:
        path = SKILLS / name / "SKILL.md"
        if not path.exists():
            errors.append(f"skills/{name}/SKILL.md: missing (required for glossary lint)")
            continue
        rel = path.relative_to(ROOT)
        for lineno, line in enumerate(read_text(path).splitlines(), start=1):
            if any(mention in line for mention in GLOSSARY_BAN_LIST_MENTIONS):
                continue
            for word, (term, word_re) in GLOSSARY_BANNED_WORDS.items():
                if word_re.search(line):
                    errors.append(
                        f"{rel}:{lineno}: banned glossary substitute '{word}' "
                        f"(codebase-design glossary: use {term})"
                    )
            if "MAY TOUCH" in line or "MUST NOT TOUCH" in line:
                continue
            if GLOSSARY_BOUNDARY_HEADING_RE.match(line):
                continue
            scrubbed = line
            for phrase in GLOSSARY_BOUNDARY_FIXED_PHRASES:
                scrubbed = scrubbed.replace(phrase, "")
            if GLOSSARY_BOUNDARY_RE.search(scrubbed):
                errors.append(
                    f"{rel}:{lineno}: 'boundary' outside its fixed phrases "
                    "(codebase-design glossary: use module, interface, or seam)"
                )


# Cross-skill pointer integrity (docs/spec/skill-library.md `## Validation
# strategy`; closing-review fix - no slice shipped it). A pointer is a
# backticked or bare skill-file name followed by a backticked or quoted
# `##`/`###` heading, the form the stage skills use to cite orchestrator
# sections (e.g. `skills/architect/SKILL.md` `### 2. Spec Approval`). The
# regex is deliberately conservative: filename-then-heading only, so prose
# that names a heading without a file (or vice versa) is never flagged.
CROSS_SKILL_POINTER_RE = re.compile(
    r"(?:`(?P<path>[\w./-]+\.md)`"
    r"|(?<![\w`/])(?P<bare>(?:SKILL|dispatch|loop|tracker|research|tactics)\.md))"
    r"(?:'s)?\s+"
    r"(?:`(?P<tick>#{2,3} [^`]+?)`|\"(?P<quote>#{2,3} [^\"]+?)\")"
)


def normalize_heading(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def check_cross_skill_pointers() -> None:
    heading_cache: dict[Path, set[str]] = {}

    def headings_of(target: Path) -> set[str]:
        if target not in heading_cache:
            heading_cache[target] = {
                normalize_heading(line)
                for line in read_text(target).splitlines()
                if re.match(r"#{1,6}\s", line)
            }
        return heading_cache[target]

    for path in sorted(SKILLS.rglob("*.md")):
        rel = path.relative_to(ROOT)
        for m in CROSS_SKILL_POINTER_RE.finditer(read_text(path)):
            name = m.group("path") or m.group("bare")
            target = ROOT / name if "/" in name else path.parent / name
            heading = normalize_heading(m.group("tick") or m.group("quote"))
            if not target.exists():
                errors.append(
                    f"{rel}: pointer names missing file {name} "
                    f"(cited section: {heading})"
                )
                continue
            if heading not in headings_of(target):
                errors.append(
                    f"{rel}: pointer `{name}` -> '{heading}' does not match "
                    "any heading in the target (cross-skill pointer "
                    "integrity, docs/spec/skill-library.md Validation strategy)"
                )


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
    check_loop_hygiene_contract()
    check_check_runner_dispatch_contract()
    check_agent_definitions()
    check_codex_install_step()
    check_watchdog_contract()
    check_watchdog_determinism_fixture()
    check_status_contract()
    check_status_run_pinning_fixture()
    check_postflight_lane_fixture()
    check_check_runner_fixture()
    check_ground_contract()
    check_run_isolation()
    check_ffcheck_contract()
    check_tracker_contract()
    check_architect_handoff_free()
    check_retired_loop_terms()
    check_skill_text_size()
    check_architect_research_text_size()
    check_skill_body_token_budgets()
    check_reference_tocs()
    check_design_guard_cap()
    check_library_inventory()
    check_library_line_budgets()
    check_library_attribution()
    check_glossary_cohesion()
    check_cross_skill_pointers()
    if errors:
        print(f"FAIL - {len(errors)} problem(s):")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(f"OK - {len(skill_dirs)} skills validated, v4 contracts clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
