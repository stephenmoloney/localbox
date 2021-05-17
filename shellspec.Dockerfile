FROM shellspec/shellspec-debian:0.28.1 as upstream

FROM ubuntu:20.04

COPY --from=upstream /opt/shellspec /shellspec_src

ENV \
    DEBIAN_FRONTEND=noninteractive \
    SHELLSPEC_VERSION=0.28.1 \
    PATH="${PATH}:/home/ubuntu/.local/bin"
    # PATH="${PATH}:/home/ubuntu/.local/lib/shellspec"

RUN \
    apt update -y -qq && \
    apt install -y sudo curl git && \
    mkdir -p /home/ubuntu && \
    groupadd -r ubuntu && \
    adduser \
        --ingroup ubuntu \
        --disabled-password \
        --shell /bin/bash \
        --gecos "ubuntu" \
        --home /home/ubuntu \
    ubuntu && \
    usermod -a -G sudo ubuntu && \
    echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    sudo chown -R ubuntu:ubuntu /home/ubuntu

USER ubuntu

RUN \
    curl -fsSL https://git.io/shellspec | \
      sh -s -e "${SHELLSPEC_VERSION}" --yes && \
    sudo apt autoremove --purge -y curl git

WORKDIR /localbox
