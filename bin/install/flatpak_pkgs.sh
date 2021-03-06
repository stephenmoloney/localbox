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

FLATHUB_FREETUBE_VERSION_FALLBACK=355e97378af7b265fecd78b07701ee1356a56d403a7f53c0abe0147c1aa3235c
FLATHUB_PDFARRANGER_VERSION_FALLBACK=b07027ad659f118b92c29e734100ed9a1c8efaa346ecaa75c29f8b541ca4370c
FLATHUB_GNOME_WEATHER_VERSION_FALLBACK=e0dadc57600a946c227a37130d3b8e137bf2ad417c440ca909a103f651315b09
FLATHUB_INSOMNIA_VERSION_FALLBACK=a885b9e093428b3a3ed98927c61adad62a66648f5ed0ba824a784df9907a0b24
FLATHUB_PEEK_VERSION_FALLBACK=5f7c34325a8a6c8812dec08037c49cb87d14e86186e5ab8cf8513fd538825b98
FLATHUB_PINTA_VERSION_FALLBACK=893cd434db92a002ace6c0d8c0f97eee52be8870e576ab46faf25a3ecf352007
FLATHUB_PITIVI_VERSION_FALLBACK=732a82a28a10f0482cbf14c2634d6a7165a25af4e6d1cc80df3e178a71bb4da1
FLATHUB_ROCKETCHAT_VERSION_FALLBACK=c386b676ebfcf6f7e892b02fbfdd6f2117e90b57036cd33b0f1c8e5f7a1198d5
FLATHUB_SLACK_VERSION_FALLBACK=a345fda1e194b1932a1937baf710d1ec9cbd483f8cb63b529d331baef850ce12
FLATHUB_SPOTIFY_VERSION_FALLBACK=fb51376f164c4d5045c59b7ba449df15457a99b9eb27c083a5d3d5133a1e41f7
FLATHUB_ZOOM_VERSION_FALLBACK=e41637d15026378340c4e408efc9abfc3a66d9411467453adde282cb5fb77363

declare -A FLATPAK_PKGS
FLATPAK_PKGS=(
    ["io.freetubeapp.FreeTube"]="${FLATHUB_FREETUBE_VERSION:-$FLATHUB_FREETUBE_VERSION_FALLBACK}"
    ["com.github.jeromerobert.pdfarranger"]="${FLATHUB_PDFARRANGER_VERSION:-$FLATHUB_PDFARRANGER_VERSION_FALLBACK}"
    ["org.gnome.Weather"]="${FLATHUB_GNOME_WEATHER_VERSION:-$FLATHUB_GNOME_WEATHER_VERSION_FALLBACK}"
    ["rest.insomnia.Insomnia"]="${FLATHUB_INSOMNIA_VERSION:-$FLATHUB_INSOMNIA_VERSION_FALLBACK}"
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
