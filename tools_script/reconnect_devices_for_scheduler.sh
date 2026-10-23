#!/bin/bash

slack_api_call() {
    url="https://slack.com/api/chat.postMessage"
    SLACK_ACCESS_TOKEN="${SLACK_BOT_TOKEN}"

    curl -X POST $url \
        -H "Authorization: Bearer $SLACK_ACCESS_TOKEN" \
	-H "Content-Type: application/json; charset=utf-8" \
	--data '
	    {
		"channel": "alerts_device_farm",
		"blocks": [
		    {
                    	"type": "section",
                    	"text": {
                     	    "type": "mrkdwn",
                      	    "text": "'"${1}"'",
                   	 },
                    },
		],
	    }
	'
}

check_device() {
    for (( count=0; count < 12; count++ )); do
        sleep 5
        echo "==============================="
        echo "device that being restarted $1"
        adb devices
        echo "==============================="
        status=$(adb devices | grep $1 | awk '{print $2}')
	echo "status: $status"
        if [ -n "$status" ] && [ "$status" == "device" ]; then
            return 0
        fi
    done

    if [ -z "$status" ]; then
        slack_api_call "timeout, device \`$1\` not coming back after 60 second being restarted"
    else
        slack_api_call "fail to reconnect device \`$1\`\nDevice status: $status"
    fi
    return 1
}

slack_api_call "Scheduler to reconnect remote devices is starting..."
adb_output=$(adb devices | grep -v "List of devices attached")

fail_count=0
fail_devices=""
while read line; do
    device=$(echo $line | awk '{print $1}')
    echo "reconnect $device"

    source ~/tools_script/reconnect_device.sh $device
    check_device $device

    output=$?
    echo "hasil : $output"
    if [ "$output" -eq 1 ]; then
        fail_devices="\`$device\` $fail_devices"
        echo "$device is fail reconnected"

	fail_count=$(($fail_count + $output))
	echo "fail count $fail_count"
    else
        echo "$device is sucess reconnected"
    fi
    echo "==============================="
done <<< "${adb_output}"



slack_api_call "Reconnect remote device scheduler has already done, <!subteam^S07HXBDSWTX>"
if [ "$fail_count" -gt 0 ]; then
    slack_api_call "Some devices are fail reconnected, \nDevices : $fail_devices"
else
    slack_api_call "All devices successfully reconnected"
fi
