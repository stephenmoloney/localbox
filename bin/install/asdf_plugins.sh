#!/usr/bin/env bash
set -Eeuo pipefail

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
        . <(curl -s "${GITHUB_URL}/bin/fallbacks.sh")
    else
        echo "${GITHUB_URL}/bin/fallbacks.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ****************************************************************************

# go-jsonnet dependencies
maybe_install_jq_as_fallback
maybe_install_go_as_fallback

function install_asdf_plugins() {
    local plugins
    local plugin
    local plugin_versions

    # Potentially required dependencies
    maybe_install_apt_pkg "libreadline-dev" "*"

    # Required for nodejs amd yarn
    maybe_install_apt_pkg "dirmngr" "*"
    maybe_install_apt_pkg "gpg" "*"
    maybe_install_apt_pkg "curl" "*"

    # Required for erlang
    maybe_install_apt_pkg "curl" "*"
    maybe_install_apt_pkg "build-essential" "*"
    maybe_install_apt_pkg "autoconf" "*"
    maybe_install_apt_pkg "libncurses5-dev" "*"
    maybe_install_apt_pkg "libwxgtk3.0-gtk3-dev" "*"
    maybe_install_apt_pkg "libgl1-mesa-dev" "*"
    maybe_install_apt_pkg "libglu1-mesa-dev" "*"
    maybe_install_apt_pkg "libpng-dev" "*"
    maybe_install_apt_pkg "libssh-dev" "*"
    maybe_install_apt_pkg "openssl" "*"
    maybe_install_apt_pkg "m4" "*"
    maybe_install_apt_pkg "xsltproc" "*"
    maybe_install_apt_pkg "fop" "*"
    maybe_install_apt_pkg "libxml2-utils" "*"

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
        "${HOME}/.config/gcloud/.default-cloud-sdk-componentsi"

    mapfile -t plugins <"${PROJECT_ROOT}/config/dotfiles/asdf/tool-versions"

    for plugin in "${plugins[@]}"; do
        IFS=' ' read -r -a plugin_array <<<"${plugin}"
        plugin="${plugin_array[0]}"
        plugin_versions=("${plugin_array[@]:1}")

        if [[ "$(
            asdf plugin list | grep -w "${plugin}" >/dev/null 2>&1
            echo $?
        )" -gt 0 ]]; then
            # Waiting on merge https://github.com/vaynerx/asdf-linkerd/pull/4
            if [[ "${plugin}" == "linkerd" ]]; then
                asdf plugin add "${plugin}" "https://github.com/stephenmoloney/asdf-linkerd"
            else
                asdf plugin add "${plugin}"
            fi
        fi

        for plugin_version in "${plugin_versions[@]}"; do
            if [[ "${plugin_version}" != "system" ]]; then
                asdf install "${plugin}" "${plugin_version}"
            fi
        done

        # Set the global version to the first one in the array
        if [[ "${plugin_versions[0]:-}" != "system" ]]; then
            echo "Setting ${plugin} to version ${plugin_versions[0]}"
            asdf global "${plugin}" "${plugin_versions[0]}"
        fi
    done
}

# shellcheck disable=SC2086
# Cleanup
if [[ -n "$(ls -A ${PROJECT_ROOT}/asdf-helm.* 2>/dev/null || true)" ]]; then
    rm -rf "${PROJECT_ROOT}/asdf-helm.*"
fi

install_asdf_plugins
