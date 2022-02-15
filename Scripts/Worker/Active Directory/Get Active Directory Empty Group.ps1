# **********************************************************************************
# Script to find empty groups in Active Directory.
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

$BuiltinGroups = @("Print Operators","Backup Operators","Replicator","Remote Desktop Users",
"Network Configuration Operators","Performance Monitor Users","Performance Log Users",
"Distributed COM Users","Cryptographic Operators","Event Log Readers","Certificate Service DCOM Access",
"RDS Remote Access Servers","RDS Endpoint Servers","RDS Management Servers","Hyper-V Administrators",
"Access Control Assistance Operators","Remote Management Users","Storage Replica Administrators",
"Domain Computers","Cert Publishers","RAS and IAS Servers","Server Operators","Account Operators",
"Incoming Forest Trust Builders","Terminal Server License Servers","Allowed RODC Password Replication Group",
"Read-only Domain Controllers","Enterprise Read-only Domain Controllers","Cloneable Domain Controllers",
"Protected Users","Key Admins","Enterprise Key Admins","DnsAdmins","DnsUpdateProxy")

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
        Log -Text "Active Directory module is not installed on the current computer" -Error
        #Because this script can't be run without this module, the script execution is stop.
        Break
    }
}
Else {

    #Active Directory module is loaded in the current Powershell session.
    Log -Text "Active Directory module is loaded in the current Powershell session"

}

Try {

    #Get all groups in Active Directory
    Log -Text "Getting all group in currently logged Active Directory"
    $Groups = Get-ADGroup -Filter * | Where-Object {$BuiltinGroups -notcontains $_.Name}
}
Catch {

    #An error occured during getting Active Directory Group
    Log -Text "An error occured during getting Active Directory Group" -Error
    #Because this script need to know every Active Directory groups to works, the script execution is stop.
    Break
    
}

$Count = 0

Write-Host "Empty Groups" -ForegroundColor DarkCyan
#Loop in each group to find Empry group.
ForEach ($Group in $Groups) {

    Write-Progress -Id 1 -Activity "Finding empty groups.." -Status "Analysing $($Count) of $($Groups.count): Group - $($Group.Name)"  -PercentComplete ($Count/$Groups.count*100) 
    $Count ++
    
    
    #Finding empty group in current group.
    Try {
        If ((Get-ADGroupMember -Identity $Group.Name).Count -eq 0) {
            Write-Host " - $($Group.Name)"
        }
    }
    Catch {
        Log -Text "An error occured guring getting Active Directory group's members for group $($Group.Name)" -Warning
    }

}

Log -Text "Script ended"
