# shellcheck shell=bash disable=SC2148

if [[ -n "$(command -v rustc)" ]]; then
    echo \
        "Rust is already installed, these tests should run on a clean image" \
        2>/dev/stderr
    exit 1
fi

EXPECTED_RUST_VERSION_FALLBACK="$(
    grep -m 1 RUST_VERSION_FALLBACK "${PWD}/bin/install/rust.sh" |
       cut -d'=' -f2
)"

function setup_install() {
    local version="${1:-}"
	echo "Starting setup_install"
    if [[ -z "${version}" ]]; then
        . "${PWD}/bin/install/rust.sh" 2>/dev/null
    else
        . "${PWD}/bin/install/rust.sh" "${version}" 2>/dev/null
    fi
    source "${HOME}/.cargo/env"
	echo "Setup complete"
}

function setup_uninstall() {
	echo "Starting setup_uninstall"
    source "${HOME}/.cargo/env"
    . "${PWD}/bin/uninstall/rust.sh" 2>/dev/null
	echo "Setup complete"
}

function rust_version() {
	rustc --version | cut -d' ' -f2
}

function cargo_version() {
	cargo --version | cut -d' ' -f2
}

function rustup_show() {
    rustup show
}

Describe 'Rust installation with fallback version'
	BeforeAll "setup_install"

	It 'installs rustup'
		When call rustup_show
		The stdout should include "Default host: x86_64-unknown-linux-gnu"
		The stderr should be blank
		The status should be success
	End
	It 'installs cargo'
		When call cargo_version
		The stdout should equal "${EXPECTED_RUST_VERSION_FALLBACK}"
		The stderr should be blank
		The status should be success
	End
	It 'installs the expected version of rust'
		When call rust_version
		The stdout should equal "${EXPECTED_RUST_VERSION_FALLBACK}"
		The stderr should be blank
		The status should be success
	End
End

Describe 'Rust installation with specified version'
	BeforeAll "setup_install 1.49.0"

	It 'installs cargo'
		When call cargo_version
        The stdout should equal "1.49.0"
		The stderr should be blank
		The status should be success
	End
	It 'installs the expected version of rust'
		When call rust_version
		The stdout should equal "1.49.0"
		The stderr should be blank
		The status should be success
	End
    It 'installs the expected version of rust'
		When call rust_version
		The stdout should equal "1.49.0"
		The stderr should be blank
		The status should be success
	End
End

Describe 'Rust installation removes rust and rustup'
    BeforeAll "setup_uninstall"

    It 'uninstalls cargo'
        When call cargo_version
        The stderr should include "command not found"
        The status should be failure
    End
    It 'uninstalls rustc'
        When call rustc_version
        The stderr should include "command not found"
        The status should be failure
    End
    It 'uninstalls rustup'
        When call rustup_show
        The stderr should include "No such file or directory"
        The status should be failure
    End
End
