#!/usr/bin/env bash

trap \
    "set +e; rm config/dotfiles/bash/bashrc.sh > /dev/null 2>&1;" \
    EXIT

function format_yaml() {
    echo "Formatting yaml with prettier..."
    find . \
        -type f \
        -name "*.y*ml" \
        -exec yarn run --silent prettier --write {} +
    echo "Finished formatting yaml with prettier"
}

function format_json() {
    echo "Formatting json with prettier..."
    find . \
        -type f \
        -name "*.json" \
        -exec yarn run --silent prettier --write {} +
    echo "Finished formatting json with prettier"
}

function format_markdown() {
    echo "Formatting markdown with prettier..."
    find . \
        -type f \
        -name "*.md" \
        -exec yarn run --silent prettier --write {} +
    echo "Finished formatting markdown with prettier"
}

function format_shell() {
    echo "Formatting shell with shfmt..."
    cp \
        config/dotfiles/bash/bashrc \
        config/dotfiles/bash/bashrc.sh
    find . \
        -type f \
        -name "*.sh" \
        -not -path "./node_modules" \
        -not -path "./spec/**/*.sh" \
        -exec shfmt -l -w -i 4 {} +
    cp \
        config/dotfiles/bash/bashrc.sh \
        config/dotfiles/bash/bashrc
    rm config/dotfiles/bash/bashrc.sh
    echo "Finished formatting shell with shfmt"
}

function format_all() {
    format_yaml
    format_json
    format_markdown
    format_shell
}
