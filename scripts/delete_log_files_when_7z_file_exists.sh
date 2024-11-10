#!/bin/bash

# Description:
# This script recursively searches for .7z files with the pattern filename.log.7z.
# For each found .7z file, it checks if the corresponding log file (without the .7z extension) exists.
# If the log file exists, the script deletes it and prints a message indicating the deletion.

# Recursively search for 7z files with the pattern filename.log.7z
find . -type f -name "*.log.7z" -print0 | while IFS= read -r -d '' file; do
    # Extract the filename without the .7z extension
    filename="${file%.7z}"

    # Check if the corresponding log file exists
    if [ -f "$filename" ]; then
        # Delete the log file
        rm "$filename"
        echo "Deleted $filename"
    fi
done
