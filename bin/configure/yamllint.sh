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

function setup_yamllint_dotfiles() {
    if [[ ! -d "${HOME}/.config/yamllint" ]]; then
        mkdir -p "${HOME}/.config/yamllint"
    fi
    cp \
        "${PROJECT_ROOT}/config/dotfiles/yamllint/config.yml" \
        "${HOME}/.config/yamllint/config"
}

function setup_yamllint() {
    if [[ -e "${HOME}/.local/bin/yamllint" ]] &&
        [[ -z "$(grep "${HOME}/.local/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.local/bin"
    fi
}
