# Helpers

# ---------------------------------------------------------------------------
# Git Worktree Helpers
# Layout assumption: ~/Projects/<repo>/<branch> (each branch is a worktree)
# ---------------------------------------------------------------------------

# _gwt_find_anchor <repo-name>
# Returns the path to any worktree subdir inside ~/Projects/<repo>/ so we can
# run "git -C <anchor>" commands from outside the repo.
function _gwt_find_anchor() {
    local repo_dir="$HOME/Projects/$1"
    [ -d "$repo_dir" ] || { echo "Project '$1' not found in $HOME/Projects" >&2; return 1 }
    for d in "$repo_dir"/*/; do
        [ -e "$d/.git" ] && { echo "${d%/}"; return 0 }
    done
    echo "No git worktree found inside $repo_dir" >&2
    return 1
}

# proj - Navigate to a project (worktree-aware)
# Usage:
#   proj                    → $HOME/Projects
#   proj <repo>             → fzf-pick a worktree inside the repo
#   proj <repo> <worktree>  → jump directly to that worktree
function proj() {
    local project_name="$1"
    local worktree_name="$2"
    local project_dir="$HOME/Projects/$project_name"

    if [ -z "$project_name" ]; then
        cd "$HOME/Projects" || return 1
        return 0
    fi

    if [ ! -d "$project_dir" ]; then
        echo "Project $project_name not found in $HOME/Projects"
        return 1
    fi

    if [ -z "$worktree_name" ]; then
        if command -v fzf &>/dev/null; then
            local selected
            selected=$(find "$project_dir" -maxdepth 1 -mindepth 1 -type d \
                | sed "s|$project_dir/||" \
                | fzf --prompt="worktree> ")
            [ -n "$selected" ] && cd "$project_dir/$selected" || return 0
        else
            cd "$project_dir" || return 1
        fi
        return 0
    fi

    if [ -d "$project_dir/$worktree_name" ]; then
        cd "$project_dir/$worktree_name" || return 1
    else
        echo "Worktree '$worktree_name' not found in $project_dir"
        return 1
    fi
}

_proj_completion() {
    local projects_dir="$HOME/Projects"
    if (( CURRENT == 2 )); then
        compadd -- $(find "$projects_dir" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)
    elif (( CURRENT == 3 )); then
        local repo_dir="$projects_dir/$words[2]"
        compadd -- $(find "$repo_dir" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)
    fi
}
compdef _proj_completion proj

# gwtstatus - Show dirty/clean state of all worktrees
# Usage:
#   gwtstatus           → uses current repo
#   gwtstatus <repo>    → uses ~/Projects/<repo>
function gwtstatus() {
    local anchor
    if [ -n "$1" ]; then
        anchor=$(_gwt_find_anchor "$1") || return 1
    else
        anchor="."
    fi

    git -C "$anchor" worktree list --porcelain \
        | awk '/^worktree/{path=$2} /^branch/{branch=$2; print path, branch}' \
        | while read -r path branch; do
            local status
            status=$(git -C "$path" status --short 2>/dev/null | wc -l | tr -d ' ')
            local label="${branch##refs/heads/}"
            printf "%-40s %s %s\n" "$label" "$path" \
                "$([ "$status" -gt 0 ] && echo "($status dirty)" || echo "(clean)")"
          done
}

_gwtstatus_completion() {
    compadd -- $(find "$HOME/Projects" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)
}
compdef _gwtstatus_completion gwtstatus

# gwtls - List worktrees (overrides oh-my-zsh alias with repo-name support)
# Usage:
#   gwtls               → uses current repo
#   gwtls <repo>        → uses ~/Projects/<repo>
unalias gwtls 2>/dev/null
function gwtls() {
    local anchor
    if [ -n "$1" ]; then
        anchor=$(_gwt_find_anchor "$1") || return 1
    else
        anchor="."
    fi
    git -C "$anchor" worktree list
}

_gwtls_completion() {
    compadd -- $(find "$HOME/Projects" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)
}
compdef _gwtls_completion gwtls

# gwtadd - Create a worktree under ~/Projects/<repo>/<branch> and cd into it
# Handles three cases automatically:
#   - branch already exists locally   → git worktree add <path> <branch>
#   - branch exists only on remote    → git worktree add <path> -b <branch> origin/<branch>
#   - branch doesn't exist anywhere   → git worktree add <path> -b <branch> <base>
# Usage:
#   gwtadd <branch>             new branch from main, or checkout existing
#   gwtadd <branch> <base>      new branch from <base> (ignored if branch already exists)
function gwtadd() {
    local branch="$1"
    local base="${2:-main}"
    [ -z "$branch" ] && { echo "Usage: gwtadd <branch> [base-branch]"; return 1 }

    local repo_root
    repo_root=$(git worktree list --porcelain | awk 'NR==1{print $2}')
    local wt_path
    wt_path="$(dirname "$repo_root")/$branch"

    if git show-ref --verify --quiet "refs/heads/$branch"; then
        # Branch exists locally
        echo "Checking out existing local branch '$branch'"
        git worktree add "$wt_path" "$branch"
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        # Branch exists on remote only
        echo "Tracking remote branch 'origin/$branch'"
        git worktree add "$wt_path" -b "$branch" "origin/$branch"
    else
        # Brand new branch
        echo "Creating new branch '$branch' from '$base'"
        git worktree add "$wt_path" -b "$branch" "$base"
    fi && cd "$wt_path"
}

# Completion: arg 1 = existing local/remote branches or free-form new name
#             arg 2 = local branch for base (only shown when creating new)
_gwtadd_completion() {
    if (( CURRENT == 2 )); then
        # Suggest local + remote branches as candidates (covers checkout existing case)
        compadd -- $(git branch --all --format='%(refname:short)' 2>/dev/null \
            | sed 's|^origin/||' | sort -u)
    elif (( CURRENT == 3 )); then
        compadd -- $(git branch --format='%(refname:short)' 2>/dev/null)
    fi
}
compdef _gwtadd_completion gwtadd

# gwts - fzf-switch between worktrees of the current repo
function gwts() {
    local selected
    selected=$(git worktree list --porcelain \
        | awk '/^worktree/{path=$2} /^branch/{branch=$2; print path "\t" branch}' \
        | column -t -s $'\t' \
        | fzf --prompt="switch worktree> " \
        | awk '{print $1}')
    [ -n "$selected" ] && cd "$selected"
}

# Completion: gwts takes no arguments (fzf handles selection interactively)
_gwts_completion() { }
compdef _gwts_completion gwts

# gwtkill - Remove a worktree and delete its branch
# Usage: gwtkill [branch]   (omit to pick with fzf)
function gwtkill() {
    local branch="$1"

    if [ -z "$branch" ]; then
        branch=$(git worktree list --porcelain \
            | awk '/^branch/{print $2}' \
            | sed 's|refs/heads/||' \
            | grep -v "$(git symbolic-ref --short HEAD 2>/dev/null)" \
            | fzf --prompt="kill worktree> ")
    fi

    [ -z "$branch" ] && return 1

    local repo_root
    repo_root=$(git worktree list --porcelain | awk 'NR==1{print $2}')
    local wt_path
    wt_path="$(dirname "$repo_root")/$branch"

    echo "Removing worktree: $wt_path"
    git worktree remove "$wt_path" --force
    echo "Deleting branch: $branch"
    git branch -D "$branch"
}

# Completion: arg 1 = existing worktree branches (excluding current branch)
_gwtkill_completion() {
    if (( CURRENT == 2 )); then
        local current_branch
        current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
        compadd -- $(git worktree list --porcelain \
            | awk '/^branch/{print $2}' \
            | sed 's|refs/heads/||' \
            | grep -v "^${current_branch}$" 2>/dev/null)
    fi
}
compdef _gwtkill_completion gwtkill

# gwtfork - Create a new worktree branching off the current branch
# Usage: gwtfork <new-branch>
function gwtfork() {
    local branch="$1"
    [ -z "$branch" ] && { echo "Usage: gwtfork <new-branch>"; return 1 }
    gwtadd "$branch" "$(git symbolic-ref --short HEAD)"
}

# Completion: gwtfork takes a free-form new branch name (no suggestions)
_gwtfork_completion() { }
compdef _gwtfork_completion gwtfork

# gwthelp - Print worktree command reference and example flows
function gwthelp() {
    echo ""
    echo "  Git Worktree Helpers"
    echo "  Layout: ~/Projects/<repo>/<branch>"
    echo ""
    echo "  Commands"
    echo "  ──────────────────────────────────────────────────────────────"
    echo "  proj <repo>                 fzf-pick a worktree and jump in"
    echo "  proj <repo> <branch>        jump directly to a worktree"
    echo "  gwtls  [repo]               list worktrees (current repo or named)"
    echo "  gwtstatus [repo]            dirty/clean state of all worktrees"
    echo "  gwtadd <branch> [base]      create worktree + cd (auto-detects existing branches)"
    echo "  gwts                        fzf-switch between worktrees of current repo"
    echo "  gwtkill [branch]            remove worktree + delete branch (fzf if omitted)"
    echo "  gwtfork <branch>            new worktree branching off current HEAD"
    echo ""
    echo "  Flows"
    echo "  ──────────────────────────────────────────────────────────────"
    echo "  Start a new feature"
    echo "    proj partners             # pick worktree via fzf"
    echo "    gwtadd feat/payments main # create + cd into new worktree"
    echo ""
    echo "  Check out an existing / remote branch"
    echo "    gwtadd feat/payments      # auto-detects local or origin branch"
    echo ""
    echo "  Switch between open worktrees"
    echo "    gwts                      # fzf picker, no stashing needed"
    echo ""
    echo "  Inspect any repo from anywhere"
    echo "    gwtls partners"
    echo "    gwtstatus partners"
    echo ""
    echo "  Spike off current branch, keep it isolated"
    echo "    gwtfork spike/experiment  # branches from current HEAD"
    echo "    gwtkill spike/experiment  # removes worktree + branch when done"
    echo ""
    echo "  End-of-day cleanup"
    echo "    gwtkill                   # fzf-pick which worktree to delete"
    echo ""
}

# Completion: gwthelp takes no arguments
_gwthelp_completion() { }
compdef _gwthelp_completion gwthelp

# zshupdate - Update oh-my-zsh and custom plugins
function zshupdate() {
	echo "Updating oh-my-zsh..."
	omz update

	local custom_plugins="$ZSH/custom/plugins"
	if [ -d "$custom_plugins" ]; then
		local plugins_updated=0
		for plugin in "$custom_plugins"/*; do
			if [ -d "$plugin" ] && [ -d "$plugin/.git" ]; then
				local plugin_name=$(basename "$plugin")
				echo "Updating custom plugin: $plugin_name..."
				(cd "$plugin" && git pull && echo "  ✓ $plugin_name updated") || echo "  ✗ Failed to update $plugin_name"
				((plugins_updated++))
			fi
		done
		if [ $plugins_updated -eq 0 ]; then
			echo "No custom plugins found to update."
		fi
	fi

	echo "Done!"
}