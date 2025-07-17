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

USER_SERVICE_NAME=python-apps-autostart-$CURRENT_USER.service
USER_SERVICE_PATH=/etc/systemd/system/$USER_SERVICE_NAME

echo "=== Debug Service Installation ==="
echo "Current user: $CURRENT_USER"
echo "Template service name: $SERVICE_NAME"
echo "Template service path: $SERVICE_PATH"
echo "User service name: $USER_SERVICE_NAME"
echo "User service path: $USER_SERVICE_PATH"
echo ""

# Check if template service file exists
echo "1. Checking if template service file exists..."
if [ -f "$SERVICE_PATH" ]; then
    echo "✅ Template service file exists at $SERVICE_PATH"
    echo "Content:"
    cat "$SERVICE_PATH"
    echo ""
else
    echo "❌ Template service file not found at $SERVICE_PATH"
fi

# Check if user-specific service file exists
echo "2. Checking if user-specific service file exists..."
if [ -f "$USER_SERVICE_PATH" ]; then
    echo "✅ User service file exists at $USER_SERVICE_PATH"
    echo "Content:"
    cat "$USER_SERVICE_PATH"
    echo ""
else
    echo "❌ User service file not found at $USER_SERVICE_PATH"
fi

# Check systemd unit files
echo "3. Checking systemd unit files..."
systemctl list-unit-files | grep python-apps || echo "No python-apps units found"

# Check if template is recognized
echo ""
echo "4. Checking template recognition..."
if systemctl list-unit-files | grep -q "$SERVICE_NAME"; then
    echo "✅ Template is registered"
else
    echo "❌ Template not found in systemd"
fi

# Check if user service is recognized
echo ""
echo "5. Checking user service recognition..."
if systemctl list-unit-files | grep -q "$USER_SERVICE_NAME"; then
    echo "✅ User service is registered"
else
    echo "❌ User service not found in systemd"
fi

# Try to enable user service with verbose output
echo ""
echo "6. Trying to enable user service with verbose output..."
if systemctl enable $USER_SERVICE_NAME --no-pager; then
    echo "✅ User service enabled successfully"
else
    echo "❌ Failed to enable user service"
    echo "Error details:"
    systemctl enable $USER_SERVICE_NAME 2>&1
fi

# Check if user service exists now
echo ""
echo "7. Checking if user service exists..."
if systemctl list-unit-files | grep -q "$USER_SERVICE_NAME"; then
    echo "✅ User service exists"
else
    echo "❌ User service not found"
fi

# Check status
echo ""
echo "8. User service status:"
systemctl status $USER_SERVICE_NAME --no-pager || echo "User service not found"

echo ""
echo "=== Debug Complete ===" 