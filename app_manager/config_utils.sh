#!/bin/bash

# Utility functions for reading JSON configuration
# Requires 'jq' to be installed: sudo apt-get install jq

# Function to get the config file path dynamically
get_config_file_path() {
    # Get the directory of the calling script
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    local config_file=""
    # If the script is in a debug directory, go up one level
    if [[ "$script_dir" == */debug ]]; then
        config_file="$(dirname "$script_dir")/apps_config.json"
    else
        config_file="$script_dir/apps_config.json"
    fi
    echo "$config_file"
}

# Function to check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed. Install with: sudo apt-get install jq"
        exit 1
    fi
}

# Function to check if config file exists and is valid JSON
check_config_file() {
    local config_file=$(get_config_file_path)
    if [ ! -f "$config_file" ]; then
        echo "Error: Configuration file $config_file not found"
        exit 1
    fi

    # Validate JSON format
    if ! jq empty "$config_file" 2>/dev/null; then
        echo "Error: Configuration file $config_file is not valid JSON"
        exit 1
    fi
}

# Expand $USER / $HOME references in a configured path.
# Deliberately not using eval: config values must never reach the shell as code.
expand_path() {
    local p="$1"
    # systemd does not guarantee USER in the service environment
    local u="${USER:-$(id -un)}"
    p="${p//\$\{USER\}/$u}"
    p="${p//\$USER/$u}"
    p="${p//\$\{HOME\}/$HOME}"
    p="${p//\$HOME/$HOME}"
    printf '%s' "$p"
}

