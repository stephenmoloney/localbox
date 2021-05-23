#!/usr/bin/bash env
# shellcheck disable=SC1091
set -euo pipefail

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]}")/utils.sh"
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
PROJECT_ROOT="$(project_root)"

RUST_INSTALL_SCRIPT="${PROJECT_ROOT}/bin/install/rust.sh"
GO_INSTALL_SCRIPT="${PROJECT_ROOT}/bin/install/go.sh"
ASDF_INSTALL_SCRIPT="${PROJECT_ROOT}/bin/install/asdf.sh"
JQ_INSTALL_SCRIPT="${PROJECT_ROOT}/bin/install/jq.sh"
NODEJS_VERSION_FALLBACK=14.17.0
YARN_VERSION_FALLBACK=1.22.10
RUBY_VERSION_FALLBACK=2.7.2
KUBECTL_VERSION_FALLBACK=1.20.0

ASDF_RUBY_DEPS=(
    autoconf
    bison
    build-essential
    libssl-dev
    libyaml-dev
    libreadline6-dev
    zlib1g-dev
    libncurses5-dev
    libffi-dev
    libgdbm6
    libgdbm-dev
    libdb-dev
)

function maybe_install_rust_as_fallback() {
    if [[ -e "${HOME}/.env/cargo" ]]; then
        source "${HOME}/.env/cargo"
    fi

    if [[ -z "$(command -v rustup)" ]] || [[ -z "$(command -v cargo)" ]]; then
        echo "Installing rust tools as a fallback measure"
        if [[ -e "${RUST_INSTALL_SCRIPT}" ]]; then
            "${RUST_INSTALL_SCRIPT}"
        else
            echo "Falling back to remote script ${GITHUB_URL}/bin/install/rust.sh"
            if curl -sIf -o /dev/null ${GITHUB_URL}/bin/install/rust.sh; then
                source <(curl -s "${GITHUB_URL}/bin/install/rust.sh")
            else
                echo "${GITHUB_URL}/bin/install/rust.sh does not exist" >/dev/stderr
                return 1
            fi
        fi
        source "${HOME}/.cargo/env"
    else
        echo "Rust version $(cargo version | cut -d' ' -f2) already installed"
    fi
}

