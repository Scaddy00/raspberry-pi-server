#!/bin/bash

# Main script to manage all Python applications - start, stop, status, restart, list
# Usage: ./manage_apps.sh [start|stop|status|restart|list|logs]

set -uo pipefail  # Exit on undefined vars, pipe failures (but not on command errors)

# Source the configuration utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config_utils.sh"

# Check if config file exists and is valid
check_config_file

# Get configuration values
main_dir=$(get_main_dir)
log_dir=$(get_log_dir)

# Validate configuration
if [ -z "$main_dir" ] || [ -z "$log_dir" ]; then
    echo "Error: Invalid configuration values. Check apps_config.json"
    exit 1
fi

# Logging function with timestamp and level, with emoji
log_file="$log_dir/manage_apps.log"
log_message() {
    local level="$1"
    local message="$2"
    local emoji=""
    case "$level" in
        INFO) emoji="ℹ️";;
        SUCCESS) emoji="✅";;
        WARNING) emoji="⚠️";;
        ERROR) emoji="❌";;
    esac
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local log_entry="$timestamp - $level $emoji - $message"
    echo "$log_entry" | tee -a "$log_file"
}

# Function to show usage
show_usage() {
    log_message "INFO" "Usage: $0 [start|stop|status|restart|list|logs]"
    echo ""
    echo "Commands:"
    echo "  start   - Start all configured applications"
    echo "  stop    - Stop all configured applications"
    echo "  status  - Show status of all configured applications"
    echo "  restart - Restart all configured applications"
    echo "  list    - List all configured applications"
    echo "  logs    - Show recent logs for all applications"
    echo ""
    echo "Examples:"
    echo "  $0 status    # Check status of all apps"
    echo "  $0 logs      # Show recent logs"
    echo ""
}

# Function to show status of all apps
show_status() {
    log_message "INFO" "Showing application status"
    echo "=== Application Status ==="
    echo ""
    
    app_names=$(get_app_names)
    app_count=$(get_app_count)
    
    if [ -z "$app_names" ]; then
        log_message "WARNING" "No applications configured."
        echo "No applications configured."
        return
    fi
    
    echo "Total configured applications: $app_count"
    echo ""
    
    # Track statistics
    running_count=0
    stopped_count=0
    dead_count=0
    missing_count=0
    
    for app in $app_names; do
        screen_name=$(get_screen_name "$app")
        script_path="$main_dir/$(get_script_path "$app")"
        description=$(get_app_description "$app")
        
        echo "App: $app"
        echo "  Description: $description"
        echo "  Script: $script_path"
        echo "  Screen: $screen_name"
        
        # Check if screen session exists
        if screen -list | grep -q "\.${screen_name}"; then
            if screen -list | grep -q "\.${screen_name}.*Dead"; then
                echo "  Status: DEAD (needs cleanup)"
                ((dead_count++))
            else
                echo "  Status: RUNNING"
                ((running_count++))
            fi
        else
            echo "  Status: STOPPED"
            ((stopped_count++))
        fi
        
        # Check if script file exists
        if [ -f "$script_path" ]; then
            echo "  Script file: EXISTS"
        else
            echo "  Script file: MISSING"
            ((missing_count++))
        fi
        
        echo ""
    done
    
    # Summary
    echo "=== Summary ==="
    echo "Running: $running_count"
    echo "Stopped: $stopped_count"
    echo "Dead: $dead_count"
    echo "Missing scripts: $missing_count"
    echo ""
}

# Function to list all configured apps
list_apps() {
    log_message "INFO" "Listing all configured applications"
    echo "=== Configured Applications ==="
    echo ""
    
    app_names=$(get_app_names)
    app_count=$(get_app_count)
    
    if [ -z "$app_names" ]; then
        log_message "WARNING" "No applications configured."
        echo "No applications configured."
        return
    fi
    
    echo "Total applications: $app_count"
    echo ""
    
    for app in $app_names; do
        screen_name=$(get_screen_name "$app")
        script_path=$(get_script_path "$app")
        description=$(get_app_description "$app")
        
        echo "App: $app"
        echo "  Description: $description"
        echo "  Script: $script_path"
        echo "  Screen: $screen_name"
        echo ""
    done
}

