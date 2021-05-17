#!/usr/bin/env bash
set -Eeuo pipefail

DOCKER_COMPOSE_VERSION_FALLBACK=1.28.5
BASE_URL=https://github.com/docker/compose/releases/download

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
if [[ -e "${UTILS_PATH}" ]]; then
    . "${UTILS_PATH}"
else
    if [[ -z "$(command -v curl)" ]]; then
        sudo apt update -y -qq
        sudo apt install -y -qq curl
    fi
    echo "Falling back to remote script ${GITHUB_URL}/bin/utils.sh"
    if curl -sIf -o /dev/null ${GITHUB_URL}/bin/utils.sh; then
        . <(curl -s "${GITHUB_URL}/bin/utils.sh")
    else
        echo "${GITHUB_URL}/bin/utils.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ************************************************************************

function get_current_version() {
    docker-compose version |
        awk NR==1 |
        cut -d' ' -f3 |
        tr -d "," 2>/dev/null || true
}

function install_docker_compose() {
    local version="${1}"

    maybe_install_apt_pkg "curl" "*"

    if [[ "$(get_current_version 2>/dev/null || true)" != "${version}" ]] ||
        [[ "$(get_current_version 2>/dev/null || true)" != "${version}" ]]; then
        pushd "$(mktemp --directory)" || exit
        sudo curl -L \
            "${BASE_URL}/${version}/docker-compose-$(uname -s)-$(uname -m)" \
            -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        popd || exit
    else
        echo "docker compose version ${version} is already installed"
        echo "Skipping installation"
    fi

    docker-compose --version
}

function main() {
    local version="${1:-$DOCKER_COMPOSE_VERSION_FALLBACK}"

    install_docker_compose "${version}"
}

main "${@}"
