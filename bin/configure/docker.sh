#!/usr/bin/env bash
# shellcheck disable=SC2125
set -eo pipefail

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]:-}")/../utils.sh"
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

function setup_docker() {
    if [[ ! -d /etc/docker ]]; then
        sudo mkdir -p /etc/docker
    fi
    if [[ ! -e /etc/docker/daemon.json ]]; then
        sudo touch /etc/docker/daemon.json
    fi
    sudo cp \
        "${PROJECT_ROOT}/config/dotfiles/docker/daemon.json" \
        /etc/docker/daemon.json
    sudo chmod 644 /etc/docker/daemon.json
    # Don't reload docker daemon if dind
    if [[ ! -e /.dockerenv ]]; then
        sudo systemctl reload docker
    fi
}
