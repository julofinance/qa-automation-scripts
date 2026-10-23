import requests
import os
import json
from datetime import datetime

# Endpoint URL
endpoint_url = "http://10.21.80.5:4723/device-farm/api/device"

def get_device_status():
    try:
        response = requests.get(endpoint_url)
        response_data = response.json()
    except requests.RequestException as e:
        print(f"Error fetching data from the endpoint: {e}")
        response_data = {}
    # Create a logs directory if it doesn't exist
    logs_dir = "./logs"
    os.makedirs(logs_dir, exist_ok=True)

    # Get existing log files
    existing_logs = set(os.listdir(logs_dir))
    cleaned_existing_logs = {value.replace('+log.txt', '') for value in existing_logs}


    # Process devices in logs_dir first
    for log_device in cleaned_existing_logs:
        log_file = f"{logs_dir}/{log_device}+log.txt"
        process_device(log_device, log_file, response_data)

    # Process remaining devices from response_data
    for device in response_data:
        device_name = device.get("name")
        log_file = f"{logs_dir}/{device_name}+log.txt"
        if device_name not in cleaned_existing_logs:
            process_device(device_name, log_file, response_data)

def process_device(device_name, log_file, response_data):
    device_status = get_device_status_from_endpoint(device_name, response_data)
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Update status to "ONLINE" if it was "device"
    if device_status == "device":
        device_status = "ONLINE"

    # Write device status to the log file
    with open(log_file, "a") as f:
        f.write(f"{timestamp} - {device_status}\n")

    # Check if status changed and send alert to Slack
    try:
        previous_state = read_previous_state(log_file)
        print(f"{device_name} : {previous_state} : {device_status}")
        if device_status != previous_state:
            send_slack_alert(device_name, device_status)
    except:
        pass

def get_device_status_from_endpoint(device_name, response_data):
    try:
        # Find the device with the matching name
        for device in response_data:
            if device.get("name") == device_name:
                return device.get("state", "UNKNOWN")

        # If device not found, return "UNKNOWN"
        return "UNKNOWN"

    except requests.RequestException as e:
        print(f"Error fetching data from the endpoint: {e}")
        return "UNKNOWN"

def read_previous_state(log_file):
    try:
        with open(log_file, "r") as f:
            lines = f.readlines()
            if lines:
                return lines[-2].split(" - ")[-1].strip()
    except FileNotFoundError:
        pass
    return None

def send_slack_alert(device_name, device_status):
    # Replace this with your Slack alert implementation
    # Example: Send a message to a Slack channel
    print(f"Alert: Device {device_name} status changed to {device_status}")

if __name__ == "__main__":
    get_device_status()
