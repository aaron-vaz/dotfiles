# black or 0	  red or 1
# green or 2	  yellow or 3
# blue or 4	    magenta or 5
# cyan or 6	    white or 7

function parse_git_dirty() {
  local STATUS=$(command git status --porcelain 2> /dev/null | tail -n1)

  if [[ -n $STATUS ]]; then
    echo "*"
  fi
}

function git_prompt_info() {
  local ref
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
  echo "%{$fg[yellow]%}‹${ref#refs/heads/}$(parse_git_dirty)›%{$reset_color%}"
}

function virtualenv_prompt_info() {
    if [ -n "$VIRTUAL_ENV" ]; then
        if [ -f "$VIRTUAL_ENV/__name__" ]; then
            local name=`cat $VIRTUAL_ENV/__name__`
        elif [ `basename $VIRTUAL_ENV` = "__" ]; then
            local name=$(basename $(dirname $VIRTUAL_ENV))
        else
            local name=$(basename $VIRTUAL_ENV)
        fi
        echo "%{$fg[green]%}‹venv:$name›%{$reset_color%}"
    fi
}

local return_code="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"

local user_host='%{$terminfo[bold]$fg[blue]%}%n on %m%{$reset_color%} '
local current_dir='%~ '
local git_branch='$(git_prompt_info)%{$reset_color%} '
local virtualenv='$(virtualenv_prompt_info)%{$reset_color%} '

local prompt_top="╭-${user_host}${current_dir}${git_branch}${virtualenv}"
local prompt_btm="╰%B▶︎%b "

PROMPT="${prompt_top}
${prompt_btm}"

RPS1="${return_code}"
