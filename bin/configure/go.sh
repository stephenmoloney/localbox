#!/usr/bin/env bash
# shellcheck disable=SC2125
set -eo pipefail

function setup_go() {
    export GOROOT="${GOROOT:-/usr/local/go}"
    if [[ -e "${GOROOT}" ]]; then
        export GOPATH="${GOPATH:-${HOME}/src/go}"
        if [[ ! -d "${GOPATH}" ]]; then
            mkdir -p "${GOPATH}"
        fi
        export PATH="${PATH}:${GOROOT}/bin"
    fi
}
