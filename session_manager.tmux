#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit
source common_utils.sh

if [[ $(get_tmux_option "@session-manager-disable-fzf-warning" "off") != "on" && ! $(command -v fzf) ]]; then
	tmux display-message "Warning: fzf was not found in PATH. Recommended for tmux-session-manager. If that is intentional, you can disable this message."
	exit
fi

declare key
declare bindings

bindings=$(get_tmux_option "@session-manager-save-key" "C-s")
for key in $bindings; do
	tmux bind-key "$key" run-shell "$(pwd)/save_session.sh"
done
bindings=$(get_tmux_option "@session-manager-save-key-root" "")
for key in $bindings; do
	tmux bind-key -n "$key" run-shell "$(pwd)/save_session.sh"
done

bindings=$(get_tmux_option "@session-manager-restore-key" "C-r")
for key in $bindings; do
	tmux bind-key "$key" run-shell "tmux display-popup -E '$(pwd)/restore_session.sh'"
done
bindings=$(get_tmux_option "@session-manager-restore-key-root" "")
for key in $bindings; do
	tmux bind-key -n "$key" run-shell "tmux display-popup -E '$(pwd)/restore_session.sh'"
done
