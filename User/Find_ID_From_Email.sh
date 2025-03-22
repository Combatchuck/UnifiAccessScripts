#!/bin/bash

# API variables
API_URL="https://10.10.10.1:12445/api/v1/developer/users"
AUTH_HEADER="Authorization: Bearer deN64WaTGT482FmJlb5PPQ"

# Input email
EMAIL="$1"

# Validate input
if [[ -z "$EMAIL" ]]; then
    echo "Usage: $0 <email>"
    exit 1
fi

# Fetch user ID based on email
USER_ID=$(curl -s -k "$API_URL" -H "$AUTH_HEADER" | jq -r --arg email "$EMAIL" '.data[] | select(.email==$email or .user_email==$email) | .id')

# Check if user was found
if [[ -z "$USER_ID" || "$USER_ID" == "null" ]]; then
    echo "User with email '$EMAIL' not found."
    exit 1
fi

# Print the user ID
echo "$USER_ID"