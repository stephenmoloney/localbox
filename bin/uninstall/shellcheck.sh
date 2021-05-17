#!/usr/bin/env bash
set -Eeuo pipefail

function uninstall_shellcheck() {
    if [[ -e /usr/local/bin/shellcheck ]]; then
        sudo rm /usr/local/bin/shellcheck
    fi
}

function main() {
    uninstall_shellcheck
}

main
