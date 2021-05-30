#!/usr/bin/env bash
# shellcheck disable=SC2128
set -euo pipefail

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]}")/../bin/utils.sh"
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

function install_and_configure_if_absent() {
    local program="${1}"
    local configure_deps
    configure_deps="go yamllint adsf"

    if [[ -z "$(command -v "${program}")" ]]; then
        echo "Executing ${PROJECT_ROOT}/bin/install/${program}.sh"
        "${PROJECT_ROOT}/bin/install/${program}.sh" ""
        if [[ -n "$(grep "${program}" <<<"${configure_deps}" 2>/dev/null || true)" ]]; then
            source "${PROJECT_ROOT}/bin/configure/${program}.sh"
            "setup_${program}"
        fi
    else
        echo "${program} is already installed, skipping..."
    fi
}

function init() {
    local programs
    programs=(docker go shfmt shellcheck yamllint asdf)

    for program in "${programs[@]}"; do
        install_and_configure_if_absent "${program}"
    done

    source "${PROJECT_ROOT}/bin/fallbacks.sh"
    maybe_install_node_as_fallback
    maybe_install_yarn_as_fallback
    yarn install --no-lockfile
}
