<#
**********************************************************************************
Script to retrieve the Active Directory Password policy.
**********************************************************************************

.SYNOPSIS
Script to retrieve the Active Directory Password policy. 

Version 1.0 of this script.
Version 2.0 of this script add the output file instead of displaying the information.

.DESCRIPTION
This script uses the command Get-ADDefaultDomainPasswordPolicy to retrieve the Active 
Directory Password policy.This script will generate text file with all collected 
information. 

This script accepts 1 parameter.
-debug       This will generate display details informations in the screen and a log file with the information related to the script execution.

WARNING: 
This script use Active Directory module.

.EXAMPLE
./Get_Active_Directory_Password_Policy.ps1 
./Get_Active_Directory_Password_Policy.ps1 -debug 

.NOTES
Author: Benoit Blais

.LINK
https://github.com/benyboy84/Powershell

#>

Param(
    [Switch]$Debug = $False
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
        Log -Text "Active Directory module is not installed on the current computer" -Error
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
    [array]$DomainPasswordPolicy = Get-ADDefaultDomainPasswordPolicy
}
Catch {
    Log -Text "An error occured when collecting default Domain Password Policy" -Error
    Break
}

#Adding "Active Directory Infomations" section title to output file.
Log -Text 'Adding "Default Domain Password Policy" section title to output file'
Try {
    Add-Content $Output "Default Domain Password Policy"
    Add-Content $Output "------------------------------"
} 
Catch {
    Log -Text 'An error occured when "Default Domain Password Policy" section title to output file' -Error
}

#Adding "Complexity Enabled" to output file.
Log -Text 'Adding "Complexity Enabled" to output file'
Try {
    If ($Null -ne $DomainPasswordPolicy.ComplexityEnabled) {
        Add-Content $Output "Complexity Enabled                : $($DomainPasswordPolicy.ComplexityEnabled)"
    } 
    Else {
        Add-Content $Output "Complexity Enabled                : No information found"
    }
}
Catch {
        Log -Text 'An error occured when adding "Complexity Enabled" to output file' -Error
}

#Adding "Maximum Password Age" to output file.
Log -Text 'Adding "Maximum Password Age" to output file'
Try {
    If ($Null -ne $DomainPasswordPolicy.MaxPasswordAge) {
        Add-Content $Output "Maximum Password Age              : $($DomainPasswordPolicy.MaxPasswordAge)"
    } 
    Else {
        Add-Content $Output "Maximum Password Age              : No information found"
    }
}
Catch {
        Log -Text 'An error occured when adding "Maximum Password Age" to output file' -Error
}

#Adding "Minimum Password Age" to output file.
Log -Text 'Adding "Minimum Password Age" to output file'
Try {
    If ($Null -ne $DomainPasswordPolicy.MinPasswordAge) {
        Add-Content $Output "Minimum Password Age              : $($DomainPasswordPolicy.MinPasswordAge)"
    } 
    Else {
        Add-Content $Output "Minimum Password Age              : No information found"
    }
}
Catch {
        Log -Text 'An error occured when adding "Minimum Password Age" to output file' -Error
}

#Adding "Password History Count" to output file.
Log -Text 'Adding "Password History Count" to output file'
Try {
    If ($Null -ne $DomainPasswordPolicy.PasswordHistoryCount) {
        Add-Content $Output "Password History Count            : $($DomainPasswordPolicy.PasswordHistoryCount)"
    } 
    Else {
        Add-Content $Output "Password History Count            : No information found"
    }
}
Catch {
        Log -Text 'An error occured when adding "Password History Count" to output file' -Error
}

#Adding "Minimum Password Length" to output file.
Log -Text 'Adding "Minimum Password Length" to output file'
Try {
    If ($Null -ne $DomainPasswordPolicy.MinPasswordLength) {
        Add-Content $Output "Minimum Password Length           : $($DomainPasswordPolicy.MinPasswordLength)"
    } 
    Else {
        Add-Content $Output "Minimum Password Length           : No information found"
    }
}
Catch {
        Log -Text 'An error occured when adding "Minimum Password Length" to output file' -Error
}

#Adding "Lockout Duration" to output file.
Log -Text 'Adding "Lockout Duration" to output file'
Try {
    If ($Null -ne $DomainPasswordPolicy.LockoutDuration) {
        Add-Content $Output "Lockout Duration                  : $($DomainPasswordPolicy.LockoutDuration)"
    } 
    Else {
        Add-Content $Output "Lockout Duration                  : No information found"
    }
}
Catch {
        Log -Text 'An error occured when adding "Lockout Duration" to output file' -Error
}

#Adding "Lockout Threshold" to output file.
Log -Text 'Adding "Lockout Threshold" to output file'
Try {
    If ($Null -ne $DomainPasswordPolicy.LockoutThreshold) {
        Add-Content $Output "Lockout Threshold                 : $($DomainPasswordPolicy.LockoutThreshold)"
    } 
    Else {
        Add-Content $Output "Lockout Threshold                 : No information found"
    }
}
Catch {
        Log -Text 'An error occured when adding "Lockout Threshold" to output file' -Error
}

#Adding "Lockout Observation Window" to output file.
Log -Text 'Adding "Lockout Observation Window" to output file'
Try {
    If ($Null -ne $DomainPasswordPolicy.LockoutObservationWindow) {
        Add-Content $Output "Lockout Observation Window        : $($DomainPasswordPolicy.LockoutObservationWindow)"
    } 
    Else {
        Add-Content $Output "Lockout Observation Window        : No information found"
    }
}
Catch {
        Log -Text 'An error occured when adding "Lockout Observation Window" to output file' -Error
}

#Adding "Reversible Encryption Enabled" to output file.
Log -Text 'Adding "Reversible Encryption Enabled" to output file'
Try {
    If ($Null -ne $DomainPasswordPolicy.ReversibleEncryptionEnabled) {
        Add-Content $Output "Reversible Encryption Enabled     : $($DomainPasswordPolicy.ReversibleEncryptionEnabled)"
    } 
    Else {
        Add-Content $Output "Reversible Encryption Enabled     : No information found"
    }
}
Catch {
        Log -Text 'An error occured when adding "Reversible Encryption Enabled" to output file' -Error
}

Log -Text "Script end"

