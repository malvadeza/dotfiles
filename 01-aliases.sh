# Helpers

alias zshsrc='source ~/.zshrc'
alias zshedit='nvim ~/.zshrc'

# Git Aliases
alias gdst='git diff --stat'
alias ggpdel='git push origin :"$(git_current_branch)"'
alias ggpforce='ggpush --force'
alias ggploko='ggpush --no-verify'
alias ggproc='git pull --rebase origin "$(git_current_branch)"'
alias ggpyolo='ggpforce --no-verify'
