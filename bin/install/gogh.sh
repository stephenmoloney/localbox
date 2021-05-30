#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

GOGH_VERSION_FALLBACK=t213

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

function install_gogh() {
    local version="${1}"

    maybe_install_apt_pkg "dconf-cli" "*"
    maybe_install_apt_pkg "uuid-runtime" "*"

    if [[ ! -d "${HOME}/src/open/gogh" ]]; then
        git clone \
            https://github.com/Mayccoll/Gogh.git \
            "${HOME}/src/open/gogh"
    fi
    pushd "${HOME}/src/open/gogh" || exit
    git checkout "${version}"

    popd || exit
}

function main() {
    local version="${1:-$GOGH_VERSION_FALLBACK}"

    install_gogh "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
