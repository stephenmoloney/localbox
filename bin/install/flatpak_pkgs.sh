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

FLATHUB_FLAMESHOT_VERSION_FALLBACK=7e52ea21c559fb78d92fcf74a373a6d4264e642f4376db8fd0bbdb59dcaa8978
FLATHUB_FREETUBE_VERSION_FALLBACK=7d3ef881c91cb02d6490dfd2f491b2c10d7cce830d4c5de61268011b28e42763
FLATHUB_GNOME_WEATHER_VERSION_FALLBACK=e6a9b9c803a6ffde2aaffc815e5079a59b5308b42559d17f905da5cd93a1bc2f
FLATHUB_PDFARRANGER_VERSION_FALLBACK=fd15f0eca6e9ccd3e7b47ff982364b55d60d32ada22b9643c4a2fb6d7e74c45a
FLATHUB_PEEK_VERSION_FALLBACK=5f7c34325a8a6c8812dec08037c49cb87d14e86186e5ab8cf8513fd538825b98
FLATHUB_PINTA_VERSION_FALLBACK=63a10de84acf55f42117816858aea948c320e798ffbce1e63e77ae3127f268b0
FLATHUB_PITIVI_VERSION_FALLBACK=dd83e6624c29d8cad7c578371616c86cd7878f72ec9243a7c145e404f1a03194
FLATHUB_ROCKETCHAT_VERSION_FALLBACK=5e459ed5727bf41145ac9a54e852fed70b9583548dcd2fdd0ef6b8263dff79ae
FLATHUB_SLACK_VERSION_FALLBACK=4c95bf1127d5ec1ca6cfaeb10161641fc46ba1fb747a40db27a32cc2beb318cd
FLATHUB_SPOTIFY_VERSION_FALLBACK=9cd9ae21dc3f17ff030aa4b401c499fe8c887e8a2e216b8d2f3892434c54510c
FLATHUB_ZOOM_VERSION_FALLBACK=baacfee7d2d9aa2423dfe2f5b2e604fe1da3637ad31bfa850ba56cf60f38f514

declare -A FLATPAK_PKGS
FLATPAK_PKGS=(
    ["org.flameshot.Flameshot"]="${FLATHUB_FLAMESHOT_VERSION:-$FLATHUB_FLAMESHOT_VERSION_FALLBACK}"
    ["io.freetubeapp.FreeTube"]="${FLATHUB_FREETUBE_VERSION:-$FLATHUB_FREETUBE_VERSION_FALLBACK}"
    ["org.gnome.Weather"]="${FLATHUB_GNOME_WEATHER_VERSION:-$FLATHUB_GNOME_WEATHER_VERSION_FALLBACK}"
    ["com.github.jeromerobert.pdfarranger"]="${FLATHUB_PDFARRANGER_VERSION:-$FLATHUB_PDFARRANGER_VERSION_FALLBACK}"
    ["com.uploadedlobster.peek"]="${FLATHUB_PEEK_VERSION:-$FLATHUB_PEEK_VERSION_FALLBACK}"
    ["com.github.PintaProject.Pinta"]="${FLATHUB_PINTA_VERSION:-$FLATHUB_PINTA_VERSION_FALLBACK}"
    ["org.pitivi.Pitivi"]="${FLATHUB_PITIVI_VERSION:-$FLATHUB_PITIVI_VERSION_FALLBACK}"
    ["chat.rocket.RocketChat"]="${FLATHUB_ROCKETCHAT_VERSION:-$FLATHUB_ROCKETCHAT_VERSION_FALLBACK}"
    ["com.slack.Slack"]="${FLATHUB_SLACK_VERSION:-$FLATHUB_SLACK_VERSION_FALLBACK}"
    ["com.spotify.Client"]="${FLATHUB_SPOTIFY_VERSION:-$FLATHUB_SPOTIFY_VERSION_FALLBACK}"
    ["us.zoom.Zoom"]="${FLATHUB_ZOOM_VERSION:-$FLATHUB_ZOOM_VERSION_FALLBACK}"
)

maybe_install_flatpak_as_fallback

function list_latest_flatpak_versions() {
    local pkg="${1}"

    sudo flatpak remote-info \
        --log \
        --system \
        flathub "${pkg}" | head -n 25
}

function install_flatpak_pkg() {
    local pkg="${1}"
    local version="${2}"

    echo "Installing version ${version} of ${pkg}"
    sudo flatpak install \
        -y \
        --noninteractive \
        --system \
        flathub "${pkg}"

    list_latest_flatpak_versions "${pkg}"

    sudo flatpak update \
        -y \
        --noninteractive \
        --system \
        --commit="${version}" \
        "${pkg}"
}

function main() {
    for pkg in "${!FLATPAK_PKGS[@]}"; do
        install_flatpak_pkg "${pkg}" "${FLATPAK_PKGS[$pkg]}"
    done
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
