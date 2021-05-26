#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_vint() {
    if [[ -n "$(command -v vint)" ]]; then
        pip3 uninstall --yes vint
    fi
}

function main() {
    uninstall_vint
}

main
