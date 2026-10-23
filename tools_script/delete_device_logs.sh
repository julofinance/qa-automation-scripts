#!/bin/bash

# Directory path
dir_path="$HOME/devices_log"

# Loop over each device_id folder
for device_folder in "$dir_path"/*; do
  # Check if it is a directory
  if [ -d "$device_folder" ]; then
    cd $device_folder
    echo $device_folder
    # Delete all txt files except the 10 most recent
    ls -t "$device_folder" | tail -n +11 | xargs -r rm
  fi
done