function maybe_install_go_as_fallback() {
    export GOPATH="${GOPATH:-${HOME}/src/go}"
    if [[ ! -d "${GOPATH}" ]]; then
        mkdir -p "${GOPATH}"
    fi
    export GOROOT="${GOROOT:-/usr/local/go}"
    if [[ -z "$(grep "${GOROOT}/bin" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${GOROOT}/bin"
    fi

    if [[ -z "$(command -v go)" ]]; then
        echo "Installing go as a fallback measure"
        if [[ -e "${GO_INSTALL_SCRIPT}" ]]; then
            "${GO_INSTALL_SCRIPT}"
        else
            echo "Falling back to remote script ${GITHUB_URL}/bin/install/go.sh"
            if curl -sIf -o /dev/null ${GITHUB_URL}/bin/install/go.sh; then
                source <(curl -s "${GITHUB_URL}/bin/install/go.sh")
            else
                echo "${GITHUB_URL}/bin/install/go.sh does not exist" >/dev/stderr
                return 1
            fi
        fi
    else
        echo "Go version $(go version | cut -d' ' -f3 | tr -d "go") already installed"
    fi
}

function maybe_install_asdf_as_fallback() {
    local asdf_version

    if [[ -z "${ASDF_DIR:-}" ]]; then
        if [[ -e "${HOME}/.asdf/asdf.sh" ]]; then
            source "${HOME}/.asdf/asdf.sh"
        fi
    else
        if [[ -e "${ASDF_DIR:-}/asdf.sh" ]]; then
            source "${ASDF_DIR}/asdf.sh"
        fi
    fi

    if [[ -z "$(command -v asdf)" ]]; then
        echo "Installing asdf as a fallback measure"
        if [[ -e "${ASDF_INSTALL_SCRIPT}" ]]; then
            "${ASDF_INSTALL_SCRIPT}"
        else
            echo "Falling back to remote script ${GITHUB_URL}/bin/install/asdf.sh"
            if curl -sIf -o /dev/null ${GITHUB_URL}/bin/install/asdf.sh; then
                source <(curl -s "${GITHUB_URL}/bin/install/asdf.sh")
            else
                echo "${GITHUB_URL}/bin/install/asdf.sh does not exist" >/dev/stderr
                return 1
            fi
        fi
    else
        asdf_version="$(
            asdf --version |
                cut -d' ' -f2 |
                tr -d "v" |
                rev |
                cut -d'-' -f2 |
                rev
        )"
        echo "asdf version ${asdf_version} already installed"
    fi
}

function maybe_install_node_as_fallback() {
    if [[ -z "${ASDF_DIR:-}" ]]; then
        if [[ -e "${HOME}/.asdf/asdf.sh" ]]; then
            source "${HOME}/.asdf/asdf.sh"
        fi
    else
        if [[ -e "${ASDF_DIR:-}/asdf.sh" ]]; then
            source "${ASDF_DIR}/asdf.sh"
        fi
    fi

    if [[ -z "$(command -v node)" ]]; then
        maybe_install_apt_pkg "dirmngr" "*"
        maybe_install_apt_pkg "gpg" "*"
        maybe_install_apt_pkg "curl" "*"

        if [[ -z "$(command -v asdf)" ]]; then
            maybe_install_asdf_as_fallback
        fi
        asdf plugin add nodejs
        asdf install nodejs "${NODEJS_VERSION_FALLBACK}"
        asdf global nodejs "${NODEJS_VERSION_FALLBACK}"
        node --version
    else
        echo "node version $(node --version) is already installed"
    fi
}

function maybe_install_yarn_as_fallback() {
    if [[ -z "${ASDF_DIR:-}" ]]; then
        if [[ -e "${HOME}/.asdf/asdf.sh" ]]; then
            source "${HOME}/.asdf/asdf.sh"
        fi
    else
        if [[ -e "${ASDF_DIR:-}/asdf.sh" ]]; then
            source "${ASDF_DIR}/asdf.sh"
        fi
    fi

    if [[ -z "$(command -v yarn)" ]]; then
        maybe_install_apt_pkg "gpg" "*"
        maybe_install_apt_pkg "curl" "*"

        if [[ -z "$(command -v asdf)" ]]; then
            maybe_install_asdf_as_fallback
        fi
        asdf plugin add yarn
        asdf install yarn "${YARN_VERSION_FALLBACK}"
        asdf global yarn "${YARN_VERSION_FALLBACK}"
        yarn --version
    else
        echo "yarn version $(yarn --version) is already installed"
    fi
}

function maybe_install_jq_as_fallback() {
    if [[ -z "$(command -v jq)" ]]; then
        echo "Installing jq as a fallback measure"
        if [[ -e "${JQ_INSTALL_SCRIPT}" ]]; then
            "${JQ_INSTALL_SCRIPT}"
        else
            echo "Falling back to remote script ${GITHUB_URL}/bin/install/jq.sh"
            if curl -sIf -o /dev/null ${GITHUB_URL}/bin/install/jq.sh; then
                source <(curl -s "${GITHUB_URL}/bin/install/jq.sh")
            else
                echo "${GITHUB_URL}/bin/install/jq.sh does not exist" >/dev/stderr
                return 1
            fi
        fi
    else
        echo "jq version $(jq --version | tr -d "jq-") is already installed"
    fi
}

function maybe_install_ruby_as_fallback() {
    if [[ -z "${ASDF_DIR:-}" ]]; then
        if [[ -e "${HOME}/.asdf/asdf.sh" ]]; then
            source "${HOME}/.asdf/asdf.sh"
        fi
    else
        if [[ -e "${ASDF_DIR:-}/asdf.sh" ]]; then
            source "${ASDF_DIR}/asdf.sh"
        fi
    fi

    if [[ -z "$(command -v ruby)" ]]; then
        if [[ -z "$(command -v asdf)" ]]; then
            maybe_install_asdf_as_fallback
        fi

        for dep in "${ASDF_RUBY_DEPS[@]}"; do
            maybe_install_apt_pkg "${dep}" "*"
        done

        asdf plugin add ruby
        asdf install ruby "${RUBY_VERSION_FALLBACK}"
        asdf global ruby "${RUBY_VERSION_FALLBACK}"
        ruby --version
    else
        echo "ruby version $(ruby --version) is already installed"
    fi
}

function maybe_install_kubectl_as_fallback() {
    if [[ -z "${ASDF_DIR:-}" ]]; then
        if [[ -e "${HOME}/.asdf/asdf.sh" ]]; then
            source "${HOME}/.asdf/asdf.sh"
        fi
    else
        if [[ -e "${ASDF_DIR:-}/asdf.sh" ]]; then
            source "${ASDF_DIR}/asdf.sh"
        fi
    fi

    if [[ -z "$(command -v kubectl)" ]]; then
        if [[ -z "$(command -v asdf)" ]]; then
            maybe_install_asdf_as_fallback
        fi

        asdf plugin add kubectl
        asdf install kubectl "${KUBECTL_VERSION_FALLBACK}"
        asdf global kubectl "${KUBECTL_VERSION_FALLBACK}"
        kubectl version --short --client
    else
        echo "kubectl version $(kubectl version --short --client | cut -d' ' -f3) is already installed"
    fi
}
