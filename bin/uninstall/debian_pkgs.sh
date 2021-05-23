#!/usr/bin/env bash
set -euo pipefail

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

function uninstall_pkgs() {
    for pkg in "${!DEBIAN_PKGS[@]}"; do
        maybe_uninstall_apt_pkg "${pkg}"
    done
}

function main() {
    uninstall_pkgs
}

main
