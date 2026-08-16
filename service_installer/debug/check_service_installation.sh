#!/bin/bash

# Debug script for service installation

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

CURRENT_USER=${SUDO_USER:-${USER:-$(id -un)}}

AUTOSTART_UNIT="python-apps-autostart-$CURRENT_USER.service"
WATCHDOG_UNIT="python-apps-watchdog-$CURRENT_USER.service"
WATCHDOG_TIMER="python-apps-watchdog-$CURRENT_USER.timer"

echo "=== Debug Service Installation ==="
echo "Current user: $CURRENT_USER"
echo "Repository root: $REPO_ROOT"
echo ""

# 1. Templates shipped in the repo
echo "1. Unit templates in the repository:"
for tpl in python-apps-autostart.service python-apps-watchdog.service python-apps-watchdog.timer; do
    if [ -f "$REPO_ROOT/service_installer/$tpl" ]; then
        echo "   ✅ $tpl"
    else
        echo "   ❌ $tpl NOT found"
    fi
done
echo ""

# 2. Installed units
echo "2. Installed unit files:"
for unit in "$AUTOSTART_UNIT" "$WATCHDOG_UNIT" "$WATCHDOG_TIMER"; do
    if [ -f "/etc/systemd/system/$unit" ]; then
        echo "   ✅ $unit installed"
    else
        echo "   ❌ $unit NOT installed"
    fi
done
echo ""

# 3. Content of the main installed unit
echo "3. Content of $AUTOSTART_UNIT:"
if [ -f "/etc/systemd/system/$AUTOSTART_UNIT" ]; then
    cat "/etc/systemd/system/$AUTOSTART_UNIT"
    echo ""
    # Unresolved placeholders mean the installer did not run correctly
    if grep -q "__USER__\|__INSTALL_DIR__" "/etc/systemd/system/$AUTOSTART_UNIT"; then
        echo "   ❌ Unresolved placeholders found - re-run: sudo ./install_service.sh"
    elif grep -q "%i" "/etc/systemd/system/$AUTOSTART_UNIT"; then
        echo "   ⚠️  Old-style %i placeholder found - re-run: sudo ./install_service.sh"
    else
        echo "   ✅ Placeholders correctly resolved"
    fi
else
    echo "   (not installed)"
fi
echo ""

# 4. systemd registration
echo "4. Registered units:"
systemctl list-unit-files | grep -F "python-apps" || echo "   No python-apps units found"
echo ""

# 5. Enabled state
echo "5. Enabled state:"
for unit in "$AUTOSTART_UNIT" "$WATCHDOG_TIMER"; do
    if systemctl is-enabled "$unit" >/dev/null 2>&1; then
        echo "   ✅ $unit is enabled"
    else
        echo "   ❌ $unit is not enabled"
    fi
done
echo ""

# 6. Watchdog schedule
echo "6. Watchdog schedule:"
systemctl list-timers --no-pager 2>/dev/null | grep -F "python-apps" || echo "   Timer not scheduled"
echo ""

# 7. Status
echo "7. Service status:"
systemctl status "$AUTOSTART_UNIT" --no-pager || true
echo ""

# 8. Logrotate
echo "8. Log rotation:"
if [ -f /etc/logrotate.d/python-apps ]; then
    echo "   ✅ /etc/logrotate.d/python-apps installed"
    cat /etc/logrotate.d/python-apps
else
    echo "   ⚠️  logrotate config not installed (optional)"
fi

echo ""
echo "=== Debug Complete ==="
