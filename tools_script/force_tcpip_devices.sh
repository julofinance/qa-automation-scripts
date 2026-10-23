#!/bin/bash

devices_serial=$(adb devices | grep -v "List of devices" | cut -f 1)

for device_serial in $devices_serial; do
    echo "open port $1 for device $device_serial"
    adb -s $device_serial tcpip $1

done
