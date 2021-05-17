# shellcheck shell=bash disable=SC2148

if [[ -n "$(command -v docker)" ]]; then
    echo \
        "Docker is already installed, these tests should run on a clean image" \
        2>/dev/stderr
    exit 1
fi

EXPECTED_DOCKER_FALLBACK_VERSION="$(
    grep -m 1 DOCKER_VERSION_FALLBACK "${PWD}/bin/install/docker.sh" |
       cut -d'=' -f2 |
       cut -c 3- |
       cut -f1 -d"~"
)"

function setup_install() {
    local version="${1:-}"
    if [[ -z "${version}" ]]; then
        . "${PWD}/bin/install/docker.sh" 2>/dev/null
    else
        . "${PWD}/bin/install/docker.sh" "${version}" 2>/dev/null
    fi
    echo "${FUNCNAME[0]} complete"
}

function setup_uninstall() {
    . "${PWD}/bin/install/docker.sh" 2>/dev/null
    . "${PWD}/bin/uninstall/docker.sh" 2>/dev/null
    echo "${FUNCNAME[0]} complete"
}

function docker_version() {
    docker --version | cut -d' ' -f3 | tr -d ","
}

Describe 'Docker installation with fallback version'
	BeforeAll "setup_install"

	It 'verify fallback version of docker is present'
		When call docker_version
		The stdout should equal "${EXPECTED_DOCKER_FALLBACK_VERSION}"
		The stderr should be blank
		The status should be success
	End
End

Describe 'Docker installation with specified version'
	BeforeAll "setup_install 5:20.10.4~3-0~ubuntu-focal"

	It 'verified specified version of docker is present'
		When call docker_version
		The stdout should equal "20.10.4"
		The stderr should be blank
		The status should be success
	End
End

Describe 'Docker uninstallation removes docker'
    BeforeAll "setup_uninstall"

    It 'verify docker is uninstalled'
		When call docker_version
        The stderr should include "No such file or directory"
        The status should be failure
    End
End
