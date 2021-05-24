#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_ansible() {
    if [[ -n "$(command -v ansible)" ]]; then
        pip3 uninstall --yes ansible
    fi
    if [[ -d "${HOME}/.ansible" ]]; then
        sudo rm -rf "${HOME}/.ansible"
    fi
}

function main() {
    uninstall_ansible
}

main
