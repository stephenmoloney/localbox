#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

BPYTOP_VERSION_FALLBACK=1.0.68

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
    bpytop --version | awk NR==1 | cut -d':' -f2
}

function setup_bpytop_themes() {
    if [[ ! -d "${HOME}/.config/bpytop/themes" ]]; then
        mkdir -p "${HOME}/.config/bpytop/themes"
    fi

    maybe_install_apt_pkg "curl" "*"

    curl \
        -s "https://raw.githubusercontent.com/aristocratos/bpytop/v${version}/LICENSE" > \
        "${HOME}/.config/bpytop/themes/LICENSE"

    cat \
        <(echo '# Apache 2.0 License') \
        <(echo '# See LICENSE file') \
        <(echo '') \
        <(curl -s "https://raw.githubusercontent.com/aristocratos/bpytop/v${version}/themes/monokai.theme") > \
        "${HOME}/.config/bpytop/themes/monokai.theme"

    cat \
        <(echo '# Apache 2.0 License') \
        <(echo '# See LICENSE file') \
        <(echo '') \
        <(curl -s "https://raw.githubusercontent.com/aristocratos/bpytop/v${version}/themes/nord.theme") > \
        "${HOME}/.config/bpytop/themes/nord.theme"
}

function install_bpytop() {
    local version="${1}"

    maybe_install_apt_pkg "python3-pip" "*"

    if [[ -z "$(get_current_version 2>/dev/null || true)" ]] ||
        [[ "$(get_current_version 2>/dev/null || true)" != "${version}" ]]; then
        pip3 install bpytop=="${version}"
    else
        echo "bpytop version ${version} is already installed"
        echo "Skipping installation"
    fi

    if [[ -z "$(grep "${HOME}/.local/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.local/bin"
    fi

    setup_bpytop_themes

    bpytop --version
}

function main() {
    local version="${1:-$BPYTOP_VERSION_FALLBACK}"

    install_bpytop "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]:-}" ]]; then
    main "${@}"
fi
