#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

DOTNET_CORE_SDK_VERSION_FALLBACK=8.0

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

function install_dotnet_core_sdk() {
    local version="${1}"
    local ubuntu_version
    local repo_url

    [[ "${version}" == "latest" ]] && version="*"

    maybe_install_apt_pkg "wget" "*"
    maybe_install_apt_pkg "lsb-release" "*"
    maybe_install_apt_pkg "apt-transport-https" "*"
    maybe_install_apt_pkg "zlib1g" "*"

    ubuntu_version="$(lsb_release -cas 2>/dev/stdout | awk NR==4)"
    repo_url="https://packages.microsoft.com/config/ubuntu/${ubuntu_version}/packages-microsoft-prod.deb"

    echo "Downloading key from ${repo_url}"
    wget \
        "${repo_url}" \
        -O packages-microsoft-prod.deb &&
        sudo dpkg -i packages-microsoft-prod.deb &&
        rm packages-microsoft-prod.deb

    if [[ ! -e /etc/apt/preferences.d/99-dotnet.pref ]]; then
        sudo mkdir -p /etc/apt/preferences.d || true
        sudo touch /etc/apt/preferences.d/99-dotnet.pref
    fi

    echo """
Package: dotnet* aspnet* netstandard*
Pin: origin \"packages.microsoft.com\"
Pin-Priority: 1001
""" | sudo tee /etc/apt/preferences.d/99-dotnet.pref

    sudo apt-get update -y -q
    maybe_install_apt_pkg "dotnet-sdk-${version}" "*"

    dotnet --info
}

function main() {
    local version="${1:-$DOTNET_CORE_SDK_VERSION_FALLBACK}"

    # Remove pre-existing packages
    sudo apt-get remove -y 'dotnet*' 'aspnet*' 'netstandard*' || true

    # Install dotnet core sdk
    install_dotnet_core_sdk "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]:-}" ]]; then
    main "${@}"
fi
