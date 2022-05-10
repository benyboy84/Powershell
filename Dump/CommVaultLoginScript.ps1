# *******************************************************************************
# Script to create a scueduled task on the computer to run a PowerShell script.
# The PoewrShell copie will be use to migrate data from C:\MyVault to Cascades
# OneDrive \ MyVault folder. With that in place, we will be able to remove the
# CommVault solution used to backup user's laptop.
# 
# This is the requirement of this script 
#
# 1. The script need the PowerShell script to migrate the data from MyVault to 
#    OneDrive in the same folfer as the script.
#
# 2. This script a CSV file containing the user laptop name and the username
#    Ex: ComputerName,User,ScheduledTaskCreation,MigrationComplete
#        Laptop1,boba00123a
#
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2020-01-20  Benoit Blais        Creation
# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION

$ScriptPath = "C:\Data\Script"                           # Network path where the files are saved.
$CSVFile = "UserVsLaptop.csv"                            # CSV file containing the laptop name and the owner.
$PowerShellScript = "MyVaultCopy.ps1"                    # Name of the script for the MyVault copy to OneDrive without Extension.

# *******************************************************************************

# Get script name.
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1

# Validate if the log folder exist, if not, create it.
If(!(Test-Path "$($ScriptPath)\$($ScriptName)")) { New-Item -ItemType Directory -Path "$($ScriptPath)\$($ScriptName)" }
$Logs = "$($ScriptPath)\$($ScriptName)\$($env:computername).log"

# Build CSV path.
$CSVPath = "$($ScriptPath)\$($CSVFile)"

$ErrorActionPreference = "stop"

# *******************************************************************************

# Validate if CSV file exist.
If (Test-Path -Path $CSVPath) {
  Try { $CSV = Import-CSV -Path $CSVPath } Catch { Exit }
} Else { Exit }

# Validating if the laptop is backup by the CommVault solution.
If ($CSV | Where {($_.ComputerName -eq $env:computername) -and ($_.ScheduledTaskCreation -ne $Null)}){


  $User = $CSV | Where {$_.ComputerName -eq $env:computername}
  # Validating if the current user is the laptop proprietary.
  If ($User.User -like $env:UserName) {
  
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Out-File -FilePath $Logs -InputObject "SCRIPT BEGIN" -Append
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | INFO  : Laptop User: $($User.User)" -Append
  
    $DestinationPath = [System.Environment]::GetEnvironmentVariable('TEMP','Machine')
    $SourcePath = "$($ScriptPath)\$($PowerShellScript)"

    # Copy of the powershell script in C:\Windows\Temp
    Try {
      Copy-Item -Path $SourcePath -Destination $DestinationPath
      Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | INFO  : $($CopyScript).ps1 copied in $($DestinationPath)" -Append
    }

    Catch {
      Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | ERROR : Unable to copy $($CopyScript).ps1 copied in $($DestinationPath)" -Append
      Exit
    } 

    # Create scheduled task to run the CommVault migration script.
    Try {
      $command = "PowerShell -WindowStyle Hidden -ExecutionPolicy unrestricted $($DestinationPath)\$($PowerShellScript)"
      @(SCHTASKS /CREATE /SC daily /MO 1 /ST 08:00 /RI 60 /DU 12:00 /TN "MyTasks\CommVaultMigration" /TR "$($command)" /F)
      @(SCHTASKS /Run /TN "MyTasks\CommVaultMigration")
      Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | INFO  : Scheduled task CommVaultMigration created" -Append
    }

    Catch {
      Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | ERROR : Unable to create CommVaultMigration scheduled task" -Append
      Exit
    }
  
    #Edit CSV file to add result of this script.
    ForEach ($Line in $CSV) {
      If ($Line.ComputerName -eq $env:computername) {
        $Line.ScheduledTaskCreation = "Success"
      }
    }  
    $SaveFile = $False
    While (-not $SaveFile){
      Try {
        $CSV | Export-Csv $CSVPath -NoTypeInformation
        $SaveFile = $True
        Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | INFO  : Edit $($CSVPath)" -Append
        Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
        Out-File -FilePath $Logs -InputObject "SCRIPT END" -Append
        Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
      }
      Catch {
        Start-Sleep -Seconds 2
        $max++
        If($Max -gt "10"){
          Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | ERROR : Unable to edit $($CSVPath)" -Append
          Break
        }
      }
    } 
  }
}