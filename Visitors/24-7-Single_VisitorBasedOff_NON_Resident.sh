#!/bin/bash
# API Endpoints
VISITOR_API="https://10.10.10.1:12445/api/v1/developer/visitors"
TOPOLOGY_API="https://10.10.10.1:12445/api/v1/developer/door_groups/topology"
AUTH_HEADER="Authorization: Bearer deN64WaTGT482FmJlb5PPQ"

# Input: First Name, Last Name, Email
FIRST_NAME="$1"
LAST_NAME="$2"
EMAIL="$3"

if [[ -z "$FIRST_NAME" || -z "$LAST_NAME" || -z "$EMAIL" ]]; then
  echo "Usage: $0 <First Name> <Last Name> <Email>"
  exit 1
fi

VISITOR_FIRST_NAME="${FIRST_NAME}"
VISITOR_LAST_NAME="${LAST_NAME}"

SCHEDULE_ID="f7e55cdf-e83c-4384-9bfc-d83bca376892"
HOLIDAY_GROUP_ID="9f2bbfe8-5ec4-496f-9de5-2cf68ec6a173"

echo "First Name: $VISITOR_FIRST_NAME"
echo "Last Name: $VISITOR_LAST_NAME"
echo "Email: $EMAIL"
echo "Schedule ID: $SCHEDULE_ID"

# Get All Locations (Doors & Door Groups)
echo "Fetching all locations..."
TOPOLOGY_RESPONSE=$(curl -s -k "$TOPOLOGY_API" -H "$AUTH_HEADER")

RESOURCES=$(echo "$TOPOLOGY_RESPONSE" | jq -c '[.data[] | {id: .id, type: "door_group"}] +
[.data[].resource_topologies[].resources[] | select(.id != null) | {id: .id, type: "door"}]')

echo "Resources to assign: $RESOURCES"

START_TIME=$(date +%s)
END_TIME=$((START_TIME + 157680000)) # 5 years

echo "Start Time: $START_TIME"
echo "End Time: $END_TIME"

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

VISITOR_RESPONSE=$(curl -s -k -X POST "$VISITOR_API" \
  -H "$AUTH_HEADER" \
  -H "accept: application/json" \
  -H "content-type: application/json" \
  --data-raw "$VISITOR_PAYLOAD")

echo "Visitor creation response: $VISITOR_RESPONSE"

VISITOR_ID=$(echo "$VISITOR_RESPONSE" | jq -r '.data.id // empty')

if [[ -z "$VISITOR_ID" || "$VISITOR_ID" == "null" ]]; then
  echo "❌ Error: Failed to retrieve Visitor ID. Check API response."
  exit 1
fi

echo "✅ Visitor ID Retrieved: $VISITOR_ID"

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

UPDATE_RESPONSE=$(curl -s -k -X PUT "$VISITOR_API/$VISITOR_ID" \
  -H "$AUTH_HEADER" \
  -H "accept: application/json" \
  -H "content-type: application/json" \
  --data-raw "$UPDATE_PAYLOAD")

echo "Visitor update response: $UPDATE_RESPONSE"

# Generate PIN Code (Random 8-Digit)
PIN_CODE=$(printf "%08d" $(( RANDOM % 100000000 )))
echo "Generated PIN Code: $PIN_CODE"

# Construct PIN Code Payload
PIN_PAYLOAD=$(jq -n --arg pin_code "$PIN_CODE" '{ pin_code: $pin_code }')

# Assign PIN Code to Visitor
PIN_RESPONSE=$(curl -s -k -X PUT "$VISITOR_API/$VISITOR_ID/pin_codes" \
  -H "$AUTH_HEADER" \
  -H "accept: application/json" \
  -H "content-type: application/json" \
  --data-raw "$PIN_PAYLOAD")

echo "PIN Code update response: $PIN_RESPONSE"