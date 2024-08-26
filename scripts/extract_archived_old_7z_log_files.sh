#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <directory_path>"
  exit 1
fi

directory_path="$1"

find "$directory_path" -type f -name "*.7z" -print0 | while IFS= read -r -d $'\0' file; do
# fd -H -t f -e 7z "$directory_path" | while read -r file; do
  7z x -o"${file%/*}" "$file"
done
