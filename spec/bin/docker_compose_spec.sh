# shellcheck shell=bash disable=SC2148

if [[ -n "$(command -v docker-compose)" ]]; then
    echo \
        "Docker is already installed, these tests should run on a clean image" \
        2>/dev/stderr
    exit 1
fi

EXPECTED_DOCKER_COMPOSE_FALLBACK_VERSION="$(
    grep -m 1 DOCKER_COMPOSE_VERSION_FALLBACK "${PWD}/bin/install/docker_compose.sh" |
       cut -d'=' -f2
)"

function setup_install() {
    local version="${1:-}"
    if [[ -z "${version}" ]]; then
        . "${PWD}/bin/install/docker_compose.sh" 2>/dev/null
    else
        . "${PWD}/bin/install/docker_compose.sh" "${version}" 2>/dev/null
    fi
    echo "${FUNCNAME[0]} complete"
}

function setup_uninstall() {
    . "${PWD}/bin/install/docker_compose.sh" 2>/dev/null
    . "${PWD}/bin/uninstall/docker_compose.sh" 2>/dev/null
    echo "${FUNCNAME[0]} complete"
}

function docker_compose_version() {
    docker-compose --version | cut -d' ' -f3 | tr -d ","
}

Describe 'docker-compose installation with fallback version'
	BeforeAll "setup_install"

	It 'verify fallback version of docker compose is present'
		When call docker_compose_version
		The stdout should equal "${EXPECTED_DOCKER_COMPOSE_FALLBACK_VERSION}"
		The stderr should be blank
		The status should be success
	End
End

Describe 'Docker installation with specified version'
	BeforeAll "setup_install 1.28.4"

	It 'verified specified version of docker-compose is present'
		When call docker_compose_version
		The stdout should equal "1.28.4"
		The stderr should be blank
		The status should be success
	End
End

Describe 'Docker uninstallation removes docker_compose'
    BeforeAll "setup_uninstall"

    It 'verify docker_compose is uninstalled'
		When call docker_compose_version
        The stderr should include "No such file or directory"
        The status should be failure
    End
End
