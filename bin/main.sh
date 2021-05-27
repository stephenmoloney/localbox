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
PROJECT_ROOT="$(project_root)"
trap 'exit_code=$?; [[ "${exit_code}" -ne 0 ]] && exit_handler "${exit_code}" "EXIT"' EXIT
trap 'exit_code=$?; exit_handler "${exit_code}" "ERR"' ERR

function install() {
    opts_handler "${@}"

    if [[ "${HEADLESS_ONLY}" == "true" ]]; then
        echo "installing in headless mode"
    else
        echo "installing in standard mode"
    fi
    if [[ "${SOURCE_ENV_FILE}" == "true" ]]; then
        echo "Sourcing environment variables from ${PROJECT_ROOT}/.env"
        source "${PROJECT_ROOT}/.env"
    else
        echo "Skipping sourcing environment variables from ${PROJECT_ROOT}/.env"
        echo "Default fallback versions will be employed"
    fi

    # Order of script execution does matter to avoid the fallback scripts being executed

    # Phase 1
    exec_with_retries "${PROJECT_ROOT}/bin/install/debian_pkgs.sh" 0 2
    exec_with_retries "${PROJECT_ROOT}/bin/install/go.sh" 0 2 "${GO_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/jq.sh" 0 2 "${JQ_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/rust.sh" 0 2 "${RUST_VERSION}"

    # Phase 2
    exec_with_retries "${PROJECT_ROOT}/bin/install/alacritty.sh" 0 2 "${ALACRITTY_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/ansible.sh" 0 2 "${ANSIBLE_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/ansible_modules.sh" 0 2
    exec_with_retries "${PROJECT_ROOT}/bin/install/asdf.sh" 0 2 "${ASDF_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/asdf_plugins.sh" 0 2
    exec_with_retries "${PROJECT_ROOT}/bin/install/azure_cli.sh" 0 2 "${AZURE_CLI_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/black.sh" 0 2 "${BLACK_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/bpytop.sh" 0 2 "${BPYTOP_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/diagrams.sh" 0 2 "${DIAGRAMS_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/docker.sh" 0 2 "${DOCKER_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/docker_compose.sh" 0 2 "${DOCKER_COMPOSE_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/dotnet_core.sh" 0 2 "${DOTNET_CORE_SDK_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/insomnia.sh" 0 2 "${INSOMNIA_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/gogh.sh" 0 2 "${GOGH_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/krew.sh" 0 2 "${KREW_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/krew_plugins.sh" 0 2 "${KREW_VERSION}"
    "${PROJECT_ROOT}/bin/install/pgcli.sh" "${PGCLI_VERSION}" "${POSTGRESQL_CLIENT_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/nerd_fonts.sh" 0 2 "${NERDFONTS_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/pipx.sh" 0 2 "${PIPX_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/powerline.sh" 0 2 "${POWERLINE_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/rust_pkgs.sh" 0 2
    exec_with_retries "${PROJECT_ROOT}/bin/install/shellcheck.sh" 0 2 "${SHELLCHECK_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/shfmt.sh" 0 2 "${SHFMT_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/tmuxinator.sh" 0 2 "${TMUXINATOR_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/vint.sh" 0 2 "${VINT_VERSION}"
    exec_with_retries "${PROJECT_ROOT}/bin/install/yamllint.sh" 0 2 "${YAMLLINT_VERSION}"

    # Phase 3
    exec_with_retries "${PROJECT_ROOT}/bin/install/tmux_plugin_manager.sh" 0 2 "${TMUX_PLUGIN_MANAGER_VERSION}"
    "${PROJECT_ROOT}/bin/install/vim.sh" \
        "${VIM_GTK3_VERSION:-latest}" \
        "${VIM_PLUG_VERSION:-0.10.0}" \
        "${TERRAFORM_LS_VERSION:-latest}" \
        "${GO_PLS_VERSION:-0.6.9}" \
        "${BASH_LANGUAGE_SERVER_VERSION:-1.17.0}" \
        "${GRAPHQL_LANGUAGE_SERVER_VERSION:-3.1.13}"
}

function setup() {
    source "${PROJECT_ROOT}/bin/configure/alacritty.sh"
    source "${PROJECT_ROOT}/bin/configure/ansible.sh"
    source "${PROJECT_ROOT}/bin/configure/asdf.sh"
    source "${PROJECT_ROOT}/bin/configure/asdf_plugins.sh"
    source "${PROJECT_ROOT}/bin/configure/azure_cli.sh"
    source "${PROJECT_ROOT}/bin/configure/bashrc.sh"
    source "${PROJECT_ROOT}/bin/configure/bpytop.sh"
    source "${PROJECT_ROOT}/bin/configure/docker.sh"
    source "${PROJECT_ROOT}/bin/configure/dotnet_core.sh"
    source "${PROJECT_ROOT}/bin/configure/editorconfig.sh"
    source "${PROJECT_ROOT}/bin/configure/git.sh"
    source "${PROJECT_ROOT}/bin/configure/go.sh"
    source "${PROJECT_ROOT}/bin/configure/gogh.sh"
    source "${PROJECT_ROOT}/bin/configure/krew.sh"
    source "${PROJECT_ROOT}/bin/configure/misc.sh"
    source "${PROJECT_ROOT}/bin/configure/markdownlint.sh"
    source "${PROJECT_ROOT}/bin/configure/pgcli.sh"
    source "${PROJECT_ROOT}/bin/configure/prettier.sh"
    source "${PROJECT_ROOT}/bin/configure/rust.sh"
    source "${PROJECT_ROOT}/bin/configure/tmux.sh"
    source "${PROJECT_ROOT}/bin/configure/vim.sh"
    source "${PROJECT_ROOT}/bin/configure/yamllint.sh"

    # Run first
    setup_locales
    setup_timezone
    setup_keyboard
    setup_directory_structure

    # Run second
    setup_alacritty_dotfiles
    setup_alacritty_desktop_file
    setup_ansible_dotfiles
    setup_asdf
    setup_asdf_dotfiles
    setup_azure_cli_dotfiles
    setup_bashrc
    setup_bpytop_dotfiles
    setup_docker
    setup_editorconfig
    setup_git_dotfiles
    setup_gnome_terminal_profiles
    setup_krew
    setup_kubectl_dotfiles
    setup_markdownlint
    setup_go
    setup_pgcli_dotfiles
    setup_prettier
    setup_rust
    setup_rustfmt
    setup_tmux
    setup_vimrc
    setup_yamllint_dotfiles

    source "${HOME}/.bashrc"
}
