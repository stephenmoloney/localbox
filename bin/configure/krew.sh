#!/usr/bin/env bash
set -eo pipefail

function setup_krew() {
    if [[ -d "${HOME}/.krew/bin" ]]; then
        export PATH="${PATH}:${HOME}/.krew/bin"
    fi
}
