#!/bin/bash

# Script to install and configure the systemd services
# Run this script as root (sudo)
#
# Usage: sudo ./install_service.sh [--no-watchdog] [--no-logrotate]

set -uo pipefail

# Resolve paths from the script location, not from the current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

INSTALL_WATCHDOG=1
INSTALL_LOGROTATE=1
for arg in "$@"; do
    case "$arg" in
        --no-watchdog)  INSTALL_WATCHDOG=0;;
        --no-logrotate) INSTALL_LOGROTATE=0;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: sudo $0 [--no-watchdog] [--no-logrotate]"
            exit 1
            ;;
    esac
done

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this script must be run as root (use sudo)"
    exit 1
fi

# Get the user the services should run as (the one who called sudo)
CURRENT_USER=${SUDO_USER:-$USER}
if [ -z "$CURRENT_USER" ] || [ "$CURRENT_USER" = "root" ]; then
    echo "Error: cannot determine the target user. Run with sudo from a normal user account."
    exit 1
fi

echo "Installing systemd services for user: $CURRENT_USER"
echo "Repository root: $REPO_ROOT"
echo ""

# Verify that the required files exist
required_files=(
    "$SCRIPT_DIR/python-apps-autostart.service"
    "$REPO_ROOT/app_manager/manage_apps.sh"
    "$REPO_ROOT/app_manager/config_utils.sh"
    "$REPO_ROOT/app_manager/apps_config.json"
)
for f in "${required_files[@]}"; do
    if [ ! -f "$f" ]; then
        echo "Error: required file not found: $f"
        exit 1
    fi
done

# Make scripts executable
chmod +x "$REPO_ROOT/app_manager"/*.sh

# Renders a unit template into /etc/systemd/system
render_unit() {
    local template="$1"
    local target_name="$2"
    sed -e "s|__USER__|$CURRENT_USER|g" \
        -e "s|__INSTALL_DIR__|$REPO_ROOT|g" \
        -e "s|__WATCHDOG_SERVICE__|python-apps-watchdog-$CURRENT_USER.service|g" \
        "$template" > "/etc/systemd/system/$target_name"
    echo "  Written /etc/systemd/system/$target_name"
}

# --- Main autostart service ---
AUTOSTART_UNIT="python-apps-autostart-$CURRENT_USER.service"
echo "Installing $AUTOSTART_UNIT"
render_unit "$SCRIPT_DIR/python-apps-autostart.service" "$AUTOSTART_UNIT"

# --- Watchdog service + timer ---
WATCHDOG_UNIT="python-apps-watchdog-$CURRENT_USER.service"
WATCHDOG_TIMER="python-apps-watchdog-$CURRENT_USER.timer"
if [ "$INSTALL_WATCHDOG" -eq 1 ]; then
    echo "Installing $WATCHDOG_TIMER"
    render_unit "$SCRIPT_DIR/python-apps-watchdog.service" "$WATCHDOG_UNIT"
    render_unit "$SCRIPT_DIR/python-apps-watchdog.timer" "$WATCHDOG_TIMER"
fi

# --- Log rotation ---
if [ "$INSTALL_LOGROTATE" -eq 1 ]; then
    if ! command -v jq >/dev/null 2>&1; then
        echo "Warning: jq not installed, skipping logrotate setup"
    else
        LOG_DIR_RAW=$(jq -r '.settings.log_dir' "$REPO_ROOT/app_manager/apps_config.json")
        # Expand against the target user, not root: under sudo $USER/$HOME point at root
        LOG_DIR="${LOG_DIR_RAW//\$\{USER\}/$CURRENT_USER}"
        LOG_DIR="${LOG_DIR//\$USER/$CURRENT_USER}"
        LOG_DIR="${LOG_DIR//\$\{HOME\}//home/$CURRENT_USER}"
        LOG_DIR="${LOG_DIR//\$HOME//home/$CURRENT_USER}"

        echo "Installing logrotate config for $LOG_DIR"
        sed -e "s|__LOG_DIR__|$LOG_DIR|g" \
            -e "s|__USER__|$CURRENT_USER|g" \
            "$SCRIPT_DIR/logrotate-python-apps.template" > /etc/logrotate.d/python-apps
        echo "  Written /etc/logrotate.d/python-apps"
    fi
fi

# Reload systemd configuration
echo ""
echo "Reloading systemd..."
systemctl daemon-reload

# Enable the units
systemctl enable "$AUTOSTART_UNIT"
if [ "$INSTALL_WATCHDOG" -eq 1 ]; then
    systemctl enable "$WATCHDOG_TIMER"
    systemctl start "$WATCHDOG_TIMER"
fi

# Verify installation
echo ""
if systemctl is-enabled "$AUTOSTART_UNIT" >/dev/null 2>&1; then
    echo "Service installed and enabled successfully!"
else
    echo "Warning: Service installation may have failed. Check with:"
    echo "  sudo systemctl status $AUTOSTART_UNIT"
fi

echo ""
echo "Useful commands:"
echo "  sudo systemctl start $AUTOSTART_UNIT     # Start the apps"
echo "  sudo systemctl stop $AUTOSTART_UNIT      # Stop the service"
echo "  sudo systemctl status $AUTOSTART_UNIT    # Check status"
echo "  sudo journalctl -u $AUTOSTART_UNIT -f    # View logs in real-time"
if [ "$INSTALL_WATCHDOG" -eq 1 ]; then
    echo ""
    echo "Watchdog (restarts crashed apps every 5 minutes):"
    echo "  systemctl list-timers | grep python-apps   # Check next run"
    echo "  sudo journalctl -u $WATCHDOG_UNIT -f       # Watchdog logs"
fi
echo ""
echo "Note: The service will start apps defined in app_manager/apps_config.json"
