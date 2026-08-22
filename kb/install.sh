#!/usr/bin/env bash
#
# Knowledge base — deliberately NOT under any one agent harness.
#
# The KB outlived one harness already (it started under OpenCode, then a second
# copy grew under Claude Code with its own search script and its own index), and
# the two drifted. It is agent-harness-agnostic on purpose: one store, one set of
# scripts, and each harness gets a symlink pointing at it. Adding a third agent
# means adding a symlink here, not forking the KB again.
#
#   ~/.agents/kb/            canonical location
#     entries/    -> this repo's kb/entries  (PUBLIC — tracked and published)
#     private/                               (never tracked, never symlinked)
#     search-kb.sh, audit-kb.sh, TEMPLATE*.md -> this repo
#     index.tsv                              (generated, gitignored)
#
#   ~/.agents/kb   -> ~/.agents/kb
#   ~/.opencode/kb -> ~/.agents/kb   (only if ~/.opencode exists)

cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)

set -e

info ()    { printf "\r  [ \033[00;34m..\033[0m ] $1\n"; }
success () { printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"; }

KB_SRC="$DOTFILES_ROOT/kb"
KB_HOME="$HOME/.agents/kb"

info 'setting up the shared knowledge base'
mkdir -p "$KB_HOME"

# Scripts and templates live in the repo.
for f in search-kb.sh audit-kb.sh TEMPLATE.md TEMPLATE-feedback.md; do
  if [ -f "$KB_SRC/$f" ]; then
    ln -sf "$KB_SRC/$f" "$KB_HOME/$f"
    success "kb/$f symlinked"
  fi
done

# Public store: tracked in this repo, so it is published. Only entries reviewed
# as naming no employer, private product, internal host, or private repo
# internals belong here.
ln -sfn "$KB_SRC/entries" "$KB_HOME/entries"
success 'kb/entries symlinked (public store)'

# Private store: outside the repo tree on purpose. A gitignored path inside the
# repo can still be committed with `git add -f` or swept in by a broad
# `git add <dir>`; a path that isn't in the repo cannot.
mkdir -p "$KB_HOME/private"
success 'kb/private created (private store, never tracked)'

# Harness consumers — symlink only for harnesses actually installed.
for harness in "$HOME/.claude" "$HOME/.opencode"; do
  if [ -d "$harness" ]; then
    ln -sfn "$KB_HOME" "$harness/kb"
    success "$(basename "$harness")/kb -> ~/.agents/kb"
  fi
done

chmod +x "$KB_HOME/"*.sh 2>/dev/null || true

success 'knowledge base installed'
