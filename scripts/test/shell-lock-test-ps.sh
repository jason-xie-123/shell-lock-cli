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
PROJECT_FOLDER=$(calc_real_path "$PROJECT_FOLDER")

test_export_function() {
    local CURRENT_SIGN=$(echo "$1" | base64 --decode)
    echo "test_export_function [$CURRENT_SIGN]: start ......"
    sleep 1
    echo "test_export_function [$CURRENT_SIGN]: finish"

    exit 100
}

export -f test_export_function

test_func() {
    local CURRENT_SIGN=$1
    local ENCODED_CURRENT_SIGN=$(echo "$1" | base64)
    COMMAND="\"$SHELL_FOLDER/shell-lock-by-ps.sh\" -mutex-name test-lock-3 -command \"test_export_function $ENCODED_CURRENT_SIGN\""
    # echo exec: "$COMMAND"
    eval "$COMMAND"
    echo "EXIT-CODE [$CURRENT_SIGN]: $?"
}

if [ "$(is_windows_platform)" != "true" ]; then
    echo ""
    echo "[ERROR]: This script only supports Windows platform"
    echo ""

    exit 1
fi

start_time_1=$(date +%s)

for i in {1..10}; do
    test_func "--abc\$HOME/def--a\'\nb--a b\c--\\$i\\--\"'//\\$i\\//\"'--" &
done

wait

end_time_1=$(date +%s)
execution_time_1=$((end_time_1 - start_time_1))

echo ""
echo "----------------------------------------"
echo "Execution time [shell-lock-test-ps]: $execution_time_1 seconds"
echo "----------------------------------------"
echo ""

cd "$OLD_PWD" || exit >/dev/null 2>&1
