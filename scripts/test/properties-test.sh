#!/bin/bash

OLD_PWD=$(pwd)
SHELL_FOLDER=$(
    cd "$(dirname "$0")" || exit
    pwd
)
PROJECT_FOLDER=$SHELL_FOLDER/../..

cd "$SHELL_FOLDER" || exit >/dev/null 2>&1

# shellcheck source=/dev/null
source "$PROJECT_FOLDER/scripts/base/env.sh"


# prop_write_by_shell() {
#     KEY_NAME=$1
#     KEY_VALUE=$2
#     PROP_FILE=$3

#     if [ "$IS_MAC_OS" == "true" ]; then
#         awk -v pat="^$KEY_NAME=" -v value="$KEY_NAME=$KEY_VALUE" '{ if ($0 ~ pat) print value; else print $0; }' "$PROP_FILE" >"$PROP_FILE.tmp"
#         mv "$PROP_FILE.tmp" "$PROP_FILE"
#     else
#         awk -v pat="^$KEY_NAME=" -v value="$KEY_NAME=$KEY_VALUE" '{ if ($0 ~ pat) print value; else print $0; }' "$PROP_FILE" >"$PROP_FILE.tmp"
#         mv "$PROP_FILE.tmp" "$PROP_FILE"
#     fi
# }

# prop_read_by_shell() {
#     KEY_NAME=$1
#     PROP_FILE=$2

#     if [ "$IS_MAC_OS" == "true" ]; then
#         grep "$KEY_NAME=" "$PROP_FILE" | cut -d'=' -f2-
#     else
#         LINE_DATA=$(grep "^$KEY_NAME=" "$PROP_FILE")

#         echo "${LINE_DATA#"${KEY_NAME}"=}"
#     fi
# }


# test_by_shell() {
#     TEST_COUNT=500
#     start_time_1=$(date +%s)

#     for i in $(seq 1 $TEST_COUNT); do
#     local CURRENT_VALUE="value$i"
#     mod=$(( i % 4 ))
#         prop_write_by_shell "aaaa$mod" "$CURRENT_VALUE" "$PROPERTIES_PATH"
#         DATA=$(prop_read_by_shell "aaaa$mod" "$PROPERTIES_PATH")
#         if [ "$DATA" != "$CURRENT_VALUE" ]; then
#             echo ""
#             echo "[ERROR]: test_by_shell failed at iteration $i, expected: $CURRENT_VALUE, got: $DATA"
#             echo ""

#             exit 1
#         fi
#     done

#     end_time_1=$(date +%s)
#     execution_time_1=$((end_time_1 - start_time_1))
#     echo ""
#     echo "----------------------------------------"
#     echo "Execution time [test_by_shell]: $TEST_COUNT times, $execution_time_1 seconds"
#     echo "----------------------------------------"
#     echo ""
# }

# calc_properties_cli_path() {
#     CURRENT_BINARY_PATH=""
#     get_os_architecture CURRENT_ARCHITECTURE

#     if [ "$CURRENT_ARCHITECTURE" == "X64" ]; then
#         if [ "$(is_windows_platform)" == "true" ]; then
#             CURRENT_BINARY_PATH="$PROJECT_FOLDER/release/windows-amd64/shell-lock-cli.exe"
#         elif [ "$(is_darwin_platform)" == "true" ]; then
#             CURRENT_BINARY_PATH="$PROJECT_FOLDER/release/darwin-amd64/shell-lock-cli"
#         else
#             echo ""
#             echo ""
#             echo "[ERROR]: Unsupported platform for X64 binary"
#             echo ""
#             echo ""

#             exit 1
#         fi
#     elif [ "$CURRENT_ARCHITECTURE" == "X86" ]; then
#         if [ "$(is_windows_platform)" == "true" ]; then
#             CURRENT_BINARY_PATH="$PROJECT_FOLDER/release/windows-386/shell-lock-cli.exe"
#         else
#             echo ""
#             echo ""
#             echo "[ERROR]: Unsupported platform for X86 binary"
#             echo ""
#             echo ""

#             exit 1
#         fi
#     elif [ "$CURRENT_ARCHITECTURE" == "ARM64" ]; then
#         if [ "$(is_windows_platform)" == "true" ]; then
#             CURRENT_BINARY_PATH="$PROJECT_FOLDER/release/windows-arm64/shell-lock-cli.exe"
#         elif [ "$(is_darwin_platform)" == "true" ]; then
#             CURRENT_BINARY_PATH="$PROJECT_FOLDER/release/darwin-arm64/shell-lock-cli"
#         else
#             echo ""
#             echo ""
#             echo "[ERROR]: Unsupported platform for ARM64 binary"
#             echo ""
#             echo ""

#             exit 1
#         fi
#     else
#         echo ""
#         echo ""
#         echo "[ERROR]: Unknown architecture: $CURRENT_ARCHITECTURE"
#         echo ""
#         echo ""

#         exit 1
#     fi

#     eval "$1=\"$CURRENT_BINARY_PATH\""
# }

# prop_write_by_properties_cli() {
#     KEY_NAME=$1
#     KEY_VALUE=$2
#     PROP_PATH=$3

#     "$PROPERTIES_CLI_PATH" -write -path="$PROP_PATH" --key="$KEY_NAME" --value="$KEY_VALUE"
# }


# prop_read_by_properties_cli() {
#     KEY_NAME=$1
#     PROP_PATH=$2

#  "$PROPERTIES_CLI_PATH" --read --path="$PROP_PATH" --key="$KEY_NAME"
# }


# test_by_properties_cli() {
#     TEST_COUNT=500
#     start_time_1=$(date +%s)

#     for i in $(seq 1 $TEST_COUNT); do
#     local CURRENT_VALUE="value$i"
#     mod=$(( i % 4 ))
#         prop_write_by_properties_cli "aaaa$mod" "$CURRENT_VALUE" "$PROPERTIES_PATH"
#         DATA=$(prop_read_by_properties_cli "aaaa$mod" "$PROPERTIES_PATH")
#         if [ "$DATA" != "$CURRENT_VALUE" ]; then
#             echo ""
#             echo "[ERROR]: test_by_properties_cli failed at iteration $i, expected: -$CURRENT_VALUE---11111, got: -$DATA---222222"
#             echo ""

#             exit 1
#         fi
#     done

#     end_time_1=$(date +%s)
#     execution_time_1=$((end_time_1 - start_time_1))
#     echo ""
#     echo "----------------------------------------"
#     echo "Execution time [test_by_properties_cli]: $TEST_COUNT times, $execution_time_1 seconds"
#     echo "----------------------------------------"
#     echo ""
# }

# IS_MAC_OS=$(is_darwin_platform)

# PROPERTIES_PATH="$SHELL_FOLDER/app.properties.test"
# calc_properties_cli_path PROPERTIES_CLI_PATH

# test_by_shell

# test_by_properties_cli

cd "$OLD_PWD" || exit >/dev/null 2>&1
