#!/usr/bin/env bash
set -eo pipefail

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
PROJECT_ROOT="$(project_root)"

function setup_alacritty_dotfiles() {
    if [[ ! -d "${HOME}/.config/alacritty" ]]; then
        mkdir -p "${HOME}/.config/alacritty"
    fi

    cp \
        "${PROJECT_ROOT}/config/dotfiles/alacritty/alacritty.yml" \
        "${HOME}/.config/alacritty/alacritty.yml"
}

function setup_alacritty_desktop_file() {
    if [[ ! -e /usr/share/applications/alacritty.desktop ]]; then
        touch /usr/share/applications/alacritty.desktop
        cat <<EOF | sudo tee -a /usr/share/applications/alacritty.desktop
[Desktop Entry]
Name=Alacritty
GenericName=Terminal
Type=Application
TryExec=/home/u1/.cargo/bin/alacritty
Exec=/home/u1/.cargo/bin/alacritty
Terminal=false
Categories=System;TerminalEmulator;
Comment=A fast, cross-platform, OpenGL terminal emulator
StartupWMClass=Alacritty
Icon=/usr/share/icons/alacritty.svg
StartupNotify=true
EOF
        sudo desktop-file-install /usr/share/applications/alacritty.desktop
        sudo update-desktop-database
    fi
}
