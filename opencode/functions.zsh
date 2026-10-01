# Older shells still carry the former `alias oc='opencode'`; drop it so the
# function below (and moc's call to it) aren't alias-expanded on re-source.
unalias oc 2>/dev/null

# oc — run opencode; --scratch runs it in a fresh temp dir, then returns to the
# original dir (and `cd -` target), even on Ctrl-C.
oc() {
  if [[ "$1" != "--scratch" ]]; then
    opencode "$@"
    return
  fi

  shift
  local orig_dir=$PWD
  local orig_oldpwd=$OLDPWD
  local tmp_dir
  tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/oc-XXXXXX") || return 1
  builtin cd -q "$tmp_dir" || return 1
  print -u2 "📁 throwaway dir: $tmp_dir"

  local exit_status
  {
    opencode "$@"
    exit_status=$?
  } always {
    # Two hops so zsh's internal oldpwd (what `cd -` uses) is restored too.
    [[ -d "$orig_oldpwd" ]] && builtin cd -q "$orig_oldpwd"
    builtin cd -q "$orig_dir" || print -u2 "⚠️  could not return to $orig_dir"
  }
  return $exit_status
}

# moc — throwaway opencode session in a fresh temp dir. Shorthand for
# `oc --scratch`; ad-hoc scratch work only.
moc() { oc --scratch "$@"; }
