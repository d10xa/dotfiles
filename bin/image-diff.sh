#!/bin/bash

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <file1> <file2>"
    exit 1
fi

FILE1="$1"
FILE2="$2"

# Check if files exist
if [ ! -f "$FILE1" ] || [ ! -f "$FILE2" ]; then
    echo "Error: File not found"
    exit 1
fi

# Create temporary files
TEMP1=$(mktemp)
TEMP2=$(mktemp)
JOINED=$(mktemp)

# Cleanup function
cleanup() {
    rm -f "$TEMP1" "$TEMP2" "$JOINED"
}
trap cleanup EXIT

# Process file: remove empty lines, comments, extract image:version
process_file() {
    grep -v '^[[:space:]]*$' "$1" | \
    grep -v '^[[:space:]]*#' | \
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
    grep ':' | \
    sed 's/\(.*\):\([^:]*\)$/\1|\2/' | \
    sort > "$2"
}

# Process both files
process_file "$FILE1" "$TEMP1"
process_file "$FILE2" "$TEMP2"

# Join files by image name
join -t'|' "$TEMP1" "$TEMP2" > "$JOINED"

# Output differences
while IFS='|' read -r image_name version1 version2; do
    if [[ "$version1" != "$version2" ]]; then
        echo "${image_name}:${version1}->${version2}"
    fi
done < "$JOINED"
