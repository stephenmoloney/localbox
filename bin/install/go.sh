#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

GO_VERSION_FALLBACK=1.16.7
export GOPATH="${GOPATH:-${HOME}/src/go}"
export GOROOT="${GOROOT:-/usr/local/go}"
export PATH="${PATH}:/usr/local/go/bin"

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

function install_go() {
    local version="${1}"

    maybe_install_apt_pkg "wget" "*"

    if [[ ! -d "${GOPATH}" ]]; then
        mkdir -p "${GOPATH}"
    fi

    if [[ "$(go version 2>/dev/null || true)" != *"${version}"* ]]; then
        echo "The current version of go does not match the required version"
        echo "Installing go version ${version}"

        wget "https://golang.org/dl/go${version}.linux-amd64.tar.gz"
        if [[ -d "${GOROOT}" ]]; then
            sudo rm -rf "${GOROOT}"
        fi
        sudo tar \
            -C /usr/local \
            -xzf "go${version}.linux-amd64.tar.gz"
        rm "go${version}.linux-amd64.tar.gz"
    else
        echo "version ${version} of go is already installed"
    fi

    go version
}

function main() {
    local version="${1:-$GO_VERSION_FALLBACK}"

    install_go "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
