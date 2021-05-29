#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_alacritty() {
    if [[ -e "${HOME}/.bash_completion.d/alacritty" ]]; then
        sudo rm "${HOME}/.bash_completion.d/alacritty"
    fi
    if [[ -e /usr/share/applications/alacritty.desktop ]]; then
        /usr/share/applications/alacritty.desktop
    fi
    cargo uninstall alacritty
}

function main() {
    uninstall_alacritty
}

main
