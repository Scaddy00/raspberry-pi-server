#!/bin/bash

# Script to diagnose systemd service problems
#
# Usage: ./test_service_startup.sh [--start-apps]
#   --start-apps  also run "manage_apps.sh start" at the end

set -uo pipefail

# Resolve paths from the script location, not from hardcoded /home/<user>/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

START_APPS=0
[ "${1:-}" = "--start-apps" ] && START_APPS=1

# Get current user
CURRENT_USER=${SUDO_USER:-${USER:-$(id -un)}}

AUTOSTART_UNIT="python-apps-autostart-$CURRENT_USER.service"
WATCHDOG_UNIT="python-apps-watchdog-$CURRENT_USER.service"
WATCHDOG_TIMER="python-apps-watchdog-$CURRENT_USER.timer"

echo "=== SYSTEMD SERVICE DIAGNOSTICS ==="
echo "User: $CURRENT_USER"
echo "Repository root: $REPO_ROOT"
echo ""

# Check if the service file exists
echo "1. Service file verification:"
if [ -f "/etc/systemd/system/$AUTOSTART_UNIT" ]; then
    echo "   ✓ Service file found"
    echo "   File content:"
    cat "/etc/systemd/system/$AUTOSTART_UNIT"
else
    echo "   ✗ Service file NOT found: /etc/systemd/system/$AUTOSTART_UNIT"
fi
echo ""

# Check service status
echo "2. Service status:"
systemctl status "$AUTOSTART_UNIT" --no-pager || true
echo ""

# Check service logs
echo "3. Recent service logs:"
journalctl -u "$AUTOSTART_UNIT" --no-pager -n 20 || true
echo ""

# Check watchdog timer
echo "4. Watchdog timer:"
if [ -f "/etc/systemd/system/$WATCHDOG_TIMER" ]; then
    echo "   ✓ Timer file found"
    systemctl list-timers --no-pager | grep -F "python-apps" || echo "   ⚠️  Timer not currently scheduled"
    echo "   Recent watchdog runs:"
    journalctl -u "$WATCHDOG_UNIT" --no-pager -n 10 || true
else
    echo "   ⚠️  Watchdog timer not installed (optional)"
fi
echo ""

# Check if app_manager directory exists
echo "5. App manager directory verification:"
if [ -d "$REPO_ROOT/app_manager" ]; then
    echo "   ✓ App manager directory found: $REPO_ROOT/app_manager"
else
    echo "   ✗ App manager directory NOT found: $REPO_ROOT/app_manager"
fi
echo ""

# Check if required scripts exist and are executable
echo "6. Script verification:"
required_scripts=(
    "$REPO_ROOT/app_manager/manage_apps.sh"
    "$REPO_ROOT/app_manager/config_utils.sh"
    "$REPO_ROOT/app_manager/apps_config.json"
)

for script in "${required_scripts[@]}"; do
    if [ -f "$script" ]; then
        echo "   ✓ Script found: $(basename "$script")"
        if [ -x "$script" ] || [[ "$script" == *.json ]]; then
            echo "   ✓ Script executable: $(basename "$script")"
        else
            echo "   ✗ Script NOT executable: $(basename "$script")"
        fi
    else
        echo "   ✗ Script NOT found: $(basename "$script")"
    fi
done
echo ""

# Check if config file exists
echo "7. Configuration file verification:"
config_file="$REPO_ROOT/app_manager/apps_config.json"
if [ -f "$config_file" ]; then
    echo "   ✓ Config file found"
    if command -v jq &> /dev/null; then
        if jq empty "$config_file" 2>/dev/null; then
            echo "   ✓ Config file is valid JSON"
        else
            echo "   ✗ Config file is NOT valid JSON"
        fi
    else
        echo "   ⚠️  jq not installed, cannot validate JSON"
    fi
else
    echo "   ✗ Config file NOT found"
fi
echo ""

# Check directory permissions
echo "8. Directory permissions:"
ls -la "$REPO_ROOT/" | head -10
echo ""

# Manual script test - opt-in, this actually starts the apps
echo "9. Manual script test:"
if [ "$START_APPS" -eq 1 ]; then
    echo "   Executing app manager start script..."
    (cd "$REPO_ROOT/app_manager" && ./manage_apps.sh start)
else
    echo "   Skipped (re-run with --start-apps to actually start the apps)"
    echo "   Read-only check instead:"
    (cd "$REPO_ROOT/app_manager" && ./manage_apps.sh status)
fi
echo ""

echo "=== DIAGNOSTICS COMPLETE ==="
