# *******************************************************************************
# Script to add a proxy email adress to a mailbox.
#
# This script need Active Directory module.
# This scirpt must be run with a user having the appropriate rights to edit user.
# This script must be run on an Active Directory domain member.
# This script need a CSV.
#
#    CSV file with the username and email address to add.
#    Example:
#    USERNAME,EMAILTOADD
#    Benoit Blais,BBlais@Cascades.com
#
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2019-12-03  Benoit Blais        Creation
# *******************************************************************************

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION
$CSVFile = "User.csv"                                    # CSV file containing the username and the email address to add.

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

# Validate if Active Directory module is loaded.
If (Get-Module | Where-Object {$_.Name -eq "ActiveDirectory"}) {
  Out-File -FilePath $Logs -InputObject "INFO  : Active Directory module is already imported" -Append
}
Else {
  # If module is not imported, but available on disk then import
  If (Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"}) {
    Try {
      Import-Module "ActiveDirectory" -Verbose
      Out-File -FilePath $Logs -InputObject "INFO  : Active Directory module import successfully" -Append
    }
    Catch {
      Out-File -FilePath $Logs -InputObject "ERROR : Unable to import Active Directory module" -Append
      Out-File -FilePath $Logs -InputObject "" -Append
      Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
      Out-File -FilePath $Logs -InputObject "SCRIPT END" -Append
      Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
      Exit
    }
  }
  Else{
    Out-File -FilePath $Logs -InputObject "ERROR : Active Directory module not available" -Append
    Out-File -FilePath $Logs -InputObject "" -Append
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Out-File -FilePath $Logs -InputObject "SCRIPT END" -Append
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Exit
  }
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

  Write-Progress -Id $Id -Activity "Add Email Address..." -Status "Editing $($Count1) of $($TotalEntries.count): User - $($line.USERNAME)"  -PercentComplete ($Count1/$TotalEntries.count*100)

  $Temp = "" | Select-Object USERNAME,EMAILTOADD,STATUS
  $Temp.USERNAME = $Line.USERNAME
  $Temp.EMAILTOADD = $Line.EMAILTOADD
  
  Try {
    $SMTP = "smtp:$($Line.EMAILTOADD)"
    Set-AdUser $Line.USERNAME -Add @{Proxyaddresses="$SMTP" }
    Out-File -FilePath $Logs -InputObject "INFO  : Set Proxy Address for $($Line.USERNAME)" -Append
    $Temp.STATUS = "SUCCESS"
  }
  Catch {
    Out-File -FilePath $Logs -InputObject "ERROR : Unable to set Proxy Address for $($Line.USERNAME)" -Append
    $Temp.STATUS = "ERROR"
  }

  $ExportCSV += $Temp 
}

Out-File -FilePath $Logs -InputObject "" -Append
Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
Out-File -FilePath $Logs -InputObject "SCRIPT END" -Append
Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append

$ExportCSV | Export-CSV -Path $Export -NoTypeInformation