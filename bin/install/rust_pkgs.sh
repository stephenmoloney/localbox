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

BAT_VERSION_FALLBACK=0.19.0
BOTTOM_VERSION_FALLBACK=0.6.8
DU_DUST_VERSION_FALLBACK=0.8.0
EXA_VERSION_FALLBACK=0.10.1
FD_FIND_VERSION_FALLBACK=8.3.1
GIT_DELTA_VERSION_FALLBACK=0.12.0
HYPERFINE_VERSION_FALLBACK=1.12.0
JUST_VERSION_FALLBACK=1.0.0
LSD_VERSION_FALLBACK=0.21.0
NITROCLI_VERSION_FALLBACK=0.4.1
RIPGREP_VERSION_FALLBACK=13.0.0
TEALDEER_VERSION_FALLBACK=1.5.0
TRE_VERSION_FALLBACK=0.1.1
VIU_VERSION_FALLBACK=1.3.0
XPLR_VERSION_FALLBACK=0.19.0
declare -A RUST_PKGS
RUST_PKGS=(
    ["bat"]="${BAT_VERSION:-$BAT_VERSION_FALLBACK}"
    ["bottom"]="${BOTTOM_VERSION:-$BOTTOM_VERSION_FALLBACK}"
    ["du-dust"]="${DU_DUST_VERSION:-$DU_DUST_VERSION_FALLBACK}"
    ["exa"]="${EXA_VERSION:-$EXA_VERSION_FALLBACK}"
    ["fd-find"]="${FD_FIND_VERSION:-$FD_FIND_VERSION_FALLBACK}"
    ["git-delta"]="${GIT_DELTA_VERSION:-$GIT_DELTA_VERSION_FALLBACK}"
    ["hyperfine"]="${HYPERFINE_VERSION:-$HYPERFINE_VERSION_FALLBACK}"
    ["just"]="${JUST_VERSION:-$JUST_VERSION_FALLBACK}"
    ["lsd"]="${LSD_VERSION:-$LSD_VERSION_FALLBACK}"
    ["nitrocli"]="${NITROCLI_VERSION:-$NITROCLI_VERSION_FALLBACK}"
    ["ripgrep"]="${RIPGREP_VERSION:-$RIPGREP_VERSION_FALLBACK}"
    ["tealdeer"]="${TEALDEER_VERSION:-$TEALDEER_VERSION_FALLBACK}"
    ["tre"]="${TRE_VERSION:-$TRE_VERSION_FALLBACK}"
    ["viu"]="${VIU_VERSION:-$VIU_VERSION_FALLBACK}"
    ["xplr"]="${XPLR_VERSION:-$XPLR_VERSION_FALLBACK}"
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
