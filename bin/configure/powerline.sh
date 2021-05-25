#!/usr/bin/env bash
set -eo pipefail

function setup_powerline() {
    local powerline_path
    powerline_path="$(python3 -m site --user-site)/powerline"

    if [[ -d "${powerline_path}" ]]; then
        "${HOME}/.local/bin/powerline-daemon" -q || true
        export POWERLINE_COMMAND_ARGS=""
        export POWERLINE_SHELL_CONTINUATION=1
        export POWERLINE_BASH_CONTINUATION=1
        export POWERLINE_BASH_SELECT=1
        export POWERLINE_SHELL_SELECT=1
        . "${powerline_path}/bindings/bash/powerline.sh"
        export TMUX_POWERLINE_CONFIG_PATH="${powerline_path}/bindings/tmux/powerline.conf"
    fi
}
