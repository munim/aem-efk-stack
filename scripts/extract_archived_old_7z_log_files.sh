#!/bin/bash

# Description:
# This script takes a single parameter, which is the path to a directory.
# It finds all .7z files recursively within the specified directory
# and extracts them in place, preserving the directory structure.

# Check if the correct number of arguments is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <directory_path>"
    exit 1
fi

# Assign the provided argument to the directory_path variable
directory_path="$1"

# Find all .7z files recursively in the specified directory
# The -print0 option ensures that filenames with special characters are handled correctly
find "$directory_path" -type f -name "*.7z" -print0 | while IFS= read -r -d $'\0' file; do
    # Extract the .7z file in place, preserving the directory structure
    # The -o option specifies the output directory, which is the same as the file's directory
    7z x -o"${file%/*}" "$file"
done
