#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_nerdfonts() {
    if [[ -d "${HOME}/.nerd_fonts" ]]; then
        sudo rm -rf "${HOME}/.nerd_fonts"
    fi
    if [[ -d /usr/local/share/fonts ]]; then
        sudo rm -rf /usr/local/share/fonts
    fi
}

function main() {
    uninstall_nerdfonts
}

main
