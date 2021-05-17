# shellcheck shell=bash disable=SC2148

if [[ -n "$(command -v shellcheck)" ]]; then
   echo \
        "shellcheck is already installed, these tests should run on a clean image" \
        2>/dev/stderr
    exit 1
fi

EXPECTED_SHELLCHECK_FALLBACK_VERSION="$(
    grep -m 1 SHELLCHECK_VERSION_FALLBACK "${PWD}/bin/install/shellcheck.sh" |
       cut -d'=' -f2
)"

function setup_install() {
    local version="${1:-}"
    if [[ -z "${version}" ]]; then
        . "${PWD}/bin/install/shellcheck.sh" 2>/dev/null
    else
        . "${PWD}/bin/install/shellcheck.sh" "${version}" 2>/dev/null
    fi
    echo "${FUNCNAME[0]} complete"
}

function setup_uninstall() {
    . "${PWD}/bin/install/shellcheck.sh" 2>/dev/null
    . "${PWD}/bin/uninstall/shellcheck.sh" 2>/dev/null
    echo "${FUNCNAME[0]} complete"
}

function shellcheck_version() {
    shellcheck --version | awk NR==2 | cut -d' ' -f2
}

Describe 'shellcheck installation with fallback version'
	BeforeAll "setup_install"

	It 'verify fallback version of shellcheck is present'
		When call shellcheck_version
		The stdout should equal "${EXPECTED_SHELLCHECK_FALLBACK_VERSION}"
		The stderr should be blank
		The status should be success
	End
End

Describe 'shellcheck installation with specified version'
	BeforeAll "setup_install 0.7.0"

	It 'verified specified version of shellcheck is present'
		When call shellcheck_version
		The stdout should equal "0.7.0"
		The stderr should be blank
		The status should be success
	End
End

Describe 'shellcheck uninstallation removes shellcheck'
    BeforeAll "setup_uninstall"

    It 'verify shellcheck is uninstalled'
		When call shellcheck_version
        The stderr should include "No such file or directory"
        The status should be failure
    End
End
