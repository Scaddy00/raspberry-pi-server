#!/bin/bash

# Main script to manage all Python applications - start, stop, status, restart, list, heal
# Usage: ./manage_apps.sh [start|stop|status|restart|list|logs|heal]

set -uo pipefail  # Exit on undefined vars, pipe failures (but not on command errors)

# Source the configuration utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config_utils.sh"

# Load and validate the whole configuration up front
load_config

mkdir -p "$EXPANDED_LOG_DIR"

# Logging function with timestamp and level, with emoji
log_file="$EXPANDED_LOG_DIR/manage_apps.log"
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
    log_message "INFO" "Usage: $0 [start|stop|status|restart|list|logs|heal]"
    echo ""
    echo "Commands:"
    echo "  start   - Start all configured applications"
    echo "  stop    - Stop all configured applications"
    echo "  status  - Show status of all configured applications"
    echo "  restart - Restart all configured applications"
    echo "  list    - List all configured applications"
    echo "  logs    - Show recent logs for all applications"
    echo "  heal    - Restart only the applications that are stopped or dead"
    echo ""
    echo "Examples:"
    echo "  $0 status    # Check status of all apps"
    echo "  $0 logs      # Show recent logs"
    echo "  $0 heal      # Bring back only what crashed"
    echo ""
}

