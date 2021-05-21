#!/usr/bin/env bash
# shellcheck disable=SC1091
set -eo pipefail

function setup_tmuxinator() {
    if [[ -e /etc/bash_completion.d/tmuxinator.bash ]]; then
        source /etc/bash_completion.d/tmuxinator.bash
    fi
}
