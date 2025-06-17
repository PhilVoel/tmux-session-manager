#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit
source common_utils.sh

get_all_sessions() {
	for file in "$SAVE_DIR"/*_last; do
		if [[ "$(basename "${file%%_last}")" != "$CURRENT_SESSION" ]]; then
			basename "${file%%_last}"
		fi
	done
	local -r all_sessions="$(tmux list-sessions -F "#{session_name}")"
	for session in $all_sessions; do
		if [[ "$session" != "$CURRENT_SESSION" ]]; then
			echo "$session"
		fi
	done
}

get_archived_sessions() {
	for file in "$SAVE_DIR/"*_last_archived; do
		basename "${file%%_last_archived}"
	done
}

# Checks if the first version is greater than the second
is_version_geq() {
	[[ "$(echo -e "$1\n$2" | sort -V | sed -n 2p)" != "$2" ]]
}

declare session_name
if [[ "$1" == "--archived" ]]; then
	session_name=$(select_session "$(get_archived_sessions)")
else
	session_name=$(select_session "$(get_all_sessions)")
fi

if [[ -z "$session_name" ]]; then
	exit 0
fi

if ! tmux has-session -t "$session_name" 2> /dev/null; then
	session_file="$SAVE_DIR/${session_name}_last"
	exec < "$session_file"
	file_version="$(head -n1 | cut -d"$SEPARATOR" -f2)"
	if is_version_geq "$file_version" "$VERSION"; then
		tmux display-message -d0 "#[bg=red]Error: File version is newer than the plugin's. Press ESC to quit."
		exit 0
	fi
	if [[ "$1" == "--archived" ]]; then
		mv "$session_file"_archived "$session_file"
	fi

	start_spinner "Restoring session $session_name"
	tmux new-session -ds "$session_name" -c "$HOME"
	while read -r line; do
		case $line in
			window*)
				IFS=$SEPARATOR read -r _ window_index window_name _ _ <<< "$line"
				tmux new-window -k -t "$session_name:$window_index" -n "$window_name"
			;;
			pane*)
				IFS=$SEPARATOR read -r _ pane_index pane_current_path pane_active window_index command <<< "$line"
				if [[ "$pane_index" == "$(get_tmux_option base-index 0)" ]]; then
					tmux send-keys -t "$session_name:$window_index" "cd \"$pane_current_path\"" Enter "clear" Enter
				else
					tmux split-window -d -t "$session_name:$window_index" -c "$pane_current_path"
				fi
				if [[ "$pane_active" == "1" ]]; then
					tmux select-pane -t "$session_name:$window_index.$pane_index"
				fi
				if [[ -n "$command" ]]; then
					tmux send-keys -t "$session_name:$window_index.$pane_index" "$command" Enter
				fi
			;;
		esac
	done
	while read -r line; do
		case $line in
			window*)
				IFS=$SEPARATOR read -r _ window_index _ window_layout window_active <<< "$line"
				tmux select-layout -t "$session_name:$window_index" "$window_layout"
				if [[ "$window_active" == "1" ]]; then
					tmux select-window -t "$session_name:$window_index"
				fi
			;;
		esac
	done <<< "$(tail -n+2 < "$session_file")"
	stop_spinner "Session restored"
fi
tmux switch-client -t "$session_name"
