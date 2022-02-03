# **********************************************************************************
# Script to retreive the Active Directory Password policy.
#
# If you need to troubleshoot the script, you can enable the Debug option in
# the parameter. This will generate display information on the screen.
#
# This script use Active Directory module
#
# ==================================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2022-02-01  Benoit Blais        Original version
# **********************************************************************************

Param(
    [Switch]$Debug = $False
)

#Default action when an error occured
$ErrorActionPreference = "Stop"

# **********************************************************************************

#Log function will allow to display colored information in the PowerShell window
#if debug mode is $TRUE.
#Parameters:
#$Text : Text added to the text file.
#$Error and $Warning: These switch need to be use to specify something else then an information.
Function Log {
    Param (
        [Parameter(Mandatory=$true)][String]$Text,
        [Switch]$Error,
        [Switch]$Warning
    )
    If ($Debug) {
        $Output = "$(Get-Date) |"
        If($Error) {
            $Output += " ERROR   | $Text"
            Write-Host $Output -ForegroundColor Red
        }
        ElseIf($Warning) {
            $Output += " WARNING | $Text"
            Write-Host $Output -ForegroundColor Yellow
        }
        Else {
            $Output += " INFO    | $Text"
            Write-Host $Output -ForegroundColor Green
        }
    }
}

# **********************************************************************************

Log -Text "Script Begin"

#Validate if Active Directory module is currently loaded in Powershell session.
Log -Text "Validating if Active Directory module is loaded in the currect Powershell session"
If (!(Get-Module | Where-Object {$_.Name -eq "ActiveDirectory"})){

    #Active Directory is not currently loaded in Powershell session.
    Log -Text "Active Directory is not currently loaded in Powershell session" -Warning
    If (Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"}) { 
        
        #Active Directory module installed on that computer.
        Log -Text "Active Directory module installed on that computer"
        Try {
            #Trying to import Active Directory module.
            Log -Text "Trying to import Active Directory module"
            Import-Module ActiveDirectory 
        }
        Catch {
            #Unable to import Active Directory module.
            Log -Text "Unable to import Active Directory module" -Error
            #Because this script can't be run without this module, the script execution is stop.
            Break
        }
    
    }
    Else {
        
        #Active Directory module is not installed on the current computer.
        Log -Text "ctive Directory module is not installed on the current computer" -Error
        #Because this script can't be run without this module, the script execution is stop.
        Break
    }
}
Else {

    #Active Directory module is loaded in the current Powershell session.
    Log -Text "Active Directory module is loaded in the current Powershell session"

}

#Get Default Domain Password Policy.
Try {
    Log -Text "Getting default Domain Password Policy"
    [array]$DomainPasswordPolicy = Get-ADDefaultDomainPasswordPolicy -Server $DCtoConnect
}
Catch {
    Log -Text "An error occured when collecting default Domain Password Policy" -Error
    Break
}

Write-Host "Default Domain Password Policy" -ForegroundColor Cyan
Write-Host "Complexity Enabled            : $($DomainPasswordPolicy.ComplexityEnabled)"
Write-Host "Maximum Password Age          : $($DomainPasswordPolicy.MaxPasswordAge)"
Write-Host "Minimum Password Age          : $($DomainPasswordPolicy.MinPasswordAge)"
Write-Host "Password History Count        : $($DomainPasswordPolicy.PasswordHistoryCount)"
Write-Host "Minimum Password Length       : $($DomainPasswordPolicy.MinPasswordLength)"
Write-Host "Lockout Duration              : $($DomainPasswordPolicy.LockoutDuration)"
Write-Host "Lockout Threshold              : $($DomainPasswordPolicy.LockoutThreshold)"
Write-Host "Lockout Observation Window    : $($DomainPasswordPolicy.LockoutObservationWindow)"
Write-Host "Reversible Encryption Enabled : $($DomainPasswordPolicy.ReversibleEncryptionEnabled)"

