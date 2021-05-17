#!/usr/bin/env bash
set -Eeuo pipefail

function uninstall_shfmt() {
    if [[ -e /usr/local/bin/shfmt ]]; then
        sudo rm /usr/local/bin/shfmt
    fi
}

function main() {
    uninstall_shfmt
}

main
