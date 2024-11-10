#!/bin/bash

# Description:
# This script takes three parameters: src, dest, and lines.
# It finds all log files recursively inside the src directory,
# and then copies the first specified number of lines (lines parameter)
# to the dest directory while preserving the directory structure and filename.

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 src dest lines"
    exit 1
fi

src="$1"
dest="$2"
lines="$3"

# Check if the source directory exists
if [ ! -d "$src" ]; then
    echo "Source directory does not exist: $src"
    exit 1
fi

# Check if the destination directory exists, if not create it
if [ ! -d "$dest" ]; then
    mkdir -p "$dest"
fi

# Check if the lines parameter is a positive integer
if ! [[ "$lines" =~ ^[0-9]+$ ]] || [ "$lines" -le 0 ]; then
    echo "Lines parameter must be a positive integer: $lines"
    exit 1
fi

# Find all log files recursively in the source directory
find "$src" -type f -name "*.log" | while read -r file; do
    # Get the relative path of the file from the source directory
    relative_path="${file#$src/}"

    # Create the corresponding directory structure in the destination directory
    dest_dir="$dest/$(dirname "$relative_path")"
    mkdir -p "$dest_dir"

    # Copy the specified number of lines of the log file to the destination directory
    dest_file="$dest_dir/$(basename "$relative_path")"
    head -n "$lines" "$file" >"$dest_file"

    echo "Copied first $lines lines of $file to $dest_file"
done

echo "Done copying log files."
