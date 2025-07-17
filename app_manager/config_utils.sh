#!/bin/bash

# Utility functions for reading JSON configuration
# Requires 'jq' to be installed: sudo apt-get install jq

# Function to get the config file path dynamically
get_config_file_path() {
    # Get the directory of the calling script
    local script_dir=""
    
    # If we're in debug directory, go up one level
    if [[ "${BASH_SOURCE[1]}" == *"/debug/"* ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")/.." && pwd)"
    else
        script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    fi
    
    echo "$script_dir/apps_config.json"
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