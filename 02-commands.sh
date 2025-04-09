# Helpers

# proj: A function to navigate to a specified project directory within the $HOME/Projects folder.
#
# Usage:
#   proj <project_name>
#
# Arguments:
#   <project_name>  The name of the project directory to navigate to.
#
# Description:
#   This function checks if a project name is provided as an argument. If no argument is given,
#   it prints a usage message and exits with a non-zero status.
#   If the specified project directory exists within the $HOME/Projects folder, the function
#   changes the current working directory to that project directory.
#   If the directory does not exist, it prints an error message and exits with a non-zero status.
#
# Returns:
#   0 if the directory change is successful.
#   1 if no argument is provided or the specified project directory does not exist.
function proj() {
	local project_name="$1"
	local project_dir="$HOME/Projects/$project_name"
	
	if [ -z "$project_name" ]; then
		echo "Usage: proj <project_name>"

		return 1
	fi
	
	if [ -d "$project_dir" ]; then
		cd "$project_dir" || return
	else
		echo "Project $project_name not found in $HOME/Projects"

		return 1
	fi
}
