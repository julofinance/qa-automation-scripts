#!/bin/bash

download_apk_auto() {
    # Set the maximum number of download attempts
    max_attempts=3
    attempt=1

    APK_ENV_TYPE="$1"

    release_id="/home/qajulo/apks/last_downloaded_release_id_${APK_ENV_TYPE}.txt"

    # get last downloaded release id
    if [ -f "$release_id" ]; then
        last_downloaded_release_id=$(cat $release_id)
    else
        last_downloaded_release_id="0"
    fi

    # increment last downloaded release id
    last_downloaded_release_id=$((last_downloaded_release_id+1))

    # Create a lock file specific to the APK_ENV_TYPE in the desired directory
    lock_file="/home/qajulo/apks/download_${APK_ENV_TYPE}.lock"

    if [ -f "$lock_file" ]; then
        echo "antoher download instance is running"
        return 0
    fi
    touch "$lock_file"

    APPCENTER_USER_API_TOKEN="${APPCENTER_USER_API_TOKEN}"
    app_center_url="https://api.appcenter.ms/v0.1/apps/Julo/${APK_ENV_TYPE}-Armv7/releases/${last_downloaded_release_id}"
    echo $app_center_url

    download_url=$(curl -X GET $app_center_url \
    -H "accept: application/json" \
    -H  "X-API-Token: $APPCENTER_USER_API_TOKEN" | \
    jq -r '.download_url')
    echo $download_url


    if [ -z "$download_url" ]
    then
        echo "Download URL is empty"
        rm "$lock_file"
        return 1
    fi

    id=$(curl -X GET $app_center_url \
    -H "accept: application/json" \
    -H  "X-API-Token: $APPCENTER_USER_API_TOKEN" | \
    jq -r '.id')
    echo $id

    upload_time=$(curl -X GET $app_center_url \
    -H "accept: application/json" \
    -H  "X-API-Token: $APPCENTER_USER_API_TOKEN" | \
    jq -r '.uploaded_at')
    echo $upload_time

    export APK_NAME="${APK_ENV_TYPE}_${upload_time}_${id}"
    export APK_PATH="/home/qajulo/apks/$APK_NAME.apk"

    # Expected size
    actual_size=$(stat -c %s "$APK_PATH")
    expected_size=65000000
    # Calculate the allowed deviation (20%)
    allowed_deviation=$(echo "scale=2; $expected_size * 0.5" | bc)
    # Calculate the lower and upper bounds
    lower_bound=$(echo "$expected_size - $allowed_deviation" | bc)
    lower_bound=$(awk -v val="$lower_bound" 'BEGIN { print int(val) }')
    upper_bound=$(echo "$expected_size + $allowed_deviation" | bc)
    upper_bound=$(awk -v val="$upper_bound" 'BEGIN { print int(val) }')


    # Check if the file already exists
    if [ -f "$APK_PATH" ]; then
        echo "APK already downloaded and matches the expected size within the acceptable range. Exiting."
        # Remove the lock file
        rm "$lock_file"
        return 0
    fi

    # Download loop
    while [ "$attempt" -le "$max_attempts" ]; do
        find /home/qajulo/apks -type f -name "${APK_ENV_TYPE}_updated_on*" -delete
        touch "/home/qajulo/apks/${APK_ENV_TYPE}_updated_on_$(date +'%Y-%m-%d %H:%M:%S')"
        wget --no-verbose -O "$APK_PATH" "$download_url"
        if [ $? -eq 0 ]; then
            # Check if the downloaded file size matches the expected size
            actual_size=$(stat -c %s "$APK_PATH")

            if echo [ "$actual_size" -ge "$lower_bound" ] && [ "$actual_size" -le "$upper_bound" ]; then
                echo "APK downloaded successfully within the acceptable size range."
                cp "$APK_PATH" "/home/qajulo/apks/${APK_ENV_TYPE}_LATEST.apk"
                chmod 777 $APK_PATH
                chmod 777 "/home/qajulo/apks/${APK_ENV_TYPE}_LATEST.apk"
                # Remove the lock file
                rm "$lock_file"

                #update last downloaded release id file txt
                echo "$last_downloaded_release_id" > "$release_id"

                return 0
            else
                echo "Downloaded file size ($actual_size bytes) doesn't match the expected size. Retrying..."
            fi
        else
            echo "Download failed (attempt $attempt). Retrying..."
        fi
        attempt=$((attempt + 1))
        sleep 1
    done

    # Remove the lock file in case of failure
    rm "$lock_file"
    echo "Download failed after $max_attempts attempts."
    return 1
}

# Call the function
download_apk_auto Regression-UAT
download_apk_auto UAT
download_apk_auto Staging
