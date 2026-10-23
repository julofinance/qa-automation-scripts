#!/bin/bash

# Get main adb process PID (if exists)
adb_pid=$(pidof adb)

# If adb not running, start it as root
if [ -z "$adb_pid" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] adb not running. Starting with root."
    sudo adb kill-server
    sudo adb -a nodaemon server start >/dev/null 2>&1 &
    sleep 3
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] adb started as root."
    sudo adb devices
    exit 0
fi

# Check which user owns adb process
adb_user=$(ps -o user= -p "$adb_pid" | awk '{print $1}')

if [ "$adb_user" != "root" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] adb running as $adb_user. Restarting as root."
    sudo adb kill-server
    sudo adb -a nodaemon server start >/dev/null 2>&1 &
    sleep 3
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] adb restarted as root."
    sudo adb devices
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] adb already running as root."
    sudo adb devices
fi
