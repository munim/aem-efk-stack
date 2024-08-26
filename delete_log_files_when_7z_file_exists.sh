#!/bin/bash

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
