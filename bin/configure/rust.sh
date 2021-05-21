#!/usr/bin/env bash

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
PROJECT_ROOT="$(project_root)"

function calc_io_threads() {
    echo "$(((($(nproc --all) / 4)) * 3))"
}

function calc_unpack_ram() {
    awk \
        '/MemTotal/ {memMb = (( $2/1000/6 )); printf "%.0fMiB\n", memMb }' \
        /proc/meminfo
}

function setup_rust() {
    local io_threads="${1:-}"
    local unpack_ram="${2:-}"

    if [[ "$#" -lt 2 ]] && [[ "$#" -ne 0 ]]; then
        echo >&2 "Expected 2 arguments, only $# provided."
        return 1
    fi

    if [[ -z "${io_threads}" ]]; then
        io_threads="$(calc_io_threads)"
    fi

    if [[ -z "${unpack_ram}" ]]; then
        unpack_ram="$(calc_unpack_ram)"
    fi

    if [[ -d "${HOME}/.rustup" ]]; then
        unset RUSTUP_TOOLCHAIN
        unset RUSTUP_TRACE_DIR
        unset RUSTUP_NO_BACKTRACE
        unset RUSTUP_PERMIT_COPY_RENAME

        export RUSTUP_HOME="${HOME}/.rustup"
        export RUSTUP_DIST_SERVER=https://static.rust-lang.org
        export RUSTUP_UPDATE_ROOT="${RUSTUP_DIST_SERVER}/rustup"
        export RUSTUP_IO_THREADS
        export RUSTUP_UNPACK_RAM

        RUSTUP_IO_THREADS="${io_threads}"
        RUSTUP_UNPACK_RAM="${unpack_ram}"
    fi

    if [[ -f "${HOME}/.cargo/env" ]]; then
        source "${HOME}/.cargo/env"
    fi
}

function setup_rustfmt() {
    cp \
        "${PROJECT_ROOT}/config/dotfiles/rust/rustfmt.toml" \
        "${HOME}/.rustfmt.toml"
}
