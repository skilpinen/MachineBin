#!/bin/bash

# Check usage
if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <file_list.csv> <source_directory> <destination_directory>"
  exit 1
fi

CSV="$1"
SOURCE_DIR="$2"
DEST_DIR="$3"

# Validate input file and directories
if [[ ! -f "$CSV" ]]; then
  echo "Error: File list '$CSV' does not exist."
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: Source directory '$SOURCE_DIR' does not exist."
  exit 1
fi

mkdir -p "$DEST_DIR"

# Read each line from the CSV and process
while IFS= read -r filename; do
  [[ -z "$filename" ]] && continue  # Skip empty lines
  filepath=$(find "$SOURCE_DIR" -type f -name "$filename" 2>/dev/null | head -n 1)
  if [[ -n "$filepath" ]]; then
    cp "$filepath" "$DEST_DIR/"
    echo "Copied: $filename"
  else
    echo "Not found: $filename"
  fi
done < "$CSV"
