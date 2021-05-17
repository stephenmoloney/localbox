# shellcheck shell=bash disable=SC2148

if [[ -n "$(command -v yamllint)" ]]; then
   echo \
        "yamllint is already installed, these tests should run on a clean image" \
        2>/dev/stderr
    exit 1
fi

EXPECTED_YAMLLINT_FALLBACK_VERSION="$(
    grep -m 1 YAMLLINT_VERSION_FALLBACK "${PWD}/bin/install/yamllint.sh" |
       cut -d'=' -f2
)"

function setup_install() {
    local version="${1:-}"
    if [[ -z "${version}" ]]; then
        . "${PWD}/bin/install/yamllint.sh" 2>/dev/null
    else
        . "${PWD}/bin/install/yamllint.sh" "${version}" 2>/dev/null
    fi
    echo "${FUNCNAME[0]} complete"
}

function setup_uninstall() {
    . "${PWD}/bin/install/yamllint.sh" 2>/dev/null
    . "${PWD}/bin/uninstall/yamllint.sh" 2>/dev/null
    echo "${FUNCNAME[0]} complete"
}

function yamllint_version() {
    yamllint --version | cut -d' ' -f2
}

Describe 'yamllint installation with fallback version'
	BeforeAll "setup_install"

	It 'verify fallback version of yamllint is present'
		When call yamllint_version
		The stdout should equal "${EXPECTED_YAMLLINT_FALLBACK_VERSION}"
		The stderr should be blank
		The status should be success
	End
End

Describe 'yamllint installation with specified version'
	BeforeAll "setup_install 1.26.0"

	It 'verified specified version of yamllint is present'
		When call yamllint_version
		The stdout should equal "1.26.0"
		The stderr should be blank
		The status should be success
	End
End

Describe 'yamllint uninstallation removes yamllint'
    BeforeAll "setup_uninstall"

    It 'verify yamllint is uninstalled'
		When call yamllint_version
        The stderr should include "No such file or directory"
        The status should be failure
    End
End
