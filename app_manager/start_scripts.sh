#!/bin/bash

# Start multiple Python scripts directly from a single Bash file
# Each script is started in a separate screen session, with separate logs and central summary log

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Source the configuration utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config_utils.sh"

# Check if config file exists and is valid
check_config_file

# Get configuration values
main_dir=$(get_main_dir)
python_cmd=$(get_python_cmd)
log_dir=$(get_log_dir)

# Validate configuration values
if [ -z "$main_dir" ] || [ -z "$python_cmd" ] || [ -z "$log_dir" ]; then
    echo "Error: Invalid configuration values. Check apps_config.json"
    exit 1
fi

# Create log directory
mkdir -p "$log_dir"
log_file="$log_dir/start_scripts.log"

# Function to log messages with timestamp
log_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $level - $message" | tee -a "$log_file"
}

log_message "INFO" "Starting all Python apps in screen sessions..."

# Clean up any dead screen sessions first
log_message "INFO" "Cleaning up dead screen sessions..."
screen -wipe >/dev/null 2>&1

# Get all app names from config
app_names=$(get_app_names)
app_count=$(get_app_count)

if [ -z "$app_names" ]; then
    log_message "WARNING" "No applications found in configuration"
    exit 0
fi

log_message "INFO" "Found $app_count applications to start"

# Track statistics
started_count=0
skipped_count=0
failed_count=0

for app in $app_names; do
    script_path="$main_dir/$(get_script_path "$app")"
    log_file_app="$log_dir/${app}.log"
    screen_name=$(get_screen_name "$app")
    description=$(get_app_description "$app")

    log_message "INFO" "Processing app: $app ($description)"

    # Validate app configuration
    if [ -z "$screen_name" ] || [ -z "$script_path" ]; then
        log_message "ERROR" "Invalid configuration for app: $app"
        ((failed_count++))
        continue
    fi

    if [ ! -f "$script_path" ]; then
        log_message "ERROR" "Script not found: $script_path"
        ((failed_count++))
        continue
    fi

    # Check if screen session already exists and is active
    if screen -list | grep -q "\.${screen_name}"; then
        # Check if the session is dead
        if screen -list | grep -q "\.${screen_name}.*Dead"; then
            log_message "INFO" "Found dead screen session $screen_name, removing it"
            screen -S "$screen_name" -X quit >/dev/null 2>&1
            sleep 1
        else
            log_message "INFO" "Screen session $screen_name already running, skipping"
            ((skipped_count++))
            continue
        fi
    fi

    log_message "INFO" "Starting $script_path in screen session $screen_name"
    
    # Start the screen session
    if screen -dmS "$screen_name" bash -c "'$python_cmd' '$script_path' >> '$log_file_app' 2>&1"; then
        log_message "SUCCESS" "$script_path started in screen session $screen_name"
        ((started_count++))
    else
        log_message "ERROR" "Failed to start $script_path in screen session $screen_name"
        ((failed_count++))
    fi
done

# Final summary
log_message "INFO" "Startup complete - Started: $started_count, Skipped: $skipped_count, Failed: $failed_count"
log_message "INFO" "Check individual logs in $log_dir and use 'screen -ls' to see running sessions" 