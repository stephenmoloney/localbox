# shellcheck shell=bash disable=SC2148

if [[ -n "$(command -v shfmt)" ]]; then
   echo \
        "Shfmt is already installed, these tests should run on a clean image" \
        2>/dev/stderr
    exit 1
fi

EXPECTED_SHFMT_FALLBACK_VERSION="$(
    grep -m 1 SHFMT_VERSION_FALLBACK "${PWD}/bin/install/shfmt.sh" |
       cut -d'=' -f2
)"

function setup_install() {
    local version="${1:-}"
    if [[ -z "${version}" ]]; then
        . "${PWD}/bin/install/shfmt.sh" 2>/dev/null
    else
        . "${PWD}/bin/install/shfmt.sh" "${version}" 2>/dev/null
    fi
    echo "${FUNCNAME[0]} complete"
}

function setup_uninstall() {
    . "${PWD}/bin/install/shfmt.sh" 2>/dev/null
    . "${PWD}/bin/uninstall/shfmt.sh" 2>/dev/null
    echo "${FUNCNAME[0]} complete"
}

function shfmt_version() {
    shfmt --version | tr -d "v"
}

Describe 'shfmt installation with fallback version'
	BeforeAll "setup_install"

	It 'verify fallback version of shfmt is present'
		When call shfmt_version
		The stdout should equal "${EXPECTED_SHFMT_FALLBACK_VERSION}"
		The stderr should be blank
		The status should be success
	End
End

Describe 'shfmt installation with specified version'
	BeforeAll "setup_install 3.2.3"

	It 'verified specified version of shfmt is present'
		When call shfmt_version
		The stdout should equal "3.2.3"
		The stderr should be blank
		The status should be success
	End
End

Describe 'shfmt uninstallation removes shfmt'
    BeforeAll "setup_uninstall"

    It 'verify shfmt is uninstalled'
		When call shfmt_version
        The stderr should include "No such file or directory"
        The status should be failure
    End
End
