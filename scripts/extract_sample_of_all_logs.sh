#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 <source_dir> <destination_dir> <N>"
    echo "  source_dir: The directory to search for log files."
    echo "  destination_dir: The directory to save the tail outputs."
    echo "  N: The number of lines to tail from each log file."
    exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    usage
fi

# Assign arguments to variables
SOURCE_DIR="$1"
DEST_DIR="$2"
N="$3"

# Ensure source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist."
    exit 1
fi

# Ensure destination directory exists, create if not
if [ ! -d "$DEST_DIR" ]; then
    echo "Destination directory '$DEST_DIR' does not exist, creating it."
    mkdir -p "$DEST_DIR"
fi

# Function to find the latest log file in a directory and tail N lines
process_directory() {
    local dir="$1"
    local relative_path="${dir#$SOURCE_DIR}"
    local dest_path="$DEST_DIR/$relative_path"

    # Create the destination directory if it doesn't exist
    mkdir -p "$dest_path"

    # Find the latest log file in the directory
    latest_log=$(find "$dir" -maxdepth 1 -type f -name "*.log" -printf "%T+ %p\n" | sort -r | head -n 1 | cut -d' ' -f2-)

    if [ -z "$latest_log" ]; then
        echo "No log files found in $dir"
        return
    fi

    # Extract the log file name
    log_file_name=$(basename "$latest_log")

    # Tail N lines from the latest log file and save to the destination directory
    tail -n "$N" "$latest_log" >"$dest_path/$log_file_name.tail"

    echo "Processed $latest_log -> $dest_path/$log_file_name.tail"
}

# Recursively process each directory in the source directory
while IFS= read -r -d '' dir; do
    process_directory "$dir"
done < <(find "$SOURCE_DIR" -type d -print0)

echo "Processing complete."
