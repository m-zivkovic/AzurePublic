# Import the GraphAPI module
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.SignIns

# Replace tenant ID
Connect-MgGraph -TenantId "ADD TENANT ID HERE" -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All","UserAuthenticationMethod.ReadWrite.All"


# Load users from CSV file
$users = Import-Csv -Path "users.csv"

# Initialize arrays to store users' information
$registeredSMSUsers = @()
$failedregisteredSMSUsers = @()
$noPhoneUsers = @()
$noUsersFound = @()


# Loop through each user
foreach ($user in $users) {
    
    # Get the user by UPN
    $graphUser = Get-MgUser -Filter "userPrincipalName eq '$($user.UPN)'"
    
    # Check if the user exists in Azure AD
    if ($graphUser) {
    
        # Check if the user has a work phone number
        if ($graphUser.mobilePhone) {

                   
            # Check if the user has already registered MFA SMS
            if (!(get-MgUserAuthenticationPhoneMethod -UserId $user.UPN).phonenumber) {

                
                # Try to set MFA SMS phone number to the user
                try
                {
                    New-MgUserAuthenticationPhoneMethod -UserId $user.UPN -phoneType "mobile" -phoneNumber $graphUser.mobilePhone

                    Write-Host "User $($user.UPN) phone number set to $($graphUser.mobilePhone)"
                }
                catch
                {
                    Write-Host "Failed to set $($user.UPN) Phone number to $($graphUser.mobilePhone)"
                    $failedregisteredSMSUsers += $graphUser
                }

            }
            else {
                $registeredSMSUsers += $graphUser
            }
        } 
        else {
            $noPhoneUsers += $graphUser
        }
    }
    else {
        $noUsersFound += $user.UPN
    }
    
}

Write-Host

if ($noUsersFound){
    # Print the users who can not be found in AAD
    Write-Host "Users not found in AAD:"
    $noUsersFound | ForEach-Object {
        Write-Host "User: $($_.UPN)"
    }
    Write-Host
}


if ($noPhoneUsers){
    # Print the users who do not have a phone set in AAD
    Write-Host "Users who do not have a phone set in AAD:"
    $noPhoneUsers | ForEach-Object {
        Write-Host "User: $($_.DisplayName), Object ID: $($_.Id)"        
    }
    Write-Host
}


if ($registeredSMSUsers){
    # Print the users who have already registered SMS on MFA
    Write-Host "Users who have already registered SMS on MFA:"
    $registeredSMSUsers | ForEach-Object {
        Write-Host "User: $($_.DisplayName), Object ID: $($_.Id)"        
    }
    Write-Host
}


if ($failedregisteredSMSUsers){
    # Print the users who failed to registere SMS on MFA
        Write-Host "Failed to registere SMS on MFA Users:"
        $failedregisteredSMSUsers | ForEach-Object {
            Write-Host "User: $($_.DisplayName), Object ID: $($_.Id)"            
    }
}

# Disconnect from Azure AD
Disconnect-MgGraph
