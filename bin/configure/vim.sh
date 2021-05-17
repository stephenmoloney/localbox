#!/usr/bin/env bash
# shellcheck disable=SC2125
set -eo pipefail

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

function setup_vimrc() {
    if [[ ! -d "${HOME}/.vim" ]]; then
        mkdir -p "${HOME}/.vim"
    fi

    if [[ ! -d "${HOME}/.vim/tmp" ]]; then
        mkdir -p "${HOME}/.vim/tmp"
    fi

    cp \
        "${PROJECT_ROOT}/config/dotfiles/vim/vimrc" \
        "${HOME}/.vimrc"

    if [[ ! -d "${HOME}/.vim/snippets" ]]; then
        mkdir -p "${HOME}/.vim/snippets"
    fi

    cp \
        "${PROJECT_ROOT}/config/vim/coc/coc-settings.json" \
        "${HOME}/.vim/coc-settings.json"

    if [[ -n "$(ls -A "${PROJECT_ROOT}/config/vim/snippets")" ]] &&
        [[ -d "${PROJECT_ROOT}/config/vim/snippets" ]]; then
        cp \
            "${PROJECT_ROOT}/config/vim/snippets/*" \
            "${HOME}/.vim/snippets"
    fi
}
