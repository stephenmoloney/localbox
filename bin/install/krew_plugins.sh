#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

# ******* Importing fallbacks.sh as a means of installing missing deps *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
FALLBACKS_PATH="$(dirname "${BASH_SOURCE[0]}")"/../fallbacks.sh
if [[ -e "${FALLBACKS_PATH}" ]]; then
    source "${FALLBACKS_PATH}"
else
    if [[ -z "$(command -v curl)" ]]; then
        sudo apt update -y -qq
        sudo apt install -y -qq curl
    fi
    echo "Falling back to remote script ${GITHUB_URL}/bin/fallbacks.sh"
    if curl -sIf -o /dev/null ${GITHUB_URL}/bin/fallbacks.sh; then
        source <(curl -s "${GITHUB_URL}/bin/fallbacks.sh")
    else
        echo "${GITHUB_URL}/bin/fallbacks.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ****************************************************************************

declare -A KREW_PLUGINS
KREW_PLUGINS=(
    ["access-matrix"]=""
)

maybe_install_kubectl_as_fallback

if [[ -e "${HOME}/.krew/bin" ]] &&
    [[ -z "$(grep "${HOME}/.krew/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
    export PATH="${PATH}:${HOME}/.krew/bin"
else
    echo "krew must be installed" >/dev/stderr
    exit 1
fi

function install_krew_plugins() {
    if [[ -d "${PATH}:${HOME}/.krew/bin" ]] &&
        [[ -z "$(grep "${HOME}/.krew/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.krew/bin"
    fi

    for plugin in "${!KREW_PLUGINS[@]}"; do
        kubectl krew install "${plugin}"
    done
}

function main() {
    install_krew_plugins
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main
fi
