#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_jmespath() {
    if [[ -n "$(command -v jmespath)" ]]; then
        pipx uninstall --force jmespath
    fi
}

function main() {
    uninstall_jmespath
}

main
