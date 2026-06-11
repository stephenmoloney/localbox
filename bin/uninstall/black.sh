#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_black() {
    if [[ -n "$(command -v black)" ]]; then
        pipx uninstall --force black
    fi
}

function main() {
    uninstall_black
}

main
