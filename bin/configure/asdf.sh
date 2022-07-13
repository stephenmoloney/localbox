#!/usr/bin/env bash
# shellcheck disable=SC2125
set -eo pipefail

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
PROJECT_ROOT="$(project_root)"

function setup_asdf() {
    export ASDF_CONFIG_FILE="${HOME}/.asdfrc"
    export ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${HOME}/.tool-versions"
    export ASDF_DIR="${HOME}/.asdf"
    export ASDF_DATA_DIR="${HOME}/.asdf"
    if [[ -d "${HOME}/.asdf" ]]; then
        source "${HOME}/.asdf/asdf.sh"
        source "${HOME}/.asdf/completions/asdf.bash"
    fi
}

function setup_asdf_dotfiles() {
    cp \
        "${PROJECT_ROOT}/config/dotfiles/asdf/asdfrc" \
        "${HOME}/.asdfrc"
    cp \
        "${PROJECT_ROOT}/config/dotfiles/asdf/tool-versions" \
        "${HOME}/.tool-versions"
}
