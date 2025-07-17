#!/bin/bash

# Debug script for service installation
# Run this script as root (sudo)

SERVICE_NAME=python-apps-autostart.service
SERVICE_PATH=/etc/systemd/system/$SERVICE_NAME

# Get current user or use default
CURRENT_USER=${SUDO_USER:-$USER}
if [ -z "$CURRENT_USER" ]; then
    echo "Error: Cannot determine current user"
    exit 1
fi

echo "=== Debug Service Installation ==="
echo "Current user: $CURRENT_USER"
echo "Service name: $SERVICE_NAME"
echo "Service path: $SERVICE_PATH"
echo ""

# Check if service file exists
echo "1. Checking if service file exists..."
if [ -f "$SERVICE_PATH" ]; then
    echo "✅ Service file exists at $SERVICE_PATH"
    echo "Content:"
    cat "$SERVICE_PATH"
    echo ""
else
    echo "❌ Service file not found at $SERVICE_PATH"
fi

# Check systemd unit files
echo "2. Checking systemd unit files..."
systemctl list-unit-files | grep python-apps || echo "No python-apps units found"

# Check if template is recognized
echo ""
echo "3. Checking template recognition..."
if systemctl list-unit-files | grep -q "$SERVICE_NAME"; then
    echo "✅ Template is registered"
else
    echo "❌ Template not found in systemd"
fi

# Try to enable with verbose output
echo ""
echo "4. Trying to enable service with verbose output..."
if systemctl enable python-apps-autostart@$CURRENT_USER.service --no-pager; then
    echo "✅ Service enabled successfully"
else
    echo "❌ Failed to enable service"
    echo "Error details:"
    systemctl enable python-apps-autostart@$CURRENT_USER.service 2>&1
fi

# Check if instance exists now
echo ""
echo "5. Checking if service instance exists..."
if systemctl list-unit-files | grep -q "python-apps-autostart@$CURRENT_USER.service"; then
    echo "✅ Service instance exists"
else
    echo "❌ Service instance not found"
fi

# Check status
echo ""
echo "6. Service status:"
systemctl status python-apps-autostart@$CURRENT_USER.service --no-pager || echo "Service not found"

echo ""
echo "=== Debug Complete ===" 