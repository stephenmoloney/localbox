#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

function uninstall_pdf2odt() {
    if [[ -n "$(command -v pdf2odt)" ]]; then
        pip3 uninstall --yes pdf2odt
    fi
}

function main() {
    uninstall_pdf2odt
}

main
