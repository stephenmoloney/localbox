#!/usr/bin/env bash
set -Eeuo pipefail

declare -A KREW_PLUGINS
KREW_PLUGINS=(
    ["access-matrix"]=""
)

function install_krew_plugins() {
    if [[ -d "${PATH}:${HOME}/.krew/bin" ]] &&
        [[ -z "$(grep "${HOME}/.krew/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.krew/bin"
    fi

    for plugin in "${!KREW_PLUGINS[@]}"; do
        kubectl krew install "${plugin}"
    done
}

install_krew_plugins
