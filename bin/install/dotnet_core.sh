#!/usr/bin/env bash
set -Eeuo pipefail

DOTNET_CORE_SDK_VERSION_FALLBACK=5.0

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

function install_dotnet_core_sdk() {
    local version="${1}"
    local ubuntu_version

    [[ "${version}" == "latest" ]] && version="*"

    maybe_install_apt_pkg "wget" "*"
    maybe_install_apt_pkg "lsb-release" "*"
    maybe_install_apt_pkg "apt-transport-https" "*"

    ubuntu_version="$(lsb_release -cas 2>/dev/stdout | awk NR==4)"

    wget \
        "https://packages.microsoft.com/config/ubuntu/${ubuntu_version}/packages-microsoft-prod.deb" \
        -O packages-microsoft-prod.deb &&
        sudo dpkg -i packages-microsoft-prod.deb &&
        rm packages-microsoft-prod.deb &&
        sudo apt update -y -qq &&
        sudo apt install -y "dotnet-sdk-${version}"

    dotnet --version
}

function main() {
    local version="${1:-$DOTNET_CORE_SDK_VERSION_FALLBACK}"

    install_dotnet_core_sdk "${version}"
}

main "${@}"
