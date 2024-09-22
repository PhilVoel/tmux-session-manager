# Version
export VERSION="1.0.2"

# Get the current tmux session name.
CURRENT_SESSION=$(
	if [ "$(tmux display-message -p "#{session_grouped}")" = 0 ]; then
		tmux display-message -p "#{session_name}"
	else
		tmux display-message -p "#{session_group}"
	fi
)

# Separator in save files
export SEPARATOR=$'\t'

# Get the value of a tmux option or a default value if the option is not set.
# Usage: get_tmux_option "name of option" "default value"
get_tmux_option() {
	local option_name="$1"
	local default_value="$2"
	local tmux_value
	tmux_value=$(tmux show-option -gqv "$option_name")
	if [ -n "$tmux_value" ]; then
		echo "$tmux_value"
	else
		echo "$default_value"
	fi
}

# Get the save directory from the tmux options and expand $HOME.
SAVE_DIR=$(get_tmux_option "@session-manager-save-dir" "${HOME}/.local/share/tmux/sessions" | sed "s,\$HOME,$HOME,g; s,\~,$HOME,g")
mkdir -p "$SAVE_DIR"
export SAVE_DIR

# Get the path for the new save file.
NEW_SAVE_FILE="${SAVE_DIR}/${CURRENT_SESSION}_$(date +"%Y-%m-%dT%H:%M:%S")"
export NEW_SAVE_FILE

# Get the path for the last save file for this session.
export LAST_SAVE_FILE="${SAVE_DIR}/${CURRENT_SESSION}_last"

new_spinner() {
	local current=0
	local chars="/-\|"
	while true; do
		tmux display-message "${chars:$current:1} $1"
		current=$(((current + 1) % 4))
		sleep 0.1
	done
}

# Start a spinner with a message.
# Usage: start_spinner "Some message"
start_spinner() {
	new_spinner "$1"&
	export SPINNER_PID=$!
}

# Stop the current spinner and display a message.
# Usage: stop_spinner "Some message"
stop_spinner() {
	kill "$SPINNER_PID"
	tmux display-message "$1"
}
