#!/bin/bash

export PATH=${PATH}:/home/qajulo//platform-tools

# Ensure your version of bash supports associative arrays
if [ "${BASH_VERSINFO:-0}" -lt 4 ]; then
    echo "Bash version 4 or greater is required."
    exit 1
fi

echo "" > /home/qajulo/tools_script/redeploy_expected_devices.txt

# Read device serials from a file
devices_serial=$(cat /home/qajulo/tools_script/expected_devices.txt)

adb_output=$(adb devices)

# Check if 'List of devices attached' is in adb_output
check_adb_okay=$(echo "$adb_output" | grep -q "List of devices attached" && echo yes || echo no)

if [ "$check_adb_okay" != "yes" ]; then
	exit 1;
fi

# Declare an associative array
declare -A adb_output_lines

# Fill the associative array with adb_output lines, prefixing keys with 'key_'
while IFS= read -r line; do
    device_serial=$(echo "$line" | awk '{print $1}')
    device_status=$(echo "$line" | awk '{print $2}')
    adb_output_lines["key_$device_serial"]=$device_status
done <<< "$adb_output"

for device_serial in $devices_serial; do
	adb_name="key_$device_serial"
	log_name="log_$device_serial"
	check_adb_connected="no"
	check_adb_unauthorized="no"

	# Check the status of the device from the associative array
	if [[ "${adb_output_lines[$adb_name]}" == "device" ]]; then
		check_adb_connected="yes"
	elif [[ "${adb_output_lines[$adb_name]}" == "unauthorized" ]]; then
		check_adb_unauthorized="yes"
	fi

	last_line=$(tail -n 1 /home/qajulo/tools_script/logs/$log_name.txt)
	
	export device_serial_number="$device_serial"

	if [ "$check_adb_connected" = "yes" ]; then
		status="connected"
		echo "$device_serial " >> /home/qajulo/tools_script/redeploy_expected_devices.txt
	elif [ "$check_adb_unauthorized" = "yes" ]; then
		status="unauthorized"
	else
		status="disconnected"
	fi

	echo "On $(date '+%H:%M:%S, %d %B %Y')"
	echo "$device_serial $status"

	if [ "$last_line" != "$device_serial $status" ]; then
		echo "On $(date '+%H:%M:%S, %d %B %Y')" >> /home/qajulo/tools_script/logs/$log_name.txt
		echo "$device_serial $status" >> /home/qajulo/tools_script/logs/$log_name.txt
		export device_status="${status^^}"
		/home/qajulo/.pyenv/shims/python /home/qajulo/tools_script/logs/alert_slack.py
	fi

	# chmod 777 /home/qajulo/tools_script/logs/$log_name.txt
done

count_check=$(cat /home/qajulo/tools_script/count_check.txt)
((count_check++))
echo "$count_check" > /home/qajulo/tools_script/count_check.txt
if [[ "$count_check" == "15" ]]; then
	echo "check redeployment docker appium server"
	echo "0" > /home/qajulo/tools_script/count_check.txt
	/home/qajulo/tools_script/redeploy.bash > /home/qajulo/tools_script/redeploy.log 2>&1
else
	echo "$count_check, need 15 to do redeployemnt check"
fi

exec $SHELL
