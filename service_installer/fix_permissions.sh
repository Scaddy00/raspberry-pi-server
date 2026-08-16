#!/bin/bash

# Script to give execution permissions to all shell scripts

set -uo pipefail

# Resolve paths from the script location, not from the current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Giving execution permissions to scripts..."
echo "Repository root: $REPO_ROOT"
echo ""

scripts=(
    "$REPO_ROOT/app_manager/manage_apps.sh"
    "$REPO_ROOT/app_manager/config_utils.sh"
    "$REPO_ROOT/app_manager/debug/validate_config.sh"
    "$REPO_ROOT/app_manager/debug/repair_environment.sh"
    "$REPO_ROOT/service_installer/install_service.sh"
    "$REPO_ROOT/service_installer/uninstall_service.sh"
    "$REPO_ROOT/service_installer/fix_permissions.sh"
    "$REPO_ROOT/service_installer/debug/test_service_startup.sh"
    "$REPO_ROOT/service_installer/debug/check_service_installation.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo "✓ Execution permissions given to: ${script#$REPO_ROOT/}"
    else
        echo "⚠️  File not found: ${script#$REPO_ROOT/}"
    fi
done

echo ""
echo "Operation completed!"

# Show current permissions to verify
echo ""
echo "Current app_manager script permissions:"
ls -la "$REPO_ROOT/app_manager"/*.sh 2>/dev/null || echo "No .sh files found in app_manager"
ls -la "$REPO_ROOT/app_manager/debug"/*.sh 2>/dev/null || echo "No .sh files found in app_manager/debug"

echo ""
echo "Current service_installer script permissions:"
ls -la "$REPO_ROOT/service_installer"/*.sh 2>/dev/null || echo "No .sh files found in service_installer"
ls -la "$REPO_ROOT/service_installer/debug"/*.sh 2>/dev/null || echo "No .sh files found in service_installer/debug"
