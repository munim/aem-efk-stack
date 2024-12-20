#!/bin/bash

# Description:
# This script downloads log files from Adobe Cloud Manager environments.
# It takes an optional parameter to specify the number of days for which logs should be downloaded.
# The script uses the `aio` command-line tool to interact with Adobe Cloud Manager.

# Define environment IDs and service-to-log mappings
ENV_IDS=(136297)
declare -A SVC_MAP
SVC_MAP["author"]="aemaccess aemerror aemrequest cdn"
SVC_MAP["publish"]="aemaccess aemerror aemrequest cdn"
SVC_MAP["dispatcher"]="httpdaccess httpderror aemdispatcher"

# Function to download logs
download_logs() {
    for envid in "${ENV_IDS[@]}"; do
        for svc in "${!SVC_MAP[@]}"; do
            # Convert string to array
            LOGS=($(echo ${SVC_MAP[$svc]} | tr " " "\n"))
            for logname in "${LOGS[@]}"; do
                OUTDIR="./logs/$envid/$svc/$logname"
                mkdir -p $OUTDIR >/dev/null 2>&1
                echo "####### Downloading: $svc - $logname [$DAYS day(s)] #######"
                aio cloudmanager:environment:download-logs $envid $svc $logname $DAYS -o $OUTDIR
            done
        done
    done
}

# Function to check if the `aio` command-line tool is installed
function check_if_aio_is_installed() {
    if ! command -v aio &>/dev/null; then
        echo "ERROR: aio not installed. Refer to adobeio documentation for installation instruction"
        exit 1
    fi
}

# Parse command-line options
while getopts ":hd:" opt; do
    case $opt in
    d) DAYS=$OPTARG ;;
    h)
        echo "Usage: $0 [-d days]"
        echo "  -d days  Specify the number of days (default: 1)"
        exit 0
        ;;
    \?)
        echo "Invalid option: -$OPTARG"
        exit 1
        ;;
    esac
done

# Set default value to 1 if not provided
DAYS=${DAYS:-1}

# Check if `aio` is installed and then download logs
check_if_aio_is_installed
download_logs
