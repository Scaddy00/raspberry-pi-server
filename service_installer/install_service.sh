#!/bin/bash

# Script to install and configure the systemd service
# Run this script as root (sudo)

SERVICE_NAME=python-apps-autostart.service
SERVICE_PATH=/etc/systemd/system/$SERVICE_NAME

# Get current user or use default
CURRENT_USER=${SUDO_USER:-$USER}
if [ -z "$CURRENT_USER" ]; then
    echo "Error: Cannot determine current user"
    exit 1
fi

echo "Installing systemd service for user: $CURRENT_USER"

echo "Installing systemd service for Python app manager..."

# Verify that files exist
if [ ! -f "python-apps-autostart.service" ]; then
    echo "Error: python-apps-autostart.service not found!"
    exit 1
fi

# Check if app_manager directory exists
if [ ! -d "../app_manager" ]; then
    echo "Error: app_manager directory not found!"
    echo "Make sure you're running this from the service_installer directory"
    exit 1
fi

# Check if required scripts exist in app_manager
if [ ! -f "../app_manager/start_scripts.sh" ]; then
    echo "Error: start_scripts.sh not found in app_manager directory!"
    exit 1
fi

if [ ! -f "../app_manager/config_utils.sh" ]; then
    echo "Error: config_utils.sh not found in app_manager directory!"
    exit 1
fi

# Make scripts executable
chmod +x ../app_manager/*.sh

# Copy the service file to the systemd directory (with correct path)
sudo cp python-apps-autostart.service $SERVICE_PATH

# Reload systemd configuration first
sudo systemctl daemon-reload

# Enable the user-specific service instance
sudo systemctl enable python-apps-autostart@$CURRENT_USER.service

# Verify installation
if systemctl is-enabled python-apps-autostart@$CURRENT_USER.service >/dev/null 2>&1; then
    echo "Service installed and enabled successfully!"
else
    echo "Warning: Service installation may have failed. Check with:"
    echo "  sudo systemctl status python-apps-autostart@$CURRENT_USER.service"
fi
echo ""
echo "Useful commands:"
echo "  sudo systemctl start python-apps-autostart@$CURRENT_USER.service    # Start the service"
echo "  sudo systemctl stop python-apps-autostart@$CURRENT_USER.service     # Stop the service"
echo "  sudo systemctl status python-apps-autostart@$CURRENT_USER.service   # Check status"
echo "  sudo systemctl restart python-apps-autostart@$CURRENT_USER.service  # Restart the service"
echo "  sudo journalctl -u python-apps-autostart@$CURRENT_USER.service -f  # View logs in real-time"
echo ""
echo "Note: The service will start apps defined in app_manager/apps_config.json" 