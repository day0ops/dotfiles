#!/bin/bash

# Script to generate licenses using the genlicense tool
# This script can be run from anywhere and will reference the licensing project

# Determine project root using HOME directory
# You can override this by setting LICENSING_PROJECT_ROOT environment variable
if [ -n "$LICENSING_PROJECT_ROOT" ]; then
    PROJECT_ROOT="$LICENSING_PROJECT_ROOT"
else
    # Default: construct path from HOME
    # Adjust this path to match your project location relative to HOME
    PROJECT_ROOT="${HOME}/Projects/work/private/licensing"
fi

# Change to the project root directory
cd "$PROJECT_ROOT" || exit 1

# Run the genlicense tool and extract the encrypted license string
LICENSE_STRING=$(go run tools/cmd/genlicense/main.go "$@" 2>/dev/null | grep -A 1 "Encrypted license string:" | tail -1 | sed 's/^[[:space:]]*//')

# Check if license string was obtained
if [ -z "$LICENSE_STRING" ]; then
    echo "Error: Failed to generate license" >&2
    exit 1
fi

# Extract payload (first part before the dot)
JWT_PAYLOAD=$(echo "$LICENSE_STRING" | cut -d'.' -f1)

# Check if we have a valid format (should have 2 parts separated by one dot)
JWT_PARTS=$(echo "$LICENSE_STRING" | tr -cd '.' | wc -c)
if [ "$JWT_PARTS" -ne 1 ]; then
    echo "Error: Invalid license format (expected 2 parts separated by dot)" >&2
    exit 1
fi

# Decode base64url payload (add padding if needed and convert base64url to base64)
# Base64url uses - and _ instead of + and /, and omits padding
PADDED_PAYLOAD=$(echo "$JWT_PAYLOAD" | sed 's/-/+/g; s/_/\//g')
# Add padding
case $((${#PADDED_PAYLOAD} % 4)) in
    2) PADDED_PAYLOAD="${PADDED_PAYLOAD}==" ;;
    3) PADDED_PAYLOAD="${PADDED_PAYLOAD}=" ;;
esac

# Decode and parse JSON
DECODED_JSON=$(echo "$PADDED_PAYLOAD" | base64 -d 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$DECODED_JSON" ]; then
    echo "Error: Failed to decode JWT payload" >&2
    exit 1
fi

# Extract expiration timestamp (exp field)
EXP=$(echo "$DECODED_JSON" | grep -o '"exp":[0-9]*' | cut -d':' -f2)

if [ -z "$EXP" ]; then
    echo "Error: JWT payload missing expiration field" >&2
    exit 1
fi

# Get current timestamp
CURRENT_TIME=$(date +%s)

# Check if license is expired
if [ "$CURRENT_TIME" -ge "$EXP" ]; then
    echo "Error: License has expired (expires: $(date -r "$EXP" 2>/dev/null || echo "unknown"))" >&2
    exit 1
fi

# Check if license is valid (not before field, if present)
NBF=$(echo "$DECODED_JSON" | grep -o '"nbf":[0-9]*' | cut -d':' -f2)
if [ -n "$NBF" ] && [ "$CURRENT_TIME" -lt "$NBF" ]; then
    echo "Error: License is not yet valid (valid from: $(date -r "$NBF" 2>/dev/null || echo "unknown"))" >&2
    exit 1
fi

# License is valid, print it
echo "$LICENSE_STRING"