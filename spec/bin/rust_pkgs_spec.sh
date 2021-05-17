# shellcheck shell=bash disable=SC2148

declare -A TEST_RUST_PKGS
export TEST_RUST_PKGS=(
    ["bat"]="BAT_VERSION"
    ["bottom"]="BOTTOM_VERSION"
    ["code-minimap"]="CODE_MINIMAP_VERSION"
    ["du-dust"]="DU_DUST_VERSION"
    ["exa"]="EXA_VERSION"
    ["fd-find"]="FD_FIND_VERSION"
    ["git-delta"]="GIT_DELTA_VERSION"
    ["hyperfine"]="HYPERFINE_VERSION"
    ["just"]="JUST_VERSION"
    ["lsd"]="LSD_VERSION"
    ["nitrocli"]="NITROCLI_VERSION"
    ["ripgrep"]="RIPGREP_VERSION"
    ["procs"]="PROCS_VERSION"
    ["spotify-tui"]="SPOTIFY_TUI_VERSION"
    ["tealdeer"]="TEALDEER_VERSION"
    ["tre"]="TRE_VERSION"
    ["viu"]="VIU_VERSION"
)

for pkg in "${!RUST_PKGS[@]}"; do
    if [[ -n "$(command -v "${pkg}")" ]]; then
        echo \
            "${pkg} is already installed, these tests should run on a clean image" \
            2>/dev/stderr
        exit 1
    fi
done

function setup_install() {
    echo "Starting ${FUNCNAME[0]}"
    . "${PWD}/bin/install/rust_pkgs.sh" 2>/dev/null
    echo "${FUNCNAME[0]} complete"
}

function setup_uninstall() {
    echo "Starting ${FUNCNAME[0]}"
    "${PWD}/bin/install/rust_pkgs.sh" 2>/dev/null
    "${PWD}/bin/uninstall/rust_pkgs.sh" 2>/dev/null
    echo "${FUNCNAME[0]} complete"
}

function teardown_install() {
    # "${PWD}/bin/uninstall/bat.sh" 2>/dev/null
    "${PWD}/bin/uninstall/rust_pkgs.sh" 2>/dev/null
    echo "${FUNCNAME[0]} complete"
}

function teardown_uninstall() {
    echo "${FUNCNAME[0]} complete"
}

function actual_pkg_version() {
    local pkg="${1}"

    source "${HOME}/.cargo/env"
    cargo install --list | grep -m 1 "${pkg}" | cut -d' ' -f2 | tr -d '[:][v]'
}

function expected_fallback_version() {
    local pkg="${1}"

    (grep -m 1 "${pkg}_FALLBACK" "${PWD}/bin/install/rust_pkgs.sh") | cut -d'=' -f2
}

Describe 'rust package installation with fallback version'
    BeforeAll "setup_install"
    AfterAll "teardown_install"

    Parameters:dynamic
        for pkg in "${!TEST_RUST_PKGS[@]}"; do
            %data "${pkg}" "${TEST_RUST_PKGS[$pkg]}"
        done
    End

    It "installs rust package ($1) fallback version"
        actual_pkg_version="$(actual_pkg_version "$1")"
        expected_fallback_version="$(expected_fallback_version "$2")"
        %logger "$1 actual version is ${actual_pkg_version}, $1 expected version is ${expected_fallback_version}"
        When call actual_pkg_version "$1"
        The stdout should equal "${expected_fallback_version}"
        The stderr should be blank
        The status should be success
        Assert [ "${actual_pkg_version}" = "${expected_fallback_version}" ]
    End
End
