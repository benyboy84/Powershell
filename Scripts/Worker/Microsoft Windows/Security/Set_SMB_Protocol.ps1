<#
**********************************************************************************
Script manage SMBv1 protocol.
**********************************************************************************

.SYNOPSIS
Script manage SMBv1 protocol. 

Version 1.0 of this script.
Version 2.0 of this script allows you to write the result of the script to an output file.

.DESCRIPTION
This script is use to get the state of the SMBv1 protocol and enable or disable it. 

By default this script will get the state of the protocol SMBv1.

This script accepts 4 parameters.
-debug       This will generate display details informations in the Powershell window and a log file with the information related to the script execution.
-output      This will generate an output file instead of displaying information in the Powershell window.
-enable      This will enable SMBv1 protocol.
-disable     This will disable SMBv1 protocol.

WARNING:
This script needs to be run "AS ADMINISTRATOR".
Your system needs to reboot to take effect of the change.

.EXAMPLE
./Set_SMB_Protocol.ps1 
./Set_SMB_Protocol.ps1 -debug
./Set_SMB_Protocol.ps1 -output
./Set_SMB_Protocol.ps1 -enable
./Set_SMB_Protocol.ps1 -disable

.NOTES
Author: Benoit Blais

.LINK
https://github.com/benyboy84/Powershell

#>

Param(
    [Switch]$Debug = $False,
    [Switch]$Output = $False,
    [Switch]$Enable = $False,
    [Switch]$Disable = $False
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
            $Text | Out-File -FilePath $file -Append -Encoding utf8
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

#Getting the state of SMBv1 protocol.
Log -Text "Getting the state of SMBv1 protocol"
Try {
    $SMBv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
}
Catch {
    Log -Text "An error occured during getting the state of SMBv1 protocol" -Error
}

Write-Host "SMBv1 protocol state : $($SMBv1.State)" -ForegroundColor Cyan
Out -Text "SMBv1 protocol state : $($SMBv1.State)"

#If enable parameter is present, enabling SMBv1 protocol.
If ($Enable) {
    If ($($SMBv1.State) -match "disabled") {
        Log -Text "Enabling SMBv1 protocol"
        Try {
            Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart | Out-Null
            $Text = "SMBv1 protocol is enabled"
            Write-Host  $Text
            Out -Text $Text
            $Text = "You must restart your computer"
            Write-Host $Text -ForegroundColor Yellow
            Out -Text $Text 
        }
        Catch {
            $Text = "An error occured during enabling SMBv1 protocol"
            Write-Host $Text -ForegroundColor Red
            Write-Host "$($PSItem.Exception.Message)" -ForegroundColor Red
            Out -Text $Text
            Log -Text $Text -Error
            Log -Text "$($PSItem.Exception.Message)" -Error
        }
    }
    Else {
        $Text = "SMBv1 protocol is already disabled"
        Write-Host $Text
        Out -Text $Text
        Log -Text $Text
    }
}

#If enable parameter is present, disabling SMBv1 protocol.
If ($Disable) {
    If ($($SMBv1.State) -match "enabled") {
        Log -Text "Disabling SMBv1 protocol"
        Try {
            Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart | Out-Null
            $Text = "SMBv1 protocol is disabled"
            Write-Host  $Text
            Out -Text $Text
            $Text = "You must restart your computer"
            Write-Host $Text -ForegroundColor Yellow
            Out -Text $Text 
        }
        Catch {
            $Text = "An error occured during disabling SMBv1 protocol"
            Write-Host $Text -ForegroundColor Red
            Write-Host "$($PSItem.Exception.Message)" -ForegroundColor Red
            Out -Text $Text
            Log -Text $Text -Error
            Log -Text "$($PSItem.Exception.Message)" -Error
        }
    }
    Else {
        $Text = "SMBv1 protocol is already disabled"
        Write-Host $Text
        Out -Text $Text
        Log -Text $Text
    }
}

Log -Text "Script end"