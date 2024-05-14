#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit
source common_utils.sh

get_all_sessions() {
	local all_files
	all_files="$(ls "$SAVE_DIR")"
	for file in $all_files; do
		if [[ "$file" =~ _last$ ]] && [[ "${file%%_last}" != "$CURRENT_SESSION" ]]; then
			echo "${file%%_last}"
		fi
	done
	local all_sessions
	all_sessions="$(tmux list-sessions -F "#{session_name}")"
	for session in $all_sessions; do
		if [[ "$session" != "$CURRENT_SESSION" ]]; then
			echo "$session"
		fi
	done
}

session_name="$(get_all_sessions | sort | uniq | fzf)"
if [[ -z "$session_name" ]]; then
	exit 0
elif ! tmux list-sessions -F "#{session_name}" | grep -xq "$session_name"; then
	start_spinner "Restoring session $session_name"
	tmux new-session -ds "$session_name" -c "$HOME"
	while read -r line; do
		if grep -q "^window" <<< "$line"; then
			IFS=$SEPARATOR read -r _ window_index window_name _ _ <<< "$line"
			tmux new-window -k -t "$session_name:$window_index" -n "$window_name"
		elif grep -q "^pane" <<< "$line"; then
			IFS=$SEPARATOR read -r _ pane_index pane_current_path pane_active window_index command <<< "$line"
			if [[ "$pane_index" == "0" ]]; then
				tmux send-keys -t "$session_name:$window_index" "cd $pane_current_path" Enter C-l
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
		if grep -q "^window"; then
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
