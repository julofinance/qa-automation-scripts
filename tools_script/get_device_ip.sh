#!/bin/bash

adb -s $1 shell ip  -o a   | grep 'wlan0' | grep 'inet '| cut -d / -f 1 | cut --complement -d 't' -f 1 | cut --complement -d ' ' -f 1
