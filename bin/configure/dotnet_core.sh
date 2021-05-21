#!/usr/bin/env bash
set -eo pipefail

function setup_dotnet_core() {
    # https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet#environment-variables
    export DOTNET_CLI_TELEMETRY_OPTOUT=true
    export DOTNET_ROOT=/usr/share/dotnet
    export NUGET_PACKAGES="${HOME}/.nuget/packages"
    export DOTNET_NOLOGO=true
    export DOTNET_MULTILEVEL_LOOKUP=true
    # DOTNET_ROLL_FORWARD
    # DOTNET_ROLL_FORWARD_TO_PRERELEASE
    # DOTNET_ROLL_FORWARD_ON_NO_CANDIDATE_FX
    export DOTNET_CLI_UI_LANGUAGE=en-us
    export DOTNET_DISABLE_GUI_ERRORS=false
    # DOTNET_RUNTIME_ID
    # DOTNET_SHARED_STORE
    # DOTNET_STARTUP_HOOKS
    # DOTNET_BUNDLE_EXTRACT_BASE_DIR
    # COREHOST_TRACE
    # COREHOST_TRACEFILE
    # COREHOST_TRACE_VERBOSITY
}
