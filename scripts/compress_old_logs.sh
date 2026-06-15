#!/bin/bash

# Description:
# This script searches for log files in a specified directory and compresses them using 7z,
# excluding files with today's and yesterday's dates in their filenames.
# The script uses the `fd` tool to find files and `7z` to compress them.

# Detect OS
OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
    DATE_CMD="date -v-1d"
    GREP_CMD="sed"
else
    DATE_CMD="date -d \"-1 day\""
    GREP_CMD="grep -oP"
fi

# Set the directory to search recursively
search_dir="./logs/"

# Get today's and yesterday's dates in YYYY-MM-DD format
today=$(date +%Y-%m-%d)
yesterday=$($DATE_CMD +%Y-%m-%d)

# Set the regex pattern to match files that end with YYYY-MM-DD.log
pattern='^.*([0-9]{4}-[0-9]{2}-[0-9]{2})\.log$'

# Use fd to search for files recursively
for file in $(fd -I --regex "$pattern" "$search_dir"); do
    # Extract the date from the filename
    if [[ "$OS" == "Darwin" ]]; then
        date_match=$(echo "$file" | sed 's/.*\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/')
    else
        date_match=$(echo "$file" | grep -oP '([0-9]{4}-[0-9]{2}-[0-9]{2})(?=\.log$)')
    fi

    # Skip files that match today's and yesterday's dates
    if [ "$date_match" != "$today" ] && [ "$date_match" != "$yesterday" ]; then
        # Compress the file using 7z
        if 7z a -mx=5 -m0=lzma2 "${file}.7z" "$file"; then
            # Remove the original file
            rm "$file"
        fi
    fi
done
