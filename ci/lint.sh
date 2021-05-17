#!/usr/bin/env bash
# shellcheck disable=SC2044
set -euo pipefail

trap \
    "set +e; rm config/dotfiles/bash/bashrc.sh > /dev/null 2>&1;" \
    EXIT

function lint_yaml() {
    echo "Linting yaml with prettier..."
    find . \
        -type f \
        -name "*.y*ml" \
        -exec yarn --silent prettier --check {} +
    yamllint --strict ./
    echo "Finished formatting yaml with prettier"
}

function lint_markdown() {
    echo "Linting markdown with prettier..."
    yarn run \
        --silent markdownlint-cli2 \
        "**/*.md" \
        "#node_modules"
    echo "Finished formatting markdown with prettier"
}

function lint_shell() {
    echo "Linting shell with shfmt..."
    cp \
        config/dotfiles/bash/bashrc \
        config/dotfiles/bash/bashrc.sh
    for sh_file in $(find . -type f -name '*.sh'); do
        shellcheck --shell bash "${sh_file}"
    done
    find . \
        -type f \
        -name "*.sh" \
        -not -path "./node_modules" \
        -not -path "./spec/**/*.sh" \
        -exec shfmt -l -d -i 4 {} +
    cp \
        config/dotfiles/bash/bashrc.sh \
        config/dotfiles/bash/bashrc
    rm config/dotfiles/bash/bashrc.sh
    echo "Finished formatting shell with shfmt"
}

function lint_all() {
    lint_yaml
    lint_markdown
    lint_shell
}
