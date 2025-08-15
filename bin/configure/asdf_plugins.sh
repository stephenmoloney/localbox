#!/usr/bin/env bash
# shellcheck disable=SC2155
set -eo pipefail

function setup_java() {
    if [[ -e "${HOME}/.asdf/plugins/java/set-java-home.bash" ]]; then
        source "${HOME}/.asdf/plugins/java/set-java-home.bash"
    fi
}

function setup_kubectl_dotfiles() {
    if [[ ! -e "${HOME}/.kube/config" ]]; then
        if [[ ! -d "${HOME}/.kube" ]]; then
            mkdir -p "${HOME}/.kube"
        fi
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
    if [[ ! -e "${HOME}/.kube/config" ]]; then
        setup_kubectl_dotfiles
    fi

    # Ensure that KUBECONFIG is set
    if [[ -z "${KUBECONFIG:-}" ]]; then
        export KUBECONFIG="${HOME}/.kube/config"
    fi

    # Append all the discovered kubeconfig files into the KUBECONFIG variable
    while IFS=' ' read -r -a kubeconfig_files; do
        if [[ -z "$(grep "${kubeconfig_files[0]}" <<<"${KUBECONFIG:-}" 2>/dev/null || true)" ]]; then
            export KUBECONFIG="${KUBECONFIG}:${kubeconfig_files[0]}"
        fi
    done < <(find "${HOME}/.kube" -maxdepth 3 -type f | grep "\.conf")
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

    python_current_version="$(asdf list python | awk NR==1 | xargs)"
    export CLOUDSDK_PYTHON="$(readlink -f "${HOME}"/.asdf/installs/python/"${python_current_version}"/bin/python3)"
    export USE_GKE_GCLOUD_AUTH_PLUGIN=True
}

function setup_starship() {
    # local terminal_application
    # shellcheck disable=SC2046
    # terminal_application="$(pstree -sA $$ | awk -F "---" '{ print $3 }')"

    # Use alternate status tool in gnome terminal
    #if [[ "${terminal_application}" != "gnome-terminal" ]]; then
    #    return 0
    #fi

    if [[ -n "$(starship --version)" ]]; then
        local tmp_dir

        tmp_dir=$(mktemp --directory)
        # Ignore unbound variable
        # preexec_functions: unbound variable
        echo "set +u" >>"$tmp_dir/starship.sh"
        starship init --print-full-init bash >>"$tmp_dir/starship.sh"
        source "$tmp_dir/starship.sh"
        rm "$tmp_dir/starship.sh"
    fi
    #eval "$(cat "$tmp_dir/starship.sh")"

    if [[ -n "$(starship --version)" ]]; then
        eval "$(starship init bash)"
    fi
}

function setup_starship_dotfiles() {
    if [[ ! -d "${HOME}/.config" ]]; then
        mkdir -p "${HOME}/.config"
    fi

    cp \
        "$(project_root)/config/dotfiles/starship/starship.toml" \
        "${HOME}/.config/starship.toml"
}

function setup_yarn() {
    local yarn_global_path
    yarn_global_path="$(yarn global bin)"

    if [[ -z "${yarn_global_path}" ]] &&
        [[ -z "$(grep "${yarn_global_path}" <<<"${PATH}" 2>/dev/null || true)" ]]; then
        export PATH="${PATH}:${yarn_global_path}"
    fi

    yarn config set registry https://registry.npmjs.org -g >/dev/null
}

function setup_yq() {
    if [[ -z "$(command -v yq)" ]]; then
        yq shell-completion bash >"${HOME}"/.bash_completion.d/yq
        source "${HOME}"/.bash_completion.d/yq
    fi
}
