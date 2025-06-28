#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit
source common_utils.sh

# Separator for tmux format strings
declare S=$SEPARATOR

# Tmux format string for windows
WINDOW_FORMAT="window$S#{window_index}$S#{window_name}$S#{window_layout}$S#{window_active}"

# Tmux format string for panes
PANE_FORMAT="pane$S#{pane_index}$S#{pane_current_path}$S#{pane_active}$S#{window_index}$S#{pane_pid}"

start_spinner "Saving current session"
if [[ -e "${NEW_SAVE_FILE}_archived" ]]; then
	mv "${NEW_SAVE_FILE}_archived" "$NEW_SAVE_FILE"
fi
echo "version$S$VERSION" > "$NEW_SAVE_FILE"
tmux list-windows -F "$WINDOW_FORMAT" >> "$NEW_SAVE_FILE"
tmux list-panes -s -F "$PANE_FORMAT" | while IFS="$SEPARATOR" read -r line; do
	pids=$(ps -ao "ppid,pid" \
		| sed "s/^ *//" \
		| grep "^$(cut -f6 <<< "$line")" \
		| rev \
		| cut -d' ' -f1 \
		| rev)
	command="$(for pid in $pids; do
		if [[ "$(grep ^ID= /etc/os-release | cut -d'=' -f2)" == "nixos" \
			&& "$(get_tmux_option "@session-manager-diable-nixos-nvim-check" "off")" != "on" \
			&& "$(cut -d' ' -f1 <<< "$(ps -p $pid -o cmd)" | tail +2 | xargs basename)" == "nvim" ]]; then
			echo -n "nvim"
			while read -r arg; do
				if [ -n "$arg" ]; then
					echo -n " '$arg'"
				fi
			done <<< "$(xargs -0L1 < /proc/$pid/cmdline | tail +8)"
		else
			while read -r arg; do
				echo -n "'$arg' "
			done <<< "$(xargs -0L1 < /proc/$pid/cmdline)"
		fi
	done)"
	awk -v command="$command" \
		'BEGIN {FS=OFS="\t"} {$6=command; print}'\
		<<< "$line" >> "$NEW_SAVE_FILE"
done
if ! cmp -s "$NEW_SAVE_FILE" "$LAST_SAVE_FILE"; then
	ln -sf "$NEW_SAVE_FILE" "$LAST_SAVE_FILE"
else
	rm "$NEW_SAVE_FILE"
fi
stop_spinner "Session saved"
