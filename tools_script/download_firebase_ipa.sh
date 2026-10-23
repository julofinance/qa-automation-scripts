download_ipa_auto() {
    # Set the maximum number of download attempts
    max_attempts=3
    attempt=1

    IPA_ENV_TYPE="$1"

    release_id="/home/qajulo/ipas/last_downloaded_firebase_release_id_${IPA_ENV_TYPE}.txt"

    # get last downloaded release id
    if [ -f "$release_id" ]; then
        last_downloaded_release_id=$(cat $release_id)
    else
        last_downloaded_release_id="0"
    fi

    # Create a lock file specific to the IPA_ENV_TYPE in the desired directory
    lock_file="/home/qajulo/ipas/download_firebase_${IPA_ENV_TYPE}.lock"

    if [ -f "$lock_file" ]; then
        echo "antoher download instance is running"
        return 0
    fi
    touch "$lock_file"

    response=$(echo | bash /home/qajulo/tools_script/get_firebase_ipa_info.sh $IPA_ENV_TYPE)
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

    export IPA_NAME="${IPA_ENV_TYPE}_${upload_time}_${id}"
    export IPA_PATH="/home/qajulo/ipas/$IPA_NAME.ipa"

    # Expected size
    actual_size=$(stat -c %s "$IPA_PATH")
    expected_size=65000000
    # Calculate the allowed deviation (20%)
    allowed_deviation=$(echo "scale=2; $expected_size * 0.5" | bc)
    # Calculate the lower and upper bounds
    lower_bound=$(echo "$expected_size - $allowed_deviation" | bc)
    lower_bound=$(awk -v val="$lower_bound" 'BEGIN { print int(val) }')
    upper_bound=$(echo "$expected_size + $allowed_deviation" | bc)
    upper_bound=$(awk -v val="$upper_bound" 'BEGIN { print int(val) }')


    # Check if the file already exists
    if [ -f "$IPA_PATH" ]; then
        echo "IPA already downloaded and matches the expected size within the acceptable range. Exiting."
        # Remove the lock file
        rm "$lock_file"
        echo "==========================================="
        return 0
    elif [ '$id' == '$last_downloaded_release_id' ]; then
        echo "IPA already downloaded and the id matches the id in ${release_id}. Exiting."
        # Remove the lock file
        rm "$lock_file"
        echo "==========================================="
        return 0

    fi

    # Download loop
    while [ "$attempt" -le "$max_attempts" ]; do
        find /home/qajulo/ipas -type f -name "${IPA_ENV_TYPE}_updated_on*" -delete
        touch "/home/qajulo/ipas/${IPA_ENV_TYPE}_updated_on_$(date +'%Y-%m-%d %H:%M:%S')"
        echo "trying to download"
        #wget --no-verbose -O "$IPA_PATH" "$download_url"
        curl -L -o "$IPA_PATH" "$download_url"
        if [ $? -eq 0 ]; then
            # Check if the downloaded file size matches the expected size
            actual_size=$(stat -c %s "$IPA_PATH")

            if echo [ "$actual_size" -ge "$lower_bound" ] && [ "$actual_size" -le "$upper_bound" ]; then
                echo "IPA downloaded successfully within the acceptable size range."
                cp "$IPA_PATH" "/home/qajulo/ipas/${IPA_ENV_TYPE}_LATEST.ipa"
                chmod 777 $IPA_PATH
                chmod 777 "/home/qajulo/ipas/${IPA_ENV_TYPE}_LATEST.ipa"
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
download_ipa_auto UAT
download_ipa_auto Staging
download_ipa_auto Regression
