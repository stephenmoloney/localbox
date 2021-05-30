#!/usr/bin/env bash
set -euo pipefail
trap "set +eu" EXIT

SHELLSPEC_VERSION=0.28.1

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]}")/../bin/utils.sh"
if [[ -e "${UTILS_PATH}" ]]; then
    source "${UTILS_PATH}"
else
    if [[ -z "$(command -v curl)" ]]; then
        sudo apt update -y -qq
        sudo apt install -y -qq curl
    fi
    echo "Falling back to remote script ${GITHUB_URL}/bin/utils.sh"
    if curl -sIf -o /dev/null ${GITHUB_URL}/bin/utils.sh; then
        source <(curl -s "${GITHUB_URL}/bin/utils.sh")
    else
        echo "${GITHUB_URL}/bin/utils.sh does not exist" >/dev/stderr
        return 1
    fi
fi
# ************************************************************************
PROJECT_ROOT="$(project_root)"

function create_user() {
    apt update -y -qq
    apt install -y sudo make
    if [[ -z "$(grep ubuntu /etc/passwd 2>/dev/null || true)" ]]; then
        if [[ -d /home/ubuntu ]]; then
            groupadd -r ubuntu
            adduser \
                --ingroup ubuntu \
                --disabled-password \
                --shell /bin/bash \
                --gecos "ubuntu" \
                --no-create-home \
                --home /home/ubuntu \
                ubuntu
        else
            groupadd -r ubuntu
            adduser \
                --ingroup ubuntu \
                --disabled-password \
                --shell /bin/bash \
                --gecos "ubuntu" \
                --home /home/ubuntu \
                ubuntu
        fi
        usermod -a -G sudo ubuntu
        echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" >>/etc/sudoers
        sudo chown -R ubuntu:ubuntu /home/ubuntu
    fi
}

function get_image_status() {
    local container_id
    container_id="$(docker ps -a --filter=name=localbox --latest -q)"
    if [[ -n "${container_id}" ]]; then
        docker inspect -f '{{.State.Status}}' "${container_id}" | tr -d '[:space:]'
    fi
}

function emulate_ci() {
    local docker_status
    local image_name
    local new_image_hash

    docker_status="$(get_image_status)"
    image_name=ubuntu:20.04

    echo "Current state of localbox docker container: ${docker_status}"
    if [[ "${docker_status}" == "removing" ]]; then
        echo "Force removing existing localbox container"
        docker rm -f localbox
    fi

    # In the event that the image is not running, attempt a sort of recovery
    if [[ "${docker_status}" != "running" ]]; then
        if [[ -n "${docker_status}" ]]; then
            new_image_hash="$(openssl rand -hex 3)"
            image_name="local/localbox:${new_image_hash}"
        fi
        echo "Image name is ${image_name}"
        # Recover the previous container image (if any)
        docker commit \
            "$(docker ps -a --filter=name=localbox --latest -q 2>/dev/null || true)" \
            "${image_name}" 2>/dev/null ||
            docker tag ubuntu:20.04 "${image_name}"
        # Remove the previous container (if any)
        docker rm -f localbox 2>/dev/null || true
        # Start the new container and keep it alive
        docker run \
            -d \
            --name localbox \
            --dns 1.1.1.1 \
            "${image_name}" \
            bash -c 'mkdir -p /home/ubuntu/src/open/localbox && sleep 5544332s'
        docker_status="$(get_image_status 2>/dev/null || true)"
        echo "localbox docker container is now ${docker_status} using image ${image_name}"
    else
        echo "localbox docker container is already ${docker_status} using image ${image_name}"
    fi

    # Copy in files from this repository to the container
    docker exec -ti localbox bash -c "rm -rf /root/localbox"
    docker cp "${PROJECT_ROOT}" localbox:/root/localbox

    # Prepare the container (install ubuntu user and sudo)
    docker exec \
        -ti \
        -e CI=true \
        --workdir /root/localbox \
        localbox \
        bash -c "source ./ci/provision_emulate.sh && create_user"
    # Copy in files from this repository for access from ubuntu user
    docker exec -ti localbox bash -c "rm -rf /home/ubuntu/src/open/localbox"
    docker cp "${PROJECT_ROOT}" localbox:/home/ubuntu/src/open/localbox

    # Run the install and configure commands
    docker exec \
        -ti \
        --workdir /home/ubuntu/src/open/localbox \
        --user ubuntu \
        -e USER=ubuntu \
        -e CI=true \
        localbox \
        bash -c 'make provision'
}

function install_shellspec() {
    local version="${1:-$SHELLSPEC_VERSION}"

    maybe_install_apt_pkg curl "*"

    curl -fsSL https://git.io/shellspec |
        sh -s -e "${version}" --yes

    export PATH="${PATH}:${HOME}/.local/bin"
}
