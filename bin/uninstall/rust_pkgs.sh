#!/bin/env bash
set -euo pipefail

RUST_PKGS=(
    bat
    bottom
    code-minimap
    du-dust
    exa
    fd-find
    git-delta
    hyperfine
    just
    lsd
    nitrocli
    ripgrep
    procs
    tealdeer
    tre
    viu
)

if [[ -e "${HOME}/.cargo/.env" ]]; then
    source "${HOME}/.cargo/.env"
else
    echo "Cargo must be installed" >/dev/stderr
    return 1
fi

for pkg in "${RUST_PKGS[@]}"; do
    if [[ -n "$(command -v "${pkg}")" ]]; then
        cargo uninstall "${pkg}"
    fi
done
