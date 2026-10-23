#!/bin/bash

download_apk_auto() {
    # Set the maximum number of download attempts
    max_attempts=3
    attempt=1

    PROJECT_NAME="$1"
    APK_ENV_TYPE="$2"

    if [ "$PROJECT_NAME" = "FC" ]; then
        PREFIX_APK_NAME="FC_${APK_ENV_TYPE}"
    else
        PREFIX_APK_NAME="${APK_ENV_TYPE}"
    fi

    release_id="/home/qajulo/apks/last_downloaded_firebase_release_id_${PREFIX_APK_NAME}.txt"

    # get last downloaded release id
    if [ -f "$release_id" ]; then
        last_downloaded_release_id=$(cat $release_id)
    else
        last_downloaded_release_id="0"
    fi

    # Create a lock file specific to the APK_ENV_TYPE in the desired directory
    lock_file="/home/qajulo/apks/download_firebase_${PREFIX_APK_NAME}.lock"

    if [ -f "$lock_file" ]; then
        echo "antoher download instance is running"
        return 0
    fi
    touch "$lock_file"

    response=$(echo | bash /home/qajulo/tools_script/get_firebase_apk_info.sh $PROJECT_NAME $APK_ENV_TYPE)
    echo $response

    if [ -z "$response" ]
    then
        echo "Failed to fetch release information."
        rm "$lock_file"
        return 1
    fi

    download_url=$(echo "$response" | jq -r '.releases[0].binaryDownloadUri')
    echo "download_url = ${download_url}"

    if [ -z "$download_url" ]
    then
        echo "Download URL is empty"
        rm "$lock_file"
        return 1
    fi

    id=$(echo "$response" | jq -r '.releases[0].name' | awk -F'/' '{print $NF}')
    echo "id = ${id}"

    upload_time=$(echo "$response" | jq -r '.releases[0].createTime')
    echo "upload_time = ${upload_time}"

    export APK_NAME="${PREFIX_APK_NAME}_${upload_time}_${id}"
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
        echo "==========================================="
        return 0
    elif [ '$id' == '$last_downloaded_release_id' ]; then
        echo "APK already downloaded and the id matches the id in ${release_id}. Exiting."
        # Remove the lock file
        rm "$lock_file"
        echo "==========================================="
        return 0

    fi

    # Download loop
    while [ "$attempt" -le "$max_attempts" ]; do
        find /home/qajulo/apks -type f -name "${PREFIX_APK_NAME}_updated_on*" -delete
        touch "/home/qajulo/apks/${PREFIX_APK_NAME}_updated_on_$(date +'%Y-%m-%d %H:%M:%S')"
        echo "trying to download"
        #wget --no-verbose -O "$APK_PATH" "$download_url"
        curl -L -o "$APK_PATH" "$download_url"
        if [ $? -eq 0 ]; then
            # Check if the downloaded file size matches the expected size
            actual_size=$(stat -c %s "$APK_PATH")

            if echo [ "$actual_size" -ge "$lower_bound" ] && [ "$actual_size" -le "$upper_bound" ]; then
                echo "APK downloaded successfully within the acceptable size range."
                cp "$APK_PATH" "/home/qajulo/apks/${PREFIX_APK_NAME}_LATEST.apk"
                chmod 777 $APK_PATH
                chmod 777 "/home/qajulo/apks/${PREFIX_APK_NAME}_LATEST.apk"
                # Remove the lock file
                rm "$lock_file"

                #update last downloaded release id file txt
                echo "$id" > "$release_id"
                echo "==========================================="

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
    echo "==========================================="
    return 1
}

# Call the function
download_apk_auto J1 UAT
download_apk_auto J1 Staging
download_apk_auto J1 Regression
download_apk_auto FC UAT
download_apk_auto FC Staging
download_apk_auto FC Regression
