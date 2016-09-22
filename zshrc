# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# ZSH_THEME="miloshadzic"
# ZSH_THEME="random"
# ZSH_THEME="avit"
ZSH_THEME="gallois"

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Uncomment this to disable bi-weekly auto-update checks
DISABLE_AUTO_UPDATE="true"

plugins=(
	command-not-found
	zsh-syntax-highlighting
	git
	brew
	heroku
	postgres
	python
	pip
	django
	virtualenvwrapper
	ruby
	rvm
	rails
	rake
	bundler
	node
	npm
	nvm
	docker
)
# alias vim="mvim -v"

export PATH="/usr/texbin:/usr/local/bin:$PATH"
export PATH="$HOME/.rvm/bin:$PATH" # Add RVM to PATH for scripting

export WORKON_HOME="$HOME/.envs"

export JAVA_HOME="$(/usr/libexec/java_home)"

source $ZSH/oh-my-zsh.sh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

# export MANPATH="/usr/local/man:$MANPATH"

# # Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"
