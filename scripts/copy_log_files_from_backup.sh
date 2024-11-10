#!/bin/bash

# Description:
# This script synchronizes log files from a source directory to a destination directory
# based on a specified date range. It uses rsync to include only log files with dates
# within the specified range and excludes all other files.

# Check for the correct number of arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <source_path> <destination_path> <start_date> [end_date]"
    echo "Date format: YYYY-MM-DD"
    exit 1
fi

# Define source and destination paths from arguments
SOURCE_PATH="$1"
DESTINATION_PATH="$2"
START_DATE="$3"
END_DATE="$4"

# Convert start date to seconds since epoch
START_EPOCH=$(date -d "$START_DATE" +%s)

# If no end date is provided, set end date to a future date
if [ -z "$END_DATE" ]; then
    END_EPOCH=$(date +%s) # Use current date
else
    END_EPOCH=$(date -d "$END_DATE" +%s)
fi

# Generate the include patterns for rsync
INCLUDE_PATTERNS=""
for ((d = 0; d <= ($END_EPOCH - $START_EPOCH) / 86400; d++)); do
    CURRENT_DATE=$(date -d "$START_DATE + $d days" +%Y-%m-%d)
    INCLUDE_PATTERNS+="--include=*-${CURRENT_DATE}.log.7z "
done

# Final rsync command
rsync -av --include='*/' $INCLUDE_PATTERNS --exclude='*' "$SOURCE_PATH/" "$DESTINATION_PATH/"
