#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

ALACRITTY_VERSION_FALLBACK=0.7.2

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
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
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

maybe_install_rust_as_fallback

function get_current_version() {
    alacritty --version | cut -d ' ' -f2
}

function install_alacritty() {
    local version="${1}"

    maybe_install_apt_pkg "cmake" "*"
    maybe_install_apt_pkg "pkg-config" "*"
    maybe_install_apt_pkg "libfreetype6-dev" "*"
    maybe_install_apt_pkg "libfontconfig1-dev" "*"
    maybe_install_apt_pkg "libxcb-xfixes0-dev" "*"
    maybe_install_apt_pkg "python3" "*"

    if [[ -z "$(get_current_version 2>/dev/null || true)" ]] ||
        [[ "$(get_current_version 2>/dev/null || true)" != "${version}" ]]; then
        cargo install alacritty \
            --version "${version}" \
            --force
    else
        echo "alacritty version ${version} is already installed"
        echo "Skipping installation"
    fi

    # Download the alacritty bash completion script
    if [[ ! -d "${HOME}/.bash_completion.d" ]]; then
        mkdir -p "${HOME}/.bash_completion.d"
    fi

    if [[ -e "${HOME}/.bash_completion.d/alacritty" ]]; then
        sudo rm "${HOME}/.bash_completion.d/alacritty"
    fi

    sudo curl -s \
        -o "${HOME}/.bash_completion.d/alacritty" \
        "https://raw.githubusercontent.com/alacritty/alacritty/v${version}/extra/completions/alacritty.bash"

    if [[ ! -e /user/share/icons/alacritty.svg ]]; then
        sudo curl -s \
            -o /usr/share/icons/alacritty.svg \
            "https://raw.githubusercontent.com/alacritty/alacritty/v${version}/extra/logo/alacritty-term.svg"
    fi

    alacritty --version
}

function main() {
    local version="${1:-$ALACRITTY_VERSION_FALLBACK}"

    install_alacritty "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
