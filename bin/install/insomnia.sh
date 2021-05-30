#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

INSOMNIA_VERSION_FALLBACK="*"

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

function install_insomnia() {
    local version="${1}"

    [[ "${version}" == "latest" ]] && version="*"

    if [[ -z "$(grep "insomnia-ubuntu" /etc/apt/sources.list.d/insomnia.list 2>/dev/null || true)" ]]; then
        echo "deb [trusted=yes arch=amd64] https://download.konghq.com/insomnia-ubuntu/ default all" |
            sudo tee -a /etc/apt/sources.list.d/insomnia.list
    fi

    maybe_install_apt_pkg insomnia "${version}"
}

function main() {
    local version="${1:-$INSOMNIA_VERSION_FALLBACK}"

    install_insomnia "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
