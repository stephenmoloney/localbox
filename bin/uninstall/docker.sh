#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"

function uninstall_docker() {
    maybe_uninstall_apt_pkg "docker-ce"
    maybe_uninstall_apt_pkg "docker-ce-cli"
    maybe_uninstall_apt_pkg "containerd.io"
}

function main() {
    uninstall_docker
}

main
