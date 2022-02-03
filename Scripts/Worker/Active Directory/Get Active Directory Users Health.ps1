# **********************************************************************************
# Script to find all users in Active Directory with potential security issues.
#
# If you need to troubleshoot the script, you can enable the Debug option in
# the parameter. This will generate display information on the screen.
#
# This script use Active Directory module
#
# ==================================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2022-02-01  Benoit Blais        Original version
# **********************************************************************************

Param(
    [Switch]$Debug = $False
)

#Default action when an error occured
$ErrorActionPreference = "Stop"

# **********************************************************************************

#Log function will allow to display colored information in the PowerShell window
#if debug mode is $TRUE.
#Parameters:
#$Text : Text added to the text file.
#$Error and $Warning: These switch need to be use to specify something else then an information.
Function Log {
    Param (
        [Parameter(Mandatory=$true)][String]$Text,
        [Switch]$Error,
        [Switch]$Warning
    )
    If ($Debug) {
        $Output = "$(Get-Date) |"
        If($Error) {
            $Output += " ERROR   | $Text"
            Write-Host $Output -ForegroundColor Red
        }
        ElseIf($Warning) {
            $Output += " WARNING | $Text"
            Write-Host $Output -ForegroundColor Yellow
        }
        Else {
            $Output += " INFO    | $Text"
            Write-Host $Output -ForegroundColor Green
        }
    }
}

# **********************************************************************************

#Maximum last logon date for an account
$LastLoggedOnDate = $(Get-Date).AddDays(-180)

#List of properties for Active Directory Users
$ADLimitedProperties = @("Name","Enabled","SAMAccountname","DisplayName","Enabled","LastLogonDate","PasswordLastSet","PasswordNeverExpires","PasswordNotRequired","PasswordExpired","SmartcardLogonRequired","AccountExpirationDate","AdminCount","Created","Modified","LastBadPasswordAttempt","badpwdcount","mail","CanonicalName","DistinguishedName","ServicePrincipalName","SIDHistory","PrimaryGroupID","UserAccountControl")

# **********************************************************************************

Log -Text "Script Begin"

#Validate if Active Directory module is currently loaded in Powershell session.
Log -Text "Validating if Active Directory module is loaded in the currect Powershell session"
If (!(Get-Module | Where-Object {$_.Name -eq "ActiveDirectory"})){

    #Active Directory is not currently loaded in Powershell session.
    Log -Text "Active Directory is not currently loaded in Powershell session" -Warning
    If (Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"}) { 
        
        #Active Directory module installed on that computer.
        Log -Text "Active Directory module installed on that computer"
        #Trying to import Active Directory module.
        Log -Text "Trying to import Active Directory module"
        Try {
            Import-Module ActiveDirectory 
        }
        Catch {
            #Unable to import Active Directory module.
            Log -Text "Unable to import Active Directory module" -Error
            #Because this script can't be run without this module, the script execution is stop.
            Break
        }
    
    }
    Else {
        
        #Active Directory module is not installed on the current computer.
        Log -Text "ctive Directory module is not installed on the current computer" -Error
        #Because this script can't be run without this module, the script execution is stop.
        Break
    }
}
Else {

    #Active Directory module is loaded in the current Powershell session.
    Log -Text "Active Directory module is loaded in the current Powershell session"

}

# **********************************************************************************

#Get all Active Directory users
Log -Text "Getting all Active Directory users"
Try {
    Log -Text "Getting all Active Directory users"
    [array]$DomainUsers = Get-ADUser -Filter * -Property $ADLimitedProperties 
} 
Catch {
    Log -Text "An error occured during getting Active Directory users"
}

#Find all enabled user.
[array]$DomainEnabledUsers = $DomainUsers | Where {$_.Enabled -eq $True }

#Find all disabled users.
[array]$DomainDisabledUsers = $DomainUsers | Where {$_.Enabled -eq $false }
Write-Host "Disabled Users ($($DomainDisabledUsers.Count))" -ForegroundColor Cyan
ForEach ($DomainDisabledUser in $DomainDisabledUsers) {
    Write-Host " - $($DomainDisabledUser.Name)" 
}

#Find all inactive users. For that, we use the value configure above with the maximum last logon date.
#When an inactive account is not disabled or remains outside password expiration limits, perpetrators 
#who try to hack into an organization can use these accounts because their activities will go unnoticed. 
#In addition, employees who leave the organization can misuse their login credentials to access network 
#resources.
[array]$DomainEnabledInactiveUsers = $DomainEnabledUsers | Where { $_.LastLogonDate -le $LastLoggedOnDate }
Write-Host "Inactive Users Users ($($DomainEnabledInactiveUsers.Count))" -ForegroundColor Cyan
ForEach ($DomainEnabledInactiveUser in $DomainEnabledInactiveUsers) {
    Write-Host " - $($DomainEnabledInactiveUser.Name)" 
}

