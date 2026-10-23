#!/bin/bash

if [ "$1" == "Staging" ]; then
    PROJECT_ID="421447544248"
    SECRET="${FIREBASE_SA_STAGING}"
elif [ "$1" == "UAT" ] || [ "$1" == "Regression" ]; then
    PROJECT_ID="789256274704"
    SECRET="${FIREBASE_SA_UAT}"
else
    echo "Please provide the environment as an argument."
fi

APP_ID="1:$PROJECT_ID:android:6b7f4559879fc7ab"

if [ -n "$2" ]; then
    processed_time=$(echo "$2" | sed 's/ at / /')

    low_boundary_date=$(date --date="$processed_time" --utc +%Y-%m-%dT%H:%M:%S.0Z)

    upper_boundary_date=$(date --date="$processed_time +1 second" --utc +%Y-%m-%dT%H:%M:%S.0Z)
fi


# # Configuration
KEY=$(echo "$SECRET" | base64 --decode)

# Function to get access token using the service account
get_access_token() {
  # Extract the client email and private key from the service account file
  CLIENT_EMAIL=$(echo "$KEY" | jq -r '.client_email')
  PRIVATE_KEY=$(echo "$KEY" | jq -r '.private_key' | sed 's/\\n/\n/g')

  # Define the JWT payload and header
  HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')
  CLAIM_SET=$(echo -n "{\"iss\":\"$CLIENT_EMAIL\",\"scope\":\"https://www.googleapis.com/auth/cloud-platform\",\"aud\":\"https://oauth2.googleapis.com/token\",\"exp\":$(($(date +%s)+3600)),\"iat\":$(date +%s)}" | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')

  # Create the signature
  SIGNATURE=$(echo -n "$HEADER.$CLAIM_SET" | openssl dgst -sha256 -sign <(echo -n "$PRIVATE_KEY") | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')

  # Construct the JWT
  JWT="$HEADER.$CLAIM_SET.$SIGNATURE"

  # Get the access token
  ACCESS_TOKEN=$(curl -s --request POST \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=$JWT" \
    https://oauth2.googleapis.com/token | jq -r '.access_token')

  echo "$ACCESS_TOKEN"
}

# Get access token
ACCESS_TOKEN=$(get_access_token)

# Check if we successfully retrieved the access token
if [ -z "$ACCESS_TOKEN" ]; then
  echo "Failed to get access token."
  exit 1
fi

filters=""

if [ -n "$2" ]; then
    filters="$filters&filter=createTime>=\"$low_boundary_date\"&filter=createTime<=\"$upper_boundary_date\""
fi

if [ "$1" == "Regression" ]; then
    filters="$filters&filter=releaseNotes.text=*regression-automation-apk*"
fi

url="https://firebaseappdistribution.googleapis.com/v1/projects/$PROJECT_ID/apps/$APP_ID/releases?pageSize=1$filters"

encoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$url', safe=':/?&='))")

# # Fetch the latest release information from Firebase App Distribution
RELEASE_INFO=$(curl -s --request GET \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  $encoded_url)

# Check if the release information was retrieved
if [ -z "$RELEASE_INFO" ]; then
  echo "Failed to fetch release information."
  exit 1
fi

echo $RELEASE_INFO
