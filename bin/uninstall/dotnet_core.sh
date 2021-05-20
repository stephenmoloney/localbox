#!/usr/bin/env bash
set -Eeuo pipefail

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

function uninstall_dotnet_core_sdk() {
    local version="${1:-}"

    if [[ -z "${version}" ]]; then
        version="$(
            sudo apt list --installed 2>/dev/null |
                grep dotnet-sdk |
                cut -d'/' -f1 |
                sed 's/dotnet-sdk-//g'
        )"
    fi

    maybe_uninstall_apt_pkg "dotnet-sdk-${version}"
    sudo apt autoremove -y
}

function main() {
    local version="${1:-}"

    uninstall_dotnet_core_sdk "${version}"
}

main "${@}"
