#!/bin/bash

# set -e
# set -x

check_gh_exist() {
    if ! command -v gh &>/dev/null; then
        if [ "$(uname)" = "Darwin" ]; then
            echo "[WARN]: can not find gh command and install gh command"

            brew install gh
        fi
    fi

    if ! command -v gh &>/dev/null; then
        echo ""
        echo ""
        echo "[ERROR]: can not find gh command"
        echo ""
        echo ""

        exit 1
    fi

    echo "gh version"
    gh --version
}

check_jq_exist() {
    if ! command -v jq &>/dev/null; then
        if [ "$(uname)" = "Darwin" ]; then
            echo "[WARN]: can not find jq command and install jq command"

            brew install jq
        fi
    fi

    if ! command -v jq &>/dev/null; then
        echo ""
        echo ""
        echo "[ERROR]: can not find jq command"
        echo ""
        echo ""

        exit 1
    fi

    echo "jq version"
    jq --version
}

check_dotnet_exist() {
    if ! command -v dotnet &>/dev/null; then
        brew install --cask dotnet-sdk@8
    fi

    if ! command -v dotnet &>/dev/null; then
        echo ""
        echo ""
        echo "[ERROR]: can not find dotnet command, please install it manually"
        echo ""
        echo ""

        exit 1
    fi

    echo dotnet version
    dotnet --version
}

check_folder_exist() {
    FOLDER=$1
    if [ -d "$FOLDER" ]; then
        echo "true"
    else
        echo "false"
    fi
}

check_file_exist() {
    FILE=$1
    if [ -f "$FILE" ]; then
        echo "true"
    else
        echo "false"
    fi
}

check_path_exist() {
    FILE=$1
    if [ -e "$FILE" ]; then
        echo "true"
    else
        echo "false"
    fi
}

check_string_is_not_empty() {
    STR=$1
    if [ -z "$STR" ]; then
        echo "false"
    else
        echo "true"
    fi
}

format_bool_value() {
    case $1 in
    true | True | TRUE | tRUE)
        echo "true"
        ;;
    *)
        echo "false"
        ;;
    esac
}

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

check_windows_os_info_exist() {
    if [ "$(uname)" = "Darwin" ]; then
        echo ""
        echo "[WARN]: windows-os-info command only support Windows"
        echo ""
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" || -n "$WINDIR" ]]; then
        if ! command -v windows-os-info &>/dev/null; then
            echo "[WARN]: can not find windows-os-info command and install windows-os-info command"

            DOWNLOAD_URL="https://github.com/jason-xie-123/windows-os-info/releases/download/v0.1.1/windows-os-info.exe"
            DOWNLOAD_FILE_NAME="windows-os-info.exe"

            CURRENT_SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

            rm -rf "${CURRENT_SCRIPT_DIR:?}/$DOWNLOAD_FILE_NAME"

            COMMAND="curl -L -o \"$CURRENT_SCRIPT_DIR/$DOWNLOAD_FILE_NAME\" \"$DOWNLOAD_URL\""
            echo exec: "$COMMAND"
            if ! eval "$COMMAND"; then
                echo ""
                echo "[ERROR]: failed to download $DOWNLOAD_FILE_NAME from $DOWNLOAD_URL"
                echo ""

                exit 1
            else
                echo ""
                echo "[INFO]: download $DOWNLOAD_FILE_NAME from $DOWNLOAD_URL"
                echo ""
            fi

            if [ "$(check_file_exist "$CURRENT_SCRIPT_DIR/$DOWNLOAD_FILE_NAME")" = "true" ]; then
                BINS_TARGET_FOLDER="/usr/bin"
                if [ "$(check_folder_exist "/usr/local/bin")" = "true" ]; then
                    BINS_TARGET_FOLDER=/usr/local/bin
                    if [[ ":$PATH:" != *":$BINS_TARGET_FOLDER:"* ]]; then
                        export PATH="$PATH:$BINS_TARGET_FOLDER"
                    fi
                fi
                cp "$CURRENT_SCRIPT_DIR/$DOWNLOAD_FILE_NAME" "$BINS_TARGET_FOLDER/windows-os-info.exe"

                rm -rf "${CURRENT_SCRIPT_DIR:?}/$DOWNLOAD_FILE_NAME"
            else
                echo ""
                echo "[WARN]: can not find $CURRENT_SCRIPT_DIR/$DOWNLOAD_FILE_NAME"
                echo ""
            fi
        fi

        if ! command -v windows-os-info &>/dev/null; then
            echo ""
            echo ""
            echo "[ERROR]: can not find windows-os-info command"
            echo ""
            echo ""

            exit 1
        fi
    fi
}

get_os_architecture() {
    CURRENT_OS_ARCHITECTURE=""
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" || -n "$WINDIR" ]]; then
        # win 11 开始系统已经标记 wmic 命令为废弃方法，在某些 win11 设备上不存在 wmic 命令
        # OS_ARCHITECTURE_RESULT=$(wmic os get osarchitecture)
        check_windows_os_info_exist
        OS_ARCHITECTURE_RESULT=$(windows-os-info --action=os_arch)
        if [ "$OS_ARCHITECTURE_RESULT" == "arm64" ]; then
            CURRENT_OS_ARCHITECTURE="ARM64"
        elif [ "$OS_ARCHITECTURE_RESULT" == "x86" ]; then
            CURRENT_OS_ARCHITECTURE="X86"
        elif [ "$OS_ARCHITECTURE_RESULT" == "x64" ]; then
            CURRENT_OS_ARCHITECTURE="X64"
        else
            CURRENT_OS_ARCHITECTURE="unknown"
        fi
    elif [ "$(uname)" = "Darwin" ]; then
        OS_ARCHITECTURE_RESULT=$(uname -m)
        if [ "$OS_ARCHITECTURE_RESULT" = "x86_64" ]; then
            CURRENT_OS_ARCHITECTURE="X64"
        elif [ "$OS_ARCHITECTURE_RESULT" = "arm64" ]; then
            CURRENT_OS_ARCHITECTURE="ARM64"
        else
            CURRENT_OS_ARCHITECTURE="unknown"
        fi
    else
        CURRENT_OS_ARCHITECTURE="unknown"
    fi

    eval "$1=\"$CURRENT_OS_ARCHITECTURE\""
}

