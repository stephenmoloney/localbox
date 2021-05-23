#!/usr/bin/env bash
# shellcheck disable=SC2125
set -eo pipefail

function setup_java() {
    if [[ -e "${HOME}/.asdf/plugins/java/set-java-home.bash" ]]; then
        source "${HOME}/.asdf/plugins/java/set-java-home.bash"
    fi
}

function setup_kubectl() {
    if [[ -z "$(command -v kubectl)" ]]; then
        kubectl completion bash >"${HOME}/.bash_completion.d/kubectl"
        source "${HOME}/.bash_completion.d/kubectl"
    fi
}

function setup_gcloud() {
    local gcloud_version

    if [[ -z "$(command -v gcloud)" ]]; then
        gcloud_version="$(gcloud --version | awk NR==1 | awk '{print $4}')"
        if [[ -e "${HOME}/.asdf/installs/gcloud/${gcloud_version}/completion.bash.inc" ]]; then
            source "${HOME}/.asdf/installs/gcloud/${gcloud_version}/completion.bash.inc"
        fi
        if [[ -e "${HOME}/.asdf/installs/gcloud/${gcloud_version}/path.bash.inc" ]]; then
            source "${HOME}/.asdf/installs/gcloud/${gcloud_version}/path.bash.inc"
        fi
    fi
}

function setup_starship() {
    if [[ -n "$(starship --version)" ]]; then
        eval "$(starship init bash)"
    fi
}

function setup_yq() {
    if [[ -z "$(command -v yq)" ]]; then
        yq shell-completion bash >"${HOME}/bash_completion.d/yq"
        source"${HOME}/bash_completion.d/yq"
    fi
}
