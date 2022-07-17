#!/usr/bin/env bash
# shellcheck disable=SC2125
set -eo pipefail

function setup_java() {
    if [[ -e "${HOME}/.asdf/plugins/java/set-java-home.bash" ]]; then
        source "${HOME}/.asdf/plugins/java/set-java-home.bash"
    fi
}

function setup_kafka() {
    # Setup bash completion for kafka shell scripts
    if [[ ! -e "${HOME}"/.bash_completion.d/kafkaAdmin ]] || [[ ! -e "${HOME}"/.bash_completion.d/kafkaBin ]]; then
        pushd "$(mktemp -d)"
        git clone https://github.com/Kafka-In-Action-Book/kafka_tools_completion.git ./
        git checkout 62ba192e65f4494a100a98f9a37720f343b3d868
        cp ./0.10.2/kafkaAdmin "${HOME}"/.bash_completion.d/kafkaAdmin
        cp ./0.10.2/kafkaBin "${HOME}"/.bash_completion.d/kafkaBin
        popd
    fi
    source "${HOME}"/.bash_completion.d/kafkaAdmin
    source "${HOME}"/.bash_completion.d/kafkaBin
}

function setup_kaf() {
    if [[ ! -e "${HOME}"/.bash_completion.d/kaf ]] && [[ -n "$(command -v kaf || true)" ]]; then
        kaf completion bash >"${HOME}"/.bash_completion.d/kaf
    fi
    source "${HOME}"/.bash_completion.d/kaf
}

function setup_k3d() {
    if [[ ! -e "${HOME}"/.bash_completion.d/k3d ]] && [[ -n "$(command -v k3d || true)" ]]; then
        k3d completion bash >"${HOME}"/.bash_completion.d/k3d
    fi
    source "${HOME}"/.bash_completion.d/k3d
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

    # # Concatenate the kubeconfig files into the ~/.kube/config file
    # # Exclude files with the string prod in the name
    if [[ -d "${HOME}/.kube" ]]; then
        if [[ ! -e "${HOME}/.kube/config" ]]; then
            setup_kubectl_dotfiles
        fi
        while IFS=' ' read -r -a kubeconfig_files; do
            if [[ "${kubeconfig_files[0]}" != *"prod"* ]]; then
                if [[ -z "${KUBECONFIG:-}" ]]; then
                    export KUBECONFIG="${HOME}/.kube/config"
                fi
                if [[ -z "$(grep "${kubeconfig_files[0]}" <<<"${KUBECONFIG:-}" 2>/dev/null || true)" ]]; then
                    if [[ -z "${KUBECONFIG}" ]]; then
                        export KUBECONFIG="${HOME}/.kube/config:${kubeconfig_files[0]}"
                    else
                        export KUBECONFIG="${KUBECONFIG}:${kubeconfig_files[0]}"
                    fi
                fi
            fi
        done < <(find "${HOME}/.kube" -maxdepth 3 -type f | grep "\.conf")
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
        # preexec_functions: unbound variable:w
        echo "set +u" >>"$tmp_dir/starship.sh"
        starship init --print-full-init bash >>"$tmp_dir/starship.sh"
        source "$tmp_dir/starship.sh"
        rm "$tmp_dir/starship.sh"
    fi
    #eval "$(cat "$tmp_dir/starship.sh")"

    # if [[ -n "$(starship --version)" ]]; then
    #     eval "$(starship init bash)"
    # fi
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
}

function setup_yq() {
    if [[ -z "$(command -v yq)" ]]; then
        yq shell-completion bash >"${HOME}/bash_completion.d/yq"
        source"${HOME}/bash_completion.d/yq"
    fi
}
