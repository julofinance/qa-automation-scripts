import requests
import json
import os
import slack_sdk

def check_devices_stf():
    # Define the API endpoint
    api_url = 'http://10.168.64.144:7100/api/v1/devices'

    # Define the authentication bearer token
    auth_token = os.environ.get("STF_TOKEN")

    # Make a GET request to the API with the bearer token
    headers = {'Authorization': f'Bearer {auth_token}'}
    response = requests.get(api_url, headers=headers)
    print(response)

    # Check if the response is successful
    if response.status_code == 200:
        # Load the JSON response
        json_response = response.json()

        # Initialize a list to store device information
        devices_info = []

        # Check if the device_info.json file exists and load its content
        if os.path.exists('device_info.json'):
            with open('device_info.json', 'r') as file:
                saved_devices_info = json.load(file)

                # Iterate through the devices in the JSON response
                for device in json_response['devices']:
                    if not device['present']:
                        # Save device information if not ready
                        device_info = {
                            'device_name': device['model'],
                            'device_serial': device['serial'],
                            'status': 'Not Ready'
                        }
                        devices_info.append(device_info)

                        # Check if the device serial is not present and not recorded in saved_devices_info
                        if not any(d['device_serial'] == device['serial'] for d in saved_devices_info):
                            send_slack_alert(f"Device {device['model']} with serial {device['serial']} is not present.")
                    else:
                        # Check if the device serial is present but was not recorded in saved_devices_info
                        if any(d['device_serial'] == device['serial'] for d in saved_devices_info):
                            send_slack_alert(f"Device {device['model']} with serial {device['serial']} is back online.", tag_team=False)

            # Save the device information to device_info.json
            with open('device_info.json', 'w') as file:
                json.dump(devices_info, file, indent=4)
        else:
            # Save the device information to device_info.json as it's the first run
            with open('device_info.json', 'w') as file:
                json.dump(devices_info, file, indent=4)


def send_slack_alert(message, tag_team=True):
    channel = "#alerts_device_farm"

    if tag_team:
        message = message +"\n<!subteam^S07219LANNM>."
        
    token = os.environ.get("SLACK_BOT_TOKEN")

    client = slack_sdk.WebClient(token)

    client.chat_postMessage(
        channel=channel,
        text=message,
        blocks=[{"type": "section", "text": {"type": "mrkdwn", "text": f"{message}"}}],
    )

if __name__ == "__main__":
    check_devices_stf()

