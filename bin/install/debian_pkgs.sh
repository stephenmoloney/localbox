#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]:-}")/../utils.sh"
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

declare -A DEBIAN_PKGS
DEBIAN_PKGS=(
    ["adb"]="*"
    ["atool"]="*"
    ["bash-completion"]="*"
    ["cloc"]="*"
    ["dialog"]="*"
    ["converseen"]="*"
    ["exuberant-ctags"]="*"
    ["fonts-noto-color-emoji"]="*"
    ["jdupes"]="*"
    ["git"]="*"
    ["gitk"]="*"
    ["git-cola"]="*"
    ["gnome-tweaks"]="*"
    ["gnome-browser-connector"]="*"
    ["gnupg"]="*"
    ["httpie"]="*"
    ["inxi"]="*"
    ["libarchive-tools"]="*"
    ["libhidapi-dev"]="*"
    ["lsb-release"]="*"
    ["libssl-dev"]="*"
    ["nautilus-image-converter"]="*"
    ["fastfetch"]="*"
    ["nnn"]="*"
    ["openvpn"]="*"
    ["openssl"]="*"
    ["python-is-python3"]="*"
    ["python3-pip"]="*"
    ["python3-setuptools"]="*"
    ["python3-venv"]="*"
    ["qrencode"]="*"
    ["scdaemon"]="*"
    ["scrcpy"]="*"
    ["tesseract-ocr"]="*"
    ["tmux"]="*"
    ["tree"]="*"
    ["unzip"]="*"
    ["wget"]="*"
    ["pipx"]="*"
    ["xsel"]="*"
)
GUI_APPS="fastfetch git-cola gitk gnome-browser-connector gnome-tweaks xsel"

function requires_gui() {
    local pkg="${1}"

    if [[ -z "$(grep "${pkg}" <<<"${GUI_APPS}" 2>/dev/null || true)" ]]; then
        echo "false"
    else
        echo "true"
    fi
}

function main() {
    local pkg
    local pkg_version
    local -a pkg_args=()
    local -a pinned=()

    for pkg in "${!DEBIAN_PKGS[@]}"; do
        if [[ "$(requires_gui "${pkg}")" == "true" ]]; then
            continue
        fi

        pkg_version="${DEBIAN_PKGS[$pkg]}"
        pkg_args+=("${pkg}" "${pkg_version}")

        if [[ "${pkg_version}" != "*" ]]; then
            pinned+=("${pkg}")
        fi
    done

    if [[ "${#pkg_args[@]}" -gt 0 ]]; then
        maybe_install_apt_pkgs_with_versions "${pkg_args[@]}"
    fi

    # Pin the packages to their versions (where not *)
    for pkg in "${pinned[@]}"; do
        apt_hold_pkg "${pkg}"
    done

    sudo apt-mark showhold
}

if [[ "$0" == "${BASH_SOURCE[0]:-}" ]]; then
    main
fi
