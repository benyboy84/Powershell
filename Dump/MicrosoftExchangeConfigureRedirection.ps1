# *******************************************************************************
# Script to configure mail forwarding.
#
# This script need Microsoft Exchange Management Snap In.
# This scirpt must be run with a user having the appropriate rights to mailbox.
# This script must be run on an Exchange server.
# This script need a CSV.
#
#    CSV file with the username and email address to add.
#    Example:
#    DISPLAY_NAME,USERNAME,EMAIL_FORWARD_TO
#    Benoit Blais,blab0270,Benoit_Blais@cascades.com
#
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2019-12-04  Benoit Blais        Creation
# *******************************************************************************

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION
$CSVFile = "User.csv"                                    # CSV file containing the username.

# *******************************************************************************

$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1
$TimeStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Logs = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).log"
$Export = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).csv"
$CSVPath = "$($ScriptPath)\$($CSVFile)"
$Id = 1
$Count1 = 0
$ExportCSV = @()

# *******************************************************************************

# Start script
Out-File -FilePath $Logs -InputObject "--------------------------------------------------" 
Out-File -FilePath $Logs -InputObject "SCRIPT BEGIN" -Append
Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
Out-File -FilePath $Logs -InputObject "" -Append

$ErrorActionPreference = "stop"

# Validate if Microsoft.Exchange.Management.PowerShell.SnapIn is loaded
If (! (Get-PSSnapin -Registered Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction:SilentlyContinue) ) {
  Try {	
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
    Out-File -FilePath $Logs -InputObject "INFO  : Microsoft Exchange Management SnapIn successfully loaded" -Append
  }
  Catch {
    Out-File -FilePath $Logs -InputObject "ERROR : Unable to load Microsoft Exchange Management SnapIn" -Append
    Out-File -FilePath $Logs -InputObject "" -Append
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Out-File -FilePath $Logs -InputObject "SCRIPT END" -Append
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Exit
  }
}
Else {
  Out-File -FilePath $Logs -InputObject "INFO  : Microsoft Exchange Management SnapIn already loaded" -Append
}

# Validate if CSV file exist.
If (Test-Path -Path $CSVPath) {
  Try {
    $CSV = Import-CSV -Path $CSVPath
    $TotalEntries = Import-CSV -Path $CSVPath | Measure-Object
    Out-File -FilePath $Logs -InputObject "INFO  : Read input file: $($CSVPath)" -Append
    }
  Catch {
    Out-File -FilePath $Logs -InputObject "ERROR : unable to read input file: $($CSVPath)" -Append
    Out-File -FilePath $Logs -InputObject "" -Append
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Out-File -FilePath $Logs -InputObject "SCRIPT END" -Append
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Exit
  }
}
else {
  Out-File -FilePath $Logs -InputObject "ERROR : unable to find input file: $($CSVPath)" -Append
  Out-File -FilePath $Logs -InputObject "" -Append
  Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
  Out-File -FilePath $Logs -InputObject "SCRIPT END" -Append
  Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
  Exit
}

# Loop through each line of the CSV file
ForEach ($Line in $CSV) { 

  Write-Progress -Id $Id -Activity "Configure Email Forward..." -Status "Editing $($Count1) of $($TotalEntries.count): User - $($line.DISPLAY_NAME)"  -PercentComplete ($Count1/$TotalEntries.count*100)

  $Temp = "" | Select-Object DISPLAY_NAME,EMAIL_FORWARD_TO,STATUS
  $Temp.DISPLAY_NAME = $Line.DISPLAY_NAME
  $Temp.EMAIL_FORWARD_TO = $Line.EMAIL_FORWARD_TO
  

  Try {
    $Name = "$($Line.DISPLAY_NAME) (Cascades)"
    $Alias = $Name -replace '\s',''
    $Alias = $Alias -replace '\(',''
    $Alias = $Alias -replace '\)',''
    #New-MailContact -Name $Name -Alias $Alias -ExternalEmailAddress $Line.EMAIL_FORWARD_TO
    #Set-MailContact $Name  -HiddenFromAddressListsEnabled $true
    Out-File -FilePath $Logs -InputObject "INFO  : MailContact created for $($Name) with Alias $($Alias)" -Append
    Try {
      #Set-Mailbox -Identity $Line.USERNAME -DeliverToMailboxAndForward $false -ForwardingAddress $Line.EMAIL_FORWARD_TO 
      Out-File -FilePath $Logs -InputObject "INFO  : Forwarding configure for $($Line.DISPLAY_NAME)" -Append
      $Temp.STATUS = "SUCCESS"
    }
    Catch {
      Out-File -FilePath $Logs -InputObject "ERROR : Unable to configure forwarding for $($Line.DISPLAY_NAME)" -Append
      $Temp.STATUS = "ERROR"
    }
  }
  Catch {
    Out-File -FilePath $Logs -InputObject "ERROR : Unable to create MailContact for $($Name) with Alias $($Alias)" -Append
    $Temp.STATUS = "ERROR"
  }

  $ExportCSV += $Temp 
}

Out-File -FilePath $Logs -InputObject "" -Append
Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
Out-File -FilePath $Logs -InputObject "SCRIPT END" -Append
Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append

$ExportCSV | Export-CSV -Path $Export -NoTypeInformation