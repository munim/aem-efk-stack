#!/bin/bash

ENV_IDS=(136297)
declare -A SVC_MAP
SVC_MAP["author"]="aemaccess aemerror aemrequest cdn"
SVC_MAP["publish"]="aemaccess aemerror aemrequest cdn"
SVC_MAP["dispatcher"]="httpdaccess httpderror aemdispatcher"
SERVICES=(author publish)
LOG_NAMES=(aemaccess aemerror aemrequest cdn)
DAYS="1"

for envid in "${ENV_IDS[@]}"; do
  for svc in "${!SVC_MAP[@]}"; do
    # convert string to array
    LOGS=($(echo ${SVC_MAP[$svc]} | tr " " "\n"))
    for logname in "${LOGS[@]}"; do
      OUTDIR="./logs/$envid/$svc/$logname"
      mkdir -p $OUTDIR >/dev/null 2>&1
      echo "Downloading: $svc - $logname"
      aio cloudmanager:environment:download-logs $envid $svc $logname $DAYS -o $OUTDIR
    done;
  done;
done;
# for envid in "${ENV_IDS[@]}"; do
#   for svc in "${SERVICES[@]}"; do
#     for logname in "${LOG_NAMES[@]}"; do
#       OUTDIR="./logs/$envid/$svc/$logname"
#       mkdir -p $OUTDIR >/dev/null 2>&1
#       echo "Downloading: $svc - $logname"
#       aio cloudmanager:environment:download-logs $envid $svc $logname $DAYS -o $OUTDIR
#     done;
#   done;
# done;
