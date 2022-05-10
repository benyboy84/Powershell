#**********************************************************************************
# Script to find all information regarding Active Directory.
#
# This script will generate text file with all the collected information and
# a log file with the information related to the script execution.
#
# If you need to troubleshoot the script, you can enable the Debug option in
# the parameter. This will generate display information on the screen.
#
# IMPORTANT: This script needs to be run directly on a Domain Controller.
#
# ==================================================================================
# 
# Date        By                  Modification
# ----------  ------------------  --------------------------------------------------
# 2022-02-14  Benoit Blais        Original version
# **********************************************************************************

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

#EventViewer related to Domain Controller
$ADEventLog = @("Active Directory Web Services","Application","DFS Replication","Directory Service","DNS Server","System")

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
    Try {Add-Content $Log "$(Get-Date) | $Text"} Catch {$Null}
}

# **********************************************************************************

Log -Text "Script Begin"

#Delete output file or text file if already exist.
Log -Text "Validating if output or log file already exist"
If (Get-ChildItem -Path $ScriptPath | Where-Object {($_.Name -match "$($ScriptName)") -and ($_.Name -notmatch "$($ScriptName).ps1") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).log") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).txt")}){
    #Old file exist, we will try to delete it.
    Log -Text "Deleting old output and log file"
    Try {
        Get-ChildItem -Path $ScriptPath | Where-Object {($_.Name -match "$($ScriptName)") -and ($_.Name -notmatch "$($ScriptName).ps1") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).log") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).txt")} | Remove-Item
    }
    Catch {
        Log -Text "An error occured when deleting old output and log file"
    }
}

#Adding "Event Log Analysis" to output file.
Log -Text 'Adding "Event Log Analysis" to output file'
Try {
    Add-Content $Output "Event Log Analysis"
    Add-Content $Output "------------------"
} 
Catch {
    Log -Text 'An error occured when adding "Event Log Analysis" to output file' -Error
}

#Get list of event logs.
Log -Text "Getting a list of event logs"
Try {
    $EventLogs = Get-EventLog -List
}
Catch {
    Log -Text "An error occured during getting a list of event logs"
}

#Loop through each evant log and if it's related to Active Directory, get Error and Warning statistics.
Log -Text "Loop through each evant log to get statistics"
ForEach ($Log in $EventLogs ){

    #We only take care of the logs related to Active Directory
    If ($ADEventLog -contains $Log.log) {

        #Getting all errors in the last month
        Log -Text "Getting all errors in the last month for $($Log.log)"
        Try {
            [Array]$ErrorEvents = Get-EventLog -LogName $Log.log -EntryType Error -After (Get-Date).AddMonths(-1)
        }
        Catch {
            [Array]$ErrorEvents = $Null
            Log -Text "An error occured during getting all errors in the last month for $($Log.log)" -Error
        }

        #Adding event log to output file.
        Log -Text "Adding $($Log.log) to output file"
        Try {
            Add-Content $Output "$($Log.log) Error(s): $($ErrorEvents.Count)"
        } 
        Catch {
            Log -Text "An error occured when adding $Log.log to output file" -Error
        }

        #Create an array of differents sources events.
        Log "Creating an array of differents sources events for $($Log.log)"
        [Array]$SourceErrorEvents = $ErrorEvents | Sort-Object -Property Source -Unique | Select-Object Source

        #If one or more sources of error exist, we will validate each of them in order to calculate the number of events. 
        If ($SourceErrorEvents.Count -gt 0) {
            
            ForEach ($SourceErrorEvent in $SourceErrorEvents) {
                
                #Get all events related to that source event.
                Log -Text "Getting a list of events with source $($SourceErrorEvent.Source)"
                [Array]$Events =  $ErrorEvents | Where-Object {$_.Source -eq $SourceErrorEvent.Source}
                
                #Adding source event to output file.
                Log -Text "Adding $($SourceErrorEvent.Source) to output file"
                Try {
                    Add-Content $Output "Source Event $($SourceErrorEvent.Source): $($Events.Count)"
                } 
                Catch {
                    Log -Text "An error occured when adding $($SourceErrorEvent.Source) to output file" -Error
                }

                #If more then five event exist, we will on ly list the newest five.
                If ($Events.Count -gt 5) {
                    Log -Text "Writing $($SourceErrorEvent.Source) events to output file"
                    Try {
                        $Events | Select-Object -First 5 | Out-File -FilePath $Output -Append -Encoding utf8
                    }
                    Catch {
                        "An error occured when writing $($SourceErrorEvent.Source) events to output file"
                    }
                }
                Else {
                    Log -Text "Writing $($SourceErrorEvent.Source) events to output file"
                    Try {
                        $Events | Select-Object -First $Events.Count | Out-File -FilePath $Output -Append -Encoding utf8
                    }
                    Catch {
                        "An error occured when writing $($SourceErrorEvent.Source) events to output file"
                    }
                }
            }

        }

        #Getting all warnings in the last month
        Log -Text "Getting all warnings in the last month for $($Log.log)"
        Try {
            [Array]$WarningEvents = Get-EventLog -LogName $Log.log -EntryType Warning -After (Get-Date).AddMonths(-1)
        }
        Catch {
            [Array]$WarningEvents = $Null
            Log -Text "An error occured during getting all warnings in the last month for $($Log.log)" -Error
        }

        #Adding event log to output file.
        Log -Text "Adding $Log.log to output file"
        Try {
            Add-Content $Output "$($Log.log) Warning(s): $($WarningEvents.Count)"
        } 
        Catch {
            Log -Text "An error occured when adding $Log.log to output file" -Error
        }

        #Create an array of differents sources events.
        Log "Creating an array of differents sources events for $($Log.log)"
        [Array]$SourceWarningEvents = $WarningEvents | Sort-Object -Property Source -Unique | Select-Object Source

        #If one or more sources of Warning exist, we will validate each of them in order to calculate the number of events. 
        If ($SourceWarningEvents.Count -gt 0) {
            
            ForEach ($SourceWarningEvent in $SourceWarningEvents) {
                
                #Get all events related to that source event.
                Log -Text "Getting a list of events with source $($SourceWarningEvent.Source)"
                [Array]$Events =  $WarningEvents | Where-Object {$_.Source -eq $SourceWarningEvent.Source}
                
                #Adding source event to output file.
                Log -Text "Adding $($SourceWarningEvent.Source) to output file"
                Try {
                    Add-Content $Output "Source Event $($SourceWarningEvent.Source): $($Events.Count)"
                } 
                Catch {
                    Log -Text "An error occured when adding $($SourceWarningEvent.Source) to output file" -Error
                }

                #If more then five event exist, we will on ly list the newest five.
                If ($Events.Count -gt 5) {
                    Log -Text "Writing $($SourceWarningEvent.Source) events to output file"
                    Try {
                        $Events | Select-Object -First 5 | Out-File -FilePath $Output -Append -Encoding utf8
                    }
                    Catch {
                        "An error occured when writing $($SourceWarningEvent.Source) events to output file"
                    }
                }
                Else {
                    Log -Text "Writing $($SourceWarningEvent.Source) events to output file"
                    Try {
                        $Events | Select-Object -First $Events.Count | Out-File -FilePath $Output -Append -Encoding utf8
                    }
                    Catch {
                        "An error occured when writing $($SourceWarningEvent.Source) events to output file"
                    }
                }
            }

        }

    }
}

