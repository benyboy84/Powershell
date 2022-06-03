<#
**********************************************************************************
Script to remove Solitaire applications under user context
**********************************************************************************

.SYNOPSIS
Script to remove Solitaire applications under user context.

Version 1.0 of this script.

.DESCRIPTION
This script is use to remove Solitaire applications under user context. 

This script accepts 2 parameters.
-debug       This will generate display details informations in the Powershell window and a log file with the information related to the script execution.
-output      This will generate an output file instead of displaying information in the Powershell window.

.EXAMPLE
./RemoveSolitaireApps.ps1 
./RemoveSolitaireApps.ps1  -debug
./RemoveSolitaireApps.ps1  -output <path>

.NOTES
Author: Benoit Blais

.LINK
https://github.com/benyboy84/Powershell

#>

Param(
    [String]$Application,
    [Switch]$Debug = $False,
    [String]$Output = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\RemoveSolitaireApps.log"
)

#Default action when an error occured
$ErrorActionPreference = "Stop"

#Windows Application to remove
$Applications = @("Microsoft.MicrosoftSolitaireCollection")

# **********************************************************************************

#Log function will allow to display colored information in the PowerShell window if 
#debug mode is $TRUE. It will create a log file with the information related to the 
#script execution if output contain a path.
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
    If ($Null -ne $Output) {
        Try {Add-Content $Output "$(Get-Date) | $Text"} Catch {$Null}
    }
}

# **********************************************************************************

#Validate output files.
If ($Output -match '\\') {
    #Path contain a "\" like a regular path
    [Array]$OutputLocationArray = $Output.Split("\")
    [Array]$OutputLocationArray = $OutputLocationArray[0..($OutputLocationArray.Count-2)]
    $OutputLocation = $OutputLocationArray -join "\"
    If (Test-Path -Path $OutputLocation) {
        If (Test-Path -Path $Output) {
            #Output files exists, we will try to delete it.
            Try {
                Remove-Item -Path $Output -Force
            } 
            Catch {
                #Unable to remove the existing file.
                #We will execute the script without output file.
                $Output = $Null
            }
        }
    }
    Else {
        #The folder does not exist.
        #We will execute the script without output file.
        $Output = $Null
    }
}
Else {
    #The path does not contain any "\", so it's not a valid path.
    #We will execute the script without output file.
    $Output = $Null
}

Log -Text "Script begin"

#Get all installed package to remove.
Try {
    Log -Text "Getting all installed packages to remove."
    $AppxPackages = @()
    ForEach ($Application in $Applications) {
        $AppxPackages += Get-AppxPackage $Application
    }
}
Catch {
    Log -Text "Unable to get installed packages to remove." -Error
    Log -Test "$($PSItem.Exception.Message)" -Error
    Write-Error -Message "Unable to get installed packages to remove."
    Exit 1
}

If ($AppxPackages.Count -ne 0) {
    
    #Lopp into each installed package to remove.
    ForEach ($AppxPackage in $AppxPackages) {

        Try {
            Log -Text "Removing $($AppxPackage.Name)..."
            Get-AppxPackage $AppxPackage.Name | Remove-AppxPackage
            Log -Text "Package $($AppxPackage.Name) succesfully removed."
        }
        Catch {
            Log -Text "Unable to remove $($AppxPackage.Name)" -Error
            Log -Test "$($PSItem.Exception.Message)" -Error
            Write-Error -Message "Unable to remove $($AppxPackage.Name)"
        }
    }

}
Else {

    Log -Text "Application not installed"
    Exit 0

}

