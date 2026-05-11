#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_diagrams() {
    if [[ -n "$(command -v diagrams)" ]]; then
        pipx uninstall --force diagrams
    fi
}

function main() {
    uninstall_diagrams
}

main
