#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_pgcli() {
    if [[ -n "$(command -v pgcli)" ]]; then
        pip3 uninstall --yes pgcli
    fi
}

function main() {
    uninstall_pgcli
}

main
