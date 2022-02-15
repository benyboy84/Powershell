<#
**********************************************************************************
Script to find last Actives Directory change(s) from Event Viewer.
**********************************************************************************

.SYNOPSIS
Script to find last Actives Directory change(s) from Event Viewer. 

Version 1.0 of this script.

.DESCRIPTION
This script uses the Windows security event log to collect events about changes 
made to Active Directory. For entries to be present in the event log, the domain 
controller's auditing settings must be properly configured. This script will 
generate text file with all collected information. 

This script accepts 1 parameter.
-debug       This will generate display details informations in the screen and a log file with the information related to the script execution.

WARNING: 
This script needs to be run directly on a Domain Controller and needs 
to be run "AS ADMINISTRATOR".

.EXAMPLE
./Get_Active_Directory_changes_from_Event_Viewer.ps1 
./Get_Active_Directory_changes_from_Event_Viewer.ps1 -debug 

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

#EventID related to Active Directory changes
$ActiveDirectoryChanges = @(
    #New-Object PSObject -Property @{EventID = "4661";Description = "A handle to an object was requested"}
    #New-Object PSObject -Property @{EventID = "4662";Description = "An operation was performed on an object"}
    #New-Object PSObject -Property @{EventID = "5139";Description = "A directory service object was moved"}
    #New-Object PSObject -Property @{EventID = "5136";Description = "A directory service object was modified"}
    #New-Object PSObject -Property @{EventID = "5137";Description = "A directory service object was created"}
    #New-Object PSObject -Property @{EventID = "5138";Description = "A directory service object was undeleted"}
    #New-Object PSObject -Property @{EventID = "5139";Description = "A directory service object was moved"}
    #New-Object PSObject -Property @{EventID = "5141";Description = "A directory service object was deleted"}
    New-Object PSObject -Property @{EventID = "4720";Description = "A user account was created"}
    New-Object PSObject -Property @{EventID = "4722";Description = "A user accound was enabled"}
    New-Object PSObject -Property @{EventID = "4723";Description = "An attempt was made to change an accounts password"}
    New-Object PSObject -Property @{EventID = "4724";Description = "An attempt was made to reset an accounts password"}
    New-Object PSObject -Property @{EventID = "4725";Description = "A user account was disabled"}
    New-Object PSObject -Property @{EventID = "4726";Description = "A user account was deleted"}
    New-Object PSObject -Property @{EventID = "4738";Description = "A user account was changed"}
    New-Object PSObject -Property @{EventID = "4740";Description = "A user account was lock out"}
    New-Object PSObject -Property @{EventID = "4767";Description = "A user account was unlocked"}
    New-Object PSObject -Property @{EventID = "4780";Description = "The ACL was set on accounts which are members of administrators groups"}
    New-Object PSObject -Property @{EventID = "4781";Description = "The name of an account was changed"}
    New-Object PSObject -Property @{EventID = "4794";Description = "An attempt was mode to set the Directory Service Restore Mode administrator password"}
    New-Object PSObject -Property @{EventID = "5376";Description = "Credential Manader credentials were backed up"}
    New-Object PSObject -Property @{EventID = "5377";Description = "Credential Manader credentials were restored from backup"}
    New-Object PSObject -Property @{EventID = "4741";Description = "A computer account was created"}
    New-Object PSObject -Property @{EventID = "4742";Description = "A computer account was changed"}
    New-Object PSObject -Property @{EventID = "4743";Description = "A computer account was deleted"}
    New-Object PSObject -Property @{EventID = "4727";Description = "A security-enabled global group was created"}
    New-Object PSObject -Property @{EventID = "4728";Description = "A member was added to a security-enabled global group"}
    New-Object PSObject -Property @{EventID = "4729";Description = "A member was removed from a security-enabled global group"}
    New-Object PSObject -Property @{EventID = "4730";Description = "A security-enabled global group was deleted"}
    New-Object PSObject -Property @{EventID = "4731";Description = "A security-enabled local group was created"}
    New-Object PSObject -Property @{EventID = "4732";Description = "A member was added to a security-enabled local group"}
    New-Object PSObject -Property @{EventID = "4733";Description = "A member was removed from a security-enabled local group"}
    New-Object PSObject -Property @{EventID = "4734";Description = "A security-enabled local group was created"}
    New-Object PSObject -Property @{EventID = "4735";Description = "A security-enabled local group was changed"}
    New-Object PSObject -Property @{EventID = "4737";Description = "A security-enabled global group was changed"}
    New-Object PSObject -Property @{EventID = "4754";Description = "A security-enabled universal group was created"}
    New-Object PSObject -Property @{EventID = "4755";Description = "A security-enabled universal group was changed"}
    New-Object PSObject -Property @{EventID = "4756";Description = "A member was added to a security-enabled universal group"}
    New-Object PSObject -Property @{EventID = "4757";Description = "A member was removed to a security-enabled universal group"}
    New-Object PSObject -Property @{EventID = "4758";Description = "A security-enabled uiversal group was deleted"}
    New-Object PSObject -Property @{EventID = "4764";Description = "A group type was change"}
    New-Object PSObject -Property @{EventID = "4744";Description = "A security-disabled local group was created"}
    New-Object PSObject -Property @{EventID = "4745";Description = "A security-disabled local group was changed"}
    New-Object PSObject -Property @{EventID = "4746";Description = "A member was added to a security-disabled local group"}
    New-Object PSObject -Property @{EventID = "4747";Description = "A member was removed to a security-disabled local group"}
    New-Object PSObject -Property @{EventID = "4748";Description = "A security-disabled local group was deleted"}
    New-Object PSObject -Property @{EventID = "4749";Description = "A security-disabled global group was created"}
    New-Object PSObject -Property @{EventID = "4750";Description = "A security-disabled global group was changed"}
    New-Object PSObject -Property @{EventID = "4751";Description = "A member was added to a security-disabled global group"}
    New-Object PSObject -Property @{EventID = "4752";Description = "A member was removed to a security-disabled global group"}
    New-Object PSObject -Property @{EventID = "4753";Description = "A security-disabled global group was deleted"}
    New-Object PSObject -Property @{EventID = "4759";Description = "A security-disabled universal group was created"}
    New-Object PSObject -Property @{EventID = "4760";Description = "A security-disabled universal group was changed"}
    New-Object PSObject -Property @{EventID = "4761";Description = "A member was added to a security-disabled universal group"}
    New-Object PSObject -Property @{EventID = "4762";Description = "A member was removed to a security-disabled universal group"}
    New-Object PSObject -Property @{EventID = "4763";Description = "A security-disabled universal group was deleted"}
)
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

