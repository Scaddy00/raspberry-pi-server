#!/bin/bash

# Script to give execution permissions to all shell scripts

echo "Giving execution permissions to scripts..."

# List of all shell scripts to make executable
scripts=(
    "start_scripts.sh"
    "stop_scripts.sh"
    "install_service.sh"
    "debug_service.sh"
)

# Give execution permissions to each script
for script in "${scripts[@]}"; do
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
echo "Current script permissions:"
ls -la *.sh 