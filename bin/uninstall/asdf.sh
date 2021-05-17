#!/usr/bin/env bash
set -Eeuo pipefail

function uninstall_asdf() {
    if [[ -n "$(command -v asdf)" ]]; then
        sudo rm -rf "${HOME}/.asdf"
    fi
    source "${HOME}/.bashrc"
}

function main() {
    uninstall_asdf
}

main
