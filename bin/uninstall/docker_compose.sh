#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_docker_compose() {
    if [[ -e /usr/local/bin/docker-compose ]]; then
        sudo rm /usr/local/bin/docker-compose
    fi
}

function main() {
    uninstall_docker_compose
}

main
