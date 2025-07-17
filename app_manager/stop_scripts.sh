#!/bin/bash

# Stop only screen sessions defined in the configuration file

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Source the configuration utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config_utils.sh"

# Check if config file exists and is valid
check_config_file

# Get log directory from config
log_dir=$(get_log_dir)

# Validate log directory
if [ -z "$log_dir" ]; then
    echo "Error: Invalid log directory configuration"
    exit 1
fi

log_file="$log_dir/stop_scripts.log"
mkdir -p "$log_dir"

# Function to log messages with timestamp
log_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $level - $message" | tee -a "$log_file"
}

log_message "INFO" "Stopping configured screen sessions..."

# Clean up dead sessions first
log_message "INFO" "Cleaning up dead screen sessions..."
screen -wipe >/dev/null 2>&1

# Get all screen names from config
screen_names=$(get_all_screen_names)
app_count=$(get_app_count)

if [ -z "$screen_names" ]; then
    log_message "WARNING" "No screen sessions defined in configuration"
    exit 0
fi

log_message "INFO" "Found $app_count configured applications to stop"

# Terminate all configured screen sessions
log_message "INFO" "Terminating the following configured screen sessions:"
echo "$screen_names" | tee -a "$log_file"

# Track statistics
stopped_count=0
already_stopped_count=0
failed_count=0

for screen_name in $screen_names; do
    log_message "INFO" "Processing screen: $screen_name"
    
    # Check if session exists
    if screen -list | grep -q "\.${screen_name}"; then
        # Check if session is dead
        if screen -list | grep -q "\.${screen_name}.*Dead"; then
            log_message "INFO" "Screen $screen_name is dead, removing it"
            if screen -S "$screen_name" -X quit >/dev/null 2>&1; then
                log_message "SUCCESS" "Dead screen $screen_name removed"
                ((stopped_count++))
            else
                log_message "ERROR" "Failed to remove dead screen $screen_name"
                ((failed_count++))
            fi
        else
            log_message "INFO" "Terminating active screen $screen_name"
            if screen -S "$screen_name" -X quit; then
                log_message "SUCCESS" "Active screen $screen_name terminated"
                ((stopped_count++))
            else
                log_message "ERROR" "Failed to terminate screen $screen_name"
                ((failed_count++))
            fi
        fi
    else
        log_message "INFO" "Screen $screen_name not found (already stopped or never started)"
        ((already_stopped_count++))
    fi
    
    sleep 0.5
done

# Final cleanup
screen -wipe >/dev/null 2>&1

# Final summary
log_message "INFO" "Stop complete - Stopped: $stopped_count, Already stopped: $already_stopped_count, Failed: $failed_count"
log_message "INFO" "All configured screen sessions have been processed"