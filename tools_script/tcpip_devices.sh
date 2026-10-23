#!/bin/sh
devices_serial='8570901d0405 CA4PDMNFNFOJRCW4 SKDIOJBELNBAUOMB R9RT802Y7MZ T8LR9LU86PNFV4EQ 69HY8PAQDE7LVS9D JRHY7TFANZLJDYLF PZONRGNVPNAQMNLF 10DE2F0K4E0005K'

for device_serial in $devices_serial; do
	ip_address_device=$(adb -s $device_serial shell ip  -o a   | grep 'wlan0' | grep 'inet '| cut -d / -f 1 | cut --complement -d "t" -f 1 | cut --complement -d " " -f 1)

	if ! nc -z $ip_address_device 5555
	then
		echo open port 5555 for device $device_serial
		adb -s $device_serial tcpip 5555
	else
		echo port 5555 for device $device_serial is already open!
	fi
	# /home/jtp00027/Downloads/android/platform-tools/adb connect $ip_address_device:5555
done
