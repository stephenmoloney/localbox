#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_argos_translate_gui() {
    if [[ -n "$(command -v argostranslategui)" ]]; then
        pip3 uninstall --yes argostranslategui
    fi
}

function main() {
    uninstall_argos_translate_gui
}

main
