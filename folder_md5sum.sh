#!/bin/bash

# Check usage
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <folder_path>"
  exit 1
fi

FOLDER="$1"

# Validate folder
if [[ ! -d "$FOLDER" ]]; then
  echo "Error: '$FOLDER' is not a directory."
  exit 1
fi

OUT="md5sums.csv"
echo "filename,md5sum" > "$OUT"

# Compute MD5 for each file (excluding Apple metadata)
find "$FOLDER" -type f ! -name '._*' | while read -r file; do
  fname=$(basename "$file")
  md5=$(md5 -q "$file")
  echo "$fname,$md5" >> "$OUT"
done

echo "MD5 checksums written to $OUT"
