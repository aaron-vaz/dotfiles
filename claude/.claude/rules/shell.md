# Shell Environment

## Machine-Specific Config
Location: `~/.localrc`
- Machine-specific aliases, credentials, commands
- **Command/alias not found → check `~/.localrc` first**
- Sourced by interactive zsh. NOT available in Claude non-interactive bash subshells

## Claude Code Shell Context
Claude Code runs non-interactive bash. If you need version managers or tools that require sourcing (nvm, pyenv, etc.), source them explicitly:
```bash
source ~/.nvm/nvm.sh && nvm use --lts && <command>
```

## Node (nvm)
- Always use LTS: `nvm use --lts`

## Python

**Do NOT use system `python3` (`/usr/bin/python3`) on macOS** — Python 3.9, EOL, blocks pip (PEP 668).

**Prefer pyenv or uv for project-specific Python.** Check for `.python-version` in the repo.

**Run with specific environment:**
```bash
# Preferred: use absolute binary path (skips shim resolution entirely)
~/.pyenv/versions/<env-name>/bin/python <script>

# Or unset PYENV_VERSION and rely on repo's .python-version
(unset PYENV_VERSION && python3 <script>)
```

**Do NOT use `pyenv shell <ver>`** — exports `PYENV_VERSION`, persists into Claude child shells.

**Shims on PATH but non-interactive shells inherit `PYENV_VERSION` from parent env.** Wrong Python → check `env | grep PYENV_VERSION` first — overrides everything.

## macOS Differences
- `cat -A` broken — use `cat -e` or `od -c`
- `sed -i` needs `''`: `sed -i '' 's/old/new/' file`
- `date` differs — use `gdate` for Linux-compatible ops
- `awk` is BSD — `match($0, /pattern/, arr)` (3rd arg) GNU-only. Use `gawk` or rewrite with `sub`/`substr`
- `grep` is BSD — two ERE traps:
  - **`|` alternation requires `-E`**: `grep 'a\|b'` works only in BRE. ERE: `grep -E 'a|b'` (never escape pipe under `-E`).
  - **`\s` / `\S` / `\d` / `\w` NOT supported** — use POSIX: `[[:space:]]`, `[^[:space:]]`, `[[:digit:]]`, `[[:alnum:]_]`. Applies to BSD `grep`/`sed`, not most awk.
- `find` predicate grouping — `find dir -name '*.a' -o -name '*.b' ! -path '*/x/*'` binds `!` only to last `-o` branch. Wrap: `find dir \( -name '*.a' -o -name '*.b' \) ! -path '*/x/*'`.

## Bash Gotchas
- **Git stdout leaks into command substitution** — redirect to stderr (`>&2`) or run separately
- **`set -euo pipefail` + `grep`** — no-match returns exit 1, kills script. Append `|| true` to greps that may find nothing.
- **zsh `status` read-only** — use `result`, `output`, `git_status` etc.
- **zsh `no matches found` on empty dirs** — glob like `dir/*/` aborts whole command when nothing matches. Fixes: `setopt NULL_GLOB`; `shopt -s nullglob` (bash); guard with `[[ -d "$path" ]]` or `find`.
- **`set -e` + `((i++))` kills on first increment** — post-increment of `0` returns `0`, `set -e` treats as failure. Fixes: `((i++)) || true`; `((++i))`; or `i=$((i+1))` (portable, preferred).
- **Crontab env-var section doesn't expand shell** — `KEY=$(cat file)` at crontab top treated literally. Self-load secrets inside script from `chmod 600` file at runtime.
