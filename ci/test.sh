#!/usr/bin/env bash
# shellcheck disable=SC2128
# set -euo pipefail

export RUN_TESTS="${1:-serial}"

function build_docker_image() {
    docker build \
        --tag local/shellspec-ubuntu:latest \
        -f shellspec.Dockerfile ./
}

function run_job() {
    local spec_path="${1}"

    echo "Executing spec ${spec_path}"
    docker run \
        --rm \
        -i \
        -v "${PWD}":/localbox \
        --user ubuntu \
        local/shellspec-ubuntu:latest \
        shellspec \
        --shell bash \
        --log-file "/localbox/${spec_path}.log" \
        "${spec_path}"

    echo "Finished executing spec ${spec_path}"
}
export -f run_job

function serial_execution() {
    local spec_files

    while IFS=' ' read -r -a spec_files; do
        echo "Executing test ${spec_files[0]}"
        run_job "${spec_files[0]}"
        echo "Finished executing test ${spec_files[0]}"
        echo "Exit code: $?"
    done < <(ls -A ./spec/bin/*.sh)
}

function execute_tests() {
    build_docker_image
    serial_execution
}

function execute_test() {
    local spec_file="${1:-}"
    local use_docker="${2:-}"

    if [[ -z "${spec_file}" ]]; then
        echo "spec_file is required" >/dev/stderr
        return 1
    fi

    if [[ "${use_docker}" == "true" ]]; then
        build_docker_image
        run_job "${spec_file}"
    else
        shellspec \
            --shell bash \
            --log-file "${spec_file}.log" \
            "${spec_file}"
    fi
}
