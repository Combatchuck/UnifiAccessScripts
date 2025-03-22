#!/bin/bash

# API variables
API_URL="https://10.10.10.1:12445/api/v1/developer/users"
GROUP_ID="4929bbb7-cf20-4ee7-98c6-3adf22901c52"
GROUP_URL="https://10.10.10.1:12445/api/v1/developer/user_groups/$GROUP_ID/users"
AUTH_HEADER="Authorization: Bearer deN64WaTGT482FmJlb5PPQ"

# Input variables
FIRST_NAME="$1"
LAST_NAME="$2"
EMAIL="$3"
NEW_PIN="$4"

# Validate input
if [[ -z "$FIRST_NAME" || -z "$LAST_NAME" || -z "$EMAIL" || -z "$NEW_PIN" ]]; then
    echo "Usage: $0 <first_name> <last_name> <email> <new_pin>"
    exit 1
fi

# Get current timestamp
ONBOARD_TIME=$(date +%s)

# Create user
USER_RESPONSE=$(curl -s -k -X POST "$API_URL" \
    -H "$AUTH_HEADER" \
    -H "accept: application/json" \
    -H "content-type: application/json" \
    --data-raw "{
        \"first_name\": \"$FIRST_NAME\",
        \"last_name\": \"$LAST_NAME\",
        \"onboard_time\": $ONBOARD_TIME,
        \"user_email\": \"$EMAIL\"
    }")

# Extract user ID correctly (nested under "data")
USER_ID=$(echo "$USER_RESPONSE" | jq -r '.data.id')

# Check if user was created successfully
if [[ -z "$USER_ID" || "$USER_ID" == "null" ]]; then
    echo "Failed to create user."
    echo "Response: $USER_RESPONSE"
    exit 1
fi

echo "User created successfully with ID: $USER_ID"

# Update user's PIN
UPDATE_PIN_RESPONSE=$(curl -s -k -X PATCH "$API_URL/$USER_ID" \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    --data-raw "{ \"pin_code\": \"$NEW_PIN\" }")

echo "PIN updated successfully for user $USER_ID."

# Add user to group
ADD_TO_GROUP_RESPONSE=$(curl -s -k -X PUT "$GROUP_URL" \
    -H "$AUTH_HEADER" \
    -H "accept: application/json" \
    -H "content-type: application/json" \
    --data-raw "[ \"$USER_ID\" ]")

if [[ -z "$ADD_TO_GROUP_RESPONSE" || "$ADD_TO_GROUP_RESPONSE" == "null" ]]; then
    echo "Failed to add user to group."
    exit 1
fi

echo "User $USER_ID added to group $GROUP_ID."