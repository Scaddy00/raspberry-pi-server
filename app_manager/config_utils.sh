#!/bin/bash

# Utility functions for reading JSON configuration
# Requires 'jq' to be installed: sudo apt-get install jq

CONFIG_FILE="apps_config.json"

# Function to check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed. Install with: sudo apt-get install jq"
        exit 1
    fi
}

# Function to check if config file exists and is valid JSON
check_config_file() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Configuration file $CONFIG_FILE not found"
        exit 1
    fi
    
    # Validate JSON format
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        echo "Error: Configuration file $CONFIG_FILE is not valid JSON"
        exit 1
    fi
}

# Function to get all app names from config
get_app_names() {
    check_jq
    check_config_file
    jq -r '.apps | keys[]' "$CONFIG_FILE" 2>/dev/null | sort
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
    
    jq -r ".apps.\"$app_name\".screen_name" "$CONFIG_FILE" 2>/dev/null
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
    
    jq -r ".apps.\"$app_name\".script_path" "$CONFIG_FILE" 2>/dev/null
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
    
    jq -r ".apps.\"$app_name\".description" "$CONFIG_FILE" 2>/dev/null
}

# Function to get main directory
get_main_dir() {
    check_jq
    check_config_file
    jq -r '.settings.main_dir' "$CONFIG_FILE" 2>/dev/null
}

# Function to get python command
get_python_cmd() {
    check_jq
    check_config_file
    jq -r '.settings.python_cmd' "$CONFIG_FILE" 2>/dev/null
}

# Function to get log directory
get_log_dir() {
    check_jq
    check_config_file
    jq -r '.settings.log_dir' "$CONFIG_FILE" 2>/dev/null
}

# Function to get all screen names from config
get_all_screen_names() {
    check_jq
    check_config_file
    jq -r '.apps[].screen_name' "$CONFIG_FILE" 2>/dev/null | sort
}

# Function to validate if an app exists in config
app_exists() {
    local app_name="$1"
    check_jq
    check_config_file
    
    if [ -z "$app_name" ]; then
        return 1
    fi
    
    jq -e ".apps.\"$app_name\"" "$CONFIG_FILE" >/dev/null 2>&1
}

# Function to get total number of apps
get_app_count() {
    check_jq
    check_config_file
    jq '.apps | length' "$CONFIG_FILE" 2>/dev/null
} 