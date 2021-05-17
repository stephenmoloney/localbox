# shellcheck shell=bash disable=SC2148

declare -A DEBIAN_PKGS_TEST
DEBIAN_PKGS_TEST=(
    ["bash-completion"]="*"
    ["dialog"]="*"
    ["exuberant-ctags"]="*"
    ["git"]="*"
    ["gitk"]="*"
    ["git-cola"]="*"
	["gnome-tweak-tool"]="*"
	["gnupg"]="*"
	["httpie"]="*"
    ["libarchive-tools"]="*"
	["libhidapi-dev"]="*"
	["lsb-release"]="*"
	["libssl-dev"]="*"
	["nnn"]="*"
	["openvpn"]="*"
	["openssl"]="*"
	["python-is-python3"]="*"
	["python3-pip"]="*"
	["python3-setuptools"]="*"
	["tmux"]="*"
	["tree"]="*"
	["unzip"]="*"
	["wget"]="*"
	["xsel"]="*"
)

function setup_install() {
    . "${PWD}/bin/install/debian_pkgs.sh" 2>/dev/null
    echo "${FUNCNAME[0]} complete"
}

function setup_uninstall() {
    . "${PWD}/bin/uninstall/debian_pkgs.sh" 2>/dev/null
    echo "${FUNCNAME[0]} complete"
}

function verify_package_installed() {
    local pkg="${1}"
    local installed_pkgs
    installed_pkgs="$(sudo apt list --installed 2>/dev/null)"

    grep "${pkg}/" <<< "${installed_pkgs}"
}

function verify_package_uninstalled() {
    local pkg="${1}"
    verify_package_installed "${pkg}"
}

Describe 'Debian packages are installed'
    BeforeAll "setup_install"

    Parameters:dynamic
        for pkg in "${!DEBIAN_PKGS_TEST[@]}"; do
            %data "${pkg}"
        done
    End

    It "Verify presence of ${1}"
        When call verify_package_installed "${1}"
        The stdout should not be blank
        The status should be success
    End
End

Describe 'Debian packages are uninstalled'
	BeforeAll "setup_uninstall"

    Parameters:dynamic
        for pkg in "${!DEBIAN_PKGS_TEST[@]}"; do
            %data "${pkg}"
        done
    End

    It "Verify absence of ${1}"
        When call verify_package_uninstalled "${1}"
        The status should be failure
    End
End
