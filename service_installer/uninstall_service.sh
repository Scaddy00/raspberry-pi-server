#!/bin/bash

# Removes the systemd units installed by install_service.sh.
# Does NOT stop running apps and does NOT delete any log file.
# Run this script as root (sudo)

set -uo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this script must be run as root (use sudo)"
    exit 1
fi

CURRENT_USER=${SUDO_USER:-$USER}
if [ -z "$CURRENT_USER" ] || [ "$CURRENT_USER" = "root" ]; then
    echo "Error: cannot determine the target user. Run with sudo from a normal user account."
    exit 1
fi

AUTOSTART_UNIT="python-apps-autostart-$CURRENT_USER.service"
WATCHDOG_UNIT="python-apps-watchdog-$CURRENT_USER.service"
WATCHDOG_TIMER="python-apps-watchdog-$CURRENT_USER.timer"

echo "This will remove the following from /etc/systemd/system:"
echo "  $AUTOSTART_UNIT"
echo "  $WATCHDOG_UNIT"
echo "  $WATCHDOG_TIMER"
echo "and /etc/logrotate.d/python-apps"
echo ""
echo "Running apps and log files will NOT be touched."
echo ""
read -r -p "Continue? [y/N] " answer
case "$answer" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Aborted."; exit 0;;
esac

for unit in "$WATCHDOG_TIMER" "$WATCHDOG_UNIT" "$AUTOSTART_UNIT"; do
    if systemctl list-unit-files | grep -q "^$unit"; then
        echo "Removing $unit"
        systemctl stop "$unit" >/dev/null 2>&1
        systemctl disable "$unit" >/dev/null 2>&1
    fi
    rm -f "/etc/systemd/system/$unit"
done

rm -f /etc/logrotate.d/python-apps

systemctl daemon-reload
systemctl reset-failed >/dev/null 2>&1

echo ""
echo "Uninstall complete."
echo "Apps still running in screen are untouched. Stop them with:"
echo "  cd $(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")/app_manager && ./manage_apps.sh stop"
