#!/usr/bin/env bash

cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)

set -e

echo ''

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

info 'setting up Claude Code config directory'
mkdir -p ~/.claude

CLAUDE_SRC="$DOTFILES_ROOT/claude/.claude"

# Core files
for f in AGENTS.md CLAUDE.md persona.md settings.json mcp.json .gitignore README.md; do
  if [ -f "$CLAUDE_SRC/$f" ]; then
    ln -sf "$CLAUDE_SRC/$f" "$HOME/.claude/$f"
    success "$f symlinked"
  fi
done

# Directories
for d in rules hooks agents skills references scripts startup tests workflows; do
  if [ -d "$CLAUDE_SRC/$d" ]; then
    ln -sfn "$CLAUDE_SRC/$d" "$HOME/.claude/$d"
    success "$d/ directory symlinked"
  fi
done

# The knowledge base is NOT installed from here — it is harness-agnostic and
# owned by the top-level `kb/` topic, which symlinks ~/.claude/kb -> ~/.agents/kb
# for whichever harnesses are present. See kb/install.sh.

# Runtime directories (create if missing, don't symlink)
for d in sessions learnings logs ideas costs; do
  mkdir -p "$HOME/.claude/$d"
done

# ~/.mcp.json symlink
ln -sf "$CLAUDE_SRC/mcp.json" "$HOME/.mcp.json"
success '~/.mcp.json symlinked'

# Make scripts executable
chmod +x "$HOME/.claude/hooks/"*.sh 2>/dev/null || true
chmod +x "$HOME/.agents/kb/"*.sh 2>/dev/null || true
chmod +x "$HOME/.claude/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.claude/tests/"*.sh 2>/dev/null || true
success 'scripts made executable'

success 'Claude Code configuration installed'
echo ''
echo '  Next steps:'
echo '    1. Add MCP servers to ~/.claude/mcp.json'
echo '    2. Run /plugin in Claude Code to install plugins (optional)'
