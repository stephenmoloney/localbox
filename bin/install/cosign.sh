#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

COSIGN_VERSION_FALLBACK=2.2.2

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

# ******* Importing fallbacks.sh as a means of installing missing deps *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
FALLBACKS_PATH="$(dirname "${BASH_SOURCE[0]}")"/../fallbacks.sh
if [[ -e "${FALLBACKS_PATH}" ]]; then
    source "${FALLBACKS_PATH}"
else
    if [[ -z "$(command -v curl)" ]]; then
        sudo apt update -y -qq
        sudo apt install -y -qq curl
    fi
    echo "Falling back to remote script ${GITHUB_URL}/bin/fallbacks.sh"
    if curl -sIf -o /dev/null ${GITHUB_URL}/bin/fallbacks.sh; then
        source <(curl -s "${GITHUB_URL}/bin/fallbacks.sh")
    else
        echo "${GITHUB_URL}/bin/fallbacks.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ****************************************************************************

maybe_install_go_as_fallback

function get_current_version() {
    cosign version | grep GitVersion | cut -d "v" -f2
}

function install_cosign() {
    local version="${1}"

    maybe_install_apt_pkg "curl" "*"

    if [[ "$(get_current_version 2>/dev/null || true)" != "${version}" ]]; then
        pushd "$(mktemp --directory)" || exit
        GOOS="$(go env GOOS)" \
        GOARCH="$(go env GOARCH)" \
            go install "github.com/sigstore/cosign/v2/cmd/cosign@v${version}"
        sudo mv "${GOPATH}/bin/cosign" /usr/local/bin/cosign
        popd || exit
    else
        echo "cosign version ${version} is already installed"
        echo "Skipping installation"
    fi

    cosign version
}

function main() {
    local version="${1:-$COSIGN_VERSION_FALLBACK}"

    install_cosign "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
