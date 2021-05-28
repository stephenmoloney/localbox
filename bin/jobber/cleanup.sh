#!/usr/bin/env bash
set -eu

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
JOBNAME="cleanup :: docker | vim | bash history"

source "${PROJECT_ROOT}/bin/jobber/utils.sh"

function notify_error() {
    notify_jobber_job_error "${JOBNAME}"
    exit 1
}

function vim_cleanup() {
    set -x
    if [[ -d "${HOME}/.vim/tmp" ]]; then
        rm -rf "${HOME}/.vim/tmp" || notify_error
        mkdir -p "${HOME}/.vim/tmp" || notify_error
    fi
    set +x
}

function docker_cleanup() {
    set -x
    docker system prune --all --force || notify_error
    set +x
}

function bash_history_cleanup() {
    set -x
    cat /dev/null >"${HOME}/.bash_history" || notify_error
    rm "${HOME}/.bash_history.*" 2>/dev/null || true
    set +x
}

function main() {
    prompt_jobber_job_before_exec "${JOBNAME}"
    vim_cleanup
    docker_cleanup
    bash_history_cleanup
    notify_jobber_job_success "${JOBNAME}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
