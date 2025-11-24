#!/bin/bash
# Script to consolidate requirements.txt files by recursively following -r directives
# Creates a single requirements file with all dependencies

set -e

# Default values
INPUT_FILE="${1:-src/pybind/mgr/requirements.txt}"
OUTPUT_FILE="${2:-consolidated_requirements.txt}"

# Temporary file to track processed files (avoid circular references)
PROCESSED_FILES=$(mktemp)
trap "rm -f $PROCESSED_FILES" EXIT

# Function to resolve relative path from a base file
resolve_path() {
    local base_file="$1"
    local relative_path="$2"
    local base_dir=$(dirname "$base_file")

    # Use realpath if available, otherwise use readlink -f
    if command -v realpath &> /dev/null; then
        realpath -m "$base_dir/$relative_path" 2>/dev/null || echo "$base_dir/$relative_path"
    else
        readlink -f "$base_dir/$relative_path" 2>/dev/null || echo "$base_dir/$relative_path"
    fi
}

# Function to process a requirements file recursively
process_requirements_file() {
    local req_file="$1"
    local resolved_file

    # Resolve to absolute path
    if command -v realpath &> /dev/null; then
        resolved_file=$(realpath "$req_file" 2>/dev/null || echo "$req_file")
    else
        resolved_file=$(readlink -f "$req_file" 2>/dev/null || echo "$req_file")
    fi

    # Check if already processed
    if grep -qxF "$resolved_file" "$PROCESSED_FILES" 2>/dev/null; then
        return
    fi

    # Check if file exists
    if [ ! -f "$resolved_file" ]; then
        echo "Warning: File not found: $resolved_file" >&2
        return
    fi

    # Mark as processed
    echo "$resolved_file" >> "$PROCESSED_FILES"
    echo "Processing: $resolved_file" >&2

    # Read file line by line
    while IFS= read -r line || [ -n "$line" ]; do
        # Remove leading/trailing whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Skip empty lines and comments
        if [ -z "$line" ] || [[ "$line" =~ ^# ]]; then
            continue
        fi

        # Handle -r directive (include another requirements file)
        if [[ "$line" =~ ^-r[[:space:]]* ]]; then
            ref_file=$(echo "$line" | sed 's/^-r[[:space:]]*//')
            ref_path=$(resolve_path "$resolved_file" "$ref_file")
            process_requirements_file "$ref_path"

        # Handle -e directive (editable install)
        elif [[ "$line" =~ ^-e[[:space:]]* ]]; then
            # Resolve editable path to absolute path
            editable_path=$(echo "$line" | sed 's/^-e[[:space:]]*//')
            resolved_editable=$(resolve_path "$resolved_file" "$editable_path")

            # Don't output the -e line itself, just process its requirements
            # Check if the editable package has its own requirements.txt
            if [ -d "$resolved_editable" ]; then
                editable_req_file="$resolved_editable/requirements.txt"
                if [ -f "$editable_req_file" ]; then
                    process_requirements_file "$editable_req_file"
                fi
            fi

        # Regular package specification
        else
            echo "$line"
        fi
    done < "$resolved_file"
}

# Main execution
echo "Consolidating requirements from: $INPUT_FILE" >&2
echo "Output file: $OUTPUT_FILE" >&2
echo "------------------------------------------------------------" >&2

# Create temporary file for all packages
ALL_PACKAGES=$(mktemp)
trap "rm -f $PROCESSED_FILES $ALL_PACKAGES" EXIT

# Process the input file and collect all packages
process_requirements_file "$INPUT_FILE" > "$ALL_PACKAGES"

# Remove duplicates while preserving order
awk '!seen[$0]++' "$ALL_PACKAGES" > "$OUTPUT_FILE.tmp"

# Write final output with header
{
    echo "# Consolidated requirements file"
    echo "# Generated from: $INPUT_FILE"
    echo "# This file includes all dependencies from referenced requirements files"
    echo ""
    cat "$OUTPUT_FILE.tmp"
} > "$OUTPUT_FILE"

rm -f "$OUTPUT_FILE.tmp"

# Count packages (excluding comments and empty lines)
PACKAGE_COUNT=$(grep -v '^#' "$OUTPUT_FILE" | grep -v '^$' | wc -l)

echo "------------------------------------------------------------" >&2
echo "✓ Consolidated $PACKAGE_COUNT packages" >&2
echo "✓ Output written to: $OUTPUT_FILE" >&2
