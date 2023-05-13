#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

DOCKER_VERSION_FALLBACK=5:23.0.6-1~ubuntu.22.04~jammy

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

function install_docker() {
    local version="${1}"

    maybe_install_apt_pkg "lsb-release" "*"
    maybe_install_apt_pkg "curl" "*"
    maybe_install_apt_pkg "gpg" "*"

    if [[ ! -e /usr/share/keyrings/docker-archive-keyring.gpg ]]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
            sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    fi

    echo \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
        https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    maybe_install_apt_pkg "containerd.io" "*"
    maybe_install_apt_pkg "docker-ce" "${version}"
    apt_hold_pkg "docker-ce"
    maybe_install_apt_pkg "docker-ce-cli" "${version}"
    apt_hold_pkg "docker-ce-cli"
    if [[ -n "${USER:-}" ]]; then
        sudo usermod -aG docker "${USER}"
    fi

    docker --version
}

function main() {
    local version="${1:-$DOCKER_VERSION_FALLBACK}"

    install_docker "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
