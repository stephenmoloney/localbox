#!/usr/bin/env bash
set -eu
set -o pipefail
set -o errtrace

NERDCTL_VERSION_FALLBACK=1.6.0

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

function install_nerdctl_containerd() {
    local version="${1}"
    local download_base_url

    download_base_url=https://github.com/containerd/nerdctl/releases/download

    maybe_install_apt_pkg curl "*"
    maybe_install_apt_pkg uidmap "*"
    maybe_install_apt_pkg rootlesskit "*"

    pushd "$(mktemp -d)" || exit
    curl -fsSLO "${download_base_url}/v${version}/nerdctl-${version}-linux-amd64.tar.gz"
    tar zxvf "nerdctl-${version}-linux-amd64.tar.gz"
    sudo systemctl start containerd
    echo "Copying nerdctl to the system path"
    sudo cp ./nerdctl /usr/local/bin/nerdctl
    rm ./nerdctl ./containerd-rootless-setuptool.sh ./containerd-rootless.sh
    popd || exit
}

function main() {
    local version="${1:-$NERDCTL_VERSION_FALLBACK}"

    maybe_install_apt_pkg "containerd.io" "*"
    install_nerdctl_containerd "${version}"
}

if [[ "$0" == "${BASH_SOURCE[0]:-}" ]]; then
    main "${@}"
fi
