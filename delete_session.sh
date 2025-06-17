#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit
source common_utils.sh

get_saved_sessions() {
	for file in "$SAVE_DIR"/*_last*; do
		if [[ "$file" =~ _last$ ]]; then
			basename "${file%%_last}"
		else
			basename "${file%%_last_archived}"
		fi
	done
}

session_name=$(select_session "$(get_saved_sessions)")
if [[ -z "$session_name" ]]; then
	exit 0
fi
start_spinner "Deleting session"
rm -f "$SAVE_DIR/$session_name"_last "$SAVE_DIR/$session_name"_last_archived "$SAVE_DIR/$session_name"_[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]
stop_spinner "Session deleted"
