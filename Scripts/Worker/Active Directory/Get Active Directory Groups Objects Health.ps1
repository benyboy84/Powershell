# **********************************************************************************
# Script to find all Active Directory Groups objects informations.
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

#Default nested groups in Active Directory
$Builtin = @(
    New-Object PSObject -Property @{Group = "Administrators"; Member = "Domain Admins"}
    New-Object PSObject -Property @{Group = "Administrators"; Member = "Enterprise Admins"}
    New-Object PSObject -Property @{Group = "Users"; Member = "Domain Users"}
    New-Object PSObject -Property @{Group = "Guests"; Member = "Domain Guests"}
    New-Object PSObject -Property @{Group = "Denied RODC Password Replication Group"; Member = "Read-only Domain Controllers"}
    New-Object PSObject -Property @{Group = "Denied RODC Password Replication Group"; Member = "Group Policy Creator Owners"}
    New-Object PSObject -Property @{Group = "Denied RODC Password Replication Group"; Member = "Domain Admins"}
    New-Object PSObject -Property @{Group = "Denied RODC Password Replication Group"; Member = "Cert Publishers"}
    New-Object PSObject -Property @{Group = "Denied RODC Password Replication Group"; Member = "Enterprise Admins"}
    New-Object PSObject -Property @{Group = "Denied RODC Password Replication Group"; Member = "Schema Admins"}
    New-Object PSObject -Property @{Group = "Denied RODC Password Replication Group"; Member = "Domain Controllers"}
)

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

Try {

    #Get all groups in Active Directory
    Log -Text "Getting all group in currently logged Active Directory"
    [Array]$Groups = Get-ADGroup -Filter *
}
Catch {

    #An error occured during getting Active Directory Group
    Log -Text "An error occured during getting Active Directory Group" -Error
    #Because this script need to know every Active Directory groups to works, the script execution is stop.
    Break
    
}

Write-Host "Active Directory Groups Objects ($($Groups.Count)))" -ForegroundColor Cyan

#Get groups objects by type
Write-Host "Active Directory Groups Objects by type" -ForegroundColor Cyan
Log -Text "Active Directory Groups Objects by type"
[Array]$Count = $Groups | Where-Object {($_.GroupCategory -eq "Security") -and ($_.GroupScope -eq "DomainLocal")}
Write-Host "Domain Local Security              : $($Count.Count)"
[Array]$Count = $Groups | Where-Object {($_.GroupCategory -eq "Security") -and ($_.GroupScope -eq "Global")}
Write-Host "Global Security                    : $($Count.Count)"
[Array]$Count = $Groups | Where-Object {($_.GroupCategory -eq "Security") -and ($_.GroupScope -eq "Universal")}
Write-Host "Universal Security                 : $($Count.Count)"
[Array]$Count = $Groups | Where-Object {$_.GroupCategory -eq "Distribution"}
Write-Host "Distribution                       : $($Count.Count)"

#Loop in each group to find Empry group.
Write-Host "Empty Groups" -ForegroundColor DarkCyan
ForEach ($Group in $Groups) {

    If ($BuiltinGroups -notcontains $Group.Name){

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

}

#Loop in each group to find nested group.
$Result = @()
ForEach ($Group in $Groups) {

    $NestedGroup = $Null
    
    #Finding nested group in current group.
    Try {
        Log -Text "Finding nested group in current group $($Group.Name)"
        $NestedGroups = Get-ADGroupMember -Identity $Group.Name | Where-Object {($_.objectClass -eq 'group') -and ($_.Name -notin ($Builtin | Where-Object {$_.Group -eq $Group.Name} | Select -Property Member -ExpandProperty Member))}
    }
    Catch {
        Log -Text "An error occured guring getting Active Directory group's members for group $($Group.Name)" -Warning
    }

    #If NestedGroups is not null, we will add the nested group into the result output.
    ForEach ($NestedGroup in $NestedGroups) {

        $object = "" |  Select-Object GroupName,
                                      Member
        $object.GroupName = $Group.Name
        $object.Member = $NestedGroup.Name
        $Result += $object

    }

}

If ($Result -ne $Null) {

    #Display result of the script to the screen.
    Write-Host "Listing Nested Rroups..." -ForegroundColor Cyan
    $Result | Sort-Object -Property GroupName | Ft 

}
Else {

    Write-Host "No nested group in Active Directory" -ForegroundColor Cyan

}

Write-Host "Privileged Group's Members" -ForegroundColor Cyan
#Loop in each group to find list of users.
ForEach($Group in $ADPrivGroupArray){

    Write-Host "$Group ($($GroupMember.count))" -ForegroundColor DarkCyan
    Try {
        Log -Text "Getting members of Active Directory group $($Group)"
        [array]$GroupMember = Get-ADGroupMember -Identity $Group -Recursive  | Select-Object Name
        ForEach ($Member in $GroupMember) {
            Write-Host " - $($Member.Name)"
        }
    }
    Catch{
        Log -Text "An error occured during getting members of Active Directory group $($Group)"
    }
}

Log -Text "Script ended"