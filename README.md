# API Access and Automations

**Important**: Ensure all APIs listed in automations are protected with `10.0.0.0/8` access.

## Generating a New API Token (Admin Permissions Required)

1. Log in to **Unifi Access**.
2. Navigate to **General > API Token**.
3. Create a new token and select all permissions.

---
# User Automations

*Located in the `User Folder`. Ensure necessary permissions are set.*

### Add PIN and Group to Existing User
```bash
./Add_PIN_and_Group_To_User.sh <email> <PIN>
```

###  Create User (New User from scratch)
```bash 
     ./Create_User.sh <first_name> <last_name> <email> <new_pin>
```
### Create Multiple Users from CSV (Multiple User Creation)
##    File Format
##       CSV File (First Name, Last Name, Email, PIN)
 ```bash 
        ./Create_Users_From_CSV.sh <csv_file>
```



# Visitor Automations
*Located in the `Visitor Folder`. Ensure necessary permissions are set.*
*Still requires QR Code to be enabled and linked to existing user*

### Multiple Visitors - Guests and not residents
##    File Format
##        .TXT File (First Name Last Name Email address) Space or Tab Delemited
```bash
        ./24-7-Multiple_Visitor_BasedOff_NON_Resident.sh <visitors_file.txt>
```
### Multiple Visitors where it creates based off existing user 
##    File Format
##        .TXT File (email, one per line and must exist as a existing user) Space or Tab Delemited
```bash
        ./24-7-Multiple_VisitorBasedOff_Resident.sh <visitors_file.txt>
```
### Single User Based off non resident
```bash
    ./24-7-Single_VisitorBasedOff_NON_Resident.sh <First> <Last> <email>
```
### Single User Based off existing resident - Creates visitor as First Name: <First_Last> Last Name: <Visitor> 
```bash
   ./24-7-Single_VisitorBasedOff_Resident.sh <email>
```












# Helpful Commands

### List all Users
```bash
curl -s -k 'https://10.10.10.1:12445/api/v1/developer/users' -H 'Authorization: Bearer <token>' | \
jq '.data[]'
```

### List all Doors
```bash
curl -s -k 'https://10.10.10.1:12445/api/v1/developer/doors' -H 'Authorization: Bearer <token>' | \
jq '.data[]'
```

### List All Groups
```bash
curl -s -k 'https://10.10.10.1:12445/api/v1/developer/user_groups' -H 'Authorization: Bearer <token>' | \
jq '.data[]'
```

### List All Sites
```bash
curl -X GET 'https://api.ui.com/ea/hosts?pageSize=10' \
-H 'Accept: application/json' \
-H 'X-API-KEY: <token>' | jq '.data[]'
```

### List All Visitors
```bash
curl -s -k 'https://10.10.10.1:12445/api/v1/developer/visitors' -H 'Authorization: Bearer <token>' | \
jq '.data[]'
```
