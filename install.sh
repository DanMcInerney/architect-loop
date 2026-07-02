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

BIN_ROOT="$(cd "$(dirname "$0")" && pwd)/bin"
DRIVER_DEST="$HOME/.local/bin/architect-loop"
mkdir -p "$(dirname "$DRIVER_DEST")"
cp "$BIN_ROOT/architect-loop.sh" "$DRIVER_DEST"
chmod +x "$DRIVER_DEST"
echo "Installed architect-loop driver to $DRIVER_DEST"
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo "WARNING: $HOME/.local/bin is not on PATH" ;;
esac

if command -v codex >/dev/null 2>&1; then
    echo "Codex CLI found: $(codex --version) (need >= 0.133 for default Goal Mode)"
else
    echo "Codex CLI not found - install the builder with: npm i -g @openai/codex@latest"
fi
