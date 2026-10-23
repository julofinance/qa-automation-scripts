#!/bin/bash
for busid in $(sshpass -p "$USBIP_HOST_PASSWORD" ssh jtp00027@172.21.1.4 usbip list -l | grep -P -o "(?<=busid )\d+-\d+(\.\d+)*(?= \()")
do
    echo $busid
    sudo usbip attach -r 172.21.1.4 -b $busid
done
