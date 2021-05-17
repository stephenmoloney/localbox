#!/usr/bin/env bash
set -Eeuo pipefail

function uninstall_tmux_plugin_manager() {
    if [[ -d "${HOME}/.tmux/plugins/tpm" ]]; then
        sudo rm -rf "${HOME}/.tmux/plugins/tpm"
    fi
}

function main() {
    uninstall_tmux_plugin_manager
}

main
