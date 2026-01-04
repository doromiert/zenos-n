#!/usr/bin/env bash

# Usage: ./dump_src.sh > context_dump.txt

TARGET_DIR="./src"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: $TARGET_DIR not found."
    exit 1
fi

find "$TARGET_DIR" -type f | while read -r file; do
    echo "---- START OF FILE \"$file\" ----"
    cat "$file"
    echo -e "\n---- END OF FILE ----\n"
done