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

# Create user-specific service file
USER_SERVICE_NAME=python-apps-autostart-$CURRENT_USER.service
USER_SERVICE_PATH=/etc/systemd/system/$USER_SERVICE_NAME

echo "Creating user-specific service: $USER_SERVICE_NAME"

# Create the user-specific service content
cat > /tmp/$USER_SERVICE_NAME << EOF
[Unit]
Description=Python Applications Auto-Start Manager for $CURRENT_USER
After=network.target

[Service]
Type=oneshot
User=$CURRENT_USER
WorkingDirectory=/home/$CURRENT_USER/raspberry-pi-server/app_manager
ExecStart=/bin/bash start_scripts.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Copy the user-specific service file
sudo cp /tmp/$USER_SERVICE_NAME $USER_SERVICE_PATH

# Clean up temp file
rm /tmp/$USER_SERVICE_NAME

# Reload systemd configuration
sudo systemctl daemon-reload

# Enable the user-specific service
sudo systemctl enable $USER_SERVICE_NAME

# Verify installation
if systemctl is-enabled $USER_SERVICE_NAME >/dev/null 2>&1; then
    echo "Service installed and enabled successfully!"
else
    echo "Warning: Service installation may have failed. Check with:"
    echo "  sudo systemctl status $USER_SERVICE_NAME"
fi

echo ""
echo "Useful commands:"
echo "  sudo systemctl start $USER_SERVICE_NAME    # Start the service"
echo "  sudo systemctl stop $USER_SERVICE_NAME     # Stop the service"
echo "  sudo systemctl status $USER_SERVICE_NAME   # Check status"
echo "  sudo systemctl restart $USER_SERVICE_NAME  # Restart the service"
echo "  sudo journalctl -u $USER_SERVICE_NAME -f  # View logs in real-time"
echo ""
echo "Note: The service will start apps defined in app_manager/apps_config.json" 