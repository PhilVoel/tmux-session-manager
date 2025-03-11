#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit
source common_utils.sh

get_all_sessions() {
	local -r all_files="$(ls "$SAVE_DIR")"
	for file in $all_files; do
		if [[ "$file" =~ _last$ ]] && [[ "${file%%_last}" != "$CURRENT_SESSION" ]]; then
			echo "${file%%_last}"
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
	local -r all_files="$(ls "$SAVE_DIR")"
	for file in $all_files; do
		if [[ "$file" =~ _last_archived$ ]]; then
			echo "${file%%_last_archived}"
		fi
	done
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

if [[ "$1" == "--archived" ]]; then
	mv "$SAVE_DIR/${session_name}_last_archived" "$SAVE_DIR/${session_name}_last"
fi

if ! tmux has-session -t "$session_name" 2> /dev/null; then
	start_spinner "Restoring session $session_name"
	tmux new-session -ds "$session_name" -c "$HOME"
	while read -r line; do
		if grep -q "^window" <<< "$line"; then
			IFS=$SEPARATOR read -r _ window_index window_name _ _ <<< "$line"
			tmux new-window -k -t "$session_name:$window_index" -n "$window_name"
		elif grep -q "^pane" <<< "$line"; then
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
		fi
	done < "${SAVE_DIR}/${session_name}_last"
	while read -r line; do
		if grep -q "^window" <<< "$line"; then
			IFS=$SEPARATOR read -r _ window_index _ window_layout window_active <<< "$line"
			tmux select-layout -t "$session_name:$window_index" "$window_layout"
			if [[ "$window_active" == "1" ]]; then
				tmux select-window -t "$session_name:$window_index"
			fi
		fi
	done < "${SAVE_DIR}/${session_name}_last"
	stop_spinner "Session restored"
fi
tmux switch-client -t "$session_name"
