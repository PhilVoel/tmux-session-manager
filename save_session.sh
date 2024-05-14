#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit
source common_utils.sh

# Separator for tmux format strings
declare S=$SEPARATOR
#
# Tmux format string for windows
WINDOW_FORMAT="window$S#{window_index}$S#{window_name}$S#{window_layout}$S#{window_active}"

# Tmux format string for panes
PANE_FORMAT="pane$S#{pane_index}$S#{pane_current_path}$S#{pane_active}$S#{window_index}$S#{pane_pid}"

start_spinner "Saving current session"
echo "version$S$VERSION" > "$NEW_SAVE_FILE"
tmux list-windows -F "$WINDOW_FORMAT" >> "$NEW_SAVE_FILE"
tmux list-panes -s -F "$PANE_FORMAT" | while IFS="$SEPARATOR" read -r line; do
	awk -v command="$(declare full_command
			full_command="$(ps -ao "ppid,args" \
				| sed "s/^ *//" \
				| grep "^$(cut -f6 <<< "$line")" \
				| cut -d' ' -f2-)"
			if [[ "$(grep ^ID= /etc/os-release | cut -d'=' -f2)" == "nixos" \
				&& "$(get_tmux_option "@session-manager-diable-nixos-nvim-check" "off")" != "on" \
				&& "$(cut -d' ' -f1 <<< "$full_command" | xargs basename)" == "nvim" ]]; then
				cut -d' ' -f1,11- <<< "$full_command"
			else
				echo "$full_command"
			fi)" \
		'BEGIN {FS=OFS="\t"} {$6=command; print}'\
		<<< "$line" >> "$NEW_SAVE_FILE"
done
if ! cmp -s "$NEW_SAVE_FILE" "$LAST_SAVE_FILE"; then
	ln -sf "$NEW_SAVE_FILE" "$LAST_SAVE_FILE"
else
	rm "$NEW_SAVE_FILE"
fi
stop_spinner "Session saved"
