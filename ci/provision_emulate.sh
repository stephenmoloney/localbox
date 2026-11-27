#!/usr/bin/env bash
set -euo pipefail
trap "set +eu" EXIT

SHELLSPEC_VERSION=0.28.1

# ******* Importing utils.sh as a source of common shell functions *******
GITHUB_URL=https://raw.githubusercontent.com/stephenmoloney/localbox/master
UTILS_PATH="$(dirname "${BASH_SOURCE[0]:-}")/../bin/utils.sh"
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

    # Force the Noninteractive debconf frontend permanently in the container.
    # Setting DEBIAN_FRONTEND via docker exec env does not survive the
    # provisioning chain: sudo-rs (the default sudo on ubuntu 26.04) ignores
    # --preserve-env and strips the variable, so apt under sudo still got
    # interactive prompts (keyboard-configuration hang). The debconf
    # database setting applies to every apt/dpkg invocation regardless of
    # environment, user, or sudo boundary, and survives docker commit.
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

    # Answer dpkg conffile prompts the CI way: keep whatever is already
    # on disk unless the package has no local version.
    cat >/etc/apt/apt.conf.d/99localbox-ci <<'EOF'
DPkg::Options {
   "--force-confdef";
   "--force-confold";
};
EOF

    # The .env sets LC_ALL=en_US.UTF-8; slim docker images ship no locales,
    # so generate it here or every sourced shell warns (and perl/apt complain)
    apt install -y locales
    sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

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
        chown -R ubuntu:ubuntu /home/ubuntu
    fi

    # Grant passwordless sudo unconditionally (not only on user creation),
    # via a per-USER drop-in: sudo-rs (the default sudo on ubuntu 26.04)
    # reliably honours user specs, whereas group specs ("%sudo") are the
    # historically flaky part. /etc/sudoers.d is included by default.
    echo "ubuntu ALL=(ALL:ALL) NOPASSWD: ALL" >/etc/sudoers.d/ubuntu
    chmod 0440 /etc/sudoers.d/ubuntu

    # Fail loudly right here if passwordless sudo is broken, instead of
    # mid-provision with password prompts no one can answer.
    if ! su - ubuntu -c "sudo -n true" >/dev/null 2>&1; then
        echo "ERROR: passwordless sudo for user ubuntu is not working" >&2
        exit 1
    fi
    echo "passwordless sudo for user ubuntu verified"
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
    image_name=ubuntu:26.04

    if ! docker image inspect "${image_name}" >/dev/null 2>&1; then
        echo "Image ${image_name} not found locally, pulling..."
        docker pull "${image_name}"
    fi

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
            docker tag ubuntu:26.04 "${image_name}"
        # Remove the previous container (if any)
        docker rm -f localbox 2>/dev/null || true
        # Start the new container and keep it alive
        cpu_percent=50
        cpu_cores="$(nproc)"
        cpu_quota=$(( cpu_cores * 100000 * cpu_percent / 100 ))
        docker run \
            -d \
            --memory=4g \
            --memory-swap=4g \
            --cpu-period=100000 \
            --cpu-quota="${cpu_quota}" \
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

    # Prepare the container (install ubuntu user, sudo, locales and the
    # noninteractive debconf frontend)
    docker exec \
        -ti \
        -e CI=true \
        -e DEBIAN_FRONTEND=noninteractive \
        --workdir /root/localbox \
        localbox \
        bash -c "source ./ci/provision_emulate.sh && create_user"

    # Copy in files from this repository for access from ubuntu user
    docker exec -ti localbox bash -c "rm -rf /home/ubuntu/src/open/localbox"
    docker cp "${PROJECT_ROOT}" localbox:/home/ubuntu/src/open/localbox

    # docker cp lays files down as root; hand the tree back to the
    # ubuntu user or every mkdir/write under ${HOME} fails later
    docker exec localbox bash -c "chown -R ubuntu:ubuntu /home/ubuntu"

    # Run the install and configure commands
    docker exec \
        -ti \
        --workdir /home/ubuntu/src/open/localbox \
        --user ubuntu \
        -e USER=ubuntu \
        -e CI=true \
        -e DEBIAN_FRONTEND=noninteractive \
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
