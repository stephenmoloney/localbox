#!/usr/bin/env bash
set -eo pipefail

function setup_krew() {
    if [[ -e "${HOME}/.krew/bin" ]] &&
        [[ -z "$(grep "${HOME}/.krew/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.krew/bin"
    fi
}
