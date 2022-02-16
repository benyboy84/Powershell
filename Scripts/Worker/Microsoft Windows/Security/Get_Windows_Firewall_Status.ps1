<#
**********************************************************************************
Script to get Windows Firewall Status.
**********************************************************************************

.SYNOPSIS
Script to get Windows Firewall Status. 

Version 1.0 of this script.

.DESCRIPTION
This script is use to get the state of the Windows Firewall. 

This script accepts 2 parameters.
-debug       This will generate display details informations in the Powershell window and a log file with the information related to the script execution.
-output      This will generate an output file instead of displaying information in the Powershell window.

WARNING:
This script needs to be run directly on a Domain Controller and needs to be run "AS ADMINISTRATOR".


.EXAMPLE
./Get_Windows_Firewall_Status.ps1 
./Get_Windows_Firewall_Status.ps1 -debug
./Get_Windows_Firewall_Status.ps1 -output

.NOTES
Author: Benoit Blais

.LINK
https://github.com/benyboy84/Powershell

#>

Param(
    [Switch]$Debug = $False,
    [Switch]$Output = $False
)

#Default action when an error occured
$ErrorActionPreference = "Stop"

#Log file
$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1
$TimeStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Log = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).log"
$Outfile = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).txt"

# **********************************************************************************

#Log function will allow to display colored information in the PowerShell window and
#a log file with the information related to the script execution. if debug mode is $TRUE.
#Parameters:
#$Text : Text added to the text file.
#$Error and $Warning: These switch need to be use to specify something else then an information.
Function Log {
    Param (
        [Parameter(Mandatory=$true)][String]$Text,
        [Switch]$Error,
        [Switch]$Warning
    )
    If($Error) {
        $Text = "ERROR   | $Text"
    }
    ElseIf($Warning) {
        $Text = "WARNING | $Text"
    }
    Else {
        $Text = "INFO    | $Text"
    }
    If ($Debug) {
        If($Error) {
            Write-Host $Text -ForegroundColor Red
            Try {Add-Content $Log "$(Get-Date) | $Text"} Catch {$Null}
        }ElseIf($Warning) {
            Write-Host $Text -ForegroundColor Yellow
            Try {Add-Content $Log "$(Get-Date) | $Text"} Catch {$Null}
        }Else {
            Write-Host $Text -ForegroundColor Green
            Try {Add-Content $Log "$(Get-Date) | $Text"} Catch {$Null}
        }
    }
}

# **********************************************************************************

#Out function will allow to add informations to an output file instead of displaying 
#information in the Powershell window.
#$Text : Text added to the text file.

Function Out {
    Param (
        [Parameter(Mandatory=$true)][String]$Text
    )

    If ($Output) {

        Log -Text "Adding information to the output file: $($Text)"
        Try {
            $Text | Out-File -FilePath $Outfile -Append -Encoding utf8
        } 
        Catch {
            Log -Text 'An error occured during adding information to the output file' -Error
        }

    }
}

# **********************************************************************************

Log -Text "Script begin"

#Delete output files if they already exist.
Log -Text "Validating if outputs files already exists"
If (Get-ChildItem -Path $ScriptPath | Where-Object {($_.Name -match "$($ScriptName)") -and ($_.Name -notmatch "$($ScriptName).ps1") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).log") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).txt")}){
    #Output files exists, we will try to delete it.
    Log -Text "Deleting old output files"
    Try {
        Get-ChildItem -Path $ScriptPath | Where-Object {($_.Name -match "$($ScriptName)") -and ($_.Name -notmatch "$($ScriptName).ps1") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).log") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).txt")} | Remove-Item
    }
    Catch {
        Log -Text "An error occured when deleting old output files" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
    }
}

$Text = "Windows Firewall Status"
Write-Host $Text -ForegroundColor Cyan
Out -Text $Text

#Getting Windows Firewall Domain Profile status.
Try {
    Log -Text "Getting Windows Firewall Domain Profile status"
    $Domain = Get-NetFirewallProfile -Name Domain
}
Catch {
    Log -Text "An error occured during getting Windows Firewall Domain Profile status" -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
}

If ($Domain.Enabled) {
    $Text = "Domain Profile : Enabled"
}
ElseIf (!($Domain.Enabled)) {
    $Text = "Domain Profile : Disable"
}
Else {
    $Text = "Domain Profile : Unable to find information"
}

If (!($Domain.Enabled)) {
    Write-Host $Text -ForegroundColor Red
}
Else {
    Write-Host $Text 
}
Out -Text $Text

#Validating default inbound action for Domain Profil.
Log -Text "Validating default inbound action for Domain Profil"
If (($Domain.Enabled) -and ($Domain.DefaultInboundAction -match "Allow")) {
    $Text = "WARNING: Default inbound action is allow."
    Write-Host $Text -ForegroundColor Yellow
    Out -Text $Text
}

#Getting Windows Firewall Private Profile status.
Try {
    Log -Text "Getting Windows Firewall Private Profile status"
    $Private = Get-NetFirewallProfile -Name Private
}
Catch {
    Log -Text "An error occured during getting Windows Firewall Private Profile status" -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
}

If ($Private.Enabled) {
    $Text = "Private Profile : Enabled"
}
ElseIf (!($Private.Enabled)) {
    $Text = "Private Profile : Disable"
}
Else {
    $Text = "Private Profile : Unable to find information"
}

If (!($Private.Enabled)) {
    Write-Host $Text -ForegroundColor Red
}
Else {
    Write-Host $Text 
}
Out -Text $Text

#Validating default inbound action for Private Profil.
Log -Text "Validating default inbound action for Private Profil"
If (($Private.Enabled) -and ($Private.DefaultInboundAction -match "Allow")) {
    $Text = "WARNING: Default inbound action is allow."
    Write-Host $Text -ForegroundColor Yellow
    Out -Text $Text
}

#Getting Windows Firewall Public Profile status.
Try {
    Log -Text "Getting Windows Firewall Public Profile status"
    $Public = Get-NetFirewallProfile -Name Public
}
Catch {
    Log -Text "An error occured during getting Windows Firewall Public Profile status" -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
}

If ($Public.Enabled) {
    $Text = "Public Profile : Enabled"
}
ElseIf (!($Private.Enabled)) {
    $Text = "Public Profile : Disable"
}
Else {
    $Text = "Public Profile : Unable to find information"
}

If (!($Public.Enabled)) {
    Write-Host $Text -ForegroundColor Red
}
Else {
    Write-Host $Text 
}
Out -Text $Text

#Validating default inbound action for Public Profil.
Log -Text "Validating default inbound action for Public Profil"
If (($Public.Enabled) -and ($Public.DefaultInboundAction -match "Allow")) {
    $Text = "WARNING: Default inbound action is allow."
    Write-Host $Text -ForegroundColor Yellow
    Out -Text $Text
}

Log -Text "Script end"
