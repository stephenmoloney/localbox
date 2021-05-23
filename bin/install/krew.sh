#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

KREW_VERSION_FALLBACK=0.4.0

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
if [[ -e "${UTILS_PATH}" ]]; then
    source "${UTILS_PATH}"
else
    if [[ -z "$(command -v curl)" ]]; then
        sudo apt update -y -qq
        sudo apt install -y -qq curl
    fi
    echo "Falling back to remote script ${GITHUB_URL}/bin/utils.sh"
    if curl -sIf -o /dev/null ${GITHUB_URL}/bin/utils.sh; then
        source <(curl -s "${GITHUB_URL}/bin/utils.sh")
    else
        echo "${GITHUB_URL}/bin/utils.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ************************************************************************

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

maybe_install_kubectl_as_fallback

function install_krew() {
    local version="${1}"
    set -eu

    maybe_install_apt_pkg "curl" "*"

    pushd "$(mktemp -d)" || exit
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v${version}/krew.tar.gz"
    tar zxvf krew.tar.gz
    KREW=./krew-"$(
        uname |
            tr '[:upper:]' '[:lower:]'
    )_$(
        uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/' -e 's/aarch64$/arm64/'
    )"
    "${KREW}" install krew
    rm krew.tar.gz
    popd || exit

    if [[ -e "${HOME}/.krew/bin" ]] &&
        [[ -z "$(grep "${HOME}/.krew/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.krew/bin"
    fi

    kubectl krew version
}

function main() {
    local version="${1:-$KREW_VERSION_FALLBACK}"

    install_krew "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
