#!/bin/bash

# Fix installation script - resolves common issues
#
# Usage: ./repair_environment.sh [--create-placeholders]
#   --create-placeholders  also create missing app directories with a stub main.py

set -uo pipefail

CREATE_PLACEHOLDERS=0
[ "${1:-}" = "--create-placeholders" ] && CREATE_PLACEHOLDERS=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_MANAGER_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$APP_MANAGER_DIR")"

echo "=== Fixing Installation Issues ==="
echo "Repository root: $REPO_ROOT"
echo ""

# 1. Install jq if not present - needed before we can read the config
echo "1. Checking and installing jq..."
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    sudo apt-get update
    sudo apt-get install -y jq
    echo "✅ jq installed successfully"
else
    echo "✅ jq is already installed"
fi

source "$APP_MANAGER_DIR/config_utils.sh"

# 2. Read the real paths from the configuration instead of assuming them
echo ""
echo "2. Reading configuration..."
if ! validate_config_schema; then
    echo "❌ Configuration is invalid, fix apps_config.json before continuing"
    exit 1
fi
load_config
echo "✅ main_dir: $EXPANDED_MAIN_DIR"
echo "✅ log_dir:  $EXPANDED_LOG_DIR"

# 3. Create log directory
echo ""
echo "3. Creating log directory..."
if [ ! -d "$EXPANDED_LOG_DIR" ]; then
    echo "Creating log directory: $EXPANDED_LOG_DIR"
    mkdir -p "$EXPANDED_LOG_DIR"
    echo "✅ Log directory created"
else
    echo "✅ Log directory already exists"
fi

# 4. Check app scripts declared in the config
echo ""
echo "4. Checking app scripts..."
missing_any=0
while IFS="$CONFIG_FS" read -r app screen_name script_path_rel app_python description; do
    full_script="$EXPANDED_MAIN_DIR/$script_path_rel"
    app_dir="$(dirname "$full_script")"

    if [ -f "$full_script" ]; then
        echo "✅ $app: $full_script"
        continue
    fi

    missing_any=1
    if [ "$CREATE_PLACEHOLDERS" -eq 1 ]; then
        echo "⚠️  $app: creating placeholder at $full_script"
        mkdir -p "$app_dir"
        cat > "$full_script" << 'EOF'
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
    else
        echo "❌ $app: script NOT found at $full_script"
    fi
done < <(printf '%s\n' "${APP_ROWS[@]}")

if [ "$missing_any" -eq 1 ] && [ "$CREATE_PLACEHOLDERS" -eq 0 ]; then
    echo ""
    echo "Some scripts are missing. Either fix script_path in apps_config.json,"
    echo "or re-run with --create-placeholders to generate stub files."
fi

# 5. Check the interpreters
echo ""
echo "5. Checking Python interpreters..."
while IFS="$CONFIG_FS" read -r app screen_name script_path_rel app_python description; do
    py="${app_python:-$PYTHON_CMD}"
    if command -v "$py" >/dev/null 2>&1 || [ -x "$py" ]; then
        echo "✅ $app: $py"
    else
        echo "❌ $app: interpreter NOT found: $py"
    fi
done < <(printf '%s\n' "${APP_ROWS[@]}")

# 6. Set correct permissions
echo ""
echo "6. Setting correct permissions..."
if [ -f "$REPO_ROOT/service_installer/fix_permissions.sh" ]; then
    bash "$REPO_ROOT/service_installer/fix_permissions.sh" >/dev/null
    echo "✅ Permissions set"
else
    chmod +x "$APP_MANAGER_DIR"/*.sh "$SCRIPT_DIR"/*.sh
    echo "✅ App manager permissions set"
fi

# 7. Test configuration
echo ""
echo "7. Testing configuration..."
if "$SCRIPT_DIR/validate_config.sh"; then
    echo "✅ Configuration test passed"
else
    echo "❌ Configuration test failed"
    echo "You may need to configure apps_config.json properly"
fi

echo ""
echo "=== Fix Complete ==="
echo ""
echo "You can now try starting the service again:"
echo "  sudo systemctl start python-apps-autostart-$(id -un).service"
echo "  sudo systemctl status python-apps-autostart-$(id -un).service"
echo ""
echo "Or manage apps manually:"
echo "  cd $APP_MANAGER_DIR"
echo "  ./manage_apps.sh start"
echo "  ./manage_apps.sh status"
