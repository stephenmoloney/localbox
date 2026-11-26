#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

ANSIBLE_CORE_VERSION_FALLBACK=2.21.0

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

function get_current_version() {
    ansible --version 2>/dev/null | cut -d ' ' -f2 || true
}

function install_ansible() {
    local version="${1}"
    local current_version

    maybe_install_apt_pkg "python3-pip" "*"
    if ! command -v pipx &>/dev/null; then
        sudo apt-get install -y pipx
        sudo pipx ensurepath --force
        export PATH="$HOME/.local/bin:$PATH"
    fi

    current_version="$(get_current_version)"

    if [[ -z "${current_version}" ]] || [[ "${current_version}" != "${version}" ]]; then
        pipx install --force "ansible-core==${version}"
    else
        echo "ansible version ${version} is already installed"
        echo "Skipping installation"
    fi

    if [[ -z "$(grep "${HOME}/.local/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.local/bin"
    fi

    ansible --version
}

function install_ansible_auxillaries() {
    pipx inject ansible-core ansible-lint

    ansible-lint --version
}

function main() {
    local version="${1:-$ANSIBLE_CORE_VERSION_FALLBACK}"

    install_ansible "${version}"
    install_ansible_auxillaries
}

if [[ "$0" == "${BASH_SOURCE[0]:-}" ]]; then
    main "${@}"
fi
