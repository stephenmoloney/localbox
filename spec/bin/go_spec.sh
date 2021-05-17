# shellcheck shell=bash disable=SC2148

if [[ -n "$(command -v go)" ]]; then
    echo \
        "Go is already installed, these tests should run on a clean image" \
        2>/dev/stderr
    exit 1
fi

EXPECTED_GO_FALLBACK_VERSION="$(
    grep -m 1 GO_VERSION_FALLBACK "${PWD}/bin/install/go.sh" |
       cut -d'=' -f2
)"

function setup_install() {
    local version="${1:-}"
    if [[ -z "${version}" ]]; then
        . "${PWD}/bin/install/go.sh" 2>/dev/null
    else
        . "${PWD}/bin/install/go.sh" "${version}" 2>/dev/null
    fi
    echo "${FUNCNAME[0]} complete"
}

function setup_uninstall() {
    . "${PWD}/bin/install/go.sh" 2>/dev/null
    . "${PWD}/bin/uninstall/go.sh" 2>/dev/null
    echo "${FUNCNAME[0]} complete"
}

function go_version() {
    go version | cut -d' ' -f3 | tr -d "go"
}

Describe 'go installation with fallback version'
	BeforeAll "setup_install"

	It 'verify fallback version of go is present'
		When call go_version
		The stdout should equal "${EXPECTED_GO_FALLBACK_VERSION}"
		The stderr should be blank
		The status should be success
	End
End

Describe 'go installation with specified version'
	BeforeAll "setup_install 1.15.7"

	It 'verified specified version of go is present'
		When call go_version
		The stdout should equal "1.15.7"
		The stderr should be blank
		The status should be success
	End
End

Describe 'go uninstallation removes go'
    BeforeAll "setup_uninstall"

    It 'verify go is uninstalled'
		When call go_version
        The stderr should include "No such file or directory"
        The status should be failure
    End
End
