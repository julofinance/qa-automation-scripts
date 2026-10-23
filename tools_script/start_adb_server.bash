#!/bin/bash
for ((i=0; i<60; i++)); do
    /home/qajulo/platform-tools/adb -a start-server
    sleep 1
done

