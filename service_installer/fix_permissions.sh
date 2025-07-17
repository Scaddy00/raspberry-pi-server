#!/bin/bash

# Script to give execution permissions to all shell scripts

echo "Giving execution permissions to scripts..."

# List of all shell scripts in app_manager to make executable
app_manager_scripts=(
    "../app_manager/manage_apps.sh"
    "../app_manager/config_utils.sh"
    "../app_manager/debug/validate_config.sh"
    "../app_manager/debug/repair_environment.sh"
)

# List of all shell scripts in service_installer to make executable
service_scripts=(
    "install_service.sh"
    "fix_permissions.sh"
    "debug/test_service_startup.sh"
    "debug/check_service_installation.sh"
)

echo "Setting permissions for app_manager scripts..."
# Give execution permissions to app_manager scripts
for script in "${app_manager_scripts[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo "✓ Execution permissions given to: $script"
    else
        echo "⚠️  File not found: $script"
    fi
done

echo ""
echo "Setting permissions for service_installer scripts..."
# Give execution permissions to service_installer scripts
for script in "${service_scripts[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo "✓ Execution permissions given to: $script"
    else
        echo "⚠️  File not found: $script"
    fi
done

echo ""
echo "Operation completed!"

# Show current permissions to verify
echo ""
echo "Current app_manager script permissions:"
ls -la ../app_manager/*.sh 2>/dev/null || echo "No .sh files found in app_manager"
ls -la ../app_manager/debug/*.sh 2>/dev/null || echo "No .sh files found in app_manager/debug"

echo ""
echo "Current service_installer script permissions:"
ls -la *.sh 2>/dev/null || echo "No .sh files found in service_installer"
ls -la debug/*.sh 2>/dev/null || echo "No .sh files found in service_installer/debug" 