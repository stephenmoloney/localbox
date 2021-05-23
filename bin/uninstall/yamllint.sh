#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_yamllint() {
    if [[ -n "$(command -v yamllint)" ]]; then
        pip3 uninstall --yes yamllint
    fi
}

function main() {
    uninstall_yamllint
}

main
