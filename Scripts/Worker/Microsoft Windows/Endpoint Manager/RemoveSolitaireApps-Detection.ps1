<#
**********************************************************************************
Script to detect if Solitaire applications are removed.
**********************************************************************************

.SYNOPSIS
Script to detect if Solitaire applications like are removed

Version 1.0 of this script.

.DESCRIPTION
This script is use to detect if Solitaire applications are removed

.EXAMPLE
./RemoveSolitaireApps-Detection.ps1 

.NOTES
Author: Benoit Blais

.LINK
https://github.com/benyboy84/Powershell

#>
#Default action when an error occured
$ErrorActionPreference = "Stop"

#Windows Application to remove
$Applications = @("Microsoft.MicrosoftSolitaireCollection")

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
