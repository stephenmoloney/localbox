#!/usr/bin/env bash
# shellcheck disable=SC2154
set -eu
set -o pipefail
set -o errtrace

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]}")/utils.sh"
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
export PROJECT_ROOT
PROJECT_ROOT="$(project_root)"
trap 'exit_code=$?; [[ "${exit_code}" -ne 0 ]] && exit_handler "${exit_code}" "EXIT"' EXIT
trap 'exit_code=$?; exit_handler "${exit_code}" "ERR"' ERR

function preinstall() {
    opts_handler "${@}"

    if [[ "${SOURCE_ENV_FILE:-true}" == "true" ]]; then
        echo "Sourcing environment variables from ${PROJECT_ROOT}/.env"
        set -o allexport
        source "${PROJECT_ROOT}/.env"
        set +o allexport
    else
        echo "Skipping sourcing environment variables from ${PROJECT_ROOT}/.env"
        echo "Default fallback versions will be adpoted"
    fi

    # Setting vars common regardless of fallbacks
    if [[ -z "${XKBLAYOUT:-}" ]]; then export XKBLAYOUT=us; fi
    if [[ -z "${BACKSPACE:-}" ]]; then export BACKSPACE=guess; fi
    if [[ -z "${XKBMODEL:-}" ]]; then export XKBMODEL=pc105; fi
    if [[ -z "${TZ:-}" ]]; then export TZ=Europe/Zurich; fi
    if [[ -z "${LANG:-}" ]]; then export LANG=en_US.UTF-8; fi
    if [[ -z "${LANGUAGE:-}" ]]; then export LANGUAGE=en_US.UTF-8; fi
    if [[ -z "${LC_ALL:-}" ]]; then export LC_ALL=en_US.UTF-8; fi

    source "${PROJECT_ROOT}/bin/configure/misc.sh"
    setup_locales
    setup_timezone
    setup_keyboard
    setup_directory_structure

    echo "${TZ}" | sudo --preserve-env tee /etc/timezone >/dev/null
    sudo --preserve-env apt install -y tzdata
    sudo --preserve-env dpkg-reconfigure --frontend=noninteractive tzdata
    sudo --preserve-env apt install -y \
        apt-transport-https \
        ca-certificates \
        software-properties-common \
        curl \
        locales \
        keyboard-configuration
    sudo --preserve-env locale-gen "${LANG}"
    sudo --preserve-env dpkg-reconfigure --frontend=noninteractive locales
    sudo --preserve-env update-locale LANG="${LANG}"
    locale
    export GIT_TERMINAL_PROMPT=0
}
