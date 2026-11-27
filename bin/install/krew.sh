#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

KREW_VERSION_FALLBACK=0.5.0

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]:-}")/../utils.sh"
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
FALLBACKS_PATH="$(dirname "${BASH_SOURCE[0]:-}")"/../fallbacks.sh
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

# Heal a common asdf state: the version is registered as installed but the
# shim is missing (interrupted install callback) or ~/.asdf/shims is not
# on PATH in this shell. krew needs a working kubectl before anything else.
if ! command -v kubectl >/dev/null 2>&1; then
    if [[ -d "${HOME}/.asdf/shims" ]]; then
        export PATH="${HOME}/.asdf/shims:${PATH}"
    fi
fi
if ! command -v kubectl >/dev/null 2>&1; then
    if asdf plugin list 2>/dev/null | grep -qx kubectl; then
        echo "kubectl shim missing despite version being registered, running asdf reshim"
        asdf reshim kubectl
    fi
fi

maybe_install_kubectl_as_fallback

function get_current_krew_version() {
    if [[ -e "${HOME}/.krew/bin" ]] &&
        [[ -z "$(grep "${HOME}/.krew/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.krew/bin"
    fi
    kubectl krew version |
        awk NR==2 |
        awk '{print $2}' 2>/dev/null || true
}

function install_krew() {
    local version="${1}"
    local suffix
    set -eu

    if [[ "$(get_current_krew_version)" != "${version}" ]]; then
        rm -rf "${HOME}"/.krew 2>/dev/null || true
        suffix="$(
            uname |
                tr '[:upper:]' '[:lower:]'
        )_$(
            uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/' -e 's/aarch64$/arm64/'
        )"

        maybe_install_apt_pkg "curl" "*"

        pushd "$(mktemp -d)" || exit

        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v${version}/krew-${suffix}.tar.gz"
        tar zxvf "krew-${suffix}.tar.gz"
        KREW=./krew-"${suffix}"
        "${KREW}" install krew
        rm "krew-${suffix}.tar.gz"
        popd || exit

        if [[ -e "${HOME}/.krew/bin" ]] &&
            [[ -z "$(grep "${HOME}/.krew/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
            export PATH="${PATH}:${HOME}/.krew/bin"
        fi
    else
        echo "krew version ${version} is already installed"
        echo "Skipping installation"
    fi

    kubectl krew version
}

function main() {
    local version="${1:-$KREW_VERSION_FALLBACK}"

    install_krew "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]:-}" ]]; then
    main "${@}"
fi
