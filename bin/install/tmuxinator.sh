#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

TMUXINATOR_VERSION_FALLBACK=3.0.2

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

maybe_install_ruby_as_fallback

function get_current_version() {
    tmuxinator version | cut -d' ' -f2
}

function setup_bash_completion() {
    sudo wget \
        "https://raw.githubusercontent.com/tmuxinator/tmuxinator/v${TMUXINATOR_VERSION_FALLBACK}/completion/tmuxinator.bash" \
        -O /etc/bash_completion.d/tmuxinator.bash
}

function install_tmuxinator() {
    local version="${1}"

    if [[ -z "$(get_current_version 2>/dev/null || true)" ]] ||
        [[ "$(get_current_version 2>/dev/null || true)" != "${version}" ]]; then
        gem install tmuxinator -v "${version}"
        setup_bash_completion
    else
        echo "tmuxinator version ${version} is already installed"
        echo "Skipping installation"
    fi

    if [[ ! -d /etc/bash_completion.d/tmuxinator.bash ]]; then
        setup_bash_completion
    fi

    tmuxinator version
}

function main() {
    local version="${1:-$TMUXINATOR_VERSION_FALLBACK}"

    install_tmuxinator "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
