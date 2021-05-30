#!/usr/bin/env bash
# shellcheck disable=2009,2143
set -eo pipefail

function setup_powerline() {
    local powerline_path
    powerline_path="$(python3 -m site --user-site || true)/powerline"

    if [[ -d "${powerline_path}" ]]; then
        if [[ -z "$(ps aux | grep "powerline-daemon" | awk NR==1 | grep -v grep)" ]]; then
            "${HOME}/.local/bin/powerline-daemon" --quiet
        else
            "${HOME}/.local/bin/powerline-daemon" --replace --quiet
        fi
        export POWERLINE_COMMAND_ARGS=""
        export POWERLINE_SHELL_CONTINUATION=1
        export POWERLINE_BASH_CONTINUATION=1
        export POWERLINE_BASH_SELECT=1
        export POWERLINE_SHELL_SELECT=1
        . "${powerline_path}/bindings/bash/powerline.sh"
        export TMUX_POWERLINE_CONFIG_PATH="${powerline_path}/bindings/tmux/powerline.conf"
    fi
}
