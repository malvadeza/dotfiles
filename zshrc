export ANTIGEN_PATH="$HOME/.antigen"
export ANTIGEN_ZSH="$ANTIGEN_PATH/antigen.zsh"
export WORKON_HOME="$HOME/Envs"
export PATH="/usr/local/bin:$PATH"

source $ANTIGEN_ZSH


# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle heroku
antigen bundle command-not-found

# Languges Bundles
# Ruby
antigen bundle ruby
antigen bundle rails
antigen bundle rake
antigen bundle rvm

# Python
antigen bundle python
antigen bundle pip
antigen bundle django
antigen bundle virtualenv
antigen bundle virtualenvwrapper

# Node
antigen bundle node
antigen bundle npm
antigen bundle nvm

antigen bundle postgres

# OS Specific plugins
# TODO
antigen bundle brew

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Load the theme.
antigen theme miloshadzic

# Tell antigen that you're done.
antigen apply
