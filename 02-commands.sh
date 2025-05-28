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