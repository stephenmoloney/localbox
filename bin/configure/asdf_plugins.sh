#!/usr/bin/env bash
# shellcheck disable=SC2125
set -eo pipefail

function setup_java() {
    if [[ -e "${HOME}/.asdf/plugins/java/set-java-home.bash" ]]; then
        source "${HOME}/.asdf/plugins/java/set-java-home.bash"
    fi
}

function setup_kubectl_dotfiles() {
    if [[ ! -e "${HOME}/.kube/config" ]]; then
        cp \
            "${PROJECT_ROOT}/config/dotfiles/kube/config.yml" \
            "${HOME}/.kube/config"
    fi
}

function setup_kubectl() {
    # Add kubectl completion
    if [[ -z "$(command -v kubectl)" ]]; then
        kubectl completion bash >"${HOME}/.bash_completion.d/kubectl"
        source "${HOME}/.bash_completion.d/kubectl"
    fi
    # Concatenate the kubeconfig files into the ~/.kube/config file
    # Exclude files with the string prod in the name
    if [[ -d "${HOME}/.kube" ]]; then
        if [[ ! -e "${HOME}/.kube/config" ]]; then
            setup_kubectl_dotfiles
        fi
        while IFS=' ' read -r -a kubeconfig_files; do
            if [[ "${kubeconfig_files[0]}" != *"prod"* ]]; then
                if [[ -z "$(grep "${kubeconfig_files[0]}" <<<"${KUBECONFIG}" 2>/dev/null || true)" ]]; then
                    if [[ -z "${KUBECONFIG}" ]]; then
                        export KUBECONFIG="${kubeconfig_files[0]}"
                    else
                        export KUBECONFIG="${KUBECONFIG}:${kubeconfig_files[0]}"
                    fi
                fi
            fi
        done < <(ls -A "${HOME}"/.kube/*)
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
    local terminal_application
    # shellcheck disable=SC2046
    terminal_application="$(pstree -sA $$ | awk -F "---" '{ print $3 }')"

    # Use alternate status tool in gnome terminal (will default to powerline for example)
    if [[ "${terminal_application}" != "gnome-terminal" ]]; then
        if [[ -n "$(starship --version)" ]]; then
            eval "$(starship init bash)"
        fi
    fi
}

function setup_yq() {
    if [[ -z "$(command -v yq)" ]]; then
        yq shell-completion bash >"${HOME}/bash_completion.d/yq"
        source"${HOME}/bash_completion.d/yq"
    fi
}
