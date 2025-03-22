#!/bin/bash
# API Endpoints
VISITOR_API="https://10.10.10.1:12445/api/v1/developer/visitors"
TOPOLOGY_API="https://10.10.10.1:12445/api/v1/developer/door_groups/topology"
AUTH_HEADER="Authorization: Bearer deN64WaTGT482FmJlb5PPQ"

# Schedule and Holiday Group IDs
SCHEDULE_ID="f7e55cdf-e83c-4384-9bfc-d83bca376892"
HOLIDAY_GROUP_ID="9f2bbfe8-5ec4-496f-9de5-2cf68ec6a173"

# Input: Visitors file
VISITORS_FILE="$1"

if [[ -z "$VISITORS_FILE" ]]; then
  echo "Usage: $0 <visitors_file.txt>"
  exit 1
fi

if [[ ! -f "$VISITORS_FILE" ]]; then
  echo "❌ File '$VISITORS_FILE' not found."
  exit 1
fi

echo "Processing visitors from file: $VISITORS_FILE"

# Fetch All Locations (Doors & Door Groups)
echo "Fetching all locations..."
TOPOLOGY_RESPONSE=$(curl -s -k "$TOPOLOGY_API" -H "$AUTH_HEADER")

# Extract Valid Resources (doors + door_groups)
RESOURCES=$(echo "$TOPOLOGY_RESPONSE" | jq -c '[.data[] | {id: .id, type: "door_group"}] +
    [.data[].resource_topologies[].resources[] | select(.id != null) | {id: .id, type: "door"}]')

echo "Resources to assign: $RESOURCES"

# Function to create a visitor
create_visitor() {
  local FIRST_NAME="$1"
  local LAST_NAME="$2"
  local EMAIL="$3"

  echo "Creating visitor: $FIRST_NAME $LAST_NAME ($EMAIL)"

  VISITOR_PAYLOAD=$(jq -n \
    --arg first_name "$FIRST_NAME" \
    --arg last_name "$LAST_NAME" \
    --arg email "$EMAIL" \
    --argjson start_time "$(date +%s)" \
    --argjson end_time "$(( $(date +%s) + 157680000 ))" \
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
    echo "❌ Error: Failed to retrieve Visitor ID for $EMAIL. Skipping."
    echo "----------------------------------------"
    return
  fi

  echo "✅ Visitor ID Retrieved: $VISITOR_ID"

  # Update Visitor
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

  # Assign PIN Code to Visitor
  PIN_PAYLOAD=$(jq -n --arg pin_code "$PIN_CODE" '{ pin_code: $pin_code }')

  PIN_RESPONSE=$(curl -s -k -X PUT "$VISITOR_API/$VISITOR_ID/pin_codes" \
    -H "$AUTH_HEADER" \
    -H "accept: application/json" \
    -H "content-type: application/json" \
    --data-raw "$PIN_PAYLOAD")

  echo "PIN Code update response: $PIN_RESPONSE"
  echo "----------------------------------------"
}

# Read the visitors file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip empty lines and lines starting with #
  [[ -z "$line" || "$line" =~ ^# ]] && continue

  # Read First Name, Last Name, Email using read with multiple IFS delimiters
  IFS=$' \t' read -r FIRST_NAME LAST_NAME EMAIL <<< "$line"

  # Validate fields
  if [[ -z "$FIRST_NAME" || -z "$LAST_NAME" || -z "$EMAIL" ]]; then
    echo "❌ Invalid line: '$line'. Skipping."
    echo "----------------------------------------"
    continue
  fi

  create_visitor "$FIRST_NAME" "$LAST_NAME" "$EMAIL"
done < "$VISITORS_FILE"

echo "All visitors processed."