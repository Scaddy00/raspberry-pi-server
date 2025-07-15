#!/bin/bash

# Script to install and configure the systemd service
# Run this script as root (sudo)

echo "Installing systemd service for start_scripts..."

# Verify that files exist
if [ ! -f "start_scripts.service" ]; then
    echo "Error: start_scripts.service not found!"
    exit 1
fi

if [ ! -f "start_scripts.sh" ]; then
    echo "Error: start_scripts.sh not found!"
    exit 1
fi

# Make the script executable
chmod +x start_scripts.sh

# Copy the script to the user's home directory
cp start_scripts.sh /home/scad-pi/raspberry-pi-server/
chmod +x /home/scad-pi/raspberry-pi-server/start_scripts.sh

# Copy the service file to the systemd directory
cp start_scripts.service /etc/systemd/system/

# Reload systemd configuration
systemctl daemon-reload

# Enable the service for automatic startup
systemctl enable start_scripts.service

echo "Service installed and enabled!"
echo ""
echo "Useful commands:"
echo "  sudo systemctl start start_scripts.service    # Start the service"
echo "  sudo systemctl stop start_scripts.service     # Stop the service"
echo "  sudo systemctl status start_scripts.service   # Check status"
echo "  sudo systemctl restart start_scripts.service  # Restart the service"
echo "  sudo journalctl -u start_scripts.service -f  # View logs in real-time" 