# ---------------------------------------------------------------------------
# Git Insights — repo health analysis commands
# Inspired by https://piechowski.io/post/git-commands-before-reading-code/
#
# Commands (long form → short alias):
#   git-churn        → gchurn          most-modified files (past year)
#   git-contributors → gcontributors   contributors ranked by commit count
#   git-hotspots     → ghotspots       files appearing most in fix/bug commits
#   git-velocity     → gvelocity       monthly commit count over repo lifetime
#   git-crisis       → gcrisis         revert / hotfix / rollback commits
#   git-insights     → ginsights       run all five in sequence
# ---------------------------------------------------------------------------

# _git_insights_repo [path]
# Resolves and validates the target repo path. Defaults to CWD.
function _git_insights_repo() {
    local repo="${1:-$(pwd)}"
    if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
        echo "Error: '$repo' is not a git repository." >&2
        return 1
    fi
    echo "$(cd "$repo" && pwd)"
}

_git_insights_hr() { printf '\n%s\n\n' "$(printf '─%.0s' {1..60})"; }

# git-churn [path]
# Lists the 20 most-modified files in the past year.
# High churn = patch-on-patch areas worth understanding first.
function git-churn() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo ""
        echo "  git-churn [path]   alias: gchurn"
        echo ""
        echo "  Lists the 20 most-modified files over the past year."
        echo "  High churn indicates problem areas where every change"
        echo "  is a patch on a patch — read these files first."
        echo ""
        echo "  Arguments"
        echo "    path   path to a git repo (default: current directory)"
        echo ""
        return 0
    fi

    local repo
    repo=$(_git_insights_repo "$1") || return 1

    echo ""
    echo "Code Churn — most-modified files (past year)"
    echo "$(basename "$repo")"
    echo "High churn = patch-on-patch areas; read these before touching anything else."
    echo ""
    git -C "$repo" log --format=format: --name-only --since="1 year ago" \
        | sort | uniq -c | sort -nr | head -20 \
        | awk 'NF {printf "  %5s  %s\n", $1, $2}'
    echo ""
}
alias gchurn='git-churn'

# git-contributors [path]
# Ranks all contributors by commit count (merges excluded).
# A single dominant author = high bus-factor risk.
function git-contributors() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo ""
        echo "  git-contributors [path]   alias: gcontributors"
        echo ""
        echo "  Ranks all contributors by commit count (merges excluded)."
        echo "  Low spread across authors signals high bus-factor risk:"
        echo "  one person leaving could stall the project."
        echo ""
        echo "  Arguments"
        echo "    path   path to a git repo (default: current directory)"
        echo ""
        return 0
    fi

    local repo
    repo=$(_git_insights_repo "$1") || return 1

    echo ""
    echo "Contributors — ranked by commit count"
    echo "$(basename "$repo")"
    echo "Merges excluded. Low spread across authors = high bus-factor risk."
    echo ""
    git -C "$repo" shortlog -sn --no-merges \
        | awk '{printf "  %5s  %s\n", $1, substr($0, index($0,$2))}'
    echo ""
}
alias gcontributors='git-contributors'

# git-hotspots [path]
# Lists the 20 files most often touched by fix/bug/broken commits (past year).
# Repeated fixes in the same file = recurring defect area.
function git-hotspots() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo ""
        echo "  git-hotspots [path]   alias: ghotspots"
        echo ""
        echo "  Lists the 20 files most often touched by commits whose"
        echo "  message contains 'fix', 'bug', or 'broken' (past year)."
        echo "  Files that keep breaking deserve extra scrutiny."
        echo ""
        echo "  Arguments"
        echo "    path   path to a git repo (default: current directory)"
        echo ""
        return 0
    fi

    local repo
    repo=$(_git_insights_repo "$1") || return 1

    echo ""
    echo "Bug Hotspots — files in fix/bug commits (past year)"
    echo "$(basename "$repo")"
    echo "Files that keep appearing in fix/bug/broken commits. Recurring fixes = fragile area."
    echo ""
    git -C "$repo" log -i -E --grep="fix|bug|broken" \
        --name-only --format='' --since="1 year ago" \
        | sort | uniq -c | sort -nr | head -20 \
        | awk 'NF {printf "  %5s  %s\n", $1, $2}'
    echo ""
}
alias ghotspots='git-hotspots'

