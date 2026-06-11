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
    ansible --version | cut -d ' ' -f2
}

function install_ansible() {
    local version="${1}"

    maybe_install_apt_pkg "python3-pip" "*"
    if ! command -v pipx &>/dev/null; then
        sudo apt-get install -y pipx
        sudo pipx ensurepath --force
        export PATH="$HOME/.local/bin:$PATH"
    fi

    if [[ -z "$(get_current_version 2>/dev/null || true)" ]] ||
        [[ "$(get_current_version 2>/dev/null || true)" != "${version}" ]]; then
        pipx install --force ansible-core=="${version}"
    else
        echo "ansible version ${version} is already installed"
        echo "Skipping installation"
    fi

    if [[ -z "$(grep "${HOME}/.local/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.local/bin"
    fi

    if [[ -L ~/.local/bin/ansible ]]; then
        rm ~/.local/bin/ansible || true
    fi

    ln -s \
        /home/u2/.local/pipx/venvs/ansible-core/bin/ansible \
        ~/.local/bin/ansible

    ansible --version
}

function install_ansible_auxillaries() {
    pipx inject ansible-core ansible-lint

    if [[ -L ~/.local/bin/ansible-lint ]]; then
        rm ~/.local/bin/ansible-lint || true
    fi

    ln -s \
        /home/u2/.local/pipx/venvs/ansible-core/bin/ansible-lint \
        ~/.local/bin/ansible-lint

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
