#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

PENCIL_VERSION_FALLBACK=3.1.1

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

function install_pencil() {
    local version="${1}"

    sudo apt autoremove --purge -y pencil 2>/dev/null || true

    maybe_install_apt_pkg "wget" "*"
    maybe_install_apt_pkg "libgconf-2-4" "*"
    (
        sudo apt --fix-broken install -y
        maybe_install_apt_pkg "libgconf-2-4" "*"
    )

    pushd "$(mktemp -d)" || exit
    wget \
        "https://pencil.evolus.vn/dl/V${version}.ga/pencil_${version}.ga_amd64.deb" \
        -O "pencil_${version}.ga_amd64.deb"

    sudo dpkg --install "pencil_${version}.ga_amd64.deb"
    rm "pencil_${version}.ga_amd64.deb"
    popd || exit
}

function main() {
    local version="${1:-$PENCIL_VERSION_FALLBACK}"

    install_pencil "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
