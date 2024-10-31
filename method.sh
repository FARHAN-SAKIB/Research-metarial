#!/bin/bash

# Check if file path is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <path/to/PartitioningTest.java>"
    exit 1
fi

# Full path to the Java file
FILE_PATH="$1"

# Fixed output directory
OUTPUT_DIR="C:/Users/Farhan Sakib/Desktop/Research/Project/apex-core/method name"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Get the base name of the file without the extension
OUTPUT_FILE="${OUTPUT_DIR}/$(basename "${FILE_PATH%.java}.txt")"  # Use .txt extension for clarity

# Clear previous output file if it exists
> "$OUTPUT_FILE"

# Check if the file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "File not found: $FILE_PATH"
    exit 1
fi

# Find and extract methods containing @Test annotation from the specified file
echo "Extracting @Test methods from file '$FILE_PATH'..."
grep -A 5 "@Test" "$FILE_PATH" | \
sed -n 's/.*\(\s\+\(public\|protected\|private\)\s\+\w\+\s\+\w\+\s*(.*\)$/\1/p' >> "$OUTPUT_FILE"

# Check if any methods were found
if [ -s "$OUTPUT_FILE" ]; then
    echo "Methods extracted to '$OUTPUT_FILE':"
    cat "$OUTPUT_FILE"
else
    echo "No @Test methods found in '$FILE_PATH'."
    # Optionally, remove the empty output file
    rm -f "$OUTPUT_FILE"
fi

# Check if the output file was created successfully
if [ -f "$OUTPUT_FILE" ]; then
    echo "Output file created successfully: $OUTPUT_FILE"
else
    echo "Failed to create output file: $OUTPUT_FILE"
fi
