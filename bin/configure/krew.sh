#!/usr/bin/env bash
set -eo pipefail

function setup_krew() {
    export PATH="${PATH}:${HOME}/.krew/bin"
}
