<#
**********************************************************************************
Script to set VDA registration.
**********************************************************************************

.SYNOPSIS
Script to set VDA registration. 

Version 1.0 of this script.

.DESCRIPTION
This script is used to configure VDA registration through the registry.  

This script accepts 2 parameters.
-debug       This will generate display details informations in the Powershell window.
-output      This will generate an output file with the information related to the script execution.

.EXAMPLE
./VDA Registration.ps1 
./VDA Registration.ps1 -debug
./VDA Registration.ps1 -output

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

#New Delivery Controller or Cloud Connector if use with Citrix Cloud
#You have tu use the FQDN.
$ListOfDCs = @("WVM-CTXCL-P01.gazmet.com","WVB-CTXCL-P01.gazmet.com")

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

#Validating value of ListOfDCs.
Log -Text "Validating value of ListOfDCs"
ForEach ($Item in $ListOfDCs){
    If (($Item.Split(".")).Count -lt 3) {
        Log -Text "Value contain in ListOfDCs is not an FQDN" -Error
        Exit 1
    }
}

#Getting the current value of the Delivery Controller or Cloud Connector if use with Citrix Cloud.
Log -Text "Getting the current value of the Delivery Controller or Cloud Connector if use with Citrix Cloud"
If (Test-Path "HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent") {
    If (Get-ItemProperty "HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent" "ListOfDCs" -ErrorAction SilentlyContinue) {
        Try {
            $Value = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent' -Name "ListOfDCs"
        }
        Catch {
            Log -Text "An error occured when getting property value" -Error
            Log -Text "$($PSItem.Exception.Message)" -Error
            Exit 1
        }
    }
    Else {
        Log -Text "ListOfDCs does not exist in registry" -Error
        Exit 1
    }
}
Else {
    Log -Text "Registry key 'HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent' does not exist" -Error
    Exit 1
}

#Valiating if ListOfDCs is not empty.
If ($Value -eq "") {

    Log -Text "ListOfDCs exist but, is empty" -Warning
        
}

#Creating the new value
Try {
    Log -Text "Creating the new registry value by adding the new Delivery Controller to the existing list"
    $Value = $Value.Split(" ")
    $Value = $Value + $ListOfDCs
    $Value = $Value -Join " "
}
Catch {
    Log -Text "An error occured during the creating of the new value" -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
    Exit 1
}

#Setting the new registry value.
Log -Text "Setting the new registry value"
Try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent" -Name "ListOfDCs" -Value $Value
    Log -Text "New value succesfully set in registry"
}
Catch {
    Log -Text "An error occured during setting the new value" -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
    Exit 1
}