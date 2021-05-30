#!/usr/bin/env bash
set -eo pipefail

LIGHT_PROFILES=(
    github
    lunaria-light
    pencil-light
)

DARK_PROFILES=(
    azu
    blazer
    chalk
    chalkboard
    lunaria-dark
    lunaria-eclipse
    miu
    nord
    seafoam-pastel
    slate
    tin
    zenburn
)

ALL_PROFILES=("${LIGHT_PROFILES[@]}" "${DARK_PROFILES[@]}")

SELECTED_THEME="${1:-Azu}"

function get_name_from_uuid() {
    local uuid="${1}"

    gsettings get \
        org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"${uuid}"/ \
        visible-name |
        tr -d "'"
}

function find_uuid_from_name() {
    local name="${1}"
    local uuids

    # shellcheck disable=SC2162
    read -a uuids <<<"$(gsettings get org.gnome.Terminal.ProfilesList list | tr -d "[]\',")"

    for uuid in "${uuids[@]}"; do
        if [[ "${name}" == "$(get_name_from_uuid "${uuid}")" ]]; then
            echo "${uuid}"
        fi
    done
}

function setup_gnome_terminal_profiles() {
    local selected_theme="${1:-$SELECTED_THEME}"
    local profile

    # local selected_theme_uuid
    # selected_theme_uuid="$(find_uuid_from_name "${selected_theme}")"

    dconf reset -f /org/gnome/terminal/
    profile="$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")"

    gsettings set \
        "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile}/" \
        visible-name \
        "default"

    pushd "${HOME}/src/open/gogh/themes" || exit
    for profile in "${ALL_PROFILES[@]}"; do
        echo "Installing the ${profile} theme"
        export TERMINAL="gnome-terminal"
        bash -c "./${profile}.sh"
        unset TERMINAL
    done
    popd || exit

    cat <<EOF | sudo tee /usr/share/applications/org.gnome.Terminal.desktop
[Desktop Entry]
# VERSION=3.36.2
Name=Terminal
Comment=Use the command line
Keywords=shell;prompt;command;commandline;cmd;
TryExec=gnome-terminal
Exec=gnome-terminal
Icon=org.gnome.Terminal
Type=Application
Categories=GNOME;GTK;System;TerminalEmulator;
StartupNotify=true
X-GNOME-SingleWindow=false
OnlyShowIn=GNOME;Unity;
Actions=new-window;preferences;
X-Ubuntu-Gettext-Domain=gnome-terminal

[Desktop Action new-window]
Name=New Window
Exec=gnome-terminal --tab-with-profile=${selected_theme} --tab-with-profile=${selected_theme} --tab-with-profile=${selected_theme}

[Desktop Action preferences]
Name=Preferences
Exec=gnome-terminal --preferences
EOF

    sudo chmod 644 /usr/share/applications/org.gnome.Terminal.desktop
}
