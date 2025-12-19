#!/usr/bin/env bash

set -euo pipefail

log_info() {
    echo "[INFO] $*"
}

log_warn() {
    echo "[WARN] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

fail() {
    log_error "$1"
    exit 1
}

command_exists() {
    command -v "$1" &>/dev/null
}

ensure_path_in_env() {
    local target="$1"

    if [[ ":$PATH:" != *":$target:"* ]]; then
        PATH="$PATH:$target"
    fi
}

is_windows_platform() {
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" || -n "${WINDIR:-}" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

is_darwin_platform() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

check_folder_exist() {
    local folder="$1"

    if [[ -d "$folder" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

check_file_exist() {
    local file="$1"

    if [[ -f "$file" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

check_path_exist() {
    local path="$1"

    if [[ -e "$path" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

check_string_is_not_empty() {
    local value="$1"

    if [[ -z "$value" ]]; then
        echo "false"
    else
        echo "true"
    fi
}

format_bool_value() {
    case "$1" in
    true | True | TRUE | tRUE)
        echo "true"
        ;;
    *)
        echo "false"
        ;;
    esac
}

transfer_path_to_unix() {
    if [[ $(is_windows_platform) == "true" ]]; then
        local win_path="$1"

        if [[ $(check_string_is_not_empty "$win_path") == "false" ]]; then
            echo "$win_path"
        else
            cygpath "$win_path"
        fi
    else
        echo "$1"
    fi
}

transfer_path_to_windows() {
    if [[ $(is_windows_platform) == "true" ]]; then
        cygpath -w "$1"
    else
        echo "$1"
    fi
}

get_command_path() {
    local name="$1"

    if [[ -z "$name" ]]; then
        echo ""
        return
    fi

    if command_exists "$name"; then
        if [[ $(is_darwin_platform) == "true" ]]; then
            transfer_path_to_unix "$(which "$name")"
        elif [[ $(is_windows_platform) == "true" ]]; then
            transfer_path_to_unix "$(where "$name")"
        else
            which "$name"
        fi
    else
        echo ""
    fi
}

calc_real_path() {
    if [[ $(is_darwin_platform) == "true" ]]; then
        grealpath "$1"
    else
        realpath "$1"
    fi
}

calc_relative_path() {
    local from_path="$1"
    local to_path="$2"

    if [[ $(is_darwin_platform) == "true" ]]; then
        grealpath --relative-to="$from_path" "$to_path"
    else
        realpath --relative-to="$from_path" "$to_path"
    fi
}

check_realpath_exist() {
    if [[ $(is_darwin_platform) == "true" ]]; then
        if ! command_exists grealpath; then
            log_warn "Missing grealpath command, installing via Homebrew"
            brew install coreutils
        fi

        command_exists grealpath || fail "Cannot find grealpath command"
        log_info "grealpath Path: $(get_command_path grealpath)"
        grealpath --version
    elif [[ $(is_windows_platform) == "true" ]]; then
        command_exists realpath || fail "Cannot find realpath command"
        log_info "realpath Path: $(get_command_path realpath)"
        realpath --version
    fi
}

check_gh_exist() {
    if ! command_exists gh; then
        if [[ $(is_darwin_platform) == "true" ]]; then
            log_warn "Missing gh command, installing via Homebrew"
            brew install gh
        fi
    fi

    command_exists gh || fail "Cannot find gh command"
    gh --version
}

check_jq_exist() {
    if ! command_exists jq; then
        if [[ $(is_darwin_platform) == "true" ]]; then
            log_warn "Missing jq command, installing via Homebrew"
            brew install jq
        fi
    fi

    command_exists jq || fail "Cannot find jq command"
    jq --version
}

check_dotnet_exist() {
    if ! command_exists dotnet; then
        brew install --cask dotnet-sdk@8
    fi

    command_exists dotnet || fail "Cannot find dotnet command, please install it manually"
    dotnet --version
}

check_choco_exist() {
    if [[ $(is_windows_platform) == "true" ]]; then
        if ! command_exists choco; then
            log_warn "Missing choco command, installing via PowerShell"
            powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        fi

        command_exists choco || fail "Cannot find choco command"
        log_info "choco Path: $(get_command_path choco)"
        choco --version
    else
        log_warn "Chocolatey is only supported on Windows"
    fi
}

check_dos2unix_exist() {
    if ! command_exists dos2unix; then
        if [[ $(is_darwin_platform) == "true" ]]; then
            log_warn "Missing dos2unix command, installing via Homebrew"
            brew install dos2unix
        elif [[ $(is_windows_platform) == "true" && "$OSTYPE" == "cygwin" ]]; then
            log_warn "Missing dos2unix command, installing via Cygwin setup"
            check_cygwin_setup_exist
            /setup-x86_64.exe -q -P unix2dos, dos2unix
        fi
    fi

    command_exists dos2unix || fail "Cannot find dos2unix command"
    log_info "dos2unix Path: $(get_command_path dos2unix)"
    dos2unix --version
}

check_unix2dos_exist() {
    if ! command_exists unix2dos; then
        if [[ $(is_darwin_platform) == "true" ]]; then
            log_warn "Missing unix2dos command, installing via Homebrew"
            brew install unix2dos
        elif [[ $(is_windows_platform) == "true" && "$OSTYPE" == "cygwin" ]]; then
            log_warn "Missing unix2dos command, installing via Cygwin setup"
            check_cygwin_setup_exist
            /setup-x86_64.exe -q -P unix2dos, dos2unix
        fi
    fi

    command_exists unix2dos || fail "Cannot find unix2dos command"
    log_info "unix2dos Path: $(get_command_path unix2dos)"
    unix2dos --version
}

check_shfmt_exist() {
    if ! command_exists shfmt; then
        if [[ $(is_darwin_platform) == "true" ]]; then
            log_warn "Missing shfmt command, installing via Homebrew"
            brew install shfmt
        elif [[ $(is_windows_platform) == "true" ]]; then
            log_warn "Missing shfmt command, installing via Chocolatey"
            check_choco_exist
            choco install shfmt -y --force
        fi
    fi

    command_exists shfmt || fail "Cannot find shfmt command"
    log_info "shfmt Path: $(get_command_path shfmt)"
    shfmt --version
}

check_shellcheck_exist() {
    if ! command_exists shellcheck; then
        if [[ $(is_darwin_platform) == "true" ]]; then
            log_warn "Missing shellcheck command, installing via Homebrew"
            brew install shellcheck
        elif [[ $(is_windows_platform) == "true" ]]; then
            log_warn "Missing shellcheck command, installing via Chocolatey"
            check_choco_exist
            choco install shellcheck -y --force
        fi
    fi

    command_exists shellcheck || fail "Cannot find shellcheck command"
    log_info "shellcheck Path: $(get_command_path shellcheck)"
    shellcheck --version
}

check_cygwin_setup_exist() {
    if [[ "$OSTYPE" != "cygwin" ]]; then
        log_warn "Cygwin setup check is only needed on Windows Cygwin environments"
        return
    fi

    if [[ $(check_file_exist "/setup-x86_64.exe") == "true" ]]; then
        log_info "/setup-x86_64.exe exists"
        return
    fi

    local download_url="https://www.cygwin.com/setup-x86_64.exe"
    local download_file="setup-x86_64.exe"

    rm -f "/${download_file}"

    local system_root_path
    system_root_path=$(powershell.exe -Command "echo \$env:SystemRoot" | tr -d '\r')
    local command
    command="\"$(transfer_path_to_unix "$system_root_path/System32/curl.exe")\" -L -o \"$(transfer_path_to_windows "/$download_file")\" \"$download_url\""
    log_info "exec: $command"
    eval "$command" || fail "Failed to download $download_file from $download_url"
    log_info "Downloaded $download_file from $download_url"
}

check_windows_os_info_exist() {
    if [[ $(is_windows_platform) != "true" ]]; then
        log_warn "windows-os-info command only supports Windows"
        return
    fi

    if ! command_exists windows-os-info; then
        log_warn "Missing windows-os-info command, downloading binary"

        local download_url="https://github.com/jason-xie-123/windows-os-info/releases/download/v0.1.1/windows-os-info.exe"
        local download_file="windows-os-info.exe"
        local current_script_dir
        current_script_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

        rm -f "$current_script_dir/$download_file"

        local command
        command="curl -L -o \"$current_script_dir/$download_file\" \"$download_url\""
        log_info "exec: $command"
        eval "$command" || fail "Failed to download $download_file from $download_url"

        if [[ $(check_file_exist "$current_script_dir/$download_file") == "true" ]]; then
            local bins_target_folder="/usr/bin"
            if [[ $(check_folder_exist "/usr/local/bin") == "true" ]]; then
                bins_target_folder="/usr/local/bin"
                ensure_path_in_env "$bins_target_folder"
            fi

            cp "$current_script_dir/$download_file" "$bins_target_folder/windows-os-info.exe"
            rm -f "$current_script_dir/$download_file"
        else
            log_warn "Cannot find $current_script_dir/$download_file after download"
        fi
    fi

    command_exists windows-os-info || fail "Cannot find windows-os-info command"
}

get_os_architecture() {
    local __result_var="$1"
    local __arch="unknown"

    if [[ $(is_windows_platform) == "true" ]]; then
        check_windows_os_info_exist
        local result
        result=$(windows-os-info --action=os_arch)

        case "$result" in
        arm64) __arch="ARM64" ;;
        x86) __arch="X86" ;;
        x64) __arch="X64" ;;
        *) __arch="unknown" ;;
        esac
    elif [[ $(is_darwin_platform) == "true" ]]; then
        local result
        result=$(uname -m)

        case "$result" in
        x86_64) __arch="X64" ;;
        arm64) __arch="ARM64" ;;
        esac
    fi

    eval "$__result_var=\"$__arch\""
}

get_git_bash_path() {
    if [[ $(is_windows_platform) == "true" ]]; then
        local git_path
        git_path=$(reg query "HKLM\SOFTWARE\GitForWindows" //v InstallPath 2>&1 | grep "InstallPath" | sed -r 's/.*InstallPath\s+REG_SZ\s+//')

        if [[ $(check_folder_exist "$git_path") == "true" ]]; then
            printf "%s\n" "$git_path\\usr\\bin\\bash.exe"
        else
            where bash
        fi
    else
        which bash
    fi
}

run_command_or_fail() {
    local command="$1"
    local error_message="$2"

    log_info "exec: $command"
    if ! eval "$command"; then
        fail "$error_message"
    fi
}

export -f calc_real_path
export -f transfer_path_to_unix
export -f get_git_bash_path
export -f run_command_or_fail

check_realpath_exist
