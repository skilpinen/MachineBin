#!/bin/bash

# Usage check
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <samplesheet.csv> <search_directory> [--flat]"
  exit 1
fi

CSV="$1"
SEARCH_DIR="$2"
FLAT="$3"

if [[ ! -f "$CSV" ]]; then
  echo "Error: CSV file '$CSV' does not exist."
  exit 1
fi

if [[ ! -d "$SEARCH_DIR" ]]; then
  echo "Error: Search directory '$SEARCH_DIR' does not exist."
  exit 1
fi

# Output file
if [[ "$FLAT" == "--flat" ]]; then
  OUT="${CSV%.csv}_flat_md5.csv"
  echo "filename,md5sum" > "$OUT"
else
  OUT="${CSV%.csv}_with_md5.csv"
  head -n 1 "$CSV" | awk -F, '{print $0",md5_fastq_1,md5_fastq_2"}' > "$OUT"
fi

# Process rows
tail -n +2 "$CSV" | while IFS=',' read -r id group replicate control single_end fastq1 fastq2 is_control; do
    for fq in "$fastq1" "$fastq2"; do
        fname=$(basename "$fq")
        [[ -z "$fname" || "$fname" == "NA" ]] && continue
        path=$(find "$SEARCH_DIR" -type f -name "$fname" 2>/dev/null | head -n 1)
        md5=""
        [[ -f "$path" ]] && md5=$(md5 -q "$path")

        if [[ "$FLAT" == "--flat" ]]; then
            echo "$fname,$md5" >> "$OUT"
        fi
    done

    if [[ "$FLAT" != "--flat" ]]; then
        fname1=$(basename "$fastq1")
        fname2=$(basename "$fastq2")
        path1=$(find "$SEARCH_DIR" -type f -name "$fname1" 2>/dev/null | head -n 1)
        path2=$(find "$SEARCH_DIR" -type f -name "$fname2" 2>/dev/null | head -n 1)
        md5_1=""
        md5_2=""
        [[ -f "$path1" ]] && md5_1=$(md5 -q "$path1")
        [[ -f "$path2" ]] && md5_2=$(md5 -q "$path2")
        echo "$id,$group,$replicate,$control,$single_end,$fastq1,$fastq2,$is_control,$md5_1,$md5_2" >> "$OUT"
    fi
done
