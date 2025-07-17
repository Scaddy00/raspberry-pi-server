#!/bin/bash

# Debug script to test configuration functions
set -e

echo "=== Configuration Debug Script ==="

# Source the configuration utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config_utils.sh"

echo "1. Checking if jq is installed..."
if command -v jq &> /dev/null; then
    echo "✅ jq is installed: $(which jq)"
    echo "✅ jq version: $(jq --version)"
else
    echo "❌ jq is NOT installed"
    echo "To install jq, run: sudo apt-get update && sudo apt-get install jq"
    exit 1
fi

echo ""
echo "2. Checking config file..."
config_file=$(get_config_file_path)
if [ -f "$config_file" ]; then
    echo "✅ Config file exists: $config_file"
else
    echo "❌ Config file not found: $config_file"
    exit 1
fi

echo ""
echo "3. Validating JSON format..."
if jq empty "$config_file" 2>/dev/null; then
    echo "✅ JSON format is valid"
else
    echo "❌ JSON format is invalid"
    echo "JSON validation error:"
    jq empty "$config_file"
    exit 1
fi

echo ""
echo "4. Testing configuration functions..."

echo "Testing get_main_dir..."
main_dir=$(get_main_dir)
echo "  main_dir: $main_dir"

echo "Testing get_python_cmd..."
python_cmd=$(get_python_cmd)
echo "  python_cmd: $python_cmd"

echo "Testing get_log_dir..."
log_dir=$(get_log_dir)
echo "  log_dir: $log_dir"

echo "Testing get_app_names..."
app_names=$(get_app_names)
echo "  app_names: $app_names"

echo "Testing get_app_count..."
app_count=$(get_app_count)
echo "  app_count: $app_count"

echo ""
echo "5. Testing individual apps..."
for app in $app_names; do
    echo "  App: $app"
    echo "    script_path: $(get_script_path "$app")"
    echo "    screen_name: $(get_screen_name "$app")"
    echo "    description: $(get_app_description "$app")"
    
    script_path="$main_dir/$(get_script_path "$app")"
    echo "    full_script_path: $script_path"
    if [ -f "$script_path" ]; then
        echo "    ✅ Script file exists"
    else
        echo "    ❌ Script file NOT found"
    fi
    echo ""
done

echo ""
echo "6. Checking python command..."
if command -v "$python_cmd" &> /dev/null; then
    echo "✅ Python command is available: $(which "$python_cmd")"
    echo "✅ Python version: $("$python_cmd" --version)"
else
    echo "❌ Python command NOT found: $python_cmd"
fi

echo ""
echo "7. Checking log directory..."
if [ -d "$log_dir" ]; then
    echo "✅ Log directory exists: $log_dir"
else
    echo "⚠️  Log directory does not exist: $log_dir"
    echo "Will be created when needed"
fi

echo ""
echo "=== Debug Complete ===" 