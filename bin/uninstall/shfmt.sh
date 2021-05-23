#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_shfmt() {
    if [[ -e /usr/local/bin/shfmt ]]; then
        sudo rm /usr/local/bin/shfmt
    fi
}

function main() {
    uninstall_shfmt
}

main
