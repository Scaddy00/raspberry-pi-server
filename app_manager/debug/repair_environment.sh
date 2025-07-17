#!/bin/bash

# Fix installation script - resolves common issues
set -e

echo "=== Fixing Installation Issues ==="

# Get current user
CURRENT_USER=$(whoami)

# 1. Install jq if not present
echo "1. Checking and installing jq..."
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    sudo apt-get update
    sudo apt-get install -y jq
    echo "✅ jq installed successfully"
else
    echo "✅ jq is already installed"
fi

# 2. Create log directory if it doesn't exist
echo ""
echo "2. Creating log directory..."
LOG_DIR="/home/$CURRENT_USER/bash_logs"
if [ ! -d "$LOG_DIR" ]; then
    echo "Creating log directory: $LOG_DIR"
    mkdir -p "$LOG_DIR"
    echo "✅ Log directory created"
else
    echo "✅ Log directory already exists"
fi

# 3. Check and create app directories based on apps_config.json
echo ""
echo "3. Checking app directories..."
MAIN_DIR="/home/$CURRENT_USER"

# Get app directories from config if possible
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../apps_config.json"

if [ -f "$CONFIG_FILE" ]; then
    echo "Reading app directories from config..."
    # Extract script paths and create directories
    app_dirs=$(jq -r '.apps[].script_path' "$CONFIG_FILE" 2>/dev/null | sed 's|/[^/]*$||' | sort -u)
    
    for app_dir in $app_dirs; do
        full_path="$MAIN_DIR/$app_dir"
        if [ ! -d "$full_path" ]; then
            echo "⚠️  Creating missing directory: $full_path"
            mkdir -p "$full_path"
            
            # Create a placeholder main.py if it doesn't exist
            if [ ! -f "$full_path/main.py" ]; then
                cat > "$full_path/main.py" << 'EOF'
#!/usr/bin/env python3
"""
Placeholder script - replace with your actual application
"""
import time
import sys

def main():
    print(f"Starting {sys.argv[0]}...")
    try:
        while True:
            print(f"Running... {time.strftime('%Y-%m-%d %H:%M:%S')}")
            time.sleep(60)  # Run every minute
    except KeyboardInterrupt:
        print("Stopping...")

if __name__ == "__main__":
    main()
EOF
                echo "  Created placeholder main.py in $full_path"
            fi
        else
            echo "✅ Directory exists: $full_path"
        fi
    done
else
    echo "⚠️  Config file not found, creating default directories..."
    # Fallback to default directories if config not found
    declare -a REQUIRED_DIRS=(
        "$MAIN_DIR/apps/wish_discord_bot"
        "$MAIN_DIR/apps/jw_group_app"
        "$MAIN_DIR/apps/talk_sync_app"
    )

    for dir in "${REQUIRED_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            echo "⚠️  Creating missing directory: $dir"
            mkdir -p "$dir"
            
            # Create a placeholder main.py if it doesn't exist
            if [ ! -f "$dir/main.py" ]; then
                cat > "$dir/main.py" << 'EOF'
#!/usr/bin/env python3
"""
Placeholder script - replace with your actual application
"""
import time
import sys

def main():
    print(f"Starting {sys.argv[0]}...")
    try:
        while True:
            print(f"Running... {time.strftime('%Y-%m-%d %H:%M:%S')}")
            time.sleep(60)  # Run every minute
    except KeyboardInterrupt:
        print("Stopping...")

if __name__ == "__main__":
    main()
EOF
                echo "  Created placeholder main.py in $dir"
            fi
        else
            echo "✅ Directory exists: $dir"
        fi
    done
fi

# 4. Set correct permissions for app_manager scripts
echo ""
echo "4. Setting correct permissions..."
cd "$SCRIPT_DIR/.."
chmod +x manage_apps.sh
chmod +x config_utils.sh
chmod +x debug/validate_config.sh
chmod +x debug/repair_environment.sh
echo "✅ App manager permissions set"

# 5. Set permissions for service_installer scripts if they exist
if [ -d "../service_installer" ]; then
    echo "Setting service installer permissions..."
    cd "../service_installer"
    chmod +x install_service.sh
    chmod +x fix_permissions.sh
    if [ -d "debug" ]; then
        chmod +x debug/*.sh
    fi
    echo "✅ Service installer permissions set"
    cd "$SCRIPT_DIR/.."
fi

# 6. Test configuration
echo ""
echo "5. Testing configuration..."
if ./debug/validate_config.sh; then
    echo "✅ Configuration test passed"
else
    echo "❌ Configuration test failed"
    echo "You may need to configure apps_config.json properly"
fi

echo ""
echo "=== Fix Complete ==="
echo ""
echo "You can now try starting the service again:"
echo "  sudo systemctl start python-apps-autostart-$CURRENT_USER.service"
echo "  sudo systemctl status python-apps-autostart-$CURRENT_USER.service"
echo ""
echo "Or manage apps manually:"
echo "  ./manage_apps.sh start"
echo "  ./manage_apps.sh status" 