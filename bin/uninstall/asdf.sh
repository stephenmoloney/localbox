#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

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
