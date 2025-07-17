#!/bin/bash

# Script to install and configure the systemd service
# Run this script as root (sudo)

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

# Copy the service file to the systemd directory
cp python-apps-autostart.service /etc/systemd/system/

# Reload systemd configuration
systemctl daemon-reload

# Enable the service for automatic startup
systemctl enable python-apps-autostart.service

echo "Service installed and enabled!"
echo ""
echo "Useful commands:"
echo "  sudo systemctl start python-apps-autostart.service    # Start the service"
echo "  sudo systemctl stop python-apps-autostart.service     # Stop the service"
echo "  sudo systemctl status python-apps-autostart.service   # Check status"
echo "  sudo systemctl restart python-apps-autostart.service  # Restart the service"
echo "  sudo journalctl -u python-apps-autostart.service -f  # View logs in real-time"
echo ""
echo "Note: The service will start apps defined in app_manager/apps_config.json" 