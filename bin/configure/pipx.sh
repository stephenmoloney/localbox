#!/usr/bin/env bash
set -eo pipefail

function setup_pipx() {
    export PIPX_HOME="${HOME}/.local/pipx"
    export PIPX_BIN_DIR="${HOME}/.local/bin"
    export USE_EMOJI=false
    export PIPX_DEFAULT_PYTHON=python3
}
