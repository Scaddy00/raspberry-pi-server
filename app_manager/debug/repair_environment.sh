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

# 3. Check and create app directories
echo ""
echo "3. Checking app directories..."
MAIN_DIR="/home/$CURRENT_USER"
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

# 4. Set correct permissions
echo ""
echo "4. Setting correct permissions..."
chmod +x start_scripts.sh
chmod +x stop_scripts.sh
chmod +x manage_apps.sh
chmod +x debug_config.sh
echo "✅ Permissions set"

# 5. Test configuration
echo ""
echo "5. Testing configuration..."
if ./debug_config.sh; then
    echo "✅ Configuration test passed"
else
    echo "❌ Configuration test failed"
    exit 1
fi

echo ""
echo "=== Fix Complete ==="
echo ""
echo "You can now try starting the service again:"
echo "  sudo systemctl start python-apps-autostart-$CURRENT_USER.service"
echo "  sudo systemctl status python-apps-autostart-$CURRENT_USER.service" 