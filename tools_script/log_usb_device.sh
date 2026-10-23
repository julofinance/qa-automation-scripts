#!/bin/bash

adb_name="$1"
docker_name=$(echo "${adb_name,,}")
log_name="log_$adb_name"

check_adb=$(/usr/bin/adb devices | grep -zqv "$adb_name" && echo no || echo yes)

check_docker=$(docker ps -a| grep -zqv "$docker_name" && echo no || echo yes)


last_line=$(tail -n 1 /home/qajulo/tools_script/$log_name.txt)

if [ $check_adb != "no" ] || [ $check_docker != "no" ]; then
	echo "On $(date '+%H:%M:%S, %d %B %Y')" 
	echo "$adb_name connected" 
	if [ "$last_line" != "$adb_name connected" ]; then	    
	    echo "On $(date '+%H:%M:%S, %d %B %Y')" >> /home/qajulo/tools_script/$log_name.txt
	    echo "$adb_name connected" >> /home/qajulo/tools_script/$log_name.txt
	fi
else
	echo "On $(date '+%H:%M:%S, %d %B %Y')" 
	echo "$adb_name disconnected" 
	if [ "$last_line" != "$adb_name disconnected" ]; then
	    echo "On $(date '+%H:%M:%S, %d %B %Y')" >> /home/qajulo/tools_script/$log_name.txt
	    echo "$adb_name disconnected" >> /home/qajulo/tools_script/$log_name.txt
	fi
fi


while true
do
	check_adb=$(/usr/bin/adb devices | grep -zqv "$adb_name" && echo no || echo yes)

	check_docker=$(docker ps -a| grep -zqv "$docker_name" && echo no || echo yes)


	last_line=$(tail -n 1 /home/qajulo/tools_script/$log_name.txt)

	if [ $check_adb != "no" ] || [ $check_docker != "no" ]; then
		echo "On $(date '+%H:%M:%S, %d %B %Y')" 
		echo "$adb_name connected" 
		if [ "$last_line" != "$adb_name connected" ]; then	    
		    echo "On $(date '+%H:%M:%S, %d %B %Y')" >> /home/qajulo/tools_script/$log_name.txt
		    echo "$adb_name connected" >> /home/qajulo/tools_script/$log_name.txt
		fi
	else
		echo "On $(date '+%H:%M:%S, %d %B %Y')" 
		echo "$adb_name disconnected" 
		if [ "$last_line" != "$adb_name disconnected" ]; then
		    echo "On $(date '+%H:%M:%S, %d %B %Y')" >> /home/qajulo/tools_script/$log_name.txt
		    echo "$adb_name disconnected" >> /home/qajulo/tools_script/$log_name.txt
		fi
	fi
done
