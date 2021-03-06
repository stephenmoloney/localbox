#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

ASDF_VERSION_FALLBACK=0.10.1

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

function install_asdf() {
    local version="${1}"

    maybe_install_apt_pkg "git" "*"

    if [[ -d "${HOME}/.asdf" ]]; then
        pushd "${HOME}/.asdf" || exit
        git fetch origin
        git checkout "v${version}"
        popd || exit
    else
        git clone \
            https://github.com/asdf-vm/asdf.git \
            --branch "v${version}" \
            "${HOME}/.asdf"
    fi

    # Workaround for bug in version 0.9.0, remove workaround in next release
    # https://github.com/asdf-vm/asdf/pull/1158
    if [[ -z "${ASDF_DIR:-}" ]]; then
        if [[ -e "${HOME}/.asdf/asdf.sh" ]]; then
            source "${HOME}/.asdf/asdf.sh"
        fi
    else
        source "${ASDF_DIR}/asdf.sh"
    fi

    asdf --version
}

function main() {
    local version="${1:-$ASDF_VERSION_FALLBACK}"

    install_asdf "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
