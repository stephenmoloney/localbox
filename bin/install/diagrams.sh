#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

DIAGRAMS_VERSION_FALLBACK=0.23.3

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]:-}")/../utils.sh"
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

function install_diagrams() {
    local version="${1}"

    maybe_install_apt_pkg "python3-pip" "*"

    pip3 install diagrams=="${version}"

    if [[ -z "$(grep "${HOME}/.local/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.local/bin"
    fi
}

function main() {
    local version="${1:-$DIAGRAMS_VERSION_FALLBACK}"

    install_diagrams "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]:-}" ]]; then
    main "${@}"
fi
