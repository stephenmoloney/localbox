#!/usr/bin/env bash
# shellcheck disable=SC2125,SC2155
set -eu
set -o pipefail
set -o errtrace

ex_community_plugin=(
    "herdr"
    "kyverno"
)
ex_community_plugin_url=(
    "https://github.com/RobLoach/asdf-herdr.git"
    "https://github.com/hobaen/asdf-kyverno-cli.git"
)

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
PROJECT_ROOT="$(project_root)"

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
    libwxgtk3.2-dev
    libgl1-mesa-dev
    libglu1-mesa-dev
    libpng-dev
    libssh-dev
    libxml2-utils
    m4
    openssl
    xsltproc
)

ASDF_PYTHON_DEPS=(
    make
    build-essential
    libssl-dev
    zlib1g-dev
    libbz2-dev
    libreadline-dev
    curl
    git
    libncursesw5-dev
    xz-utils
    tk-dev
    libxml2-dev
    libxmlsec1-dev
    libffi-dev
    liblzma-dev
    libsqlite3-dev
)

ASDF_NEOVIM_DEPS=(
    make
    gcc
    ripgrep
    fd-find
    tree-sitter-cli
    unzip
    git
    xclip
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

# Overcome an issue installing poetry
# shellcheck disable=SC2034
ASDF_INSTALL_TYPE=

# Detect container runtimes (docker writes /.dockerenv, podman writes
# /run/.containerenv). Used to skip GUI-heavy build steps such as the
# wx application of Erlang/OTP, which are useless headless.
function in_container() {
    [[ -e /.dockerenv ]] ||
        [[ -e /run/.containerenv ]]
}

function install_asdf_plugins() {
    local python_current_version
    local plugins
    local plugin
    local plugin_versions
    local ex_url
    local i

    maybe_install_apt_pkgs \
        "libreadline-dev" \
        "${ASDF_NODEJS_DEPS[@]}" \
        "${ASDF_NEOVIM_DEPS[@]}" \
        "${ASDF_ERLANG_DEPS[@]}" \
        "${ASDF_PYTHON_DEPS[@]}" \
        "${ASDF_RUBY_DEPS[@]}"

    export KERL_CONFIGURE_OPTIONS="--disable-debug --without-odbc --without-javac"
    # Skip the wx GUI application inside containers: it needs wxWidgets
    # dev packages that a headless image doesn't carry, and adds a large
    # amount of build time for something unusable without a display
    if in_container; then
        export KERL_CONFIGURE_OPTIONS="${KERL_CONFIGURE_OPTIONS} --without-wx"
    fi
    export KERL_BUILD_DOCS=yes
    export KERL_BASE_DIR="${HOME}/.kerl"

    if [[ ! -d "${HOME}/.config/gcloud/" ]]; then
        mkdir -p "${HOME}/.config/gcloud"
    fi
    cp \
        "${PROJECT_ROOT}/config/dotfiles/gcloud/default-cloud-sdk-components" \
        "${HOME}/.config/gcloud/.default-cloud-sdk-components"

    # One tool per line; strip comments and blank lines
    mapfile -t plugins < <(grep -vE '^[[:space:]]*(#|$)' \
        "${PROJECT_ROOT}/config/dotfiles/asdf/tool-versions")

    for plugin in "${plugins[@]}"; do
        IFS=' ' read -r -a plugin_array <<<"${plugin}"
        plugin="${plugin_array[0]}"
        plugin_versions=("${plugin_array[@]:1}")

        # Resolve custom URL for community plugins (empty if not in the list)
        ex_url=""
        for i in "${!ex_community_plugin[@]}"; do
            if [[ "${plugin}" == "${ex_community_plugin[i]}" ]]; then
                ex_url="${ex_community_plugin_url[i]:-}"
                break
            fi
        done

        # Idempotent: skip plugins that are already registered
        if asdf plugin list 2>/dev/null | grep -qx -- "${plugin}"; then
            echo "Plugin ${plugin} already added, skipping"
        elif [[ -n "${ex_url}" ]]; then
            echo "Adding community plugin ${ex_url}"
            asdf plugin add "${plugin}" "${ex_url}"
        else
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
            asdf set --home "${plugin}" "${plugin_versions[0]}"
        fi
    done

    # Must run AFTER the plugin loop: python is registered and installed
    # by the loop, and in a fresh container (CI) it does not exist before
    # that — asdf list python would abort with "No such plugin: python"
    if asdf plugin list 2>/dev/null | grep -qx "python"; then
        python_current_version="$(asdf list python | awk NR==1 | xargs)"
        export CLOUDSDK_PYTHON="$(readlink -f "${HOME}"/.asdf/installs/python/"${python_current_version}"/bin/python3)"
    else
        echo "python plugin not present, skipping CLOUDSDK_PYTHON setup"
    fi
}

function install_gcloud_components() {
    local gcloud_components

    mapfile -t gcloud_components <"${PROJECT_ROOT}/config/dotfiles/gcloud/default-cloud-sdk-components"

    export CLOUDSDK_CORE_DISABLE_PROMPTS=1
    gcloud config set disable_usage_reporting true

    for component in "${gcloud_components[@]}"; do
        gcloud --quiet components install "${component}"
    done
}

function main() {
    export ASDF_DATA_DIR="${HOME}"/.asdf
    export PATH="${PATH}:${ASDF_DATA_DIR}/shims"
    install_asdf_plugins
    install_gcloud_components
    gcloud components update
}

# shellcheck disable=SC2086
# Cleanup
if [[ -n "$(ls -A ${PROJECT_ROOT}/asdf-helm.* 2>/dev/null || true)" ]]; then
    rm -rf "${PROJECT_ROOT}/asdf-helm.*"
fi

if [[ "$0" == "${BASH_SOURCE[0]:-}" ]]; then
    main
fi
