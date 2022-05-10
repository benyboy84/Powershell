<#
**********************************************************************************
Script to get Active Directory services status.
**********************************************************************************

.SYNOPSIS
Script to get Active Directory services status. 

Version 1.0 of this script.

.DESCRIPTION
This script is use to get the status of the Active Directory services on the local computer. 

This script accepts 2 parameters.
-debug       This will generate display details informations in the Powershell window and a log file with the information related to the script execution.
-output      This will generate an output file instead of displaying information in the Powershell window.

WARNING:
This script needs to be run "AS ADMINISTRATOR".

.EXAMPLE
./Get_Active_Directory_Services_Status.ps1 
./Get_Active_Directory_Services_Status.ps1 -debug
./Get_Active_Directory_Services_Status.ps1 -output

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

#Active Directory services check by the script
$Services= @('DNS','DFS Replication','Intersite Messaging','Kerberos Key Distribution Center','NetLogon',’Active Directory Domain Services’)

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
        [Parameter(Mandatory=$true)]$Text
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

$Text = "Active Driectory Services Status"
Write-Host $Text -ForegroundColor Cyan
Out -Text $Text
$Result = @()
#Looping through each service th get the status
ForEach ($Service in $Services){

    $Object = "" | Select-Object Name,
                                  Status
    $Object.Name = $Service

    #Getting service status.
    Log -Text "Getting $($Service) status"
    Try {
        $ServiceStatus = $Null
        $ServiceStatus = Get-Service $Service | Select-Object Name, Status
    }
    Catch {
        Log -Text "An error occured during getting $($Service) status" -Error
    }

    If ($Null -ne $ServiceStatus.Status) {
        $Object.Status = $ServiceStatus.Status
    }
    Else {
        $Object.Status = "Unable to get status"
    }

    $Result += $Object

}

#Displaying the result at the screen
$Result
Out -Text $Result

Log -Text "Script end"