#!/usr/bin/env bash
# shellcheck disable=SC2128
set -euo pipefail

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]}")/../bin/utils.sh"
if [[ -e "${UTILS_PATH}" ]]; then
    . "${UTILS_PATH}"
else
    if [[ -z "$(command -v curl)" ]]; then
        sudo apt update -y -qq
        sudo apt install -y -qq curl
    fi
    echo "Falling back to remote script ${GITHUB_URL}/bin/utils.sh"
    if curl -sIf -o /dev/null ${GITHUB_URL}/bin/utils.sh; then
        . <(curl -s "${GITHUB_URL}/bin/utils.sh")
    else
        echo "${GITHUB_URL}/bin/utils.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ************************************************************************
PROJECT_ROOT="$(project_root)"

function install_required_pkgs() {
    . "${PROJECT_ROOT}/bin/install/docker.sh"
    . "${PROJECT_ROOT}/bin/install/go.sh"
    . "${PROJECT_ROOT}/bin/install/shfmt.sh"
    . "${PROJECT_ROOT}/bin/install/shellcheck.sh"
    . "${PROJECT_ROOT}/bin/install/yamllint.sh"
    . "${PROJECT_ROOT}/bin/install/asdf.sh"
    . "${PROJECT_ROOT}/bin/fallbacks.sh"
    maybe_install_node_as_fallback
    maybe_install_yarn_as_fallback
    yarn install --no-lockfile
}

function setup_required_pkgs() {
    . "${PROJECT_ROOT}/bin/configure/go.sh" && setup_go
    . "${PROJECT_ROOT}/bin/configure/yamllint.sh" && setup_yamllint
    . "${PROJECT_ROOT}/bin/configure/asdf.sh" && setup_asdf
}
