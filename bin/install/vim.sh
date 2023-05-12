#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

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

# ******* Importing fallbacks.sh as a means of installing missing deps *******
FALLBACKS_PATH="$(dirname "${BASH_SOURCE[0]}")"/../fallbacks.sh
if [[ -e "${FALLBACKS_PATH}" ]]; then
    source "${FALLBACKS_PATH}"
else
    if [[ -z "$(command -v curl)" ]]; then
        sudo apt update -y -qq
        sudo apt install -y -qq curl
    fi
    echo "Falling back to remote script ${GITHUB_URL}/bin/fallbacks.sh"
    if curl -sIf -o /dev/null ${GITHUB_URL}/bin/fallbacks.sh; then
        source <(curl -s "${GITHUB_URL}/bin/fallbacks.sh")
    else
        echo "${GITHUB_URL}/bin/fallbacks.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ****************************************************************************

maybe_install_go_as_fallback
maybe_install_node_as_fallback
maybe_install_yarn_as_fallback

VIM_GTK3_VERSION_FALLBACK="*"
VIM_PLUG_VERSION_FALLBACK=0.11.0
GO_PLS_VERSION_FALLBACK=0.7.5
TERRAFORM_LS_VERSION_FALLBACK="*"
BASH_LANGUAGE_SERVER_VERSION_FALLBACK=2.0.0
GRAPHQL_LANGUAGE_SERVER_VERSION_FALLBACK=3.1.13
VIM_PLUG_URL=https://raw.githubusercontent.com/junegunn/vim-plug

function install_vim_gtk3() {
    local version="${1}"

    maybe_install_apt_pkg vim-gtk3 "${version}"
    apt_hold_pkg vim-gtk3

    echo "${FUNCNAME[0]} complete"
}

function install_vim_plug() {
    local version="${1}"

    if [[ ! -e "${HOME}/.vim/autoload/plug.vim" ]]; then
        curl -fLo "${HOME}/.vim/autoload/plug.vim" \
            --create-dirs \
            "${VIM_PLUG_URL}/${version}/plug.vim"
    fi
    echo "${FUNCNAME[0]} complete"
}

function install_terraform_ls() {
    local version="${1}"

    maybe_install_apt_pkg lsb-release "*"
    maybe_install_apt_pkg software-properties-common "*"

    # shellcheck shell=bash disable=SC1078,SC1079
    sudo bash -c """\
        curl https://apt.releases.hashicorp.com/gpg | \
            gpg --dearmor \
            >/usr/share/keyrings/hashicorp.gpg
    """

    if [[ ! -e /etc/apt/sources.list.d/hashicorp.list ]]; then
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" |
            sudo tee /etc/apt/sources.list.d/hashicorp.list
    fi

    sudo apt update -y -qq
    maybe_install_apt_pkg "terraform-ls" "${version}"
    apt_hold_pkg terraform-ls
    echo "${FUNCNAME[0]} complete"
}

function install_go_pls_server() {
    local version="${1}"

    GOOS="$(go env GOOS)" \
    GOARCH="$(go env GOARCH)" \
    GO111MODULE=on \
        go install "golang.org/x/tools/gopls@v${version}"
    echo "${FUNCNAME[0]} complete"
}

function install_bash_language_server() {
    local version="${1}"

    yarn global add "bash-language-server@${version}"
    echo "${FUNCNAME[0]} complete"
}

function install_graphql_language_server() {
    local version="${1}"

    yarn global add "graphql-language-service-cli@${version}"
    echo "${FUNCNAME[0]} complete"
}

