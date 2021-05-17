#!/usr/bin/env bash
# shellcheck disable=SC2125
set -eo pipefail

function setup_directory_structure() {
    if [[ ! -d "${HOME}/src/open/localbox" ]]; then
        mkdir -p "${HOME}/src/open/localbox"
    fi
    if [[ ! -d "${HOME}/src/closed" ]]; then
        mkdir -p "${HOME}/src/closed"
    fi
    if [[ ! -d "${HOME}/src/go" ]]; then
        mkdir -p "${HOME}/src/go"
    fi
    if [[ ! -d "${HOME}/src/pkgs" ]]; then
        mkdir -p "${HOME}/src/pkgs"
    fi
}

function setup_keyboard() {
    cat <<EOT | sudo tee -a /etc/default/keyboard >/dev/null
XKBLAYOUT=${XKBLAYOUT:-us}
BACKSPACE=${BACKSPACE:-guess}
XKBMODEL=${XKBMODEL:-pc105}
EOT
}

function setup_locales() {
    export LANG
    export LANGUAGE
    export LC_ALL
    if [[ -z "${LANG}" ]]; then
        if [[ -n "$(grep LANG "${LOCALBOX_PATH}/.env" | cut -d'=' -f2 2>/dev/null || true)" ]]; then
            LANG="$(grep LANG "${LOCALBOX_PATH}/.env" | cut -d'=' -f2 2>/dev/null || true)"
        else
            LANG=en_US.UTF-8
        fi
    fi
    if [[ -z "${LANGUAGE}" ]]; then
        if [[ -n "$(grep LANGUAGE "${LOCALBOX_PATH}/.env" | cut -d'=' -f2 2>/dev/null || true)" ]]; then
            LANGUAGE="$(grep LANGUAGE "${LOCALBOX_PATH}/.env" | cut -d'=' -f2 2>/dev/null || true)"
        else
            LANGUAGE=en_US.UTF-8
        fi
    fi
    if [[ -z "${LC_ALL}" ]]; then
        if [[ -n "$(grep LC_ALL "${LOCALBOX_PATH}/.env" | cut -d'=' -f2 2>/dev/null || true)" ]]; then
            LC_ALL="$(grep LC_ALL "${LOCALBOX_PATH}/.env" | cut -d'=' -f2 2>/dev/null || true)"
        else
            LC_ALL=en_US.UTF-8
        fi
    fi
}

function setup_timezone() {
    export TZ
    if [[ -z "${TZ}" ]]; then
        if [[ -n "$(cat /etc/timezone)" ]]; then
            TZ="$(cat /etc/timezone)"
        elif [[ -n "$(grep TZ "${LOCALBOX_PATH}/.env" | cut -d'=' -f2 2>/dev/null || true)" ]]; then
            TZ="$(grep TZ "${LOCALBOX_PATH}/.env" | cut -d'=' -f2 2>/dev/null || true)"
        else
            TZ=Etc/UTC
        fi
    fi
}

function setup_editors() {
    export EDITOR=vim
    export K8S_EDITOR=vim
}

function setup_gpg_ssh_agent() {
    unset SSH_AGENT_PID
    export GPG_TTY
    GPG_TTY="$(tty)"
    export SSH_AUTH_SOCK
    SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    gpgconf --launch gpg-agent
}
