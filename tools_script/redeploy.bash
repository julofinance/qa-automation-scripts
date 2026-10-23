#!/bin/bash
echo $(date)

# Set the API endpoint and expected device UDIDs
DEVICE_FARM_API="http://localhost:4723/device-farm/api/devices"
# Read device serials from a file
devices_serial=$(awk '{ printf "%s", $0 }' < /home/qajulo/tools_script/redeploy_expected_devices.txt)
EXPECTED_UDIDS=($devices_serial)

# Function to check if a device is missing
check_device_availability() {
    local udid="$1"
    local response=$(curl -s "$DEVICE_FARM_API")
    if [[ "$response" == *"\"udid\":\"$udid\""* ]]; then
        return 0  # Device found
    else
        return 1  # Device missing
    fi
}

# Main logic
for udid in "${EXPECTED_UDIDS[@]}"; do
    if check_device_availability "$udid"; then
        echo "Device $udid is available."
    else
        echo "Device $udid is missing. Restarting ADB..."
        sudo kill -9 $(sudo lsof -t -i:5037)
        /usr/bin/adb -a start-server
        cd /home/qajulo/regressions && /usr/local/bin/docker-compose -f /home/qajulo/regressions/node-appium-docker-compose.yml up --build -d
        break
    fi
done

echo " "
echo " "