# Validate that the config has the fields the scripts depend on.
# jq only guarantees the file is syntactically valid JSON; a null screen_name
# would otherwise become the literal string "null" and propagate into paths.
validate_config_schema() {
    local config_file=$(get_config_file_path)
    local errors=""

    local missing_settings
    missing_settings=$(jq -r '
        ["main_dir", "python_cmd", "log_dir"]
        - (.settings // {} | with_entries(select(.value != null and .value != "")) | keys)
        | .[]' "$config_file" 2>/dev/null)
    if [ -n "$missing_settings" ]; then
        while read -r key; do
            errors+="  - settings.$key is missing or empty"$'\n'
        done <<< "$missing_settings"
    fi

    local bad_apps
    bad_apps=$(jq -r '
        .apps // {} | to_entries[]
        | select((.value.screen_name // "") == "" or (.value.script_path // "") == "")
        | .key' "$config_file" 2>/dev/null)
    if [ -n "$bad_apps" ]; then
        while read -r app; do
            errors+="  - app \"$app\" is missing screen_name or script_path"$'\n'
        done <<< "$bad_apps"
    fi

    # Duplicate screen names silently sabotage each other: start/stop hit the wrong app
    local dup_screens
    dup_screens=$(jq -r '
        [.apps // {} | .[].screen_name | select(. != null)]
        | group_by(.) | map(select(length > 1) | .[0]) | .[]' "$config_file" 2>/dev/null)
    if [ -n "$dup_screens" ]; then
        while read -r name; do
            errors+="  - screen_name \"$name\" is used by more than one app"$'\n'
        done <<< "$dup_screens"
    fi

    if [ -n "$errors" ]; then
        echo "Error: Invalid configuration in $config_file"
        printf '%s' "$errors"
        return 1
    fi
    return 0
}

# Field separator for APP_ROWS. Must not be whitespace: with a whitespace IFS
# (a tab counts) bash collapses consecutive separators, so an app without
# python_cmd would shift its description into the interpreter field.
CONFIG_FS=$'\x1f'

# Load the whole configuration in two jq calls and expose it as globals:
#   APP_ROWS[]  - CONFIG_FS separated: name, screen_name, script_path, python_cmd, description
#   MAIN_DIR / PYTHON_CMD / LOG_DIR            - raw values
#   EXPANDED_MAIN_DIR / EXPANDED_LOG_DIR       - with $USER/$HOME resolved
load_config() {
    check_jq
    check_config_file
    validate_config_schema || exit 1

    local config_file=$(get_config_file_path)

    mapfile -t APP_ROWS < <(jq -r '
        .apps // {} | to_entries[]
        | [.key, .value.screen_name, .value.script_path,
           (.value.python_cmd // ""), (.value.description // "")]
        | map(. // "") | join("\u001f")' "$config_file")

    local settings
    settings=$(jq -r '.settings | "MAIN_DIR=\(.main_dir|@sh) PYTHON_CMD=\(.python_cmd|@sh) LOG_DIR=\(.log_dir|@sh)"' "$config_file")
    eval "$settings"

    EXPANDED_MAIN_DIR="$(expand_path "$MAIN_DIR")"
    EXPANDED_LOG_DIR="$(expand_path "$LOG_DIR")"
}

# Resolve the interpreter for an app: per-app override, else the global default.
# A per-app python_cmd is relative to main_dir, same convention as script_path
# (e.g. "apps/my_app/.venv/bin/python"). Requires load_config to have run first.
app_python_cmd() {
    if [ -n "$1" ]; then
        printf '%s' "$EXPANDED_MAIN_DIR/$1"
    else
        printf '%s' "$PYTHON_CMD"
    fi
}

# Anchored screen session lookups.
# An unanchored match on "pyapp_foo" also matches "pyapp_foo2".
screen_session_exists() {
    screen -list | grep -qE "^[[:space:]]*[0-9]+\.$1[[:space:]]"
}

screen_session_dead() {
    screen -list | grep -E "^[[:space:]]*[0-9]+\.$1[[:space:]]" | grep -q "Dead"
}

# Poll instead of sleeping a fixed amount: a loaded Pi can be slower than any guess.
# Second argument is the number of 0.5s attempts (default 20 = 10 seconds).
wait_for_screen() {
    local i=0
    until screen_session_exists "$1"; do
        [ $((i++)) -ge "${2:-20}" ] && return 1
        sleep 0.5
    done
    return 0
}

wait_for_screen_gone() {
    local i=0
    while screen_session_exists "$1"; do
        [ $((i++)) -ge "${2:-20}" ] && return 1
        sleep 0.5
    done
    return 0
}

# Function to get all app names from config
get_app_names() {
    check_jq
    check_config_file
    local config_file=$(get_config_file_path)
    jq -r '.apps | keys[]' "$config_file" 2>/dev/null | sort
}

# Function to get screen name for an app
get_screen_name() {
    local app_name="$1"
    check_jq
    check_config_file

    if [ -z "$app_name" ]; then
        echo "Error: App name is required"
        return 1
    fi

    local config_file=$(get_config_file_path)
    jq -r ".apps.\"$app_name\".screen_name" "$config_file" 2>/dev/null
}

# Function to get script path for an app
get_script_path() {
    local app_name="$1"
    check_jq
    check_config_file

    if [ -z "$app_name" ]; then
        echo "Error: App name is required"
        return 1
    fi

    local config_file=$(get_config_file_path)
    jq -r ".apps.\"$app_name\".script_path" "$config_file" 2>/dev/null
}

# Function to get app description
get_app_description() {
    local app_name="$1"
    check_jq
    check_config_file

    if [ -z "$app_name" ]; then
        echo "Error: App name is required"
        return 1
    fi

    local config_file=$(get_config_file_path)
    jq -r ".apps.\"$app_name\".description" "$config_file" 2>/dev/null
}

# Function to get main directory
get_main_dir() {
    check_jq
    check_config_file
    local config_file=$(get_config_file_path)
    jq -r '.settings.main_dir' "$config_file" 2>/dev/null
}

# Function to get python command
get_python_cmd() {
    check_jq
    check_config_file
    local config_file=$(get_config_file_path)
    jq -r '.settings.python_cmd' "$config_file" 2>/dev/null
}

# Function to get log directory
get_log_dir() {
    check_jq
    check_config_file
    local config_file=$(get_config_file_path)
    jq -r '.settings.log_dir' "$config_file" 2>/dev/null
}

# Function to get all screen names from config
get_all_screen_names() {
    check_jq
    check_config_file
    local config_file=$(get_config_file_path)
    jq -r '.apps[].screen_name' "$config_file" 2>/dev/null | sort
}

# Function to validate if an app exists in config
app_exists() {
    local app_name="$1"
    check_jq
    check_config_file

    if [ -z "$app_name" ]; then
        return 1
    fi

    local config_file=$(get_config_file_path)
    jq -e ".apps.\"$app_name\"" "$config_file" >/dev/null 2>&1
}

# Function to get total number of apps
get_app_count() {
    check_jq
    check_config_file
    local config_file=$(get_config_file_path)
    jq '.apps | length' "$config_file" 2>/dev/null
}