#Find all users with Reversible Encryption. 
#The option to store passwords using reversible encryption provides support for applications that require 
#the user's password for authentication. Anyone who knows the account password can misuse the account. 
#Microsoft recommends disabling this setting through Group Policy using the 
#Computer Configuration\Windows Settings\Security Settings\Account Policies\Password Policy\ policy if 
#the option is no longer in use.
[array]$DomainUsersWithReversibleEncryptionPasswordArray = $DomainUsers | Where { $_.UserAccountControl -band 0x0080 } 
Write-Host "Users with Reversible Encryption Password ($($DomainUsersWithReversibleEncryptionPasswordArray.Count))" -ForegroundColor Cyan
ForEach ($DomainUsersWithReversibleEncryptionPassword in $DomainUsersWithReversibleEncryptionPasswordArray) {
    Write-Host " - $($DomainUsersWithReversibleEncryptionPassword.Name)" 
}

#Find all users with Kerberos DES.
#Accounts that can use DES to authenticate to services are at significantly greater risk of having that 
#account's logon sequence decrypted and the account compromised, since DES is considered weaker cryptography. 
#The command below helps identify the accounts that support Kerberos DES encryption in the domain.
[array]$DomainKerberosDESUsersArray = $DomainUsers | Where { $_.UserAccountControl -band 0x200000 }
Write-Host "Kerberos DES User ($($DomainKerberosDESUsersArray.Count))" -ForegroundColor Cyan
ForEach ($DomainKerberosDESUsers in $DomainKerberosDESUsersArray) {
    Write-Host " - $($DomainKerberosDESUsers.Name)" 
}

#Find all users with Password Not Required property.
[array]$DomainUserPasswordNotRequiredArray = $DomainUsers | Where {$_.PasswordNotRequired -eq $True}
Write-Host "Users with Password Not Required ($($DomainUserPasswordNotRequiredArray.Count))" -ForegroundColor Cyan
ForEach ($DomainUserPasswordNotRequired in $DomainUserPasswordNotRequiredArray) {
    Write-Host " - $($DomainUserPasswordNotRequired.Name)" 
}

#Find all users who do not require pre authentication.
#In earlier versions, Kerberos allowed authentication without a password. Now, in Kerberos 5, a password 
#is required, which is called "pre-authentication." An attack that focuses on accounts with the pre-authentication 
#option disabled is called an AS-REP roasting attack.
[array]$DomainUserDoesNotRequirePreAuthArray = $DomainUsers | Where {$_.DoesNotRequirePreAuth -eq $True}
Write-Host "User Does Not Require Pre Authentication ($($DomainUserDoesNotRequirePreAuthArray.Count))" -ForegroundColor Cyan
ForEach ($DomainUserDoesNotRequirePreAuth in $DomainUserDoesNotRequirePreAuthArray) {
    Write-Host " - $($DomainUserDoesNotRequirePreAuth.Name)" 
}

#Find all users with SID history.
#SID History enables access for another account to effectively be cloned to another. This is extremely useful to ensure 
#users retain access when moved (migrated) from one domain to another. Since the user’s SID changes when the new account 
#is created, the old SID needs to map to the new one. When a user in Domain A is migrated to Domain B, a new user account 
#is created in DomainB and DomainA user’s SID is added to DomainB’s user account’s SID History attribute. This ensures 
#that DomainB user can still access resources in DomainA.
#The interesting part of this is that SID History works for SIDs in the same domain as it does across domains in the same 
#forest, which means that a regular user account in DomainA can contain DomainA SIDs and if the DomainA SIDs are for 
#privileged accounts or groups, a regular user account can be granted Domain Admin rights without being a member of 
#Domain Admins.
[array]$DomainUsersWithSIDHistoryArray = $DomainUsers | Where {$_.SIDHistory -like "*"}
Write-Host "Users with multiples SID ($($DomainUsersWithSIDHistoryArray.Count))" -ForegroundColor Cyan
ForEach ($DomainUsersWithSIDHistory in $DomainUsersWithSIDHistoryArray) {
    Write-Host " - $($DomainUsersWithSIDHistory.Name)" 
}

#Find all user with Password Never Expire property. This account have a manual task to reset password.
#If the password isn't change with a scheduled, this is a security risk.
[array]$DomainUserPasswordNeverExpiresArray = $DomainUsers | Where {$_.PasswordNeverExpires -eq $True}
Write-Host "Users with Password Never Expires ($($DomainUserPasswordNeverExpiresArray.Count))" -ForegroundColor Cyan
ForEach ($DomainUserPasswordNeverExpires in $DomainUserPasswordNeverExpiresArray) {
    Write-Host " - $($DomainUserPasswordNeverExpires.Name) ($($DomainUserPasswordNeverExpiresArray.PasswordLastSet))" 
}
