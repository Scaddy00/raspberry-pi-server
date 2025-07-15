#!/bin/bash

# Start multiple Python scripts directly from a single Bash file
# Each script is started in a separate screen session, with separate logs and central summary log

# List of Python scripts to start (relative or absolute paths)
declare -A python_apps
python_apps["discord_bot"]="apps/wish_discord_bot/main.py"
python_apps["jw_group"]="apps/jw_group_app/main.py"
python_apps["talk_sync"]="apps/talk_sync_app/main.py"

log_dir="/home/scad-pi/bash_logs"
mkdir -p "$log_dir"
log_file="$log_dir/start_scripts.log"

echo "$(date) - MAIN - Starting all Python apps in screen sessions..." | tee -a "$log_file"

for app in "${!python_apps[@]}"; do
    script_path="${python_apps[$app]}"
    log_file_app="$log_dir/${app}.log"
    screen_name="pyapp_${app}"

    if [ ! -f "$script_path" ]; then
        echo "$(date) - MAIN - Error: $script_path not found." | tee -a "$log_file"
        continue
    fi

    # Check if screen session already exists
    if screen -list | grep -q "\.${screen_name}"; then
        echo "$(date) - MAIN - Screen session $screen_name already running for $script_path." | tee -a "$log_file"
        continue
    fi

    echo "$(date) - MAIN - Starting $script_path in screen session $screen_name." | tee -a "$log_file"
    screen -dmS "$screen_name" bash -c "python3 '$script_path' >> '$log_file_app' 2>&1"
    if [ $? -eq 0 ]; then
        echo "$(date) - MAIN - $script_path started in screen session $screen_name." | tee -a "$log_file"
    else
        echo "$(date) - MAIN - Failed to start $script_path in screen session $screen_name." | tee -a "$log_file"
    fi
done

echo "$(date) - MAIN - All Python scripts launched in screen sessions (check individual logs and use 'screen -ls')." | tee -a "$log_file" 