#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit
source common_utils.sh

get_saved_sessions() {
	for file in "$SAVE_DIR"/*_last; do
		basename "${file%%_last}"
	done
}

session_name=$(select_session "$(get_saved_sessions)")
if [[ -z "$session_name" ]]; then
	exit 0
fi
start_spinner "Archiving session"
mv "$SAVE_DIR/${session_name}_last" "$SAVE_DIR/${session_name}_last_archived"
stop_spinner "Session archived"
