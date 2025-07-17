#!/bin/bash

# Manage Python applications - start, stop, status, restart, list
# Usage: ./manage_apps.sh [start|stop|status|restart|list|logs]

set -euo pipefail  # Exit on error, undefined vars, pipe failures

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [start|stop|status|restart|list|logs]"
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
    echo "=== Application Status ==="
    echo ""
    
    app_names=$(get_app_names)
    app_count=$(get_app_count)
    
    if [ -z "$app_names" ]; then
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
    echo "=== Configured Applications ==="
    echo ""
    
    app_names=$(get_app_names)
    app_count=$(get_app_count)
    
    if [ -z "$app_names" ]; then
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
    echo "=== Recent Application Logs ==="
    echo ""
    
    app_names=$(get_app_names)
    
    if [ -z "$app_names" ]; then
        echo "No applications configured."
        return
    fi
    
    for app in $app_names; do
        log_file="$log_dir/${app}.log"
        
        echo "=== $app ==="
        if [ -f "$log_file" ]; then
            if [ -s "$log_file" ]; then
                echo "Last 10 lines of $app.log:"
                tail -n 10 "$log_file"
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
        log_file="$log_dir/${log_type}.log"
        echo "=== $log_type.log ==="
        if [ -f "$log_file" ]; then
            if [ -s "$log_file" ]; then
                echo "Last 5 lines:"
                tail -n 5 "$log_file"
            else
                echo "Log file exists but is empty"
            fi
        else
            echo "Log file not found"
        fi
        echo ""
    done
}

# Main script logic
case "${1:-}" in
    start)
        echo "Starting all configured applications..."
        "$SCRIPT_DIR/start_scripts.sh"
        ;;
    stop)
        echo "Stopping all configured applications..."
        "$SCRIPT_DIR/stop_scripts.sh"
        ;;
    status)
        show_status
        ;;
    restart)
        echo "Restarting all configured applications..."
        "$SCRIPT_DIR/stop_scripts.sh"
        sleep 2
        "$SCRIPT_DIR/start_scripts.sh"
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