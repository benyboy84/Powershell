# **********************************************************************************
# Script to find all information regarding Active Directory.
#
# When unconstrained delegation is configured, the userAccountControl attribute of 
# the object is updated to include the TRUSTED_FOR_DELEGATION flag. When an object 
# authenticates to a host with unconstrained delegation configured, the 
# ticket-granting ticket (TGT) for that account is stored in memory. This is so that 
# the host with unconstrained delegation configured can impersonate that user later, 
# if needed. When the delegated servers are under the control of an attacker, the 
# attacker can easily impersonate any server within the network using privileged 
# TGT tokens that are cached locally.
#
# If you need to troubleshoot the script, you can enable the Debug option in
# the parameter. This will generate display information on the screen.
#
# This script needs to be run directly on a Domain Controller.
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

# Identify Accounts with Kerberos Delegation
$KerberosDelegationArray = @()
#Get Active Directory Object with Kerberos Delegation.
Try {
    Log -Text "Collecting Active Directory Object with Kerberos Delegation"
    [array]$KerberosDelegationObjects =  Get-ADObject -filter { (UserAccountControl -BAND 0x0080000) -AND (PrimaryGroupID -ne '516') -AND (PrimaryGroupID -ne '521') } -prop Name,ObjectClass,PrimaryGroupID,UserAccountControl,ServicePrincipalName
}
Catch {
    Log -Text "An error occured when collecting Active Directory Object with Kerberos Delegation" -Error
}

# Loop in each Active Directory Object to find Constrained and Unconstrained
ForEach ($KerberosDelegationObjectItem in $KerberosDelegationObjects)
 {
    IF ($KerberosDelegationObjectItem.UserAccountControl -BAND 0x0080000)
     { $KerberosDelegationServices = 'All Services' ; $KerberosType = 'Unconstrained' }
    ELSE 
     { $KerberosDelegationServices = 'Specific Services' ; $KerberosType = 'Constrained' } 
     $KerberosDelegationObjectItem | Add-Member -MemberType NoteProperty -Name KerberosDelegationServices -Value $KerberosDelegationServices -Force
     $KerberosDelegationObjectItem | Add-Member -MemberType NoteProperty -Name KerberosType -Value $KerberosType -Force
     [array]$KerberosDelegationArray += $KerberosDelegationObjectItem
 }

$HUnconstrained = $KerberosDelegationArray | Where-Object {$_.KerberosType -eq "Unconstrained"} | Select Name,ObjectClass,KerberosDelegationServices
Write-Host "Active Directory Object with Unconstrained" -ForegroundColor Cyan
$Unconstrained | FT

$Constrained = $KerberosDelegationArray | Where-Object {$_.KerberosType -eq "Constrained"} | Select Name,ObjectClass,KerberosDelegationServices
Write-Host "ctive Directory Object with Constrained" -ForegroundColor Cyan
$Constrained | FT









## Identify Accounts with Kerberos Delegation
$KerberosDelegationArray = @()
[array]$KerberosDelegationObjects =  Get-ADObject -filter { (UserAccountControl -BAND 0x0080000) -AND (PrimaryGroupID -ne '516') -AND (PrimaryGroupID -ne '521') } -prop Name,ObjectClass,PrimaryGroupID,UserAccountControl,ServicePrincipalName

ForEach ($KerberosDelegationObjectItem in $KerberosDelegationObjects)
 {
    IF ($KerberosDelegationObjectItem.UserAccountControl -BAND 0x0080000)
     { $KerberosDelegationServices = 'All Services' ; $KerberosType = 'Unconstrained' }
    ELSE 
     { $KerberosDelegationServices = 'Specific Services' ; $KerberosType = 'Constrained' } 
     $KerberosDelegationObjectItem | Add-Member -MemberType NoteProperty -Name KerberosDelegationServices -Value $KerberosDelegationServices -Force
     $KerberosDelegationObjectItem | Add-Member -MemberType NoteProperty -Name KerberosType -Value $KerberosType -Force
     [array]$KerberosDelegationArray += $KerberosDelegationObjectItem
 }

$Requiredpros = $KerberosDelegationArray | Select Name,ObjectClass,KerberosDelegationServices,KerberosType
