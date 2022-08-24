<#
**********************************************************************************
Script to create Content Database based on CSV file.
**********************************************************************************

.SYNOPSIS
Script to create Content Database based on CSV file. 

Version 1.0 of this script.

.DESCRIPTION
This script is used to create Content Database base on CSV file containing a list
of all sites collection from another SharePoitn server.  

The CSV file needs to be generated with the script "Get Sites Collections.ps1".

This script accepts 2 parameters.
-debug       This will generate display details informations in the Powershell window.
-output      This will generate an output file with the information related to the script execution.

WARNING:
This script needs to be run directly on the SharePoint server.

.EXAMPLE
./Get Sites Collections.ps1 -debug
./Get Sites Collections.ps1 -output
./Get Sites Collections.ps1 -debug -output

.NOTES
Author: Benoit Blais

.LINK
https://github.com/benyboy84/Powershell

#>

Param(
    [Switch]$Debug = $False,
    [Switch]$Output = $False
)

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION

#The path of the CSV file required by the script.
$CSVFile = "C:\IT\Applications\SitesCollections.csv"

# *******************************************************************************

#Default action when an error occured
$ErrorActionPreference = "Stop"

#Log file
$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1
$TimeStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Log = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).log"

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
        }ElseIf($Warning) {
            Write-Host $Text -ForegroundColor Yellow
        }Else {
            Write-Host $Text -ForegroundColor Green
        }
    }
    If ($Output) {
        Try {Add-Content $Log "$(Get-Date) | $Text"} Catch {$Null}
    }
}

# **********************************************************************************

Log -Text "Script begin"

#Validating CSV file.
Log -Text "Valigating CSV file"
If (Test-Path $CSVFile) {
    Try {
        $Rows = Import-CSV $CSVFile
        $Headers = ($Rows | Get-Member -MemberType NoteProperty).Name
        If (($Headers -notcontains "ContentDatabase") -or ($Headers -notcontains "ContentDatabaseWebApplication")) {
            Log -Text "CSV is not correctly formatted" -Error
            Exit 1
        }
    }
    Catch {
        Log -Text "An error occurred during importing CSV file" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        Exit 1
    }
}
Else {
    Log -Text "CSV file does not exist" -Error
    Exit 1
}

#Add SharePoint PSSnaping.
Log -Text "Adding Microsoft.SharePoint.PowerShell PSSnaping"
Try {
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
}
Catch {
    Log -Text "Unable to add Microsoft.SharePoint.PowerShell PSSnaping" -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
    Exit 1
}

#Loop through each entry of the CSV file to create the Content Database.
ForEach ($Row in $Rows) {

    #Validating if Content Database exist.
    Log -Text "Validating if Content Database $($Row.ContentDatabase) exist"
    If ((Get-SPContentDatabase | Select Name -ExpandProperty Name) -notcontains $Row.ContentDatabase) {
        Log -Text "Content Database $($Row.ContentDatabase) exist does not exist" -Warning
        Log -Text "Creating Database $($Row.ContentDatabase)"
        Try {
            New-SPContentDatabase -name $Row.ContentDatabase -webapplication $Row.ContentDatabaseWebApplication | Out-Null
            Log -Text "Content Database $($Row.ContentDatabase) create successfully"
        }
        Catch {
            Log -Text "An error occurred  during the creation of the Content Database $($Row.ContentDatabase)" -Warning
            Log -Text "$($PSItem.Exception.Message)" -Error
        }
    }
    Else {
        Log -Text "Content Database $($Row.ContentDatabase) already exist"
    }

}
