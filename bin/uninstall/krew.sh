#!/usr/bin/env bash
set -Eeuo pipefail

function uninstall_krew() {
    if [[ -d "${HOME}/.krew" ]]; then
        sudo rm -rf "${HOME}/.krew"
    fi
}

function main() {
    uninstall_krew
}

main