function install_language_servers() {
    if [[ ! -d "${HOME}/.config/coc/extensions" ]]; then
        mkdir -p "${HOME}/.config/coc/extensions"
    fi

    if [[ -e "${PROJECT_ROOT}/config/vim/coc/package.json" ]]; then
        cp \
            "${PROJECT_ROOT}/config/vim/coc/package.json" \
            "${HOME}/.config/coc/extensions"
    else
        if [[ -z "$(command -v curl)" ]]; then
            sudo apt update -y -qq
            sudo apt install -y -qq curl
        fi
        echo "Falling back to remote package.json file ${GITHUB_URL}/config/vim/coc/package.json"
        if curl -sIf -o /dev/null "${GITHUB_URL}/config/vim/coc/package.json"; then
            curl \
                -o "${GITHUB_URL}/config/vim/coc/package.json" \
                "${HOME}/.config/coc/extensions/package.json"
        else
            echo "${GITHUB_URL}/config/vim/coc/package.json does not exist" >/dev/stderr
            return 1
        fi
    fi

    pushd "${HOME}/.config/coc/extensions" || exit

    if [[ -d "${HOME}/.config/coc/extensions/node_modules" ]]; then
        rm -rf "${HOME}/.config/coc/extensions/node_modules"
    fi

    if [[ ! -e "${HOME}/.vimrc" ]]; then
        maybe_configure_vimrc_as_fallback
    fi

    export NERDTREE_CLOSED=true

    # shellcheck disable=SC2015
    tty -s &&
        (
            echo "Shell running interactively"
            vim +'PlugClean|qa' +qall
            vim +'PlugInstall|qa' +qall

            yarn install \
                --silent \
                --ignore-engines \
                --ignore-platform \
                --no-lockfile \
                --no-bin-links \
                --ignore-optional \
                --production=true \
                --ignore-scripts \
                --non-interactive \
                --ignore-scripts \
                --modules-folder "${HOME}/.config/coc/extensions/node_modules"

            vim +'silent call mkdp#util#install()|qa' +qall
            vim +'CocInstall -sync coc-yaml@0.3.0|qa' +qall
        ) ||
        (
            # Do not attempt to install vim plugins in non-interactive mode
            echo "Shell running non-interactively"

            vim --ttyfail +'PlugClean|qa' +qall || true
            vim --ttyfail +'PlugInstall|qa' +qall || true

            yarn install \
                --silent \
                --ignore-engines \
                --ignore-platform \
                --no-lockfile \
                --no-bin-links \
                --ignore-optional \
                --production=true \
                --ignore-scripts \
                --non-interactive \
                --ignore-scripts \
                --modules-folder "${HOME}/.config/coc/extensions/node_modules"

            vim --ttyfail +'silent call mkdp#util#install()|qa' +qall || true
            vim --ttyfail +'CocInstall -sync coc-yaml@0.3.0|qa' +qall || true
        )

    popd || exit
    echo "${FUNCNAME[0]} complete"
}

function main() {
    local vim_version="${1:-$VIM_GTK3_VERSION_FALLBACK}"
    local vim_plug_version="${2:-$VIM_PLUG_VERSION_FALLBACK}"
    local terraform_ls_version="${3:-$TERRAFORM_LS_VERSION_FALLBACK}"
    local go_pls_version="${4:-$GO_PLS_VERSION_FALLBACK}"
    local bash_ls_version="${5:-$BASH_LANGUAGE_SERVER_VERSION_FALLBACK}"
    local graphql_ls_version="${6:-$GRAPHQL_LANGUAGE_SERVER_VERSION_FALLBACK}"

    [[ "${vim_version}" == "latest" ]] && vim_version="*"
    [[ "${terraform_ls_version}" == "latest" ]] && terraform_ls_version="*"

    if [[ -d "${HOME}/.tmux/plugins" ]]; then
        export TMUX_PLUGIN_MANAGER_PATH="${HOME}/.tmux/plugins"
    fi

    if [[ -e "${HOME}/.cargo/env" ]]; then
        source "${HOME}/.cargo/env"
    fi

    echo "${FUNCNAME[0]} starting"

    install_vim_gtk3 "${vim_version}"
    install_vim_plug "${vim_plug_version}"
    install_terraform_ls "${terraform_ls_version}"
    install_go_pls_server "${go_pls_version}"
    install_bash_language_server "${bash_ls_version}"
    install_graphql_language_server "${graphql_ls_version}"
    install_language_servers
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
