# shellcheck shell=bash disable=SC2148

if [[ -n "$(command -v asdf)" ]]; then
   echo \
        "asdf is already installed, these tests should run on a clean image" \
        2>/dev/stderr
    exit 1
fi

EXPECTED_ASDF_FALLBACK_VERSION="$(
    grep -m 1 ASDF_VERSION_FALLBACK "${PWD}/bin/install/asdf.sh" |
       cut -d'=' -f2
)"

function setup_install() {
    local version="${1:-}"
    if [[ -z "${version}" ]]; then
        . "${PWD}/bin/install/asdf.sh" 2>/dev/null
    else
        . "${PWD}/bin/install/asdf.sh" "${version}" 2>/dev/null
    fi
    echo "${FUNCNAME[0]} complete"
}

function setup_uninstall() {
    . "${PWD}/bin/install/asdf.sh" 2>/dev/null
    . "${PWD}/bin/uninstall/asdf.sh" 2>/dev/null
    echo "${FUNCNAME[0]} complete"
}

function asdf_version() {
    asdf --version | \
        cut -d' ' -f2 | \
        tr -d "v" | \
        rev | \
        cut -d'-' -f2 | \
        rev
}

Describe 'asdf installation with fallback version'
	BeforeAll "setup_install"

	It 'verify fallback version of asdf is present'
		When call asdf_version
		The stdout should equal "${EXPECTED_ASDF_FALLBACK_VERSION}"
		The stderr should be blank
		The status should be success
	End
End

Describe 'asdf installation with specified version'
	BeforeAll "setup_install 0.7.8"

	It 'verified specified version of asdf is present'
		When call asdf_version
		The stdout should equal "0.7.8"
		The stderr should be blank
		The status should be success
	End
End

Describe 'asdf uninstallation removes asdf'
    BeforeAll "setup_uninstall"

    It 'verify asdf is uninstalled'
		When call asdf_version
        The stderr should not be blank
        The status should be failure
    End
End
