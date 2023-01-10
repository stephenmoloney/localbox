#!/usr/bin/env bash
# shellcheck disable=SC1091
set -eu
set -o pipefail
set -o errtrace

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

# ******* Importing fallbacks.sh as a means of installing missing deps *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
FALLBACKS_PATH="$(dirname "${BASH_SOURCE[0]}")"/../fallbacks.sh
if [[ -e "${FALLBACKS_PATH}" ]]; then
    source "${FALLBACKS_PATH}"
else
    if [[ -z "$(command -v curl)" ]]; then
        sudo apt update -y -qq
        sudo apt install -y -qq curl
    fi
    echo "Falling back to remote script ${GITHUB_URL}/bin/fallbacks.sh"
    if curl -sIf -o /dev/null ${GITHUB_URL}/bin/fallbacks.sh; then
        source <(curl -s "${GITHUB_URL}/bin/fallbacks.sh")
    else
        echo "${GITHUB_URL}/bin/fallbacks.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ****************************************************************************

GIT_DELTA_VERSION_FALLBACK=0.12.0
JUST_VERSION_FALLBACK=1.0.0
NITROCLI_VERSION_FALLBACK=0.4.1
TEALDEER_VERSION_FALLBACK=1.5.0
declare -A RUST_PKGS
RUST_PKGS=(
    ["git-delta"]="${GIT_DELTA_VERSION:-$GIT_DELTA_VERSION_FALLBACK}"
    ["just"]="${JUST_VERSION:-$JUST_VERSION_FALLBACK}"
    ["nitrocli"]="${NITROCLI_VERSION:-$NITROCLI_VERSION_FALLBACK}"
    ["tealdeer"]="${TEALDEER_VERSION:-$TEALDEER_VERSION_FALLBACK}"
)

maybe_install_rust_as_fallback
maybe_install_apt_pkg build-essential "*"

function install_rust_pkg() {
    local pkg="${1}"
    local version="${2}"

    echo "Installing version ${version} of ${pkg}"
    cargo install "${pkg}" \
        --version "${version}" \
        --force
}

function main() {
    for pkg in "${!RUST_PKGS[@]}"; do
        if [[ "${pkg}" == "nitrocli" ]]; then
            maybe_install_apt_pkg libhidapi-dev "*"
        fi
        install_rust_pkg "${pkg}" "${RUST_PKGS[$pkg]}"
    done
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
