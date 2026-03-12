#!/usr/bin/env bash

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
    local services_to_download=()

    if [[ -z "$SERVICES" ]]; then
        services_to_download=("${!SVC_MAP[@]}")
    else
        for svc_spec in $SERVICES; do
            local svc_name="${svc_spec%%:*}"
            local log_filter="${svc_spec##*:}"
            if [[ "${SVC_MAP[$svc_name]+exists}" ]]; then
                services_to_download+=("$svc_spec")
            else
                echo "WARNING: Unknown service '$svc_name', skipping"
            fi
        done
    fi

    for envid in "${ENV_IDS[@]}"; do
        for svc_spec in "${services_to_download[@]}"; do
            local svc="${svc_spec%%:*}"
            local filter="${svc_spec##*:}"
            local filter_logs=()
            
            if [[ "$filter" == "$svc_spec" ]]; then
                mapfile -t filter_logs < <(echo ${SVC_MAP[$svc]} | tr " " "\n")
            else
                IFS=',' read -ra filter_logs <<< "$filter"
            fi
            for logname in "${filter_logs[@]}"; do
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

parse_args() {
    SERVICES=""
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--service)
                SERVICES="$SERVICES $2"
                shift 2
                ;;
            -d|--days)
                DAYS="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    echo "Usage: $0 [options]"
    echo "  -s, --service SPEC   Service(s) to download (can be specified multiple times)"
    echo "                       Format: SERVICE or SERVICE:LOGS"
    echo "                       Examples:"
    echo "                         -s publish          (all logs for publish)"
    echo "                         -s publish:cdn      (only cdn logs)"
    echo "                         -s publish:cdn,error (cdn and error logs)"
    echo "                         -s author -s publish:cdn"
    echo "                       Available services: author, publish, dispatcher"
    echo "                       Available logs: aemaccess, aemerror, aemrequest, cdn,"
    echo "                                      httpdaccess, httpderror, aemdispatcher"
    echo "                       Default: all services and all logs"
    echo "  -d, --days NUM       Number of days to download (default: 1)"
    echo "  -h, --help           Show this help message"
    exit 0
}

DAYS=${DAYS:-1}

parse_args "$@"

check_if_aio_is_installed
download_logs
