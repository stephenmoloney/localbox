#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

TMUX_PLUGIN_MANAGER_VERSION_FALLBACK=v3.1.0

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
if [[ -e "${UTILS_PATH}" ]]; then
    source "${UTILS_PATH}"
else
    if [[ -z "$(command -v curl)" ]]; then
        sudo apt update -y -qq
        sudo apt install -y -qq curl
    fi
    echo "Falling back to remote script ${GITHUB_URL}/bin/utils.sh"
    if curl -sIf -o /dev/null ${GITHUB_URL}/bin/utils.sh; then
        source <(curl -s "${GITHUB_URL}/bin/utils.sh")
    else
        echo "${GITHUB_URL}/bin/utils.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ************************************************************************

function install_tmux_plugin_manager() {
    local version="${1}"

    maybe_install_apt_pkg "git" "*"

    if [[ -d "${HOME}/.tmux/plugins/tpm" ]]; then
        rm -rf "${HOME}/.tmux/plugins/tpm"
    fi

    git clone \
        https://github.com/tmux-plugins/tpm \
        "${HOME}/.tmux/plugins/tpm"

    pushd "${HOME}/.tmux/plugins/tpm" || exit
    git fetch origin
    git checkout "${version}"
    popd || exit

    if [[ -d "${HOME}/.tmux/plugins" ]]; then
        export TMUX_PLUGIN_MANAGER_PATH="${HOME}/.tmux/plugins"
    fi
}

function main() {
    local version="${1:-$TMUX_PLUGIN_MANAGER_VERSION_FALLBACK}"

    install_tmux_plugin_manager "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
