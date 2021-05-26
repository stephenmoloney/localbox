#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_black() {
    if [[ -n "$(command -v black)" ]]; then
        pip3 uninstall --yes black
    fi
}

function main() {
    uninstall_black
}

main
