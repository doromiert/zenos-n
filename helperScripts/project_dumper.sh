#!/usr/bin/env bash

# Usage: ./dump_src.sh [-i ignore_dir_name]... <directory_path> > context_dump.txt

IGNORE_DIRS=()
TARGET_DIR=""

# Manual argument parsing to support flags placed after the directory argument
while [[ $# -gt 0 ]]; do
  case $1 in
    -i)
      if [[ $# -lt 2 ]]; then
        echo "## [ ! ] Error: Option -i requires an argument." >&2
        exit 1
      fi
      # Sanitize: remove trailing slash and leading ./
      CLEAN_DIR="${2%/}"
      CLEAN_DIR="${CLEAN_DIR#./}"
      IGNORE_DIRS+=("$CLEAN_DIR")
      shift 2 # Shift past flag and value
      ;;
    -*)
      echo "## [ ! ] Error: Invalid option: $1" >&2
      echo "Usage: $0 [-i ignore_dir_name]... <directory_path>" >&2
      exit 1
      ;;
    *)
      if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="$1"
        shift 1
      else
        echo "## [ ! ] Error: Multiple directories provided or unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

# [P14] NZX Error Standard Check: Ensure an argument is passed
if [ -z "$TARGET_DIR" ]; then
    echo "## [ ! ] Error: Missing target directory."
    echo "Usage: $0 [-i ignore_dir_name]... <directory_path>"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "## [ ! ] Error: '$TARGET_DIR' not found or is not a directory."
    exit 1
fi

# Function to process files
process_files() {
    while IFS= read -r -d '' file; do
        echo "---- START OF FILE \"$file\" ----"
        cat "$file"
        echo -e "\n---- END OF FILE ----\n"
    done
}

# Construct the find command as an array to safely handle spaces and arguments
FIND_CMD=("find" "$TARGET_DIR")

if [ ${#IGNORE_DIRS[@]} -gt 0 ]; then
    # Start the prune group
    FIND_CMD+=("-type" "d" "(")
    
    # Iterate through ignore directories to build the OR logic: -name "dir1" -o -name "dir2"
    for i in "${!IGNORE_DIRS[@]}"; do
        FIND_CMD+=("-name" "${IGNORE_DIRS[$i]}")
        
        # Add -o (OR) if this is not the last element
        if [[ "$i" -lt $((${#IGNORE_DIRS[@]} - 1)) ]]; then
            FIND_CMD+=("-o")
        fi
    done
    
    # Close prune group and add the rest of the find logic
    FIND_CMD+=(")" "-prune" "-o" "-type" "f" "-print0")
else
    # Standard find if no ignores specified
    FIND_CMD+=("-type" "f" "-print0")
fi

# Execute the constructed command
"${FIND_CMD[@]}" | process_files