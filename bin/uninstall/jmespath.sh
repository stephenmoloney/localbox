#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_jmespath() {
    if [[ -n "$(command -v jmespath)" ]]; then
        pip3 uninstall --yes jmespath
    fi
}

function main() {
    uninstall_jmespath
}

main
