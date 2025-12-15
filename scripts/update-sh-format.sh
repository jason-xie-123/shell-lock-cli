#!/bin/bash

OLD_PWD=$(pwd)
SHELL_FOLDER=$(
    cd "$(dirname "$0")" || exit
    pwd
)
PROJECT_FOLDER=$SHELL_FOLDER/..

cd "$SHELL_FOLDER" >/dev/null 2>&1 || exit

is_windows_platform() {
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" || -n "$WINDIR" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

is_darwin_platform() {
    if [ "$(uname)" = "Darwin" ]; then
        echo "true"
    else
        echo "false"
    fi
}

get_command_path() {
    if [ -n "$1" ]; then
        if command -v "$1" &>/dev/null; then
            if [ "$(is_darwin_platform)" == "true" ]; then
                transfer_path_to_unix "$(which "$1")"
            elif [ "$(is_windows_platform)" == "true" ]; then
                transfer_path_to_unix "$(where "$1")"
            fi
        else
            echo ""
        fi
    else
        echo ""
    fi
}

check_cygwin_setup_exist() {
    if [[ "$OSTYPE" == "cygwin" ]]; then
        if [ "$(check_file_exist "/setup-x86_64.exe")" = "true" ]; then
            echo ""
            echo "[SUCCESS]: /setup-x86_64.exe exist"
            echo ""
        else
            DOWNLOAD_URL="https://www.cygwin.com/setup-x86_64.exe"
            DOWNLOAD_FILE_NAME="setup-x86_64.exe"

            rm -rf "/${DOWNLOAD_FILE_NAME:?}"

            # 对于 git-bash，缺省的 curl 为 C:\Program Files\Git\mingw64\bin\curl.exe, 支持 bash 路径的
            # 对于 cygwin，缺省的 curl 为 C:\Windows\System32\curl.exe, 不支持 bash 路径的
            # 此处为了统一处理，我们一律采用 C:\Windows\System32\curl.exe 进行相关的处理
            SYSTEM_ROOT_PATH=$(powershell.exe -Command "echo \$env:SystemRoot" | tr -d '\r')
            COMMAND="\"$(transfer_path_to_unix "$SYSTEM_ROOT_PATH/System32/curl.exe")\" -L -o \"$(transfer_path_to_windows "/$DOWNLOAD_FILE_NAME")\" \"$DOWNLOAD_URL\""
            echo exec: "$COMMAND"
            if ! eval "$COMMAND"; then
                echo ""
                echo "[ERROR]: failed to download $DOWNLOAD_FILE_NAME from $DOWNLOAD_URL"
                echo ""

                exit 1
            else
                echo "[INFO]: download $DOWNLOAD_FILE_NAME from $DOWNLOAD_URL success"
            fi
        fi
    else
        echo ""
        echo "[WARN]: only need check on windows cygwin bash, current os is $OSTYPE"
        echo ""
    fi
}

check_dos2unix_exist() {
    if ! command -v dos2unix &>/dev/null; then
        if [ "$(is_darwin_platform)" == "true" ]; then
            echo "[WARN]: can not find dos2unix command and install dos2unix command"

            brew install dos2unix
        elif [ "$(is_windows_platform)" == "true" ]; then
            if [ "$OSTYPE" = "cygwin" ]; then
                echo "[WARN]: can not find dos2unix command and install dos2unix command"

                check_cygwin_setup_exist
                /setup-x86_64.exe -q -P unix2dos, dos2unix
            fi
        fi
    fi

    if ! command -v dos2unix &>/dev/null; then
        echo ""
        echo ""
        echo "[ERROR]: can not find dos2unix command"
        echo ""
        echo ""

        exit 1
    fi

    echo "dos2unix Path: $(get_command_path dos2unix)"
    echo dos2unix version
    dos2unix --version
}

check_unix2dos_exist() {
    if ! command -v unix2dos &>/dev/null; then
        if [ "$(is_darwin_platform)" == "true" ]; then
            echo "[WARN]: can not find unix2dos command and install unix2dos command"

            brew install unix2dos
        elif [ "$(is_windows_platform)" == "true" ]; then
            if [ "$OSTYPE" = "cygwin" ]; then
                echo "[WARN]: can not find dos2unix command and install unix2dos command"

                check_cygwin_setup_exist
                /setup-x86_64.exe -q -P unix2dos, dos2unix
            fi
        fi
    fi

    if ! command -v unix2dos &>/dev/null; then
        echo ""
        echo ""
        echo "[ERROR]: can not find unix2dos command"
        echo ""
        echo ""

        exit 1
    fi

    echo "unix2dos Path: $(get_command_path unix2dos)"
    echo unix2dos version
    unix2dos --version
}

check_choco_exist() {
    if [ "$(is_windows_platform)" == "true" ]; then
        if ! command -v choco &>/dev/null; then
            echo "[WARN]: can not find choco command and install choco command"

            powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        fi

        if ! command -v choco &>/dev/null; then
            echo ""
            echo ""
            echo "[ERROR]: can not find choco command"
            echo ""
            echo ""

            exit 1
        fi

        echo "choco Path: $(get_command_path choco)"
        echo "choco version"
        choco --version
    else
        echo ""
        echo "[WARN]: only windows support chocolatey, current os is $OSTYPE"
        echo ""
    fi
}

check_shfmt_exist() {
    if ! command -v shfmt &>/dev/null; then
        if [ "$(is_darwin_platform)" == "true" ]; then
            echo "[WARN]: can not find shfmt command and install shfmt command"
            brew install shfmt
        elif [ "$(is_windows_platform)" == "true" ]; then
            echo "[WARN]: can not find shfmt command and install shfmt command"

            check_choco_exist
            choco install shfmt -y --force
        fi
    fi

    if ! command -v shfmt &>/dev/null; then
        echo ""
        echo ""
        echo "[ERROR]: can not find shfmt command"
        echo ""
        echo ""

        exit 1
    fi

    echo "shfmt Path: $(get_command_path shfmt)"
    echo "shfmt version"
    shfmt --version
}

check_shellcheck_exist() {
    if ! command -v shellcheck &>/dev/null; then
        if [ "$(is_darwin_platform)" == "true" ]; then
            echo "[WARN]: can not find shellcheck command and install shellcheck command"
            brew install shellcheck
        elif [ "$(is_windows_platform)" == "true" ]; then
            echo "[WARN]: can not find shellcheck command and install shellcheck command"

            check_choco_exist
            choco install shellcheck -y --force
        fi
    fi

    if ! command -v shellcheck &>/dev/null; then
        echo ""
        echo ""
        echo "[ERROR]: can not find shellcheck command"
        echo ""
        echo ""

        exit 1
    fi

    echo "shellcheck Path: $(get_command_path shellcheck)"
    echo "shellcheck version"
    shellcheck --version
}

check_realpath_exist() {
    if [ "$(is_darwin_platform)" == "true" ]; then
        if ! command -v grealpath &>/dev/null; then
            echo "[WARN]: can not find grealpath command and install grealpath command"

            brew install coreutils
        fi

        if ! command -v grealpath &>/dev/null; then
            echo ""
            echo ""
            echo "[ERROR]: can not find grealpath command"
            echo ""
            echo ""

            exit 1
        fi

        echo ""
        echo ""
        echo "grealpath Path: $(get_command_path grealpath)"
        echo grealpath version
        grealpath --version
        echo ""
        echo ""
    elif [ "$(is_windows_platform)" == "true" ]; then
        if ! command -v realpath &>/dev/null; then
            echo ""
            echo ""
            echo "[ERROR]: can not find realpath command"
            echo ""
            echo ""

            exit 1
        fi

        echo ""
        echo ""
        echo "realpath Path: $(get_command_path realpath)"
        echo realpath version
        realpath --version
        echo ""
        echo ""
    fi
}

calc_relative_path() {
    if [ "$(is_darwin_platform)" == "true" ]; then
        grealpath --relative-to="$1" "$2"
    else
        realpath --relative-to="$1" "$2"
    fi
}

transfer_path_to_windows() {
    if [ -n "$1" ]; then
        if [ "$(is_windows_platform)" == "true" ]; then
            cygpath -w "$1"
        else
            echo "$1"
        fi
    else
        echo "$1"
    fi
}

transfer_path_to_unix() {
    if [ -n "$1" ]; then
        if [ "$(is_windows_platform)" == "true" ]; then
            cygpath -u "$1"
        else
            echo "$1"
        fi
    else
        echo "$1"
    fi
}

update_all_file_from_dir() {
    local father_dir_name=$1

    for child_file in "${father_dir_name}"/*; do
        if [ -d "${child_file}" ]; then
            update_all_file_from_dir "${child_file}"
        else
            if [[ ${check_file_suffix} = "${child_file##*.}" ]]; then
                echo check_file: "$child_file"

                dos2unix "$(transfer_path_to_windows "$child_file")"
                chmod +x "$child_file"
                shfmt -i 4 -w "$(transfer_path_to_windows "$child_file")"

                COMMAND="shellcheck \"$(transfer_path_to_windows "$child_file")\""
                if ! eval "$COMMAND"; then
                    echo ""
                    echo ""
                    echo "[ERROR]: shellcheck failed for: (${child_file})"
                    echo ""
                    echo ""

                    exit 1
                fi
            fi
        fi
    done
}

check_dos2unix_exist
check_shfmt_exist
check_realpath_exist
check_shellcheck_exist

check_file_suffix='sh'
update_all_file_from_dir "$PROJECT_FOLDER"

cd "$OLD_PWD" >/dev/null 2>&1 || exit
