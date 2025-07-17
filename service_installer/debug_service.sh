#!/bin/bash

# Script to diagnose systemd service problems

echo "=== SYSTEMD SERVICE DIAGNOSTICS ==="
echo ""

# Check if the service file exists
echo "1. Service file verification:"
if [ -f "/etc/systemd/system/python-apps-autostart.service" ]; then
    echo "   ✓ Service file found"
    echo "   File content:"
    cat /etc/systemd/system/python-apps-autostart.service
else
    echo "   ✗ Service file NOT found"
fi
echo ""

# Check service status
echo "2. Service status:"
systemctl status python-apps-autostart.service
echo ""

# Check service logs
echo "3. Recent service logs:"
journalctl -u python-apps-autostart.service --no-pager -n 20
echo ""

# Check if app_manager directory exists
echo "4. App manager directory verification:"
if [ -d "/home/scad-pi/raspberry_pi_server/app_manager" ]; then
    echo "   ✓ App manager directory found"
else
    echo "   ✗ App manager directory NOT found"
fi
echo ""

# Check if required scripts exist and are executable
echo "5. Script verification:"
required_scripts=(
    "/home/scad-pi/raspberry_pi_server/app_manager/start_scripts.sh"
    "/home/scad-pi/raspberry_pi_server/app_manager/config_utils.sh"
    "/home/scad-pi/raspberry_pi_server/app_manager/manage_apps.sh"
)

for script in "${required_scripts[@]}"; do
    if [ -f "$script" ]; then
        echo "   ✓ Script found: $(basename "$script")"
        if [ -x "$script" ]; then
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
echo "6. Configuration file verification:"
config_file="/home/scad-pi/raspberry_pi_server/app_manager/apps_config.json"
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
echo "7. Directory permissions:"
ls -la /home/scad-pi/raspberry_pi_server/ | head -10
echo ""

# Manual script test
echo "8. Manual script test:"
echo "   Executing app manager start script..."
cd /home/scad-pi/raspberry_pi_server/app_manager && ./start_scripts.sh
echo ""

echo "=== DIAGNOSTICS COMPLETE ==="