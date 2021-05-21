#!/usr/bin/env bash
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

declare -A DEBIAN_PKGS
DEBIAN_PKGS=(
    ["bash-completion"]="*"
    ["dialog"]="*"
    ["exuberant-ctags"]="*"
    ["git"]="*"
    ["gitk"]="*"
    ["git-cola"]="*"
    ["gnome-tweak-tool"]="*"
    ["gnupg"]="*"
    ["httpie"]="*"
    ["libarchive-tools"]="*"
    ["libhidapi-dev"]="*"
    ["lsb-release"]="*"
    ["libssl-dev"]="*"
    ["nnn"]="*"
    ["openvpn"]="*"
    ["openssl"]="*"
    ["python-is-python3"]="*"
    ["python3-pip"]="*"
    ["python3-setuptools"]="*"
    ["tmux"]="*"
    ["tree"]="*"
    ["unzip"]="*"
    ["wget"]="*"
    ["xsel"]="*"
)
GUI_APPS="git-cola gitk gnome-tweak-tool xsel"

function requires_gui() {
    local pkg="${1}"

    if [[ -z "$(grep "${pkg}" <<<"${GUI_APPS}" 2>/dev/null || true)" ]]; then
        echo "no"
    else
        echo "yes"
    fi
}

function main() {
    HEADLESS_ONLY="${HEADLESS_ONLY:-}"
    if [[ "${HEADLESS_ONLY}" == "true" ]]; then
        echo "Installing packages classified as not requiring a gui"
    fi
    for pkg in "${!DEBIAN_PKGS[@]}"; do
        local is_gui_app
        is_gui_app="$(requires_gui "${pkg}")"
        if [[ "${HEADLESS_ONLY}" != "true" ]]; then
            maybe_install_apt_pkg \
                "${pkg}" \
                "${DEBIAN_PKGS[$pkg]}"
        elif [[ "${HEADLESS_ONLY}" == "true" ]] && [[ "${is_gui_app}" == "no" ]]; then
            maybe_install_apt_pkg \
                "${pkg}" \
                "${DEBIAN_PKGS[$pkg]}"
        fi
    done
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main
fi
