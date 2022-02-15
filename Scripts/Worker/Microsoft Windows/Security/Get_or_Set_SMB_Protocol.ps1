<#
**********************************************************************************
Script manage SMBv1 protocol.
**********************************************************************************

.SYNOPSIS
Script manage SMBv1 protocol. 

Version 1.0 of this script.

.DESCRIPTION
This script is use to get the state of the SMBv1 protocol and enable or disable it. 

By default this script will get the state of the protocol SMBv1.

This script accepts 3 parameters.
-debug       This will generate display details informations in the screen and a log file with the information related to the script execution.
-enable      This will enable SMBv1 protocol.
-disable     This will disable SMBv1 protocol.

WARNING:
Your system needs to reboot to take effect of the change.

.EXAMPLE
./Get_or_Set_SMB_Protocol.ps1 
./Get_or_Set_SMB_Protocol.ps1 -debug
./Get_or_Set_SMB_Protocol.ps1 -enable
./Get_or_Set_SMB_Protocol.ps1 -disable

.NOTES
Author: Benoit Blais

.LINK
https://github.com/benyboy84/Powershell

#>

Param(
    [Switch]$Debug = $False,
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
$Output = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).txt"

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

#Adding SMBv1 protocol state to output file.
Log -Text 'Adding SMBv1 protocol state to output file'
Try {
    Add-Content $Output "SMBv1 protocol state : $($SMBv1.State)"
} 
Catch {
    Log -Text 'An error occured when SMBv1 protocol state to output file' -Error
}

#If enable parameter is present, enabling SMBv1 protocol.
If ($Enable) {
    Log -Text "Enabling SMBv1 protocol"
    Try {
        Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
        Log -Text "SMBv1 protocol is enabled"
        Log -Text "You must restart your computer" -Warning
    }
    Catch {
        Log -Text "An error occured during enabling SMBv1 protocol."
    }
}

#If enable parameter is present, disabling SMBv1 protocol.
If ($Disable) {
    Log -Text "Disabling SMBv1 protocol"
    Try {
        Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
        Log -Text "SMBv1 protocol is disabled"
        Log -Text "You must restart your computer" -Warning
    }
    Catch {
        Log -Text "An error occured during disabling SMBv1 protocol."
    }
}

Log -Text "Script end"