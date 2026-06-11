#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

# Default version (matches recent stable releases)
AZURE_CLI_VERSION_FALLBACK="2.87.0"

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
    if curl -sIf -o /dev/null "${GITHUB_URL}/bin/utils.sh"; then
        source <(curl -s "${GITHUB_URL}/bin/utils.sh")
    else
        echo "${GITHUB_URL}/bin/utils.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ************************************************************************

function get_current_version() {
    local ver
    ver=$({ command -v az && ~/.local/bin/az --version 2>/dev/null || echo ""; } | head -n 1 | awk '{print $2}' || true)
    if [[ -z "$ver" ]]; then
        echo ""
    else
        echo "$ver"
    fi
}

function install_azure_cli() {
    local version="${1}"

    maybe_install_apt_pkg "python3-pip" "*"
    if ! command -v pipx &>/dev/null; then
        sudo apt-get install -y pipx
        sudo pipx ensurepath --force
        export PATH="$HOME/.local/bin:$PATH"
    fi

    echo "Checking for existing Azure CLI installation..."
    local current_ver
    current_ver=$(get_current_version)

    if [[ -z "${current_ver}" ]] || [[ "${current_ver}" != "${version}" ]]; then
        echo "Installing Azure CLI version ${version} via pipx..."
        pipx uninstall azure-cli 2>/dev/null || true
        pipx install --force azure-cli=="${version}"
    else
        echo "Azure CLI version ${version} is already installed."
        echo "Skipping installation."
    fi

    if [[ -z "$(grep "${HOME}/.local/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.local/bin"
    fi

    az --version
}

function main() {
    local version="${1:-$AZURE_CLI_VERSION_FALLBACK}"
    install_azure_cli "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]:-}" ]]; then
    main "${@}"
fi
