#!/bin/bash

# Script to diagnose systemd service problems

echo "=== SYSTEMD SERVICE DIAGNOSTICS ==="
echo ""

# Check if the service file exists
echo "1. Service file verification:"
if [ -f "/etc/systemd/system/start_scripts.service" ]; then
    echo "   ✓ Service file found"
    echo "   File content:"
    cat /etc/systemd/system/start_scripts.service
else
    echo "   ✗ Service file NOT found"
fi
echo ""

# Check service status
echo "2. Service status:"
systemctl status start_scripts.service
echo ""

# Check service logs
echo "3. Recent service logs:"
journalctl -u start_scripts.service --no-pager -n 20
echo ""

# Check if script exists and is executable
echo "4. Script verification:"
if [ -f "/home/scad-pi/raspberry_pi_server/start_scripts.sh" ]; then
    echo "   ✓ Script found"
    if [ -x "/home/scad-pi/raspberry_pi_server/start_scripts.sh" ]; then
        echo "   ✓ Script executable"
    else
        echo "   ✗ Script NOT executable"
    fi
else
    echo "   ✗ Script NOT found"
fi
echo ""

# Check directory permissions
echo "5. Directory permissions:"
ls -la /home/scad-pi/raspberry_pi_server/ | head -10
echo ""

# Manual script test
echo "6. Manual script test:"
echo "   Executing /home/scad-pi/raspberry_pi_server/start_scripts.sh..."
cd /home/scad-pi/raspberry_pi_server && ./start_scripts.sh
echo ""

echo "=== DIAGNOSTICS COMPLETE ===" 