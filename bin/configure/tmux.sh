#!/usr/bin/env bash
# shellcheck disable=SC2125
set -eo pipefail

PROJECT_ROOT="$(project_root)"
# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
if [[ -e "${UTILS_PATH}" ]]; then
    . "${UTILS_PATH}"
else
    if [[ -z "$(command -v curl)" ]]; then
        sudo apt update -y -qq
        sudo apt install -y -qq curl
    fi
    echo "Falling back to remote script ${GITHUB_URL}/bin/utils.sh"
    if curl -sIf -o /dev/null ${GITHUB_URL}/bin/utils.sh; then
        . <(curl -s "${GITHUB_URL}/bin/utils.sh")
    else
        echo "${GITHUB_URL}/bin/utils.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ************************************************************************
PROJECT_ROOT="$(project_root)"

function setup_tmux() {
    cp \
        "${PROJECT_ROOT}/config/dotfiles/tmux/tmux.conf" \
        "${HOME}/.tmux.conf"

    if [[ -d "${HOME}/.tmux/plugins/tpm" ]]; then
        "${HOME}/.tmux/plugins/tpm/bin/clean_plugins"
        "${HOME}/.tmux/plugins/tpm/bin/install_plugins"
        "${HOME}/.tmux/plugins/tpm/bin/update_plugins" all
    fi
}

function setup_tmux_plugin_manager() {
    if [[ -d "${HOME}/.tmux/plugins" ]]; then
        export TMUX_PLUGIN_MANAGER_PATH="${HOME}/.tmux/plugins"
    fi
}
