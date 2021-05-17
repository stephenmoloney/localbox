#!/usr/bin/env bash
set -Eeuo pipefail

function uninstall_yamllint() {
    if [[ -n "$(command -v yamllint)" ]]; then
        pip3 uninstall --yes yamllint
    fi
}

function main() {
    uninstall_yamllint
}

main
