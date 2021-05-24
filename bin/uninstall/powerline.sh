#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_powerline() {
    if [[ -n "$(command -v powerline)" ]]; then
        pip3 uninstall --yes powerline
    fi
}

function main() {
    uninstall_powerline
}

main
