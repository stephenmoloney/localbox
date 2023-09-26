#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

PGCLI_VERSION_FALLBACK=3.5.0
POSTGRESQL_CLIENT_VERSION_FALLBACK=16

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

function get_current_version() {
    pgcli --version | cut -d' ' -f2
}

function postgresql_client_prerequisites() {
    maybe_install_apt_pkg "wget" "*"

    # shellcheck shell=bash disable=SC1078,SC1079
    sudo bash -c """\
        curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
            gpg --dearmor \
            >/usr/share/keyrings/postgresql.gpg
    """

    if [[ ! -e /etc/apt/sources.list.d/pgdg.list ]]; then
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" |
            sudo tee /etc/apt/sources.list.d/pgdg.list
    fi

    sudo apt update -y -qq
    maybe_install_apt_pkg "libpq-dev" "*"
}

function install_pgcli() {
    local pgcli_version="${1}"
    local postgresql_client_version="${2}"

    maybe_install_apt_pkg "python3-dev" "*"
    maybe_install_apt_pkg "python3-pip" "*"
    maybe_install_apt_pkg "lsb-release" "*"
    postgresql_client_prerequisites
    maybe_install_apt_pkg "postgresql-client-${postgresql_client_version}" "*"

    if [[ -z "$(get_current_version 2>/dev/null || true)" ]] ||
        [[ "$(get_current_version 2>/dev/null || true)" != "${pgcli_version}" ]]; then
        pip3 install pgcli=="${pgcli_version}"
    else
        echo "pgcli version ${pgcli_version} is already installed"
        echo "Skipping installation"
    fi

    if [[ -z "$(grep "${HOME}/.local/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${HOME}/.local/bin"
    fi

    pgcli --version
}

function main() {
    local pgcli_version="${1:-$PGCLI_VERSION_FALLBACK}"
    local postgresql_client_version="${2:-$POSTGRESQL_CLIENT_VERSION_FALLBACK}"

    install_pgcli "${pgcli_version}" "${postgresql_client_version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
