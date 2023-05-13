#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

NERDFONTS_VERSION_FALLBACK=2.3.3

NERD_FONTS_FOR_INSTALLATION=(
    UbuntuMono
    FiraCode
    JetBrainsMono
)

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

function install_nerd_fonts() {
    local version="${1}"

    maybe_install_apt_pkg "git" "*"

    if [[ ! -d "${HOME}/.nerd_fonts" ]]; then
        git clone \
            https://github.com/ryanoasis/nerd-fonts.git \
            --branch "v${version}" \
            --depth 1 \
            "${HOME}/.nerd_fonts"
    fi

    pushd "${HOME}/.nerd_fonts" || exit
    git fetch origin --tags
    git checkout "v${version}"
    chmod +x install.sh
    for font in "${NERD_FONTS_FOR_INSTALLATION[@]}"; do
        sudo ./install.sh \
            --copy \
            --ttf \
            --complete \
            --install-to-system-path \
            "${font}"
    done
    popd || exit

    echo "Nerd font installations complete"
}

function main() {
    local version="${1:-$NERDFONTS_VERSION_FALLBACK}"

    install_nerd_fonts "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
