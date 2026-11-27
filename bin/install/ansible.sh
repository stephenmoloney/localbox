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

# pipx installs app shims here; make sure it is on PATH before any
# pipx-managed command is invoked
if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
    export PATH="${HOME}/.local/bin:${PATH}"
fi

function get_current_version() {
    ansible --version 2>/dev/null | cut -d ' ' -f2 || true
}

function install_ansible() {
    local version="${1}"
    local current_version

    maybe_install_apt_pkg "python3-pip" "*"
    if ! command -v pipx &>/dev/null; then
        sudo apt-get install -y pipx
        # Run as the invoking user: 'sudo pipx ensurepath' would configure
        # root's environment, not this user's
        pipx ensurepath --force
    fi

    current_version="$(get_current_version)"

    if [[ -z "${current_version}" ]] || [[ "${current_version}" != "${version}" ]]; then
        pipx install --force "ansible-core==${version}"
    else
        echo "ansible version ${version} is already installed"
        echo "Skipping installation"
    fi

    ansible --version
}

function install_ansible_auxillaries() {
    # Install ansible-lint in its own pipx venv rather than injecting into
    # ansible-core: injection proved fragile (the package lands in the venv
    # but its app shim can silently fail to materialise, giving
    # 'command not found' with pipx reporting success)
    if ! command -v ansible-lint >/dev/null 2>&1; then
        pipx install ansible-lint
    fi

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
