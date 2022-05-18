<#
**********************************************************************************
Script to detect if Groove applications are removed.
**********************************************************************************

.SYNOPSIS
Script to detect if Groove applications like are removed

Version 1.0 of this script.

.DESCRIPTION
This script is use to detect if Geoove applications are removed

.EXAMPLE
./RemoveGrooveApps-Detection.ps1 

.NOTES
Author: Benoit Blais

.LINK
https://github.com/benyboy84/Powershell

#>
#Default action when an error occured
$ErrorActionPreference = "Stop"

#Windows Application to remove
$Applications = @("Microsoft.ZuneMusic")

# **********************************************************************************

#Validate package to remove.
Try {
    $AppxPackages = @()
    ForEach ($Application in $Applications) {
        $AppxPackages += Get-AppxPackage $Application
    }
    If ($Null -ne $AppxPackages) {
        Write-Output "Success"
        Exit 0
    }
}
Catch {
    Exit 1

}
