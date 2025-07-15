#!/bin/bash

# Stop only screen sessions started by the Python apps starter (those named pyapp_*)

# Find all relevant screen sessions
screens=$(screen -ls | grep -o '[0-9]*\.pyapp_[^ ]*')

log_file="/home/scad-pi/bash_logs/stop_scripts.log"
mkdir -p "/home/scad-pi/bash_logs"

if [ -z "$screens" ]; then
    echo "No pyapp_ screen sessions found." | tee -a "$log_file"
    exit 0
fi

# Terminate all pyapp_ screen sessions
echo "Terminating the following pyapp_ screen sessions:" | tee -a "$log_file"
echo "$screens" | tee -a "$log_file"

for s in $screens; do
    screen -S "$s" -X quit
    if [ $? -eq 0 ]; then
        echo "Screen $s terminated." | tee -a "$log_file"
    else
        echo "Failed to terminate screen $s." | tee -a "$log_file"
    fi
    sleep 0.5
done

echo "All pyapp_ screen sessions have been closed." | tee -a "$log_file"