#!/usr/bin/env bash
# shellcheck disable=SC2001,SC2034,SC2181

function check_zenity_installed() {
    if [[ -z "$(command -v zenity)" ]]; then
        echo "The zenity program is required for prompt" >&2
        echo "Job will be cancelled, exiting..." >&2
        exit 1
    fi
}

function check_jobname() {
    local jobname="${1}"

    if [[ -z "${jobname}" ]]; then
        echo "The jobname is required" >&2
        echo "Job will be cancelled, exiting..." >&2
        exit 1
    fi
}

function prompt_jobber_job_before_exec() {
    local jobname="${1}"
    local prompt
    local reject
    local accept
    local delay
    delay=5
    prompt="Do you want to allow execution of job ${jobname} by jobber now?"
    reject="Job ${jobname} has been rejected and will not run"
    accept="Job ${jobname} has been accepted and will run in ${delay} seconds"

    check_zenity_installed
    check_jobname "${jobname}"

    zenity --forms --text "${prompt}"

    if [[ $? -eq 0 ]]; then
        zenity \
            --notification \
            --text "${accept}"
        sleep "${delay}s"
    else
        zenity \
            --notification \
            --text "${reject}"
        echo "$(date) | ${reject}" >>"${HOME}/.jobber_dir/logs/output"
        exit 1
    fi
}

function notify_jobber_job_success() {
    local jobname="${1}"
    local msg
    msg="Jobber job ${jobname} succeeded, see ${HOME}/.jobber_dir/logs/output"

    check_zenity_installed
    check_jobname "${jobname}"

    zenity --info --text "${msg}"
}

function notify_jobber_job_error() {
    local jobname="${1}"
    local msg
    msg="Jobber job ${jobname} errored, see ${HOME}/.jobber_dir/logs/output"

    check_zenity_installed
    check_jobname "${jobname}"

    zenity --error --text "${msg}"
}
