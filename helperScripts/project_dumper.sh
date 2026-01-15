#!/usr/bin/env bash

# Usage: ./dump_src.sh <directory_path> > context_dump.txt

# [P14] NZX Error Standard Check: Ensure an argument is passed
if [ -z "$1" ]; then
    echo "Usage: $0 <directory_path>"
    exit 1
fi

TARGET_DIR="$1"

if [ ! -d "$TARGET_DIR" ]; then
    echo "## [ ! ] Error: $TARGET_DIR not found or is not a directory."
    exit 1
fi

# Use -print0 and read -d '' to safely handle filenames with spaces or newlines
find "$TARGET_DIR" -type f -print0 | while IFS= read -r -d '' file; do
    echo "---- START OF FILE \"$file\" ----"
    cat "$file"
    echo -e "\n---- END OF FILE ----\n"
done