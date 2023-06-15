#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

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
PROJECT_ROOT="$(project_root)"

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

maybe_install_asdf_as_fallback # asdf required for asdf plugins installation
maybe_install_jq_as_fallback   # jq required for go-jsonnet installation
maybe_install_go_as_fallback   # go required for go-jsonnet installation

# shellcheck disable=SC2034
export ASDF_WEBSOCAT_DISTRO=websocat.x86_64-unknown-linux-musl

ASDF_ERLANG_DEPS=(
    autoconf
    build-essential
    fop
    libncurses5-dev
    libwxgtk3.0-gtk3-dev
    libgl1-mesa-dev
    libglu1-mesa-dev
    libpng-dev
    libssh-dev
    libxml2-utils
    m4
    openssl
    xsltproc
)

ASDF_NODEJS_DEPS=(
    dirmngr
    gpg
    curl
)

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
# shellcheck shell=bash disable=SC2034
ASDF_GROOVY_DISABLE_JAVA_HOME_EXPORT=true

function install_asdf_plugins() {
    local plugins
    local plugin
    local plugin_versions

    # Potentially required dependencies
    maybe_install_apt_pkg "libreadline-dev" "*"

    # Required for nodejs amd yarn
    for dep in "${ASDF_NODEJS_DEPS[@]}"; do
        maybe_install_apt_pkg "${dep}" "*"
    done

    # Required for erlang
    for dep in "${ASDF_ERLANG_DEPS[@]}"; do
        maybe_install_apt_pkg "${dep}" "*"
    done

    export KERL_CONFIGURE_OPTIONS="--disable-debug --without-odbc --without-javac"
    export KERL_BUILD_DOCS=yes
    export KERL_BASE_DIR="${HOME}/.kerl"

    # asdf-gcloud should try python3 as gcloud now supports it.
    # python-is-python3 package is a workaround
    export CLOUDSDK_PYTHON=python3
    maybe_install_apt_pkg "python-is-python3" "*"
    if [[ ! -d "${HOME}/.config/gcloud/" ]]; then
        mkdir -p "${HOME}/.config/gcloud"
    fi
    cp \
        "${PROJECT_ROOT}/config/dotfiles/gcloud/default-cloud-sdk-components" \
        "${HOME}/.config/gcloud/.default-cloud-sdk-components"

    #  Required for ruby
    for dep in "${ASDF_RUBY_DEPS[@]}"; do
        maybe_install_apt_pkg "${dep}" "*"
    done

    mapfile -t plugins <"${PROJECT_ROOT}/config/dotfiles/asdf/tool-versions"

    for plugin in "${plugins[@]}"; do
        IFS=' ' read -r -a plugin_array <<<"${plugin}"
        plugin="${plugin_array[0]}"
        plugin_versions=("${plugin_array[@]:1}")

        if [[ "$(
            asdf plugin list | grep -w "${plugin}" >/dev/null 2>&1
            echo $?
        )" -gt 0 ]]; then
            asdf plugin add "${plugin}"
        fi

        for plugin_version in "${plugin_versions[@]}"; do
            if [[ "${plugin_version}" != "system" ]]; then
                asdf install "${plugin}" "${plugin_version}"
            fi
        done

        # Set the global version to the first one in the array
        if [[ "${plugin_versions[0]:-}" != "system" ]]; then
            if [[ ! -e "${HOME}"/.tool-versions ]]; then
                touch "${HOME}"/.tool-versions
            fi
            echo "Setting ${plugin} to version ${plugin_versions[0]}"
            asdf global "${plugin}" "${plugin_versions[0]}"
        fi
    done
}

function install_gcloud_components() {
    local gcloud_components

    mapfile -t gcloud_components <"${PROJECT_ROOT}/config/dotfiles/gcloud/default-cloud-sdk-components"

    for component in "${gcloud_components[@]}"; do
        gcloud components install "${component}"
    done
}

function main() {
    source "${HOME}/.asdf/asdf.sh"
    install_asdf_plugins
    install_gcloud_components
    gcloud components update
}

# shellcheck disable=SC2086
# Cleanup
if [[ -n "$(ls -A ${PROJECT_ROOT}/asdf-helm.* 2>/dev/null || true)" ]]; then
    rm -rf "${PROJECT_ROOT}/asdf-helm.*"
fi

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main
fi
