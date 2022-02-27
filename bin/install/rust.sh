#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

RUST_VERSION_FALLBACK=1.59.0

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

function install_rustup() {
    if [[ -z "${RUSTUP_HOME:-}" ]]; then
        export RUSTUP_HOME="${HOME}/.rustup"
    fi
    export RUSTUP_INIT_SKIP_PATH_CHECK=yes

    maybe_install_apt_pkg curl "*"

    if [[ -z "$(command -v rustup)" ]]; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
            -y \
            --verbose \
            --no-modify-path \
            --default-toolchain none \
            --profile minimal
    else
        echo "Skipping rustup installation, it seems to be already installed"
    fi
}

function install_rust() {
    local version="${1}"

    rustup toolchain install "${version}"
    rustup component add \
        clippy \
        rls \
        rustfmt \
        rust-analysis \
        rust-src
    rustup override set "${version}"
}

function main() {
    local version="${1:-$RUST_VERSION_FALLBACK}"

    install_rustup
    source "${HOME}/.cargo/env"
    install_rust "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
