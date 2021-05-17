#!/usr/bin/env bash
# shellcheck disable=SC1091
set -Eeuo pipefail

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
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
        . <(curl -s "${GITHUB_URL}/bin/fallbacks.sh")
    else
        echo "${GITHUB_URL}/bin/fallbacks.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ****************************************************************************

BAT_VERSION_FALLBACK=0.18.0
BOTTOM_VERSION_FALLBACK=0.5.7
CODE_MINIMAP_VERSION_FALLBACK=0.5.1
DU_DUST_VERSION_FALLBACK=0.5.4
EXA_VERSION_FALLBACK=0.10.1
FD_FIND_VERSION_FALLBACK=8.2.1
GIT_DELTA_VERSION_FALLBACK=0.7.1
HYPERFINE_VERSION_FALLBACK=1.11.0
JUST_VERSION_FALLBACK=0.9.1
LSD_VERSION_FALLBACK=0.20.1
NITROCLI_VERSION_FALLBACK=0.4.0
RIPGREP_VERSION_FALLBACK=12.1.1
PROCS_VERSION_FALLBACK=0.11.4
SPOTIFY_TUI_VERSION_FALLBACK=0.24.0
TEALDEER_VERSION_FALLBACK=1.4.1
TRE_VERSION_FALLBACK=0.1.1
VIU_VERSION_FALLBACK=1.3.0
declare -A RUST_PKGS
RUST_PKGS=(
    ["bat"]="${BAT_VERSION:-$BAT_VERSION_FALLBACK}"
    ["bottom"]="${BOTTOM_VERSION:-$BOTTOM_VERSION_FALLBACK}"
    ["code-minimap"]="${CODE_MINIMAP_VERSION:-$CODE_MINIMAP_VERSION_FALLBACK}"
    ["du-dust"]="${DU_DUST_VERSION:-$DU_DUST_VERSION_FALLBACK}"
    ["exa"]="${EXA_VERSION:-$EXA_VERSION_FALLBACK}"
    ["fd-find"]="${FD_FIND_VERSION:-$FD_FIND_VERSION_FALLBACK}"
    ["git-delta"]="${GIT_DELTA_VERSION:-$GIT_DELTA_VERSION_FALLBACK}"
    ["hyperfine"]="${HYPERFINE_VERSION:-$HYPERFINE_VERSION_FALLBACK}"
    ["just"]="${JUST_VERSION:-$JUST_VERSION_FALLBACK}"
    ["lsd"]="${LSD_VERSION:-$LSD_VERSION_FALLBACK}"
    ["nitrocli"]="${NITROCLI_VERSION:-$NITROCLI_VERSION_FALLBACK}"
    ["ripgrep"]="${RIPGREP_VERSION:-$RIPGREP_VERSION_FALLBACK}"
    ["procs"]="${PROCS_VERSION:-$PROCS_VERSION_FALLBACK}"
    ["spotify-tui"]="${SPOTIFY_TUI_VERSION:-$SPOTIFY_TUI_VERSION_FALLBACK}"
    ["tealdeer"]="${TEALDEER_VERSION:-$TEALDEER_VERSION_FALLBACK}"
    ["tre"]="${TRE_VERSION:-$TRE_VERSION_FALLBACK}"
    ["viu"]="${VIU_VERSION:-$VIU_VERSION_FALLBACK}"
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
        if [[ "${pkg}" == "spotify-tui" ]]; then
            maybe_install_apt_pkg tzdata "*"
            sudo --preserve-env dpkg-reconfigure --frontend=noninteractive tzdata
            maybe_install_apt_pkg pkg-config "*"
            maybe_install_apt_pkg libssl-dev "*"
            maybe_install_apt_pkg libxcb1-dev "*"
            maybe_install_apt_pkg libxcb-render0-dev "*"
            maybe_install_apt_pkg libxcb-shape0-dev "*"
            maybe_install_apt_pkg libxcb-xfixes0-dev "*"
        fi
        install_rust_pkg "${pkg}" "${RUST_PKGS[$pkg]}"
    done
}

main
