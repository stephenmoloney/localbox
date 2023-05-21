#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

ANSIBLE_VERSION_FALLBACK=7.5.0
ANSIBLE_LINT_VERSION_FALLBACK=6.16.2

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
    ansible --version | cut -d ' ' -f2
}

function get_current_lint_version() {
    ansible-lint --version | cut -d ' ' -f2
}

function install_ansible() {
    local version="${1}"

    maybe_install_apt_pkg "python3-pip" "*"

    if [[ -z "$(get_current_version 2>/dev/null || true)" ]] ||
        [[ "$(get_current_version 2>/dev/null || true)" != "${version}" ]]; then
        pip3 install ansible=="${version}"
    else
        echo "ansible version ${version} is already installed"
        echo "Skipping installation"
    fi

    if [[ -z "$(grep "${HOME}/.local/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.local/bin"
    fi

    ansible --version
}

function install_ansible_lint() {
    local version="${1}"

    if [[ -z "$(get_current_version 2>/dev/null || true)" ]] ||
        [[ "$(get_current_version 2>/dev/null || true)" != "${version}" ]]; then
        pip3 install ansible-lint=="${version}"
    else
        echo "ansible-lint version ${version} is already installed"
        echo "Skipping installation"
    fi

    ansible-lint --version
}

function main() {
    local version="${1:-$ANSIBLE_VERSION_FALLBACK}"
    local lint_version="${2:-$ANSIBLE_LINT_VERSION_FALLBACK}"

    install_ansible "${version}"
    install_ansible_lint "${lint_version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
