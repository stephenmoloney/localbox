#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

SHELLCHECK_VERSION_FALLBACK=0.9.0

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
    shellcheck --version | awk NR==2 | cut -d ' ' -f2
}

function install_shellcheck() {
    local version="${1}"
    local download_url
    download_url=https://github.com/koalaman/shellcheck/releases/download

    maybe_install_apt_pkg "wget" "*"
    maybe_install_apt_pkg "xz-utils" "*"

    if [[ -z "$(get_current_version 2>/dev/null || true)" ]] ||
        [[ "$(get_current_version 2>/dev/null || true)" != "${version}" ]]; then
        wget \
            --output-document="shellcheck-v${version}.linux.x86_64.tar.xz" \
            "${download_url}/v${version}/shellcheck-v${version}.linux.x86_64.tar.xz"
        if [[ ! -d "${HOME}/src/pkgs" ]]; then
            mkdir -p "${HOME}/src/pkgs"
        fi
        tar \
            -C "${HOME}/src/pkgs" \
            -xf "shellcheck-v${version}.linux.x86_64.tar.xz"
        sudo mv \
            "${HOME}/src/pkgs/shellcheck-v${version}/shellcheck" \
            /usr/local/bin/shellcheck
        sudo chmod +x /usr/local/bin/shellcheck
        rm "shellcheck-v${version}.linux.x86_64.tar.xz"
    else
        echo "shellcheck version ${version} is already installed"
        echo "Skipping installation"
    fi

    shellcheck --version
}

function main() {
    local version="${1:-$SHELLCHECK_VERSION_FALLBACK}"

    install_shellcheck "${version}"
}

main "${@}"
