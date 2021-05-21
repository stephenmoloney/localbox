#!/usr/bin/env bash
set -Eeuo pipefail

TMUX_PLUGIN_MANAGER_VERSION_FALLBACK=2afeff1529ec85d0c5ced5ece3714c2220b646a5

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
        --branch "${version}" \
        https://github.com/tmux-plugins/tpm \
        "${HOME}/.tmux/plugins/tpm"
}

function main() {
    local version="${1:-$TMUX_PLUGIN_MANAGER_VERSION_FALLBACK}"

    install_tmux_plugin_manager "${version}"
}

main "${@}"
