#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

FLATPAK_VERSION_FALLBACK="*"
FREEDESKTOP_VERSION_FALLBACK=20.08

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

function get_current_version() {
    flatpak --version | cut -d' ' -f2
}

function install_flatpak() {
    local flatpak_version="${1}"
    local freedesktop_version="${2}"

    [[ "${flatpak_version}" == "latest" ]] && flatpak_version="*"

    if [[ -z "$(get_current_version 2>/dev/null || true)" ]] ||
        [[ "$(get_current_version 2>/dev/null || true)" != "${flatpak_version}" ]]; then
        sudo add-apt-repository -y ppa:alexlarsson/flatpak
        maybe_install_apt_pkg "flatpak" "${flatpak_version}"

        sudo flatpak remote-add \
            --if-not-exists \
            --system \
            flathub https://flathub.org/repo/flathub.flatpakrepo

        sudo flatpak install \
            -y \
            --noninteractive \
            --system \
            flathub "org.freedesktop.Platform/x86_64/${freedesktop_version}"

        flatpak list
    else
        echo "flatpak version ${flatpak_version} is already installed"
        echo "Skipping installation"
    fi

    flatpak --version
}

function main() {
    local flatpak_version="${1:-$FLATPAK_VERSION_FALLBACK}"
    local freedesktop_version="${2:-$FREEDESKTOP_VERSION_FALLBACK}"

    install_flatpak "${flatpak_version}" "${freedesktop_version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
