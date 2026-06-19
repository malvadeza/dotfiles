# Helpers

# proj - Navigate to projects directory
# Usage: proj [project_name]
# Description: 
#   When called without arguments, navigates to the root Projects directory ($HOME/Projects)
#   When called with a project name, navigates to that specific project directory
#   If the specified project doesn't exist, displays an error message
# Examples:
#   proj          # Changes to $HOME/Projects
#   proj myapp    # Changes to $HOME/Projects/myapp
function proj() {
	local project_name="$1"
	local project_dir="$HOME/Projects/$project_name"
	
	if [ -z "$project_name" ]; then
		# If no project name is provided, navigate to the Projects directory
		cd "$HOME/Projects" || return 1
		return 0
	fi
	
	if [ -d "$project_dir" ]; then
		cd "$project_dir" || return
	else
		echo "Project $project_name not found in $HOME/Projects"
		return 1
	fi
}

# Completion function for proj
_proj_completion() {
  local projects_dir="$HOME/Projects"
  compadd -- $(find "$projects_dir" -maxdepth 1 -type d -exec basename {} \;)
}

compdef _proj_completion proj

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