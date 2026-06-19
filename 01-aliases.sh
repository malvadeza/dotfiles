# Helpers

alias zshsrc='source ~/.zshrc'
alias zshedit='nvim ~/.zshrc'

# Git Aliases

# gpush with required remote selection
gpush() {
  local remote="$1"
  shift
  git push "$remote" "$(git_current_branch)" "$@"
}

gpforce() {
  gpush "$1" --force
}

gploko() {
  gpush "$1" --no-verify
}

gpyolo() {
  gpush "$1" --force --no-verify
}

alias gdst='git diff --stat'
alias ggpdel='git push origin :"$(git_current_branch)"'
alias ggpforce='ggpush --force'
alias ggploko='ggpush --no-verify'
alias ggproc='git pull --rebase origin "$(git_current_branch)"'
alias ggpyolo='ggpforce --no-verify'