# Function to show status of all apps
show_status() {
    log_message "INFO" "Showing application status"
    echo "=== Application Status ==="
    echo ""

    if [ ${#APP_ROWS[@]} -eq 0 ]; then
        log_message "WARNING" "No applications configured."
        echo "No applications configured."
        return
    fi

    echo "Total configured applications: ${#APP_ROWS[@]}"
    echo ""

    # Track statistics
    running_count=0
    stopped_count=0
    dead_count=0
    missing_count=0

    local app screen_name script_path_rel app_python description
    while IFS="$CONFIG_FS" read -r app screen_name script_path_rel app_python description; do
        local script_path="$EXPANDED_MAIN_DIR/$script_path_rel"

        echo "App: $app"
        echo "  Description: $description"
        echo "  Script: $script_path"
        echo "  Screen: $screen_name"
        echo "  Python: $(app_python_cmd "$app_python")"

        if screen_session_exists "$screen_name"; then
            if screen_session_dead "$screen_name"; then
                echo "  Status: DEAD (needs cleanup)"
                dead_count=$((dead_count + 1))
            else
                echo "  Status: RUNNING"
                running_count=$((running_count + 1))
            fi
        else
            echo "  Status: STOPPED"
            stopped_count=$((stopped_count + 1))
        fi

        # Check if script file exists
        if [ -f "$script_path" ]; then
            echo "  Script file: EXISTS"
        else
            echo "  Script file: MISSING"
            missing_count=$((missing_count + 1))
        fi

        echo ""
    done < <(printf '%s\n' "${APP_ROWS[@]}")

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

    if [ ${#APP_ROWS[@]} -eq 0 ]; then
        log_message "WARNING" "No applications configured."
        echo "No applications configured."
        return
    fi

    echo "Total applications: ${#APP_ROWS[@]}"
    echo ""

    local app screen_name script_path_rel app_python description
    while IFS="$CONFIG_FS" read -r app screen_name script_path_rel app_python description; do
        echo "App: $app"
        echo "  Description: $description"
        echo "  Script: $script_path_rel"
        echo "  Screen: $screen_name"
        echo "  Python: $(app_python_cmd "$app_python")"
        echo ""
    done < <(printf '%s\n' "${APP_ROWS[@]}")
}

# Function to show recent logs
show_logs() {
    log_message "INFO" "Showing recent logs for all applications"
    echo "=== Recent Application Logs ==="
    echo ""

    if [ ${#APP_ROWS[@]} -eq 0 ]; then
        log_message "WARNING" "No applications configured."
        echo "No applications configured."
        return
    fi

    local app rest
    while IFS="$CONFIG_FS" read -r app rest; do
        local log_file_app="$EXPANDED_LOG_DIR/${app}.log"

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
    done < <(printf '%s\n' "${APP_ROWS[@]}")

    # Show main log
    echo "=== Main Log ==="
    if [ -f "$log_file" ] && [ -s "$log_file" ]; then
        echo "Last 10 lines of manage_apps.log:"
        tail -n 10 "$log_file"
    else
        echo "No manager log yet"
    fi
    echo ""
}

# Start a single application.
# Returns: 0 started, 1 failed, 2 already running
start_one_app() {
    local app="$1"
    local screen_name="$2"
    local script_path_rel="$3"
    local app_python_override="$4"
    local description="$5"

    local script_path="$EXPANDED_MAIN_DIR/$script_path_rel"
    local app_log="$EXPANDED_LOG_DIR/${app}.log"
    local python_bin
    python_bin="$(app_python_cmd "$app_python_override")"

    log_message "INFO" "Starting app: $app ($description)"
    log_message "INFO" "Script: $script_path"
    log_message "INFO" "Screen: $screen_name"

    if [ ! -f "$script_path" ]; then
        log_message "ERROR" "Script file not found: $script_path"
        return 1
    fi

    if screen_session_exists "$screen_name"; then
        if screen_session_dead "$screen_name"; then
            log_message "INFO" "Screen $screen_name is dead, removing it first."
            screen -S "$screen_name" -X quit >/dev/null 2>&1
            wait_for_screen_gone "$screen_name" 10
            screen -wipe >/dev/null 2>&1
        else
            log_message "INFO" "Screen $screen_name is already running."
            return 2
        fi
    fi

    # Redirect inside the screen so the log file is actually written.
    # python -u keeps output unbuffered, otherwise logs stay empty for minutes.
    log_message "INFO" "Starting $app in screen session $screen_name..."
    if screen -dmS "$screen_name" bash -c \
        "exec $(printf '%q' "$python_bin") -u $(printf '%q' "$script_path") >> $(printf '%q' "$app_log") 2>&1"
    then
        if wait_for_screen "$screen_name" 20; then
            log_message "SUCCESS" "Application $app started successfully in screen $screen_name."
            return 0
        fi
        log_message "ERROR" "Screen session $screen_name not found after start attempt."
        return 1
    fi

    log_message "ERROR" "Failed to start application $app in screen $screen_name."
    return 1
}

# Function to start all managed apps
start_all_apps() {
    log_message "INFO" "Starting all configured Python applications."

    if [ ${#APP_ROWS[@]} -eq 0 ]; then
        log_message "WARNING" "No applications configured."
        return 0
    fi

    log_message "INFO" "Found ${#APP_ROWS[@]} configured applications to start."

    started_count=0
    already_running_count=0
    failed_count=0

    local app screen_name script_path_rel app_python description
    while IFS="$CONFIG_FS" read -r app screen_name script_path_rel app_python description; do
        start_one_app "$app" "$screen_name" "$script_path_rel" "$app_python" "$description"
        case $? in
            0) started_count=$((started_count + 1));;
            2) already_running_count=$((already_running_count + 1));;
            *) failed_count=$((failed_count + 1));;
        esac
    done < <(printf '%s\n' "${APP_ROWS[@]}")

    log_message "INFO" "=== Start Summary ==="
    log_message "INFO" "Started: $started_count"
    log_message "INFO" "Already running: $already_running_count"
    log_message "INFO" "Failed: $failed_count"

    [ "$failed_count" -eq 0 ]
}

# Restart only the apps that are not running - used by the watchdog timer
heal_apps() {
    log_message "INFO" "Checking for stopped or dead applications."

    if [ ${#APP_ROWS[@]} -eq 0 ]; then
        log_message "WARNING" "No applications configured."
        return 0
    fi

    screen -wipe >/dev/null 2>&1

    healthy_count=0
    healed_count=0
    failed_count=0

    local app screen_name script_path_rel app_python description
    while IFS="$CONFIG_FS" read -r app screen_name script_path_rel app_python description; do
        if screen_session_exists "$screen_name" && ! screen_session_dead "$screen_name"; then
            healthy_count=$((healthy_count + 1))
            continue
        fi

        log_message "WARNING" "Application $app is not running, restarting it."
        if start_one_app "$app" "$screen_name" "$script_path_rel" "$app_python" "$description"; then
            healed_count=$((healed_count + 1))
        else
            failed_count=$((failed_count + 1))
        fi
    done < <(printf '%s\n' "${APP_ROWS[@]}")

    log_message "INFO" "=== Heal Summary ==="
    log_message "INFO" "Healthy: $healthy_count"
    log_message "INFO" "Restarted: $healed_count"
    log_message "INFO" "Failed: $failed_count"

    [ "$failed_count" -eq 0 ]
}

# Function to stop all managed apps
stop_all_apps() {
    log_message "INFO" "Starting stop procedure for managed Python applications."
    log_message "INFO" "Cleaning up dead screen sessions..."
    screen -wipe >/dev/null 2>&1

    if [ ${#APP_ROWS[@]} -eq 0 ]; then
        log_message "WARNING" "No applications configured."
        return 0
    fi

    log_message "INFO" "Found ${#APP_ROWS[@]} configured applications to stop."

    stopped_count=0
    already_stopped_count=0
    failed_count=0

    local app screen_name rest
    while IFS="$CONFIG_FS" read -r app screen_name rest; do
        log_message "INFO" "Stopping screen: $screen_name"

        if ! screen_session_exists "$screen_name"; then
            log_message "INFO" "Screen $screen_name not found (already stopped or never started)."
            already_stopped_count=$((already_stopped_count + 1))
            continue
        fi

        if screen_session_dead "$screen_name"; then
            log_message "INFO" "Screen $screen_name is dead, removing it."
        else
            log_message "INFO" "Terminating active screen $screen_name."
        fi

        screen -S "$screen_name" -X quit >/dev/null 2>&1
        if wait_for_screen_gone "$screen_name" 20; then
            log_message "SUCCESS" "Screen $screen_name terminated."
            stopped_count=$((stopped_count + 1))
        else
            log_message "ERROR" "Screen $screen_name still present after quit command."
            failed_count=$((failed_count + 1))
        fi
    done < <(printf '%s\n' "${APP_ROWS[@]}")

    # Final cleanup
    screen -wipe >/dev/null 2>&1

    log_message "INFO" "=== Stop Summary ==="
    log_message "INFO" "Stopped: $stopped_count"
    log_message "INFO" "Already stopped: $already_stopped_count"
    log_message "INFO" "Failed: $failed_count"

    [ "$failed_count" -eq 0 ]
}

# Main script logic
case "${1:-}" in
    start)
        log_message "INFO" "Starting all configured applications..."
        if start_all_apps; then
            log_message "SUCCESS" "All applications started."
        else
            log_message "ERROR" "Some applications failed to start."
            exit 1
        fi
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
            if start_all_apps; then
                log_message "SUCCESS" "All applications restarted."
            else
                log_message "ERROR" "Some applications failed to start during restart."
                exit 1
            fi
        else
            log_message "ERROR" "Some applications failed to stop during restart."
            exit 1
        fi
        ;;
    heal)
        if heal_apps; then
            log_message "SUCCESS" "All applications are running."
        else
            log_message "ERROR" "Some applications could not be restarted."
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
