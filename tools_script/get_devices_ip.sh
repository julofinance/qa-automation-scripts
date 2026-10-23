#!/bin/sh
# Function to handle errors
error_handler() {
    echo "An error occurred. Continuing execution..."
}

# Set up the trap to catch errors and call the error_handler function
trap 'error_handler' ERR

devices_serial='8570901d0405 CA4PDMNFNFOJRCW4 SKDIOJBELNBAUOMB R9RT802Y7MZ T8LR9LU86PNFV4EQ 69HY8PAQDE7LVS9D JRHY7TFANZLJDYLF 10DE2F0K4E0005K PZONRGNVPNAQMNLF'
device_name='Redmi_Note_9 VIVO_Y12 Realme_C25_S Galaxy_A03 VIVO_Y91C OPPO_A57 OPPO_F5'



for device_serial in $devices_serial; do
   echo "get this device $device_serial ip"
	ip_address_device=$(adb -s $device_serial shell ip  -o a   | grep 'wlan0' | grep 'inet '| cut -d / -f 1 | cut --complement -d "t" -f 1 | cut --complement -d " " -f 1)
    echo $device_serial $ip_address_device
done