#Getting the oldest security event log entry to see how old it is.
Log -Text "Getting the oldest security event log entry to see how old it is"
Try {
    $Oldest = (Get-Date) - (Get-WinEvent -LogName Security -Oldest -MaxEvents 1 | Select-Object TimeCreated -ExpandProperty TimeCreated) | Select-Object Days,Hours,Minutes 
}
Catch {
    Log -Text "An error occured during Getting the oldest security event log entry"
    Log -Text "$($PSItem.Exception.Message)" -Error
}

#Adding "Active Directory History" section title to output file.
Log -Text 'Adding "Active Directory History" section title to output file'
Try {
    Add-Content $Output "Active Directory History"
    Add-Content $Output "------------------------"
} 
Catch {
    Log -Text 'An error occured when adding "Active Directory History" section title to output file' -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
}

#Adding security event log history to output file.
Log -Text 'Adding security event log history to output file'
Try {
    If ($Null -ne $Oldest) {
        Add-Content $Output "Days     : $($Oldest.Days)"
        Add-Content $Output "Hours    : $($Oldest.Hours)"
        Add-Content $Output "Minutes  : $($Oldest.Minutes)"
    }
    Else {
        Add-Content $Output "Unable to get information about the security event log history"
    }
} 
Catch {
    Log -Text 'An error occured when adding security event log history to output file' -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
}

#Adding "Active Directory Changes" section title to output file.
Log -Text 'Adding "Active Directory Changes" section title to output file'
Try {
    Add-Content $Output ""
    Add-Content $Output "Active Directory Changes"
    Add-Content $Output "------------------------"
} 
Catch {
    Log -Text 'An error occured when adding "Active Directory Changes" section title to output file' -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
}

#Getting all events related to change in Active Directory.
Log -Text "Getting all events related to change in Active Directory"
Try {
    [Array]$ActiveDirectoryChangesEvents =  Get-EventLog -LogName Security | Where-Object {$ActiveDirectoryChanges.EventID -contains $_.InstanceID}
}
Catch {
    Log -Text "An error occured during getting all events related to change in Active Directory" -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
}

#Creating a table containing a list of all Active Directory changes.
$Result = @()
If ($Null -ne $ActiveDirectoryChangesEvents) {

    Log -Text "Active Directory changes was found in the security event log"
    Log -Text "Creating a table containing a list of all Active Directory changes"

    ForEach ($Event in $ActiveDirectoryChangesEvents){
        
        $Object = "" | Select-Object Time,
                                     Description,
                                     Object
        $Object.Time = $Event.TimeGenerated
        $Object.Description = $ActiveDirectoryChanges | Where-Object {$_.EventID -eq $Event.InstanceId} | Select-Object Description -ExpandProperty Description
        #Line 10 in the message should display the information "Account Name:" follow by the object name.
        #This is why we will extract the second part of that line to know which object was affected.
        $Object.Object = ((($Event.Message -split '\n')[10]).Split(":") | Select-Object -Last 1).Trim()
        $Result += $Object
    }
}
Else {
    Try {
        Log -Text "No Active Directory changes was found in the security event log"
        Add-Content $Output "No Active Directory changes was found in the security event log"
    }
    Catch {
        Log -Text "An error occured during adding information to output file" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
    }
}

#Adding Active Directory changes to output file.
Log -Text "Adding Active Directory changes to output file"
If ($Null -ne $Result) {
    Try {
        $Result| Format-Table -AutoSize | Out-File -FilePath $Output -Append -Encoding utf8
    }
    Catch {
        Log -Text "An error occured during adding Active Directory changes to output file" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
    }
}

Log -Text "Script end"
