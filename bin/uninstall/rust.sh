#!/bin/env bash
set -euo pipefail

function get_installed_target() {
    rustup target list | grep installed | cut -d' ' -f1
}

function get_default_toolchain() {
    rustup toolchain list | grep default | cut -d' ' -f1
}

function get_all_toolchains() {
    rustup toolchain list | cut -d' ' -f1
}

function remove_all_toolchains() {
    readarray -t toolchains <<<"$(get_all_toolchains)"
    for toolchain in "${toolchains[@]}"; do
        rustup toolchain uninstall "${toolchain}"
    done
}

if [[ -n "$(command -v rustup)" ]]; then
    if [[ -e "${HOME}/.cargo/bin/rustup" ]]; then
        remove_all_toolchains
        rustup self uninstall -y
    fi
fi
