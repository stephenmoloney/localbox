#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

AZURE_CLI_VERSION_FALLBACK="2.52.0-1~jammy"

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

function install_azure_cli() {
    local version="${1}"

    [[ "${version}" == "latest" ]] && version="*"

    maybe_install_apt_pkg "ca-certificates" "*"
    maybe_install_apt_pkg "curl" "*"
    maybe_install_apt_pkg "apt-transport-https" "*"
    maybe_install_apt_pkg "lsb-release" "*"
    maybe_install_apt_pkg "gnupg" "*"

    if [[ -e /etc/apt/trusted.gpg.d/microsoft.gpg ]]; then
        sudo rm /etc/apt/trusted.gpg.d/microsoft.gpg
    fi

    if [[ -e /etc/apt/sources.list.d/azure-cli.list ]]; then
        sudo rm /etc/apt/sources.list.d/azure-cli.list
    fi

    curl -sL https://packages.microsoft.com/keys/microsoft.asc |
        gpg --dearmor |
        sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg >/dev/null

    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" |
        sudo tee /etc/apt/sources.list.d/azure-cli.list

    maybe_install_apt_pkg azure-cli "${version}"
    apt_hold_pkg azure-cli

    az --version
}

function main() {
    local version="${1:-$AZURE_CLI_VERSION_FALLBACK}"

    install_azure_cli "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
