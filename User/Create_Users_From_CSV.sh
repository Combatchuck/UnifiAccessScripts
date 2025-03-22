#!/bin/bash

# API variables
API_URL="https://10.10.10.1:12445/api/v1/developer/users"
GROUP_API="https://10.10.10.1:12445/api/v1/developer/user_groups"
AUTH_HEADER="Authorization: Bearer <token>"
GROUP_ID="4929bbb7-cf20-4ee7-98c6-3adf22901c52"

# CSV File (First Name, Last Name, Email, PIN)
CSV_FILE="$1"

# Validate input
if [[ -z "$CSV_FILE" ]]; then
    echo "Usage: $0 <csv_file>"
    exit 1
fi

# Check if file exists
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: File '$CSV_FILE' not found."
    exit 1
fi

# Read CSV line by line (skip first line if it contains headers)
while IFS=',' read -r FIRST_NAME LAST_NAME EMAIL NEW_PIN; do
    # Trim spaces
    FIRST_NAME=$(echo "$FIRST_NAME" | xargs)
    LAST_NAME=$(echo "$LAST_NAME" | xargs)
    EMAIL=$(echo "$EMAIL" | xargs)
    NEW_PIN=$(echo "$NEW_PIN" | xargs)

    # Check if user exists
    USER_ID=$(curl -s -k "$API_URL" -H "$AUTH_HEADER" | jq -r --arg email "$EMAIL" '.data[] | select(.user_email==$email) | .id')

    if [[ -n "$USER_ID" && "$USER_ID" != "null" ]]; then
        echo "User '$EMAIL' already exists with ID: $USER_ID. Skipping..."
        continue
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

    # Extract new user ID
    USER_ID=$(echo "$USER_RESPONSE" | jq -r '.data.id')

    # If user creation failed
    if [[ -z "$USER_ID" || "$USER_ID" == "null" ]]; then
        echo "Failed to create user '$EMAIL'. Response: $USER_RESPONSE"
        continue
    fi

    echo "User created successfully with ID: $USER_ID"

    # Set user's PIN
    UPDATE_PIN_RESPONSE=$(curl -s -k -X PUT "$API_URL/$USER_ID" \
        -H "$AUTH_HEADER" \
        -H "Content-Type: application/json" \
        --data-raw "{ \"pin_code\": \"$NEW_PIN\" }")

    echo "PIN Update Response: $UPDATE_PIN_RESPONSE"

    # Add user to group
    ADD_TO_GROUP_RESPONSE=$(curl -s -k -X POST "$GROUP_API/$GROUP_ID/users" \
        -H "$AUTH_HEADER" \
        -H "accept: application/json" \
        -H "content-type: application/json" \
        --data-raw "[ \"$USER_ID\" ]")

    echo "Add to Group Response: $ADD_TO_GROUP_RESPONSE"

done < "$CSV_FILE"
