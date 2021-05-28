#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

JOBBER_VERSION_FALLBACK=1.4.4

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

maybe_install_go_as_fallback

function get_current_version() {
    jobber -v | cut -d' ' -f2
}

function install_jobber() {
    local version="${1}"

    maybe_install_apt_pkg "build-essential" "*"
    maybe_install_apt_pkg "git" "*"
    maybe_install_apt_pkg "zenity" "*"

    if [[ ! -d "${HOME}/.jobber_dir" ]]; then
        mkdir -p "${HOME}/.jobber_dir"
    fi
    if [[ ! -d "${HOME}/src/open" ]]; then
        mkdir -p "${HOME}/src/open"
    fi

    if [[ ! -d "${HOME}/src/open/jobber" ]]; then
        git clone \
            https://github.com/dshearer/jobber.git \
            --branch "v${version}" \
            "${HOME}/src/open/jobber"
    fi

    pushd "${HOME}/src/open/jobber" || exit
    git fetch origin
    git checkout "v${version}"
    sudo make clean
    make
    sudo make install
    popd || exit

    # Directory required by jobbermaster
    if [[ ! -d /usr/local/var/jobber ]]; then
        sudo mkdir -p /usr/local/var/jobber
    fi

    jobber -v
}

function main() {
    local version="${1:-$JOBBER_VERSION_FALLBACK}"

    install_jobber "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
