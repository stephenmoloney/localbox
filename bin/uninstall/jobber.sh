#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_jobber() {
    pushd "${HOME}/src/open/jobber" || exit
    sudo make uninstall
    popd || exit
    if [[ -d "${HOME}/.jobber_dir" ]]; then
        sudo rm -rf "${HOME}/.jobber_dir"
    fi
    if [[ -e "${HOME}/.jobber" ]]; then
        sudo rm -rf "${HOME}/.jobber"
    fi
}

function main() {
    uninstall_jobber
}

main
