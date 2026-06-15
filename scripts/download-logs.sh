#!/usr/bin/env bash

ENV_IDS=(136297)
declare -A SVC_MAP
SVC_MAP["author"]="aemaccess aemerror aemrequest cdn"
SVC_MAP["publish"]="aemaccess aemerror aemrequest cdn"
SVC_MAP["dispatcher"]="httpdaccess httpderror aemdispatcher"

FORCE_DOWNLOAD=0
DAYS_AUTO=1

parse_args() {
    SERVICES=""
    DAYS=1
    DAYS_AUTO=1
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--service)
                SERVICES="$SERVICES $2"
                shift 2
                ;;
            -d|--days)
                DAYS="$2"
                DAYS_AUTO=0
                shift 2
                ;;
            -f|--force)
                FORCE_DOWNLOAD=1
                shift
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
    echo "  -d, --days NUM       Number of days to download"
    echo "                       Default: auto-detect from last downloaded log (fallback: 1)"
    echo "  -f, --force          Force download all logs, ignoring existing files"
    echo "  -h, --help           Show this help message"
    exit 0
}

get_existing_dates() {
    local log_dir="$1"
    local logname="$2"

    if [[ ! -d "$log_dir" ]]; then
        return
    fi

    # Files are named: {envid}-{svc}-{logname}-{date}.log
    find "$log_dir" -maxdepth 1 -type f -name "*-${logname}-[0-9]*.log" 2>/dev/null | \
        sed -E "s/.*-${logname}-([0-9]{4}-[0-9]{2}-[0-9]{2})\.log$/\1/" | \
        grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
}

get_last_downloaded_date() {
    local log_dir="$1"
    local logname="$2"
    get_existing_dates "$log_dir" "$logname" | sort | tail -1
}

compute_days_since() {
    local last_date="$1"
    local last_epoch today_epoch
    last_epoch=$(date -j -f "%Y-%m-%d" "$last_date" +%s 2>/dev/null || date -d "$last_date" +%s)
    today_epoch=$(date +%s)
    echo $(( (today_epoch - last_epoch) / 86400 + 1 ))
}

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

                local days=$DAYS
                if [[ $DAYS_AUTO -eq 1 ]]; then
                    local last_date
                    last_date=$(get_last_downloaded_date "$OUTDIR" "$logname")
                    if [[ -n "$last_date" ]]; then
                        days=$(compute_days_since "$last_date")
                        echo "####### Auto-detected: $svc - $logname last downloaded $last_date → $days day(s) #######"
                    else
                        days=1
                    fi
                fi

                if [[ $FORCE_DOWNLOAD -eq 0 ]]; then
                    local existing_dates
                    mapfile -t existing_dates < <(get_existing_dates "$OUTDIR" "$logname")
                    
                    local today
                    today=$(date +%Y-%m-%d)
                    
                    local dates_to_download=()
                    for ((i=0; i<days; i++)); do
                        local d
                        d=$(date -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "$i days ago" +%Y-%m-%d)
                        local skip=0
                        
                        for existing in "${existing_dates[@]}"; do
                            if [[ "$existing" == "$d" && "$d" != "$today" ]]; then
                                skip=1
                                break
                            fi
                        done
                        
                        if [[ $skip -eq 0 ]]; then
                            dates_to_download+=("$d")
                        fi
                    done
                    
                    if [[ ${#dates_to_download[@]} -eq 0 ]]; then
                        echo "####### Skipping: $svc - $logname (all $days day(s) already downloaded) #######"
                        continue
                    fi
                    
                    local unique_dates
                    IFS=$'\n' unique_dates=($(sort -u <<<"${dates_to_download[*]}"))
                    unset IFS
                    
                    echo "####### Downloading: $svc - $logname [${#unique_dates[@]} new day(s)] #######"
                    aio cloudmanager:environment:download-logs $envid $svc $logname $days -o $OUTDIR
                else
                    echo "####### Downloading: $svc - $logname [$days day(s) - FORCE] #######"
                    aio cloudmanager:environment:download-logs $envid $svc $logname $days -o $OUTDIR
                fi
            done
        done
    done
}

function check_if_aio_is_installed() {
    if ! command -v aio &>/dev/null; then
        echo "ERROR: aio not installed. Refer to adobeio documentation for installation instruction"
        exit 1
    fi
}

parse_args "$@"

check_if_aio_is_installed
download_logs
