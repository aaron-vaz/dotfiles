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

# KB scripts + template.
#   entries/ — public store. Runtime dir today; safe to track later if wanted.
#   private/ — private store. NEVER symlinked into the dotfiles repo and never
#              tracked: this repo is public, and these entries name employers,
#              private products, internal hosts and private repo internals.
#              It lives outside the repo tree on purpose — a gitignored path
#              inside the repo can still be committed with `git add -f` or swept
#              in by a broad `git add <dir>`; a path that isn't in the repo cannot.
mkdir -p ~/.claude/kb/entries ~/.claude/kb/private
for f in search-kb.sh audit-kb.sh TEMPLATE.md; do
  if [ -f "$CLAUDE_SRC/kb/$f" ]; then
    ln -sf "$CLAUDE_SRC/kb/$f" "$HOME/.claude/kb/$f"
    success "kb/$f symlinked"
  fi
done

# Runtime directories (create if missing, don't symlink)
for d in sessions learnings logs ideas costs; do
  mkdir -p "$HOME/.claude/$d"
done

# ~/.mcp.json symlink
ln -sf "$CLAUDE_SRC/mcp.json" "$HOME/.mcp.json"
success '~/.mcp.json symlinked'

# Make scripts executable
chmod +x "$HOME/.claude/hooks/"*.sh 2>/dev/null || true
chmod +x "$HOME/.claude/kb/"*.sh 2>/dev/null || true
chmod +x "$HOME/.claude/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.claude/tests/"*.sh 2>/dev/null || true
success 'scripts made executable'

success 'Claude Code configuration installed'
echo ''
echo '  Next steps:'
echo '    1. Add MCP servers to ~/.claude/mcp.json'
echo '    2. Run /plugin in Claude Code to install plugins (optional)'
