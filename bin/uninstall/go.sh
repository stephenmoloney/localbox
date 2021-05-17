#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
export GOPATH="${GOPATH:-${HOME}/src/go}"
export GOROOT="${GOROOT:-/usr/local/go}"

function uninstall_go() {
    sudo rm -R "${GOROOT}"
}

function main() {
    uninstall_go
}

main
