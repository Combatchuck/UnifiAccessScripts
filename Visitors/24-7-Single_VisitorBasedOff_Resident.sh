#!/bin/bash
# API Endpoints
USER_API="https://10.10.10.1:12445/api/v1/developer/users"
VISITOR_API="https://10.10.10.1:12445/api/v1/developer/visitors"
TOPOLOGY_API="https://10.10.10.1:12445/api/v1/developer/door_groups/topology"
AUTH_HEADER="Authorization: Bearer <token>"

# Input: Email
EMAIL="$1"

if [[ -z "$EMAIL" ]]; then
  echo "Usage: $0 <email>"
  exit 1
fi

echo "Fetching user data for: $EMAIL"

# Fetch User Data
USER_RESPONSE=$(curl -s -k "$USER_API" -H "$AUTH_HEADER")
USER_DATA=$(echo "$USER_RESPONSE" | jq -r --arg email "$EMAIL" '.data[] | select(.email==$email or .user_email==$email)')

if [[ -z "$USER_DATA" || "$USER_DATA" == "null" ]]; then
  echo "❌ User with email '$EMAIL' not found."
  exit 1
fi

USER_ID=$(echo "$USER_DATA" | jq -r '.id // empty')
FIRST_NAME=$(echo "$USER_DATA" | jq -r '.first_name // empty')
LAST_NAME=$(echo "$USER_DATA" | jq -r '.last_name // empty')

# Update Name Format
VISITOR_FIRST_NAME="${FIRST_NAME}_${LAST_NAME}"
VISITOR_LAST_NAME="24-7_Guest"

# Assign Schedule & Holiday Group
SCHEDULE_ID="f7e55cdf-e83c-4384-9bfc-d83bca376892"
HOLIDAY_GROUP_ID="9f2bbfe8-5ec4-496f-9de5-2cf68ec6a173"

echo "User ID: $USER_ID"
echo "First Name: $VISITOR_FIRST_NAME"
echo "Last Name: $VISITOR_LAST_NAME"
echo "Schedule ID: $SCHEDULE_ID"

# Get All Locations (Doors & Door Groups)
echo "Fetching all locations..."
TOPOLOGY_RESPONSE=$(curl -s -k "$TOPOLOGY_API" -H "$AUTH_HEADER")

# Extract Valid Resources (doors + door_groups)
RESOURCES=$(echo "$TOPOLOGY_RESPONSE" | jq -c '[.data[] | {id: .id, type: "door_group"}] +
[.data[].resource_topologies[].resources[] | select(.id != null) | {id: .id, type: "door"}]')

echo "Resources to assign: $RESOURCES"

# Set Start Time (Now) and End Time (5 years later)
START_TIME=$(date +%s)
END_TIME=$((START_TIME + 157680000)) # 5 years

echo "Start Time: $START_TIME"
echo "End Time: $END_TIME"

# Construct Visitor Creation Payload (WITH RESOURCES INCLUDED)
VISITOR_PAYLOAD=$(jq -n \
  --arg first_name "$VISITOR_FIRST_NAME" \
  --arg last_name "$VISITOR_LAST_NAME" \
  --arg email "$EMAIL" \
  --argjson start_time "$START_TIME" \
  --argjson end_time "$END_TIME" \
  --arg schedule_id "$SCHEDULE_ID" \
  --argjson resources "$RESOURCES" \
  '{
    first_name: $first_name,
    last_name: $last_name,
    email: $email,
    start_time: $start_time,
    end_time: $end_time,
    visit_reason: "Business",
    schedule_id: $schedule_id,
    resources: $resources
  }')

echo "Visitor Payload: $VISITOR_PAYLOAD"

# Create Visitor
VISITOR_RESPONSE=$(curl -s -k -X POST "$VISITOR_API" \
  -H "$AUTH_HEADER" \
  -H "accept: application/json" \
  -H "content-type: application/json" \
  --data-raw "$VISITOR_PAYLOAD")

echo "Visitor creation response: $VISITOR_RESPONSE"

# Extract Visitor ID
VISITOR_ID=$(echo "$VISITOR_RESPONSE" | jq -r '.data.id // empty')

if [[ -z "$VISITOR_ID" || "$VISITOR_ID" == "null" ]]; then
  echo "❌ Error: Failed to retrieve Visitor ID. Check API response."
  exit 1
fi

echo "✅ Visitor ID Retrieved: $VISITOR_ID"

# Construct Update Payload (Assigning All Locations Again)
UPDATE_PAYLOAD=$(jq -n \
  --arg schedule_id "$SCHEDULE_ID" \
  --arg holiday_group_id "$HOLIDAY_GROUP_ID" \
  --argjson resources "$RESOURCES" \
  '{
    schedule_id: $schedule_id,
    holiday_group_id: $holiday_group_id,
    resources: $resources
  }')

echo "Update Payload Sent to API: $UPDATE_PAYLOAD"

# Send the PUT request with the properly formatted JSON payload
UPDATE_RESPONSE=$(curl -s -k -X PUT "$VISITOR_API/$VISITOR_ID" \
  -H "$AUTH_HEADER" \
  -H "accept: application/json" \
  -H "content-type: application/json" \
  --data-raw "$UPDATE_PAYLOAD")

echo "Visitor update response: $UPDATE_RESPONSE"

# Function to assign PIN with error handling
assign_pin() {
    local visitor_id="$1"
    local attempts=0
    local max_attempts=5

    while [[ $attempts -lt $max_attempts ]]; do
        PIN_CODE=$((10000000 + RANDOM % 90000000))
        echo "Generated PIN Code: $PIN_CODE"

        PIN_PAYLOAD=$(jq -n --arg pin_code "$PIN_CODE" '{ pin_code: $pin_code }')

        PIN_RESPONSE=$(curl -s -k -X PUT "$VISITOR_API/$visitor_id/pin_codes" \
            -H "$AUTH_HEADER" \
            -H "accept: application/json" \
            -H "content-type: application/json" \
            --data-raw "$PIN_PAYLOAD")

        echo "PIN Code update response: $PIN_RESPONSE"

        # Check if PIN assignment was successful
        ERROR_CODE=$(echo "$PIN_RESPONSE" | jq -r '.code // empty')

        if [[ "$ERROR_CODE" == "SUCCESS" ]]; then
            echo "✅ PIN Code '$PIN_CODE' assigned successfully."
            return 0
        elif [[ "$ERROR_CODE" == "CODE_CREDS_PIN_CODE_CREDS_ALREADY_EXIST" ]]; then
            echo "❌ PIN Code already exists. Retrying..."
        else
            echo "❌ Error assigning PIN: $ERROR_CODE"
            ((attempts++))
            echo "Retrying... ($attempts/$max_attempts)"
        fi
    done

    echo "❌ Failed to assign a unique PIN after $max_attempts attempts."
    exit 1
}

# Assign PIN Code with error handling
assign_pin "$VISITOR_ID"
