#!/usr/bin/env bash
# shellcheck disable=SC2125
set -eo pipefail

function setup_go() {
    if [[ -e /usr/local/go ]]; then
        export GOPATH="${GOPATH:-${HOME}/src/go}"
        if [[ ! -d "${GOPATH}" ]]; then
            mkdir -p "${GOPATH}"
        fi
        if [[ -e /usr/local/go/bin ]] &&
            [[ -z "$(grep /usr/local/go/bin <<<"${PATH}" 2>/dev/null || true)" ]]; then
            export PATH="${PATH}:/usr/local/go/bin"
        fi
    fi
}
