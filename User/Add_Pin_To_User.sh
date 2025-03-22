#!/bin/bash

# API variables
API_URL="https://10.10.10.1:12445/api/v1/developer/users"
AUTH_HEADER="Authorization: Bearer deN64WaTGT482FmJlb5PPQ"

# Input variables
EMAIL="$1"
NEW_PIN="$2"

# Validate input
if [[ -z "$EMAIL" || -z "$NEW_PIN" ]]; then
    echo "Usage: $0 <email> <new_pin>"
    exit 1
fi

# Fetch user ID based on email
USER_ID=$(curl -s -k "$API_URL" -H "$AUTH_HEADER" | jq -r --arg email "$EMAIL" '.data[] | select(.email==$email or .user_email==$email) | .id')

# Check if user was found
if [[ -z "$USER_ID" ]]; then
    echo "User with email '$EMAIL' not found."
    exit 1
fi

echo "Found User ID: $USER_ID"

# Update user's PIN
UPDATE_RESPONSE=$(curl -k -XPUT PATCH "$API_URL/$USER_ID" -H "$AUTH_HEADER" -H "Content-Type: application/json" --data-raw "{ \"pin_code\": \"$NEW_PIN\" }")

# Print response
echo "$UPDATE_RESPONSE"