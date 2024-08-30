#!/bin/bash

ENV_IDS=(136297)
declare -A SVC_MAP
SVC_MAP["author"]="aemaccess aemerror aemrequest cdn"
SVC_MAP["publish"]="aemaccess aemerror aemrequest cdn"
SVC_MAP["dispatcher"]="httpdaccess httpderror aemdispatcher"

download_logs () {
  for envid in "${ENV_IDS[@]}"; do
    for svc in "${!SVC_MAP[@]}"; do
      # convert string to array
      LOGS=($(echo ${SVC_MAP[$svc]} | tr " " "\n"))
      for logname in "${LOGS[@]}"; do
        OUTDIR="./logs/$envid/$svc/$logname"
        mkdir -p $OUTDIR >/dev/null 2>&1
        echo "####### Downloading: $svc - $logname #######"
        echo $DAYS
        aio cloudmanager:environment:download-logs $envid $svc $logname $DAYS -o $OUTDIR
      done;
    done;
  done;
}

function check_if_aio_is_installed() {
  if ! command -v aio &> /dev/null
  then
      echo "ERROR: aio not installed. Refer to adobeio documentation for installation instruction"
      exit 1
  fi
}

while getopts ":hd:" opt; do
  case $opt in
    d) DAYS=$OPTARG ;;
    h) 
      echo "Usage: $0 [-d days]"
      echo "  -d days  Specify the number of days (default: 1)"
      exit 0
      ;;
    \?) echo "Invalid option: -$OPTARG"; exit 1 ;;
  esac
done

# Set default value to 1 if not provided
DAYS=${DAYS:-1}

check_if_aio_is_installed
download_logs

