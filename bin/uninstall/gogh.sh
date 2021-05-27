#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_gogh() {
    if [[ -d "${HOME}/src/open/gogh" ]]; then
        sudo rm -rf "${HOME}/src/open/gogh"
    fi
}

function main() {
    uninstall_gogh
}

main
