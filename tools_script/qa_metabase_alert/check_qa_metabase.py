import os
import json
import requests
from datetime import datetime
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

# Constants
SLACK_CHANNEL = "C07EML5B0RH"
SLACK_TOKEN = os.environ.get("SLACK_BOT_TOKEN")
LOG_DIR = os.path.dirname(__file__)
LOG_FILE = os.path.join(LOG_DIR, "check_qa_metabase_log.json")
METABASE_URL = "https://live-test-metabase.julotechnology.com/api/health"

# Slack client
client = WebClient(token=SLACK_TOKEN)

# Ensure log directory exists
os.makedirs(LOG_DIR, exist_ok=True)


def load_log():
    """Load the server status log."""
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, "r") as f:
            return json.load(f)
    return {"status": []}


def save_log(log_data):
    """Save the server status log."""
    with open(LOG_FILE, "w") as f:
        json.dump(log_data, f, indent=4)


def check_server():
    """Check the Metabase server's health status."""
    try:
        response = requests.get(METABASE_URL)
        return response.status_code
    except requests.ConnectionError as e:
        print(e)
        return False


def send_slack_alert(status):
    """Send an alert to Slack based on server status."""
    if str(status).startswith("2"):
        message = "✅ Recovered: QA Metabase is UP!"
    else:
        message = f"🚨 {METABASE_URL} is down with response code {status}"

    try:
        client.chat_postMessage(channel=SLACK_CHANNEL, text=message)
    except SlackApiError as e:
        print(f"Error sending alert to Slack: {e.response['error']}")


def monitor_metabase():
    """Monitor Metabase server health and log status changes."""
    log_data = load_log()
    current_time_decimal = float(f"{datetime.now().hour}.{datetime.now().minute}")
    server_status = check_server()

    last_status_entry = log_data["status"][-1] if log_data["status"] else None

    # Only send alert if status has changed
    if not last_status_entry or str(last_status_entry[1])[0] != str(server_status)[0]:
        send_slack_alert(server_status)
        log_data["status"].append((current_time_decimal, server_status))
        save_log(log_data)


if __name__ == "__main__":
    monitor_metabase()
