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

select_session() {
	local -r sessions=$(get_all_sessions | sort | uniq)
	if command -v fzf 1>/dev/null; then
		echo "$sessions" | fzf
	else
		local -r session_count=$(echo "$sessions" | wc -w)
		local -r cancel=$((session_count+1))
		PS3="Select session (or $cancel to cancel): "
		select session in $sessions; do
			if (( REPLY == cancel )); then
				exit
			elif (( REPLY > 0 && REPLY <= session_count )); then
				echo "$session"
				break
			fi
		done
	fi
}

session_name="$(select_session)"
if [[ -z "$session_name" ]]; then
	exit 0
elif ! tmux has-session -t "$session_name"; then
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
