alias gpp="git pull --prune"
alias gfpp="git fetch --all --progress --prune"
alias glp="git log --all --graph --pretty=format:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias gpp="git pull --prune"
alias gf="git fetch --progress --prune"

# Checkout default branch, pull latest, delete merged + gone branches
gc() {
    local default_branch
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
    if [[ -z "$default_branch" ]]; then
        for b in main master; do
            git show-ref --verify --quiet "refs/remotes/origin/$b" && default_branch="$b" && break
        done
    fi
    if [[ -z "$default_branch" ]]; then
        echo "❌ Could not determine default branch" >&2
        return 1
    fi

    git checkout "$default_branch"
    git fetch --prune
    git pull --ff-only

    # Branches merged into default (excludes squash-merged)
    local merged
    merged=$(git branch --merged "$default_branch" | sed 's/^[*+[:space:]]*//' | grep -v "^[[:space:]]*$default_branch$")

    # Branches whose remote tracking ref is gone (covers squash-merged PRs)
    local gone
    gone=$(git branch -vv | awk '{ n = ($1=="*"||$1=="+") ? $2 : $1 } /: gone\]/ { print n }')

    local to_delete
    to_delete=$(echo -e "$merged\n$gone" | sort -u | grep -v "^$")

    if [[ -z "$to_delete" ]]; then
        echo "No branches to clean up."
        return 0
    fi

    # Map branch -> worktree path (main worktree excluded, its branch is $default_branch)
    local -A worktree_for_branch
    local wt_path=""
    while IFS= read -r line; do
        case "$line" in
            "worktree "*) wt_path="${line#worktree }" ;;
            "branch refs/heads/"*) worktree_for_branch[${line#branch refs/heads/}]="$wt_path" ;;
        esac
    done < <(git worktree list --porcelain)

    local branch wt_dir
    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue
        wt_dir="${worktree_for_branch[$branch]}"
        if [[ -n "$wt_dir" ]]; then
            if git worktree remove "$wt_dir" 2>/dev/null; then
                echo "🧹 Removed worktree for '$branch' ($wt_dir)"
            else
                echo "⚠️  Skipping '$branch' — worktree at $wt_dir has uncommitted changes (remove manually or use -f)" >&2
                continue
            fi
        fi
        git branch -d "$branch"
    done <<< "$to_delete"
}
