#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_bpytop() {
    if [[ -n "$(command -v bpytop)" ]]; then
        pip3 uninstall --yes bpytop
    fi
    if [[ -d "${HOME}/.config/bpytop" ]]; then
        sudo rm -rf "${HOME}/.config/bpytop"
    fi
}

function main() {
    uninstall_bpytop
}

main
