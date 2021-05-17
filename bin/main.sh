#!/usr/bin/env bash
# shellcheck disable=SC2154
set -eo pipefail

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]}")/utils.sh"
if [[ -e "${UTILS_PATH}" ]]; then
    . "${UTILS_PATH}"
else
    if [[ -z "$(command -v curl)" ]]; then
        sudo apt update -y -qq
        sudo apt install -y -qq curl
    fi
    echo "Falling back to remote script ${GITHUB_URL}/bin/utils.sh"
    if curl -sIf -o /dev/null ${GITHUB_URL}/bin/utils.sh; then
        . <(curl -s "${GITHUB_URL}/bin/utils.sh")
    else
        echo "${GITHUB_URL}/bin/utils.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ************************************************************************
PROJECT_ROOT="$(project_root)"
trap '[[ $? -ne 0 ]] && err_handler $?' ERR
trap '[[ $? -ne 0 ]] && exit_handler $?' EXIT

function install() {
    opts_handler "${@}"

    if [[ "${HEADLESS_ONLY}" == "true" ]]; then
        echo "installing in headless mode"
    else
        echo "installing in standard mode"
    fi
    if [[ "${SOURCE_ENV_FILE}" == "true" ]]; then
        echo "Sourcing environment variables from ${PROJECT_ROOT}/.env"
        . "${PROJECT_ROOT}/.env"
    else
        echo "Skipping sourcing environment variables from ${PROJECT_ROOT}/.env"
        echo "Default fallback versions will be employed"
    fi

    # Run first
    . "${PROJECT_ROOT}/bin/install/asdf.sh" "${ASDF_VERSION}"
    . "${PROJECT_ROOT}/bin/install/asdf_plugins.sh"
    . "${PROJECT_ROOT}/bin/install/azure_cli.sh" "${AZURE_CLI_VERSION}"
    . "${PROJECT_ROOT}/bin/install/debian_pkgs.sh"
    . "${PROJECT_ROOT}/bin/install/docker.sh" "${DOCKER_VERSION}"
    . "${PROJECT_ROOT}/bin/install/docker_compose.sh" "${DOCKER_COMPOSE_VERSION}"
    . "${PROJECT_ROOT}/bin/install/go.sh" "${GO_VERSION}"
    . "${PROJECT_ROOT}/bin/install/rust.sh" "${RUST_VERSION}"
    . "${PROJECT_ROOT}/bin/install/rust_pkgs.sh"
    . "${PROJECT_ROOT}/bin/install/shellcheck.sh" "${SHELLCHECK_VERSION}"
    . "${PROJECT_ROOT}/bin/install/shfmt.sh" "${SHFMT_VERSION}"
    . "${PROJECT_ROOT}/bin/install/yamllint.sh" "${YAMLLINT_VERSION}"

    # Run second (may have dependencies on first run)
    . "${PROJECT_ROOT}/bin/install/tmux_plugin_manager.sh" "${TMUX_PLUGIN_MANAGER_VERSION}"
    . "${PROJECT_ROOT}/bin/install/vim.sh" \
        "${VIM_GTK3_VERSION:-latest}" \
        "${VIM_PLUG_VERSION:-0.10.0}" \
        "${TERRAFORM_LS_VERSION:-latest}" \
        "${GO_PLS_VERSION:-0.6.9}" \
        "${BASH_LANGUAGE_SERVER_VERSION:-1.17.0}" \
        "${GRAPHQL_LANGUAGE_SERVER_VERSION:-3.1.13}"
}

function setup() {
    . "${PROJECT_ROOT}/bin/configure/asdf.sh"
    . "${PROJECT_ROOT}/bin/configure/asdf_plugins.sh"
    . "${PROJECT_ROOT}/bin/configure/azure_cli.sh"
    . "${PROJECT_ROOT}/bin/configure/bashrc.sh"
    . "${PROJECT_ROOT}/bin/configure/docker.sh"
    . "${PROJECT_ROOT}/bin/configure/editorconfig.sh"
    . "${PROJECT_ROOT}/bin/configure/git.sh"
    . "${PROJECT_ROOT}/bin/configure/go.sh"
    . "${PROJECT_ROOT}/bin/configure/misc.sh"
    . "${PROJECT_ROOT}/bin/configure/markdownlint.sh"
    . "${PROJECT_ROOT}/bin/configure/prettier.sh"
    . "${PROJECT_ROOT}/bin/configure/rust.sh"
    . "${PROJECT_ROOT}/bin/configure/tmux.sh"
    . "${PROJECT_ROOT}/bin/configure/vim.sh"
    . "${PROJECT_ROOT}/bin/configure/yamllint.sh"

    # Run first
    setup_locales
    setup_timezone
    setup_keyboard
    setup_directory_structure

    # Run second
    setup_asdf
    setup_asdf_dotfiles
    setup_azure_cli_dotfiles
    setup_bashrc
    setup_docker
    setup_editorconfig
    setup_git_dotfiles
    setup_markdownlint
    setup_go
    setup_prettier
    setup_rust
    setup_rustfmt
    setup_tmux
    setup_vimrc
    setup_yamllint_dotfiles

    . "${HOME}/.bashrc"
}
