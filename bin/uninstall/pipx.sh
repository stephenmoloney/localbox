#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_pipx() {
    if [[ -n "$(command -v pipx)" ]]; then
        pip3 uninstall --yes pipx
    fi
}

function main() {
    uninstall_pipx
}

main
