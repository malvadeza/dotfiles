DOTFILES_DIR=$HOME/dotfiles

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh
ZSH_OVERRIDES=$HOME/.zsh_overrides

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# ZSH_THEME="random"
# ZSH_THEME="miloshadzic"
# ZSH_THEME="avit"
# ZSH_THEME="gallois"
# ZSH_THEME="sorin"
# ZSH_THEME="dallas"
ZSH_THEME="eastwood"

# Uncomment this to disable bi-weekly auto-update checks
DISABLE_AUTO_UPDATE="true"

plugins=(
	brew
	bundler
	command-not-found
	docker
	git
	heroku
	node
	npm
	pip
	postgres
	python
	rails
	rake
	ruby
	rvm
	yarn
	zsh-syntax-highlighting
)

# Loads oh-my-zsh

. $ZSH/oh-my-zsh.sh

# Loads extensions
[ -f $DOTFILES_DIR/01-aliases.sh ] && . $DOTFILES_DIR/01-aliases.sh
[ -f $DOTFILES_DIR/02-commands.sh ] && . $DOTFILES_DIR/02-commands.sh

# Loads overrides
[ -f $ZSH_OVERRIDES ] && . $ZSH_OVERRIDES
