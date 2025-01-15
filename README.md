# Tmux Session Manager

We all love tmux. But whenever you close a session (for instance, by restarting your system), you lose all the windows, panes and programs you had open.\
The easy solution: Just save the entire tmux environment and restore it (that's what [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) does).\
But what if you have multiple sessions that you use for multiple projects? What if you don't need all those sessions open at the same time? What if you don't *want* them open because your laptop is a decade old and you can't afford to start dozens of programs at once?\
This plugin aims to solve that problem by only saving the session you are currently in as well as providing a fzf-based session switcher that allows you to not only switch between running sessions but also seamlessly restore a previously saved session and switch to it.

Originally just a fork of `tmux-resurrect`, this plugin has since been rewritten from scratch (although the inspiration is still obvious and I might have borrowed from them in a few places) to be a more compact codebase that I can more easily maintain and extend if necessary.

## About

This plugin tries to save the current session status as precisely as possible. Here's what's been taken care of:

- windows, panes and their layout
- current working directory for each pane
- active window
- active pane for each window
- programs running within a pane
  - taking care of NixOS' Neovim wrapper. As NixOS wraps some programs and starts them with additional arguments, the plugin removes those arguments when it detects Neovim running on NixOS. If you're using the unwrapped version of Neovim, you can disable this check in the [Configuration](#Configuration).

## Dependencies

- [`tmux`](https://github.com/tmux/tmux) (3.2 or higher)
- [`fzf`](https://github.com/junegunn/fzf) (0.13.0 or higher; optional but recommended)

> [!note]
> This plugin only uses standard functionality in fzf which was present in its initial release. In theory, every version should work but this is untested.

## Installation

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @plugin 'PhilVoel/tmux-session-manager'

Hit `prefix + I` to install the plugin.

### Manual Installation

Clone the repo:

    $ git clone https://github.com/PhilVoel/tmux-session-manager ~/clone/path

Add this line to your `.tmux.conf`:

    run-shell ~/clone/path/session_manager.tmux

Reload TMUX environment with `$ tmux source ~/.tmux.conf`.

## Configuration

You can customize the plugin by setting the following options in your `.tmux.conf`:

| Configuration option                       | Options               | Default value                   | Description                                                                                                          |
|------------------------------------------- | --------------------- | ------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `session-manager-save-dir`                 | `~/any/path/you/like` | `~/.local/share/tmux/sessions/` | Specify the directory where session data is saved.                                                                   |
| `session-manager-save-key`                 | Any key binding       | `C-s`                           | Which key binding to set for saving the current session.                                                             |
| `session-manager-save-key-root`            | Any key binding       | Not set                         | Which key binding to set in root table for saving the current session. Using `prefix` is **not** necessary.          |
| `session-manager-restore-key`              | Any key binding       | `C-r`                           | Which key binding to set for restoring or switching to a session.                                                    |
| `session-manager-restore-key-root`         | Any key binding       | Not set                         | Which key binding to set in root table for restoring or switching to a session. Using `prefix` is **not** necessary. |
| `session-manager-disable-nixos-nvim-check` | `on` or `off`         | `off`                           | When `on`, disable the check for Neovim on NixOS.                                                                    |
| `session-manager-disable-fzf-warning`      | `on` or `off`         | `off`                            | When `on`, disable the check for fzf on startup.                                                                     |

## Bug reports and contributions

I'm always thankful for bug reports and new ideas. For details, check the [guidelines](CONTRIBUTING.md).

## Credits

As already stated, this plugin is heavily inspired by [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) and I've taken small liberties with some of their code while rewriting.

## License
This software is licensed under [MIT](LICENSE.md).
