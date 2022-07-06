<#
**********************************************************************************
Script to get all sites collection informations.
**********************************************************************************

.SYNOPSIS
Script to get all sites collection informations. 

Version 1.0 of this script.

.DESCRIPTION
This script is used to configure to get all required informations to create it on
another SharePoint farm.  

This script will export the informations in a CSV file located in the same directory as
the script.

This script accepts 2 parameters.
-debug       This will generate display details informations in the Powershell window.
-output      This will generate an output file with the information related to the script execution.

WARNING:
This script needs to be run directly on the SharePoint server.

.EXAMPLE
./Get Sites Collections.ps1 
./Get Sites Collections.ps1 -debug
./Get Sites Collections.ps1 -output

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

#The URL of the main web application in the SharePoint.
$WebApplication = "https://ammc-portal.arcelormittal.com/"

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

Log -Text "Adding Microsoft.SharePoint.PowerShell PSSnaping"
Try {
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
}
Catch {
    Log -Text "Unable to add Microsoft.SharePoint.PowerShell PSSnaping" -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
    Exit 1
}

#Getting a list of all sites templates.
Log -Text "Getting a list of all sites templates"
Try {
    $Templates = [Microsoft.SharePoint.Administration.SPWebService]::ContentService.quotatemplates
}
Catch {
    Log -Text "Unable to get the template's list" -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
    Exit 1
}

#Getting a list of all sites collection.
Log -Text "Getting a list of all sites collection"
Try {
    $URLs = SPWebApplication $WebApplication | Get-SPSite -Limit All | Select Name, Url, Owner, SecondaryContact, ContentDatabase
}
Catch {
    Log -Text "Unable to get a list of all sites colllection" -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
    Exit 1
}

$Result = @()

#Loop through each site collection to get all required information to recreat it on another SharePoint server.
Log -Text "Loop through each site collection to get all required information to recreat it on another SharePoint server"
ForEach ($Url in $URLs) {

    $Object = "" | Select Name, URL, ContentDatabase, ContentDatabaseWebApplication, Language, Owner, SecondaryOwner, Template, Quota

    $Object.Name = $Url.Name
    $Object.URL = $Url.URL
    $Object.ContentDatabase = $Url.ContentDatabase.Name 
    $Object.ContentDatabaseWebApplication = $Url.ContentDatabase.WebApplication.Url
    $Object.Language = (Get-SPSite $Url.URL).RootWeb.Language
    $Object.Owner = $Url.Owner
    $Object.SecondaryOwner = $Url.SecondaryContact
    $Object.Template = "$((Get-SPWeb $Url.URL).WebTemplate)#$((Get-SPWeb $Url.URL).WebTemplateID)"
    $Object.Quota = $Templates | Where-Object {$_.QuotaID -eq (Get-SPSite $Url.URL).Quota.QuotaID} | Select Name -ExpandProperty Name

    $Result += $Object

}

Log -Text "Exporting the result in a CSV file"
Try {
    $Result | Export-CSV "$($ScriptPath)\SitesCollection.csv" -NoTypeInformation
}
Catch {
    Log -Text "Unable to export the result in a CSV file" -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
}