#Adding "Active Directory Changed" to output file.
Log -Text 'Adding "Active Directory Changed" to output file'
Try {
    Add-Content $Output ""
    Add-Content $Output "Active Directory Changed"
    Add-Content $Output "------------------------"
} 
Catch {
    Log -Text 'An error occured when adding "Active Directory Changed" to output file' -Error
}

#Getting the oldest entry in the security log to know how old it is.
Log -Text "Getting the oldest entry in the security log"
Try {
    $Oldest = (Get-Date) - (Get-WinEvent -LogName Security -Oldest -MaxEvents 1 | Select-Object TimeCreated -ExpandProperty TimeCreated) | Select-Object Days,Hours,Minutes 
}
Catch {
    Log -Text "An error occured during getting the oldest entry in the security log "
}

#Adding Security Event Log history to output file.
Log -Text 'Adding "Security Event Log history" to output file'
Try {
    Add-Content $Output "Days     : $($Oldest.Days)"
    Add-Content $Output "Hours    : $($Oldest.Hours)"
    Add-Content $Output "Minutes  : $($Oldest.Minutes)"
} 
Catch {
    Log -Text 'An error occured when adding "Security Event Log history" to output file' -Error
}

#Getting all events related to Active Directory changes.
Log -Text "Getting all events related to Active Directory changes"
Try {
    $ActiveDirectoryChangesEvents =  Get-EventLog -LogName Security | Where-Object {$ActiveDirectoryChanges.EventID -contains $_.InstanceID}
}
Catch {
    Log -Text "An error occured during getting all events related to Active Directory changes" -Error
}

#Creating a table containing a list of all Active Directory changes.
$Result = @()
Log -Text "Creating a table containing a list of all Active Directory changes"
ForEach ($Event in $ActiveDirectoryChangesEvents){
    
    $Object = "" | Select-Object Time,
                                 Description,
                                 Object
    $Object.Time = $Event.TimeGenerated
    $Object.Description = $ActiveDirectoryChanges | Where-Object {$_.EventID -eq $Event.InstanceId} | Select-Object Description -ExpandProperty Description
    $Object.Object = ((($Event.Message -split '\n')[10]).Split(":") | Select-Object -Last 1).Trim()
    $Result += $Object
}
#Adding Active Directory changes to output file.
Log -Text "Adding Active Directory changes to output file"
Try {
    $Result| format-table -AutoSize | Out-File -FilePath $Output -Append -Encoding utf8
}
Catch {
    Log -Text "An error occured during adding Active Directory changes to output file" -Error
}

Log -Text "Script ended"