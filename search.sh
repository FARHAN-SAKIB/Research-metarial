#!/bin/bash

# Define the input and output files
input_file="apex-core.log"
output_file="changed_files.log"

# Clear the output file if it exists
> "$output_file"

# Read each line from the input file
while IFS= read -r line
do
    # Extract the commit ID (assuming it's the first part of the line before the space)
    commit_id=$(echo "$line" | awk '{print $1}')
    
    # Check if the commit ID is not empty
    if [[ -n "$commit_id" ]]; then
        echo "Processing commit: $commit_id" >> "$output_file"
        
        # Fetch the changed files for this commit
        changed_files=$(git diff-tree --no-commit-id --name-only -r "$commit_id")
        
        if [[ -n "$changed_files" ]]; then
            echo "$changed_files" >> "$output_file"
        else
            echo "No files changed or invalid commit ID: $commit_id" >> "$output_file"
        fi
        
        # Add a separator for readability
        echo "----------------------------------------" >> "$output_file"
    else
        echo "Empty line or invalid format: $line" >> "$output_file"
    fi
done < "$input_file"

echo "Processing complete. Results saved in $output_file"
