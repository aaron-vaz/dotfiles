#!/bin/sh

# choose_casks writes the apps picked from Brewfile.apps to ~/.Brewfile.
# DOTFILES_CASKS (all, none or a comma separated list of cask names) answers
# without asking; with neither it and a terminal, no apps are installed and
# ~/.Brewfile is not written, so the next install asks again.
choose_casks() {
  apps="$DOTFILES/homebrew/Brewfile.apps"
  names=$(sed -n 's/^cask "\(.*\)"$/\1/p' "$apps")
  fzf="$HOME/.fzf/bin/fzf"
  [ -x "$fzf" ] || fzf=$(command -v fzf) || fzf=""

  if [ -n "$DOTFILES_CASKS" ]
  then
    case "$DOTFILES_CASKS" in
      all) chosen="$names" ;;
      none) chosen="" ;;
      *) chosen=$(echo "$DOTFILES_CASKS" | tr ',' '\n') ;;
    esac
  elif [ -t 0 ] && [ -n "$fzf" ]
  then
    # Esc picks none: nothing is installed and the question is not asked again
    chosen=$(echo "$names" | "$fzf" --multi --reverse --height=50% \
      --prompt="apps> " \
      --header="Tab: toggle  Enter: install  Esc: none  (stored in ~/.Brewfile)") || chosen=""
  else
    echo "skipping apps: set DOTFILES_CASKS=all|none|name,name to choose without a terminal"
    return 0
  fi

  {
    echo "# Apps for this machine, chosen by homebrew/install.sh. Edit freely."
    for name in $chosen
    do
      if echo "$names" | grep -qx "$name"
      then
        echo "cask \"$name\""
      else
        echo "unknown cask: $name" >&2
      fi
    done
  } > "$HOME/.Brewfile"
}

if test "$(uname)" = "Darwin"
then
  if ! command -v brew > /dev/null 2>&1
  then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # a fresh install is not on PATH until the next shell
  for brew in /opt/homebrew/bin/brew /usr/local/bin/brew
  do
    if ! command -v brew > /dev/null 2>&1 && [ -x "$brew" ]
    then
      eval "$("$brew" shellenv)"
    fi
  done

  brew bundle --file="$DOTFILES/homebrew/Brewfile"
  # apps are per machine: ~/.Brewfile holds the ones chosen here, and up keeps applying it
  if ! [ -f "$HOME/.Brewfile" ]
  then
    choose_casks
  fi
  if [ -f "$HOME/.Brewfile" ]
  then
    brew bundle --file="$HOME/.Brewfile"
  fi
fi
