#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit
source common_utils.sh

get_saved_sessions() {
	local -r all_files="$(ls "$SAVE_DIR")"
	for file in $all_files; do
		if [[ "$file" =~ _last$ ]]; then
			echo "${file%%_last}"
		fi
	done
}

session_name=$(select_session "$(get_saved_sessions)")
if [[ -z "$session_name" ]]; then
	exit 0
fi
start_spinner "Archiving session"
mv "$SAVE_DIR/${session_name}_last" "$SAVE_DIR/${session_name}_last_archived"
stop_spinner "Session archived"
