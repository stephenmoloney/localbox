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

FLATHUB_FREETUBE_VERSION_FALLBACK=816137b1abb55694cf27e1278b046cf936e73ce9bc61018637399c8f6f5cd16f
FLATHUB_PDFARRANGER_VERSION_FALLBACK=f328b151964e1e32cbb65647c4a61776f63c9de4d676d33f15e45ed545522472
FLATHUB_GNOME_WEATHER_VERSION_FALLBACK=92c42fd2e7cefc91a817f50c14dd2e8fe2ad54e4c457596463c717e5b5a933c9
FLATHUB_INSOMNIA_VERSION_FALLBACK=eecfc0ff230eb9d6bcc0a0bf3fc7640e6cbda0bf6d892b3ee87dcf54537a9aee
FLATHUB_PEEK_VERSION_FALLBACK=5f7c34325a8a6c8812dec08037c49cb87d14e86186e5ab8cf8513fd538825b98
FLATHUB_PINTA_VERSION_FALLBACK=63a10de84acf55f42117816858aea948c320e798ffbce1e63e77ae3127f268b0
FLATHUB_PITIVI_VERSION_FALLBACK=dd83e6624c29d8cad7c578371616c86cd7878f72ec9243a7c145e404f1a03194
FLATHUB_ROCKETCHAT_VERSION_FALLBACK=cbfb7785afb22fd57cdc758fd880f779eb8a3b3052ac5739567192e8f60d624f
FLATHUB_SLACK_VERSION_FALLBACK=20235ad683400e23861785b627f33747bcd9d151f10ede3bb26fe3c456dd0f4d
FLATHUB_SPOTIFY_VERSION_FALLBACK=75b8e9911bfe4c40504f47923298c38ca6090a48a5375fe1021e7597cd7c234d
FLATHUB_ZOOM_VERSION_FALLBACK=ce384fddb07dc50731858f655646da71f93fb6d6d22e9af308a5e69051b4c496

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
