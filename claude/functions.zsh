# Claude Code shell functions — sourced by dotfiles zshrc glob

cc() {
  local base_args=(--verbose)
  local force_new=0
  local pick_mode=0
  local explicit_name=""
  [[ "$1" == "-n" || "$1" == "--new" ]] && { force_new=1; shift; }
  [[ "$1" == "-r" || "$1" == "--pick" ]] && { pick_mode=1; shift; }
  [[ $force_new -eq 1 && $# -gt 0 && "$1" != -* ]] && { explicit_name="$1"; shift; }

  # ---- ~/.claude git pull (non-blocking, only if updates available) -------
  if git -C "$HOME/.claude" fetch --quiet 2>/dev/null; then
    local behind
    behind=$(git -C "$HOME/.claude" rev-list HEAD..@{u} --count 2>/dev/null)
    if [[ "${behind:-0}" -gt 0 ]]; then
      echo "🔄 ~/.claude: $behind update(s) available — pulling..." >&2
      git -C "$HOME/.claude" pull --ff-only --quiet 2>/dev/null \
        && echo "✓ ~/.claude updated" >&2 \
        || echo "⚠️  ~/.claude pull failed (conflicts?) — continuing" >&2
    fi
  fi

  local base_name
  base_name=$(basename "$(pwd)" | sed 's/[^a-zA-Z0-9_-]/_/g')

  local claude_cmd=(claude --model 'sonnet[1m]' "${base_args[@]}")

  # ---- Session naming helpers ---------------------------------------------
  _cc_new_session_name() {
    local ts
    ts=$(date +%H%M)
    if [[ -n "$explicit_name" ]]; then
      echo "${base_name}-$(echo "$explicit_name" | sed 's/[^a-zA-Z0-9_-]/-/g')-${ts}"
      return
    fi
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/[^a-zA-Z0-9_-]/-/g')
    if [[ -n "$branch" && "$branch" != "HEAD" && "$branch" != "master" && "$branch" != "main" ]]; then
      echo "${base_name}-${branch}-${ts}"
      return
    fi
    # On master/main: extract ticket ID from sessions/current.md
    local current_md="$HOME/.claude/sessions/current.md"
    if [[ -f "$current_md" ]]; then
      local ticket_slug
      ticket_slug=$(head -1 "$current_md" | grep -oE '[A-Z]+-[0-9]+' | head -1)
      if [[ -n "$ticket_slug" ]]; then
        echo "${base_name}-${ticket_slug}-${ts}"
        return
      fi
    fi
    if [[ -n "$branch" && "$branch" != "HEAD" ]]; then
      echo "${base_name}-${branch}-${ts}"
    else
      echo "${base_name}-${ts}"
    fi
  }

  # Returns: session-id TAB age-s TAB summary TAB branch
  _cc_last_session_info() {
    local project_hash
    project_hash=$(echo "$PWD" | sed 's|/|-|g')
    python3 -c '
import json, sys, time, os, glob
project_hash = sys.argv[1]
home = os.path.expanduser("~")
sessions_dir = home + "/.claude/projects/" + project_hash
if not os.path.isdir(sessions_dir): sys.exit(1)
jsonl_files = glob.glob(sessions_dir + "/*.jsonl")
if not jsonl_files: sys.exit(1)
jsonl_files.sort(key=os.path.getmtime, reverse=True)
latest = jsonl_files[0]
age_s = int(time.time() - os.path.getmtime(latest))
if age_s > 7 * 86400: sys.exit(1)
session_id = os.path.basename(latest)[:-6]
summary = ""
branch = ""
idx = sessions_dir + "/sessions-index.json"
if os.path.exists(idx):
    try:
        with open(idx) as f:
            for e in json.load(f).get("entries", []):
                if e.get("sessionId") == session_id:
                    summary = e.get("summary", "")[:60]
                    branch = e.get("gitBranch", "")
                    break
    except: pass
if not summary:
    try:
        with open(latest) as f:
            for line in f:
                try:
                    obj = json.loads(line)
                    if obj.get("type") == "user":
                        c = obj.get("message", {}).get("content", "")
                        if isinstance(c, str) and c and not c.startswith("#"):
                            summary = c[:60].replace("\n", " ")
                            break
                except: continue
    except: pass
print("\t".join([session_id, str(age_s), summary, branch]))
' "$project_hash" 2>/dev/null
  }

  _cc_format_age() {
    local age_s=$1
    if   [[ $age_s -lt 60    ]]; then echo "just now"
    elif [[ $age_s -lt 3600  ]]; then echo "$((age_s / 60))m ago"
    elif [[ $age_s -lt 86400 ]]; then echo "$((age_s / 3600))h ago"
    else                              echo "$((age_s / 86400))d ago"
    fi
  }

  # Prints tab-separated lines: age TAB summary TAB branch TAB session_id
  _cc_list_sessions() {
    local project_hash
    project_hash=$(echo "$PWD" | sed 's|/|-|g')
    python3 -c '
import json, sys, time, os, glob
project_hash = sys.argv[1]
home = os.path.expanduser("~")
sessions_dir = home + "/.claude/projects/" + project_hash
if not os.path.isdir(sessions_dir): sys.exit(1)
jsonl_files = glob.glob(sessions_dir + "/*.jsonl")
if not jsonl_files: sys.exit(1)
jsonl_files.sort(key=os.path.getmtime, reverse=True)
idx_map = {}
idx = sessions_dir + "/sessions-index.json"
if os.path.exists(idx):
    try:
        with open(idx) as f:
            for e in json.load(f).get("entries", []):
                idx_map[e["sessionId"]] = e
    except: pass
def fmt_age(s):
    if s < 60: return "just now"
    if s < 3600: return f"{s//60}m ago"
    if s < 86400: return f"{s//3600}h ago"
    return f"{s//86400}d ago"
def get_summary(path, sid):
    e = idx_map.get(sid, {})
    s = e.get("summary", "")
    if not s:
        try:
            with open(path) as f:
                for line in f:
                    try:
                        obj = json.loads(line)
                        if obj.get("type") == "user":
                            c = obj.get("message", {}).get("content", "")
                            if isinstance(c, str) and c and not c.startswith("#"):
                                s = c[:70].replace("\n", " ")
                                break
                    except: continue
        except: pass
    return s or "(no summary)"
now = time.time()
for path in jsonl_files[:30]:
    sid = os.path.basename(path)[:-6]
    age_s = int(now - os.path.getmtime(path))
    e = idx_map.get(sid, {})
    branch = e.get("gitBranch", "")
    summary = get_summary(path, sid)
    print("\t".join([fmt_age(age_s), summary, branch, sid]))
' "$project_hash" 2>/dev/null
  }

  # Renames tmux session when ~/.claude/sessions/.rename-request is written
  _cc_start_rename_watcher() {
    local watch_name="$1"
    local rename_file="$HOME/.claude/sessions/.rename-request"
    rm -f "$rename_file" 2>/dev/null
    {
      sleep 2
      while tmux has-session -t "$watch_name" 2>/dev/null; do
        if [[ -f "$rename_file" ]]; then
          local new_name
          new_name=$(tr -d '\n' < "$rename_file" | sed 's/[^a-zA-Z0-9_-]/-/g' | head -c 40)
          rm -f "$rename_file"
          if [[ -n "$new_name" ]]; then
            tmux rename-session -t "$watch_name" "$new_name" 2>/dev/null && watch_name="$new_name"
          fi
        fi
        sleep 2
      done
    } &
  }

  # ---- tmux session dispatch ----------------------------------------------
  if [[ $pick_mode -eq 1 ]]; then
    local session_list selected_line pick_id
    session_list=$(_cc_list_sessions 2>/dev/null)
    if [[ -z "$session_list" ]]; then
      echo "No sessions found for this project." >&2
      return 1
    fi
    selected_line=$(echo "$session_list" \
      | fzf --prompt="Resume > " \
            --header="Select session  (age / summary / branch)" \
            --delimiter=$'\t' --with-nth=1,2,3 \
            --height=40% --layout=reverse --no-sort)
    [[ -z "$selected_line" ]] && return 0
    pick_id=$(echo "$selected_line" | cut -f4)
    local session_name
    session_name=$(_cc_new_session_name)
    _cc_start_rename_watcher "$session_name"
    tmux new-session -s "$session_name" "${claude_cmd[@]}" --resume "$pick_id"
  elif [ $# -gt 0 ]; then
    local session_name
    session_name=$(_cc_new_session_name)
    tmux new-session -s "$session_name" "${claude_cmd[@]}" "$@"
  elif [[ $force_new -eq 1 ]]; then
    local session_name
    session_name=$(_cc_new_session_name)
    local startup_file="$HOME/.claude/startup/session-start.md"
    _cc_start_rename_watcher "$session_name"
    if [[ -f "$startup_file" ]]; then
      tmux new-session -s "$session_name" "${claude_cmd[@]}" "$(cat "$startup_file")"
    else
      tmux new-session -s "$session_name" "${claude_cmd[@]}"
    fi
  else
    local session_name="$base_name"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
      local found_session
      found_session=$(tmux list-panes -a -F "#{session_name}|#{pane_current_path}" 2>/dev/null \
        | awk -F'|' -v dir="$(pwd)" '$2 == dir || index($2, dir "/") == 1 {print $1; exit}')
      [[ -n "$found_session" ]] && session_name="$found_session"
    fi

    if tmux has-session -t "$session_name" 2>/dev/null; then
      local existing_cwd
      existing_cwd=$(tmux list-panes -t "$session_name" -F "#{pane_current_path}" 2>/dev/null | head -1)
      echo "⚠️  Session '$session_name' already running (cwd: ${existing_cwd/#$HOME/~})" >&2
      echo "   [Enter] Attach to existing   [n] New session" >&2
      read -r "choice?→ "
      if [[ "$choice" == "n" || "$choice" == "N" ]]; then
        session_name=$(_cc_new_session_name)
        local startup_file="$HOME/.claude/startup/session-start.md"
        _cc_start_rename_watcher "$session_name"
        if [[ -f "$startup_file" ]]; then
          tmux new-session -s "$session_name" "${claude_cmd[@]}" "$(cat "$startup_file")"
        else
          tmux new-session -s "$session_name" "${claude_cmd[@]}"
        fi
      else
        if [ -n "$TMUX" ]; then
          tmux switch-client -t "$session_name"
        else
          tmux attach-session -t "$session_name"
        fi
      fi
    else
      local startup_file="$HOME/.claude/startup/session-start.md"
      local last_info last_id last_age last_summary last_branch age_str
      local -a resume_args=()

      last_info=$(_cc_last_session_info 2>/dev/null) || true
      if [[ -n "$last_info" ]]; then
        last_id=$(echo "$last_info" | cut -f1)
        last_age=$(echo "$last_info" | cut -f2)
        last_summary=$(echo "$last_info" | cut -f3)
        last_branch=$(echo "$last_info" | cut -f4)
        age_str=$(_cc_format_age "$last_age")
        echo "💾 Last session ($age_str, $last_branch): $last_summary" >&2
        read -r "choice?   Resume? [Y/n] "
        if [[ "$choice" != "n" && "$choice" != "N" ]]; then
          resume_args=(--resume "$last_id")
        fi
      fi

      _cc_start_rename_watcher "$session_name"
      if [[ ${#resume_args[@]} -gt 0 ]]; then
        tmux new-session -s "$session_name" "${claude_cmd[@]}" "${resume_args[@]}"
      elif [[ -f "$startup_file" ]]; then
        tmux new-session -s "$session_name" "${claude_cmd[@]}" "$(cat "$startup_file")"
      else
        tmux new-session -s "$session_name" "${claude_cmd[@]}"
      fi
    fi
  fi
}
