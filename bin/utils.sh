#!/usr/bin/env bash
# shellcheck disable=SC2001,SC2034,SC2181

CALLER_RELATIVE_PATH="$(echo "${BASH_SOURCE[0]:-}" | sed "s/$(basename "${BASH_SOURCE[0]:-}")//")"
export TZ=${TZ:-Etc/UTC}
export DEBIAN_FRONTEND=noninteractive

function project_root() {
    local script_relative_to_root=../

    if [[ -z "$(command -v git)" ]]; then
        sudo apt update -y >/dev/null 2>&1
        sudo apt install -y git >/dev/null 2>&1
    fi
    git rev-parse --show-toplevel 2>/dev/null || (
        pushd "${CALLER_RELATIVE_PATH}" >/dev/null 2>&1 || exit &&
            pushd "${script_relative_to_root}" >/dev/null 2>&1 &&
            echo "${PWD}" &&
            popd >/dev/null 2>&1 || exit &&
            popd >/dev/null 2>&1 || exit
    )
}

function install_pkg() {
    local pkg="${1}"
    local pkg_version="${2}"

    if [[ "${pkg_version}" == "*" ]]; then
        echo "Installing latest version of ${pkg}"
        sudo apt update -y -qq
        sudo --preserve-env apt install -y "${pkg}"
    else
        echo "Installing version ${pkg_version} of ${pkg}"
        sudo apt update -y -qq
        sudo --preserve-env apt install -y --allow-downgrades "${pkg}=${pkg_version}"
    fi
}

function apt_hold_pkg() {
    local pkg="${1}"
    local apt_installed
    apt_installed="$(sudo apt list --installed 2>/dev/null)"

    if [[ -z "${pkg}" ]]; then
        echo "pkg must be set as the first variable"
    fi

    if [[ -z "$(grep "${pkg}/" <<<"${apt_installed}" 2>/dev/null || true)" ]]; then
        sudo apt hold "${pkg}"
    fi
}

function apt_unhold_pkg() {
    local pkg="${1}"
    local apt_installed
    apt_installed="$(sudo apt list --installed 2>/dev/null)"

    if [[ -z "${pkg}" ]]; then
        echo "pkg must be set as the first variable"
    fi

    if [[ -z "$(grep "${pkg}/" <<<"${apt_installed}" 2>/dev/null || true)" ]]; then
        sudo apt unhold "${pkg}"
    fi
}

function maybe_install_apt_pkg() {
    local pkg="${1}"
    local pkg_version="${2}"
    local apt_installed
    apt_installed="$(sudo apt list --installed 2>/dev/null)"

    if [[ -z "${pkg}" ]]; then
        echo "pkg must be set as the first variable"
    fi

    if [[ -z "${pkg_version}" ]]; then
        echo "pkg_version must be set as the second variable"
    fi

    if [[ -z "$(grep "${pkg}/" <<<"${apt_installed}" 2>/dev/null || true)" ]]; then
        install_pkg "${pkg}" "${pkg_version}"
    elif [[ -z "$(grep "${pkg}/" <<<"${apt_installed}" | grep "${pkg_version}" 2>/dev/null || true)" ]]; then
        apt_unhold_pkg "${pkg}"
        install_pkg "${pkg}" "${pkg_version}"
    else
        echo "package ${pkg} version ${pkg_version} is already installed"
        echo "Skipping ${pkg} installation"
    fi
}

function maybe_uninstall_apt_pkg() {
    local pkg="${1}"
    local apt_installed
    apt_installed="$(sudo apt list --installed 2>/dev/null)"

    if [[ -z "${pkg}" ]]; then
        echo "pkg must be set as the first variable"
    fi

    if [[ -n "$(grep "${pkg}/" <<<"${apt_installed}" 2>/dev/null || true)" ]]; then
        sudo --preserve-env apt autoremove --purge -y "${pkg}"
    fi
}

function opts_handler() {
    for opt in "$@"; do
        case "${opt}" in
        --headless=true)
            export HEADLESS_ONLY=true
            shift
            ;;
        --headless=false)
            export HEADLESS_ONLY=false
            shift
            ;;
        --use-fallback-versions=true)
            export SOURCE_ENV_FILE=false
            shift
            ;;
        --use-fallback-versions=false)
            export SOURCE_ENV_FILE=true
            shift
            ;;
        *)
            echo "unexpected option encountered"
            shift
            break
            ;;
        esac
    done
    echo "HEADLESS_ONLY: ${HEADLESS_ONLY:-false}"
    echo "SOURCE_ENV_FILE: ${SOURCE_ENV_FILE:-true}"
}

function exec_with_retries() {
    local script="${1}"
    local current_try="${2:-0}"
    local max_retries="${3:-3}"
    local script_args="${4:-}"

    sleep 3s
    current_try=$(("${current_try}" + 1))
    if [[ "${current_try}" -eq 1 ]]; then
        echo "---------------------------------------------------"
        echo "Executing ${script}"
        echo "---------------------------------------------------"
    else
        echo "***************************************************"
        echo "Initiating retry ${current_try} of ${max_retries} :: ${script} ${script_args}"
        echo "***************************************************"
    fi
    if [[ "${max_retries}" -gt "${current_try}" ]]; then
        if [[ -z "${script_args}" ]]; then
            "${script}" || exec_with_retries "${script}" "${current_try}" "${max_retries}"
        else
            "${script}" "${script_args}" || exec_with_retries "${script}" "${current_try}" "${max_retries}" "${script_args}"
        fi
    else
        if [[ -z "${script_args}" ]]; then
            "${script}"
        else
            "${script}" "${script_args}"
        fi
    fi
}

function is_docker() {
    if [[ -e /.dockerenv ]]; then
        echo "true"
    fi
}

function headless_only() {
    if [[ "${HEADLESS_ONLY:-false}" == "true" ]]; then
        echo "true"
    fi
}

function exit_handler() {
    local rc="${1}"
    local type="${2}"

    echo "${type}, rc: ${rc}"
    echo "Source: ${BASH_SOURCE[*]}"
    echo "Line Number: ${BASH_LINENO[*]}"
    echo "Function : ${FUNCNAME[*]}"
    echo "Command: ${BASH_COMMAND}"

    exit "${rc}"
}
