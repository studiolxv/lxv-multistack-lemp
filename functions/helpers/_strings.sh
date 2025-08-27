#!/bin/sh
sanitize_string() {
    # Converts all special characters to the specified replacement
    local REPLACEMENT="${2:-}"
    echo "$1" | sed "s/[^a-zA-Z0-9]/$REPLACEMENT/g"
}

# Convert a string to uppercase
uc_word() {
    input="$1"
    printf '%s' "$input" | tr '[:lower:]' '[:upper:]'
}

search_file_replace() {
    local FILE="$1"
    local SEARCH="$2"
    local REPLACE="$3"

    # Ensure the file exists
    if [ ! -f "$FILE" ]; then
        echo "❌ Error: File not found: $FILE" >&2
        return 1
    fi

    # Perform search and replace
    sed "s|$SEARCH|$REPLACE|g" "$FILE" > "$FILE.tmp"

    # Check if sed operation was successful
    if [ $? -eq 0 ]; then
        mv "$FILE.tmp" "$FILE"
    else
        echo "❌ Error: Failed to update $FILE" >&2
        rm -f "$FILE.tmp"  # Cleanup on failure
        return 1
    fi
}

