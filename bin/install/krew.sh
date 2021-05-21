#!/usr/bin/env bash
set -Eeuo pipefail

KREW_VERSION_FALLBACK=0.4.0

function install_krew() {
    local version="${1}"

    maybe_install_apt_pkg "curl" "*"
    # TODO fallback installation of kubectl

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

    export PATH="${PATH}:${HOME}/.krew/bin"

    kubectl krew version
}

function main() {
    local version="${1:-$KREW_VERSION_FALLBACK}"

    install_krew "${version}"
}

main "${@}"
