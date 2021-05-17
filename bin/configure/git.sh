#!/usr/bin/env bash
# shellcheck disable=SC2125,SC1091
set -eo pipefail

function setup_git_dotfiles() {
    cp \
        "${PROJECT_ROOT}/config/dotfiles/git/gitconfig" \
        "${HOME}/.gitconfig"
    cp \
        "${PROJECT_ROOT}/config/dotfiles/git/git_template" \
        "${HOME}/.git_template"
    cp \
        "${PROJECT_ROOT}/config/dotfiles/git/gitignore_global" \
        "${HOME}/.gitignore_global"
    cp \
        "${PROJECT_ROOT}/config/dotfiles/git/gitattributes" \
        "${HOME}/.gitattributes"
    touch "${HOME}/.gitconfig.themes"
}

function setup_git() {
    if [[ -e /usr/share/bash-completion/completions/git ]]; then
        source /usr/share/bash-completion/completions/git
    fi
}
