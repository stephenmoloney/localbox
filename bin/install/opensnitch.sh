#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

OPENSNITCH_VERSION_FALLBACK=1.5.2

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

function install_opensnitch() {
    local version="${1}"

    sudo apt autoremove --purge -y opensnitch 2>/dev/null || true

    pushd "$(mktemp -d)" || exit

    wget \
        "https://github.com/evilsocket/opensnitch/releases/download/v${version}/opensnitch_${version}-1_amd64.deb" \
        -O "opensnitch_${version}-1_amd64.deb"

    wget \
        "https://github.com/evilsocket/opensnitch/releases/download/v${version}/python3-opensnitch-ui_${version}-1_all.deb" \
        -O "python3-opensnitch-ui_${version}-1_all.deb"

    ls -al

    sudo apt install -y ./opensnitch_"${version}"-1_amd64.deb
    sudo apt install -y ./python3-opensnitch-ui_"${version}"-1_all.deb
    rm ./*.deb
    popd || exit
}

function main() {
    local version="${1:-$OPENSNITCH_VERSION_FALLBACK}"

    install_opensnitch "${version}"
    sudo systemctl enable --now opensnitch
    sudo systemctl start opensnitch
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
