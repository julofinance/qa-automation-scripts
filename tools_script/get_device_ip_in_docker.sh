#!/bin/bash

# Convert the input parameter to lowercase
lowercase_param=$(echo "$1" | tr '[:upper:]' '[:lower:]')

# Execute the command within the specified Docker container without requesting a TTY
docker exec $(docker ps -aqf "name=$lowercase_param") /bin/sh -c "adb shell ip -o a | grep 'wlan0' | grep 'inet ' | cut -d / -f 1 | cut --complement -d 't' -f 1 | cut --complement -d ' ' -f 1"

