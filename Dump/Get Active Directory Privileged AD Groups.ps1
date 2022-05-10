# **********************************************************************************
# Script to get members of privileged groups.
#
# In Active Directory, privileged accounts have controlling rights and permissions. 
# They can carry out all designated tasks in Active Directory, on domain controllers, 
# and on client computers. On the flip side, privileged account abuse can result in 
# data breaches, downtime, failed compliance audits, and other bad situations. These 
# groups should be audited often and cleaned up if any inappropriate members are 
# added to them.
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

Log -Text "Script Begin"

#Validate if Active Directory module is currently loaded in Powershell session.
Log -Text "Validating if Active Directory module is loaded in the currect Powershell session"
If (!(Get-Module | Where-Object {$_.Name -eq "ActiveDirectory"})){

    #Active Directory is not currently loaded in Powershell session.
    Log -Text "Active Directory is not currently loaded in Powershell session" -Warning
    If (Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"}) { 
        
        #Active Directory module installed on that computer.
        Log -Text "Active Directory module installed on that computer"
        Try {
            #Trying to import Active Directory module.
            Log -Text "Trying to import Active Directory module"
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

#List of all privileged groups.
$ADPrivGroupArray = @(
 'Administrators',
 'Domain Admins',
 'Enterprise Admins',
 'Schema Admins',
 'Account Operators',
 'Server Operators',
 'Group Policy Creator Owners',
 'DNSAdmins',
 'Enterprise Key Admins',
 'Exchange Domain Servers',
 'Exchange Enterprise Servers',
 'Exchange Admins',
 'Organization Management',
 'Exchange Windows Permissions'
)

Write-Host "Privileged Group's Members" -ForegroundColor Cyan
$Count = 0
#Loop in each group to find list of users.
ForEach($Group in $ADPrivGroupArray){

    Write-Progress -Id 1 -Activity "Listing users in privileged groups.." -Status "Analysing $($Count) of $($ADPrivGroupArray.count): Group - $($Group)"  -PercentComplete ($Count/$ADPrivGroupArray.count*100) 
    $Count++
    
    Write-Host $Group -ForegroundColor DarkCyan
    Try {
        Log -Text "Getting members of Active Directory group $($Group)"
        $GroupMember = Get-ADGroupMember -Identity $Group -Recursive  | Select-Object Name
        ForEach ($Member in $GroupMember) {
            Write-Host " - $($Member.Name)"
        }
    }
    Catch{
        Log -Text "An error occured during getting members of Active Directory group $($Group)"
    }
}
