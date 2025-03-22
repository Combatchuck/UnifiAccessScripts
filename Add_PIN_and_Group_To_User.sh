#!/bin/bash

# API variables
API_URL="https://10.10.10.1:12445/api/v1/developer/users"
GROUP_ID="4929bbb7-cf20-4ee7-98c6-3adf22901c52"
GROUP_URL="https://10.10.10.1:12445/api/v1/developer/user_groups/$GROUP_ID/users"
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
if [[ -z "$USER_ID" || "$USER_ID" == "null" ]]; then
    echo "User with email '$EMAIL' not found."
    exit 1
fi

echo "Found User ID: $USER_ID"

# Update user's PIN
UPDATE_PIN_RESPONSE=$(curl -s -k -X PATCH "$API_URL/$USER_ID" -H "$AUTH_HEADER" -H "Content-Type: application/json" --data-raw "{ \"pin_code\": \"$NEW_PIN\" }")

echo "PIN updated successfully for user $USER_ID."

# Add user to group
ADD_TO_GROUP_RESPONSE=$(curl -s -k -X PUT "$GROUP_URL" -H "$AUTH_HEADER" -H "accept: application/json" -H "content-type: application/json" --data-raw "[ \"$USER_ID\" ]")

echo "User $USER_ID added to group $GROUP_ID."