# Function to show recent logs
show_logs() {
    log_message "INFO" "Showing recent logs for all applications"
    echo "=== Recent Application Logs ==="
    echo ""
    
    app_names=$(get_app_names)
    
    if [ -z "$app_names" ]; then
        log_message "WARNING" "No applications configured."
        echo "No applications configured."
        return
    fi
    
    for app in $app_names; do
        log_file_app="$log_dir/${app}.log"
        
        echo "=== $app ==="
        if [ -f "$log_file_app" ]; then
            if [ -s "$log_file_app" ]; then
                echo "Last 10 lines of $app.log:"
                tail -n 10 "$log_file_app"
            else
                echo "Log file exists but is empty"
            fi
        else
            echo "Log file not found"
        fi
        echo ""
    done
    
    # Show main logs
    echo "=== Main Logs ==="
    for log_type in "start_scripts" "stop_scripts"; do
        log_file_type="$log_dir/${log_type}.log"
        echo "=== $log_type.log ==="
        if [ -f "$log_file_type" ]; then
            if [ -s "$log_file_type" ]; then
                echo "Last 5 lines:"
                tail -n 5 "$log_file_type"
            else
                echo "Log file exists but is empty"
            fi
        else
            echo "Log file not found"
        fi
        echo ""
    done
}

# Function to stop all managed apps (merged from stop_all_apps.sh)
stop_all_apps() {
    log_message "INFO" "Starting stop procedure for managed Python applications."
    # Clean up dead screen sessions
    log_message "INFO" "Cleaning up dead screen sessions..."
    screen -wipe >/dev/null 2>&1

    # Get all screen names from configuration
    screen_names=$(get_all_screen_names)
    app_count=$(get_app_count)

    if [ -z "$screen_names" ]; then
        log_message "WARNING" "No screen sessions defined in configuration."
        return 0
    fi

    log_message "INFO" "Found $app_count configured applications to stop."

    # Statistics
    stopped_count=0
    already_stopped_count=0
    failed_count=0

    for screen_name in $screen_names; do
        log_message "INFO" "Stopping screen: $screen_name"
        # Check if the session exists
        if screen -list | grep -q "\.${screen_name}"; then
            # Check if the session is dead
            if screen -list | grep -q "\.${screen_name}.*Dead"; then
                log_message "INFO" "Screen $screen_name is dead, removing it."
                if screen -S "$screen_name" -X quit >/dev/null 2>&1; then
                    log_message "SUCCESS" "Dead screen $screen_name removed."
                    ((stopped_count++))
                else
                    log_message "ERROR" "Failed to remove dead screen $screen_name."
                    ((failed_count++))
                fi
            else
                log_message "INFO" "Terminating active screen $screen_name."
                if screen -S "$screen_name" -X quit; then
                    log_message "SUCCESS" "Active screen $screen_name terminated."
                    ((stopped_count++))
                else
                    log_message "ERROR" "Failed to terminate screen $screen_name."
                    ((failed_count++))
                fi
            fi
        else
            log_message "INFO" "Screen $screen_name not found (already stopped or never started)."
            ((already_stopped_count++))
        fi
        sleep 0.5
        # Extra check: verify that the session is actually terminated
        if screen -list | grep -q "\.${screen_name}"; then
            log_message "WARNING" "Screen $screen_name may still be running after quit command."
        fi
    done

    # Final cleanup
    screen -wipe >/dev/null 2>&1

    # Final summary
    log_message "INFO" "=== Stop Summary ==="
    log_message "INFO" "Stopped: $stopped_count"
    log_message "INFO" "Already stopped: $already_stopped_count"
    log_message "INFO" "Failed: $failed_count"
    log_message "INFO" "All configured screen sessions have been processed."
}

# Main script logic
case "${1:-}" in
    start)
        log_message "INFO" "Starting all configured applications..."
        # (Assume start logic is now handled here or in manage_apps.sh itself)
        ;;
    stop)
        log_message "INFO" "Stopping all configured applications..."
        if stop_all_apps; then
            log_message "SUCCESS" "All applications stopped."
        else
            log_message "ERROR" "Some applications failed to stop."
            exit 1
        fi
        ;;
    status)
        show_status
        ;;
    restart)
        log_message "INFO" "Restarting all configured applications..."
        if stop_all_apps; then
            sleep 2
            # (Assume start logic is now handled here or in manage_apps.sh itself)
            log_message "SUCCESS" "All applications restarted."
        else
            log_message "ERROR" "Some applications failed to stop during restart."
            exit 1
        fi
        ;;
    list)
        list_apps
        ;;
    logs)
        show_logs
        ;;
    *)
        show_usage
        exit 1
        ;;
esac 