#!/usr/bin/env bash
set -eo pipefail

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

function setup_jobber_dotfiles() {
    if [[ ! -d "${HOME}/.jobber_dir/logs" ]]; then
        mkdir -p "${HOME}/.jobber_dir/logs"
    fi
    if [[ ! -e "${HOME}/.jobber_dir/logs/output" ]]; then
        touch "${HOME}/.jobber_dir/logs/output"
    fi

    cp \
        "${PROJECT_ROOT}/config/dotfiles/jobber/init.yaml" \
        "${HOME}/.jobber"

    sudo chmod 600 "${HOME}/.jobber"

    jobber reload
}
