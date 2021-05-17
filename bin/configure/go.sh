#!/usr/bin/env bash
# shellcheck disable=SC2125
set -eo pipefail

function setup_go() {
    if [[ -e /usr/local/go ]]; then
        export GOPATH="${HOME}/src/go"
        if [[ ! -d "${GOPATH}" ]]; then
            mkdir -p "${GOPATH}"
        fi
        export GOROOT=/usr/local/go
        export PATH="${PATH}:${GOROOT}/bin"
    fi
}
