#!/usr/bin/env bash
set -Eeuo pipefail

JQ_VERSION_FALLBACK=1.6

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

function get_current_version() {
    jq --version | tr -d "jq-"
}

function install_jq() {
    local version="${1}"

    maybe_install_apt_pkg "wget" "*"

    if [[ -z "$(get_current_version 2>/dev/null || true)" ]] ||
        [[ "$(get_current_version 2>/dev/null || true)" != "${version}" ]]; then
        wget \
            "https://github.com/stedolan/jq/releases/download/jq-${version}/jq-linux64"
        sudo chmod +x jq-linux64
        sudo mv jq-linux64 /usr/local/bin/jq
    else
        echo "jq version ${version} is already installed"
        echo "Skipping installation"
    fi

    jq --version
}

function main() {
    local version="${1:-$JQ_VERSION_FALLBACK}"

    install_jq "${version}"
}

main "${@}"