# git-velocity [path]
# Prints monthly commit counts across the repo's full history.
# Shows whether the team is accelerating, stable, or declining.
function git-velocity() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo ""
        echo "  git-velocity [path]   alias: gvelocity"
        echo ""
        echo "  Prints monthly commit counts across the repo's full history."
        echo "  Reveals whether the team is accelerating, holding steady,"
        echo "  or winding down."
        echo ""
        echo "  Arguments"
        echo "    path   path to a git repo (default: current directory)"
        echo ""
        return 0
    fi

    local repo
    repo=$(_git_insights_repo "$1") || return 1

    echo ""
    echo "Velocity — commits per month"
    echo "$(basename "$repo")"
    echo "Full repo history. Rising numbers = team accelerating; flat or falling = slowing down."
    echo ""
    git -C "$repo" log --format='%ad' --date=format:'%Y-%m' \
        | sort | uniq -c \
        | awk '{printf "  %s  %s\n", $2, $1}'
    echo ""
}
alias gvelocity='git-velocity'

# git-crisis [path]
# Lists commits with revert/hotfix/emergency/rollback in the message (past year).
# High count = firefighting culture or a fragile deploy pipeline.
function git-crisis() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo ""
        echo "  git-crisis [path]   alias: gcrisis"
        echo ""
        echo "  Lists commits mentioning revert, hotfix, emergency, or"
        echo "  rollback in the past year."
        echo "  A high count suggests a firefighting culture or a fragile"
        echo "  deploy pipeline rather than stable development."
        echo ""
        echo "  Arguments"
        echo "    path   path to a git repo (default: current directory)"
        echo ""
        return 0
    fi

    local repo
    repo=$(_git_insights_repo "$1") || return 1

    local results
    results=$(git -C "$repo" log --oneline --since="1 year ago" \
        | grep -iE 'revert|hotfix|emergency|rollback' || true)

    echo ""
    echo "Crisis Patterns — reverts / hotfixes (past year)"
    echo "$(basename "$repo")"
    echo "Commits mentioning revert, hotfix, emergency, or rollback. High count = firefighting culture."
    echo ""

    if [ -z "$results" ]; then
        echo "  (none found)"
    else
        local count
        count=$(echo "$results" | wc -l | tr -d ' ')
        echo "  Total: $count"
        echo ""
        echo "$results" | head -20 | awk '{printf "  %s\n", $0}'
        if [ "$count" -gt 20 ]; then
            echo "  ... and $((count - 20)) more"
        fi
    fi
    echo ""
}
alias gcrisis='git-crisis'

# git-insights [path]
# Runs all five analysis commands in sequence.
function git-insights() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo ""
        echo "  git-insights [path]   alias: ginsights"
        echo ""
        echo "  Runs all five git analysis commands in sequence:"
        echo "    git-churn        most-modified files (past year)"
        echo "    git-contributors contributors ranked by commit count"
        echo "    git-hotspots     files in fix/bug commits (past year)"
        echo "    git-velocity     monthly commit count over repo lifetime"
        echo "    git-crisis       revert / hotfix / rollback commits"
        echo ""
        echo "  Arguments"
        echo "    path   path to a git repo (default: current directory)"
        echo ""
        echo "  Individual command help"
        echo "    git-churn --help"
        echo "    git-contributors --help"
        echo "    git-hotspots --help"
        echo "    git-velocity --help"
        echo "    git-crisis --help"
        echo ""
        return 0
    fi

    local repo
    repo=$(_git_insights_repo "$1") || return 1

    _git_insights_hr
    echo "  Git Insights: $(basename "$repo")"
    echo "  Path: $repo"
    _git_insights_hr

    git-churn "$repo"
    _git_insights_hr
    git-contributors "$repo"
    _git_insights_hr
    git-hotspots "$repo"
    _git_insights_hr
    git-velocity "$repo"
    _git_insights_hr
    git-crisis "$repo"
}
alias ginsights='git-insights'
