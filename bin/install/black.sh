#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

BLACK_VERSION_FALLBACK=26.5.1

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

function get_current_version() {
    black --version 2>/dev/null | head -n1 | cut -d' ' -f2 || true
}

function install_black() {
    local version="${1}"
    local current_version

    maybe_install_apt_pkg "python3-pip" "*"
    if ! command -v pipx &>/dev/null; then
        sudo apt-get install -y pipx
        sudo pipx ensurepath --force
        export PATH="$HOME/.local/bin:$PATH"
    fi

    current_version="$(get_current_version)"

    if [[ -z "${current_version}" ]] || [[ "${current_version}" != "${version}" ]]; then
        pipx install --force "black==${version}"
    else
        echo "black version ${version} is already installed"
        echo "Skipping installation"
    fi

    if [[ -z "$(grep "${HOME}/.local/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.local/bin"
    fi

    black --version
}

function main() {
    local version="${1:-$BLACK_VERSION_FALLBACK}"

    install_black "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]:-}" ]]; then
    main "${@}"
fi
