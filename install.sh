#!/usr/bin/env bash
set -euo pipefail

SRC_ROOT="$(cd "$(dirname "$0")" && pwd)/skills"
if [ "${1:-}" = "--project" ]; then
    DEST_ROOT="$(pwd)/.claude/skills"
else
    DEST_ROOT="$HOME/.claude/skills"
fi

mkdir -p "$DEST_ROOT"
for skill in "$SRC_ROOT"/*/; do
    name="$(basename "$skill")"
    rm -rf "${DEST_ROOT:?}/$name"
    cp -r "$skill" "$DEST_ROOT/$name"
    echo "Installed /$name to $DEST_ROOT/$name"
done

# Codex reads skills from $CWD/.agents/skills (repo) or $HOME/.agents/skills
# (user) - developers.openai.com/codex/skills. Same source tree, no committed
# duplicate.
if [ "${1:-}" = "--project" ]; then
    CODEX_DEST_ROOT="$(pwd)/.agents/skills"
else
    CODEX_DEST_ROOT="$HOME/.agents/skills"
fi

mkdir -p "$CODEX_DEST_ROOT"
for skill in "$SRC_ROOT"/*/; do
    name="$(basename "$skill")"
    rm -rf "${CODEX_DEST_ROOT:?}/$name"
    cp -r "$skill" "$CODEX_DEST_ROOT/$name"
    echo "Installed Codex skill $name to $CODEX_DEST_ROOT/$name"
done

if command -v codex >/dev/null 2>&1; then
    echo "Codex CLI found: $(codex --version) (need >= 0.133 for default Goal Mode)"
else
    echo "Codex CLI not found - install the builder with: npm i -g @openai/codex@latest"
fi
