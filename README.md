API Listed in automations has the highest permissions and should be protected
Requires 10.0.0.0/8 access

## To Generate a new API Token (Requires Admin Permissions)
Log in to Unifi Access -> General -> API Token
Create a new token and pick all permissions


########################################

# User Automations (User Folder)
### Add PIN and Group to User (Adding to existing User)

        ./Add_PIN_and_Group_To_User.sh <email> <PIN>
### Add PIN to User (Adding to existing User)
    
        ./Add_Pin_To_User.sh <email> <PIN>
### Create User (New User from scratch)
   
     ./Create_User.sh <first_name> <last_name> <email> <new_pin>
### Create Multiple Users from CSV (Multiple User Creation)
##    File Format
##       CSV File (First Name, Last Name, Email, PIN)
   
        ./Create_Users_From_CSV.sh <csv_file>


########################################

# Visitor Automations (Visitor Folder) 
### Multiple Visitors - still requires QR Code to be enabled and linked to existing user
##    File Format
##        .TXT File (First Name Last Name Email address) Space or Tab Delemited

        ./24-7-Multiple_Visitor_BasedOff_NON_Resident.sh <visitors_file.txt>
### Multiple Visitors where it creates based off existing user - still requires QR Code to be enabled
##    File Format
##        .TXT File (email, one per line and must exist as a existing user) Space or Tab Delemited

        ./24-7-Multiple_VisitorBasedOff_Resident.sh <visitors_file.txt>
### Single User Based off non resident - still requires QR Code to be enabled and linked to existing user

    ./24-7-Single_VisitorBasedOff_NON_Resident.sh <First> <Last> <email>
### Single User Based off existing resident - Creates visitor as First Name: <First_Last> Last Name: <Visitor> 

    ./24-7-Single_VisitorBasedOff_Resident.sh <email>






