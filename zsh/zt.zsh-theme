# black or 0	  red or 1
# green or 2	  yellow or 3
# blue or 4	    magenta or 5
# cyan or 6	    white or 7

export PROMPT_EOL_MARK=''

zmodload zsh/datetime
autoload -Uz add-zsh-hook
add-zsh-hook precmd prompt_precmd
add-zsh-hook preexec prompt_preexec

autoload colors && colors
for COLOR in RED GREEN YELLOW BLUE MAGENTA CYAN BLACK WHITE; do
    eval local $COLOR='%{$fg_no_bold[${(L)COLOR}]%}'  #wrap colours between %{ %} to avoid weird gaps in autocomplete
    eval local BOLD_$COLOR='%{$fg_bold[${(L)COLOR}]%}'
done
local RESET_COLOUR='%{$reset_color%}'

export LS_COLORS="rs=0:di=38;5;33:ln=38;5;51:mh=00:pi=40;38;5;11:so=38;5;13:do=38;5;5:bd=48;5;232;38;5;11:cd=48;5;232;38;5;3:or=48;5;232;38;5;9:mi=01;05;37;41:su=48;5;196;38;5;15:sg=48;5;11;38;5;16:ca=48;5;196;38;5;226:tw=48;5;10;38;5;16:ow=48;5;10;38;5;21:st=48;5;21;38;5;15:ex=38;5;40:*.tar=38;5;9:*.tgz=38;5;9:*.arc=38;5;9:*.arj=38;5;9:*.taz=38;5;9:*.lha=38;5;9:*.lz4=38;5;9:*.lzh=38;5;9:*.lzma=38;5;9:*.tlz=38;5;9:*.txz=38;5;9:*.tzo=38;5;9:*.t7z=38;5;9:*.zip=38;5;9:*.z=38;5;9:*.Z=38;5;9:*.dz=38;5;9:*.gz=38;5;9:*.lrz=38;5;9:*.lz=38;5;9:*.lzo=38;5;9:*.xz=38;5;9:*.bz2=38;5;9:*.bz=38;5;9:*.tbz=38;5;9:*.tbz2=38;5;9:*.tz=38;5;9:*.deb=38;5;9:*.rpm=38;5;9:*.jar=38;5;9:*.war=38;5;9:*.ear=38;5;9:*.sar=38;5;9:*.rar=38;5;9:*.alz=38;5;9:*.ace=38;5;9:*.zoo=38;5;9:*.cpio=38;5;9:*.7z=38;5;9:*.rz=38;5;9:*.cab=38;5;9:*.jpg=38;5;13:*.jpeg=38;5;13:*.gif=38;5;13:*.bmp=38;5;13:*.pbm=38;5;13:*.pgm=38;5;13:*.ppm=38;5;13:*.tga=38;5;13:*.xbm=38;5;13:*.xpm=38;5;13:*.tif=38;5;13:*.tiff=38;5;13:*.png=38;5;13:*.svg=38;5;13:*.svgz=38;5;13:*.mng=38;5;13:*.pcx=38;5;13:*.mov=38;5;13:*.mpg=38;5;13:*.mpeg=38;5;13:*.m2v=38;5;13:*.mkv=38;5;13:*.webm=38;5;13:*.ogm=38;5;13:*.mp4=38;5;13:*.m4v=38;5;13:*.mp4v=38;5;13:*.vob=38;5;13:*.qt=38;5;13:*.nuv=38;5;13:*.wmv=38;5;13:*.asf=38;5;13:*.rm=38;5;13:*.rmvb=38;5;13:*.flc=38;5;13:*.avi=38;5;13:*.fli=38;5;13:*.flv=38;5;13:*.gl=38;5;13:*.dl=38;5;13:*.xcf=38;5;13:*.xwd=38;5;13:*.yuv=38;5;13:*.cgm=38;5;13:*.emf=38;5;13:*.ogv=38;5;13:*.ogx=38;5;13:*.aac=38;5;45:*.au=38;5;45:*.flac=38;5;45:*.m4a=38;5;45:*.mid=38;5;45:*.midi=38;5;45:*.mka=38;5;45:*.mp3=38;5;45:*.mpc=38;5;45:*.ogg=38;5;45:*.ra=38;5;45:*.wav=38;5;45:*.oga=38;5;45:*.opus=38;5;45:*.spx=38;5;45:*.xspf=38;5;45:"

function prompt_pure_human_time_to_var() {
  local human
  local total_milliseconds=$1
  local var=$2
  local total_seconds=$(printf '%d' $total_milliseconds)

  if [ $total_seconds -ge 1 ]
  then
  	local days=$(( total_seconds / 60 / 60 / 24 ))
  	local hours=$(( total_seconds / 60 / 60 % 24 ))
  	local minutes=$(( total_seconds / 60 % 60 ))
  	local seconds=$(( total_seconds % 60 ))
  	(( days > 0 )) && human+="${days}d "
  	(( hours > 0 )) && human+="${hours}h "
  	(( minutes > 0 )) && human+="${minutes}m "
  	human+="${seconds}s"
  else
    local milliseconds=$(printf '%d' $((total_milliseconds*1000)))
    human+="${milliseconds}ms"
  fi

	typeset -g "${var}"="${human}"
}

function prompt_preexec() {
  timer=${timer:-$EPOCHREALTIME}
}

function prompt_precmd() {
  if [ $timer ]; then
    prompt_pure_human_time_to_var $(($EPOCHREALTIME - $timer)) "timer_show"
    export EXECUTION_TIME="${CYAN}‹${timer_show}›%{$reset_color%}"
    unset timer
  fi
}

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
  echo "${YELLOW}‹${ref#refs/heads/}${BOLD_RED}$(parse_git_dirty)%{$reset_color%}${YELLOW}›%{$reset_color%}"
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
        echo "${GREEN}‹venv:$name›%{$reset_color%}"
    fi
}

function user_display() {
  local display

  if [[ "$SSH_CONNECTION" != '' ]]
  then
    display="${YELLOW}‹SSH›%n${RESET_COLOUR} ${BOLD_BLUE}on %m${RESET_COLOUR}"
  else
    display="${BOLD_BLUE}%n on %m${RESET_COLOUR}"
  fi

  echo $display
}

local return_code="%(?..${RED}%? ↵${RESET_COLOUR})"

local user_host="$(user_display) "
local current_dir='%~ '
local git_branch='$(git_prompt_info) '
local virtualenv='$(virtualenv_prompt_info) '
local exe_time='$EXECUTION_TIME '

local prompt_top="╭─${user_host}${exe_time}${current_dir}${git_branch}${virtualenv}"
local prompt_btm="╰─❯ "

PROMPT="${prompt_top}
${prompt_btm}"

RPS1="${return_code}"
