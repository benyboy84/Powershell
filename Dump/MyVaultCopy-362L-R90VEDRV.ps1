# *******************************************************************************
# Script to ...
#
# This script need .. :
#
# 1. 
#
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2020-01-20  Benoit Blais        Creation
# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION
$ScriptPath = "C:\Data\Script"                           # Network path where the files are saved.
$OneDriveScriptFile = "OneDriveMapper.ps1"               # OneDriveMapper script.

# *******************************************************************************

# Get script name.
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1

# Validate if the log folder exist, if not, create it.
$Logs = "$($ScriptPath)\$($ScriptName)\$($env:computername).log"

$ErrorActionPreference = "stop"

# *******************************************************************************

# Validate operating system version
$WindowsVersion = [System.Environment]::OSVersion.Version
If ($WindowsVersion.Major -eq 10) {

$env:OneDriveCommercial
$env:OneDrive
}


# Validate if the computer can reach the Cascades network.
If (Tesh-Path $ScriptPath) {

  # Validate if the log folder exist, if not, create it.
  If(!(Test-Path "$($ScriptPath)\$($ScriptName)")) { New-Item -ItemType Directory -Path "$($ScriptPath)\$($ScriptName)" }

  # Validate if drive letter is currently in use.
  If(Test-Path $DriveLetter) {
    # Validate if the drive is mapped to Cascades OneDrive
    $MappedDrive = Get-PSDrive $DriveLetter.SubString(0,1)
    If ($MappedDrive.DisplayRoot.Substring(0,28) -like $OneDrivePath) {
      
    } Else {
    # unmap drive
    }
  }


}
Else { Exit }



Function Mirror() 
{

# Get source and destination from function parameter
# $Source = "C:\MyVault"
# $Destination = "V:\" or "C:\%Username"\OneDrive - Cascades"

  Out-File -FilePath $Global:Logs -InputObject "--------------------------------------------------" -Append
  Out-File -FilePath $Global:Logs -InputObject "FILE SYNCHRONIZATION" -Append
  Out-File -FilePath $Global:Logs -InputObject "--------------------------------------------------" -Append
  Out-File -FilePath $Global:Logs -InputObject "" -Append
  Out-File -FilePath $Global:Logs -InputObject "Start time:       $(Get-Date)" -Append
  Out-File -FilePath $Global:Logs -InputObject "Source:           $($Source)" -Append
  Out-File -FilePath $Global:Logs -InputObject "Destination:      $($Destination)" -Append
  Out-File -FilePath $Global:Logs -InputObject "" -Append
  Out-File -FilePath $Global:Logs -InputObject "Files:            *.*" -Append
  Out-File -FilePath $Global:Logs -InputObject "" -Append
  Out-File -FilePath $Global:Logs -InputObject "--------------------------------------------------" -Append
  Out-File -FilePath $Global:Logs -InputObject "" -Append

  $CountTotalFiles = 0
  $CountTotalBytes = 0
  $CountNewerFiles = 0
  $CountNewerBytes = 0
  $CountSkipFiles = 0
  $CountSkipBytes = 0
  $CountCopyFiles = 0
  $CountCopyBytes = 0
  $CountFailFiles = 0
  $CountFailBytes = 0
  $CountExtraFiles = 0
  $CountExtraBytes = 0
  
  $Temp = "" | Select-Object SourceDirectory,TotalFiles,CopiedFiles,SkippedFiles,NewerFiles,FailedFiles,ExtrasFiles,
                             TotalBytes,CopiedBytes,SkippedBytes,NewerBytes,FailedBytes,ExtrasBytes,State

  Try { $SourceFiles = Get-ChildItem -Path $Source -Recurse }
  Catch {  Exit }
  $SourceFilesList = @()
  ForEach ($sFile in $SourceFiles) {
    $SourceFile = "" | Select-Object FullName,Length,LastWriteTime
    $SourceFile.FullName = $sFile.FullName.Replace($Source,"")
    $SourceFile.Length = $sFile.Length
    $SourceFile.LastWriteTime = $sFile.LastWriteTime
    $SourceFilesList += $SourceFile
  }

  Try { $TargetFiles = Get-ChildItem -Path $Destination -Recurse }
  Catch { Exit }
  $TargetFilesList = @()
  ForEach ($tFile in $TargetFiles) {
    $TargetFile = "" | Select-Object FullName,Length,LastWriteTime
    $TargetFile.FullName = $tFile.FullName.Replace($Target,"")
    $TargetFile.Length = $tFile.Length
    $TargetFile.LastWriteTime = $tFile.LastWriteTime
    $TargetFilesList += $TargetFile
  } 

  Try{ $Diff = Compare-Object -ReferenceObject $SourceFilesList -DifferenceObject $TargetFilesList -Property FullName -IncludeEqual }
  Catch {  $Diff = $Null
    Out-File -FilePath $Global:Logs -InputObject " ERROR: Unable to compare source and destination" -Append
    Out-File -FilePath $Global:Logs -InputObject "" -Append
    Exit
  }
    
  ForEach($File in $Diff) {  

    $CountTotalFiles++ 

    If ($PerentFolder -ne (Split-Path -Parent -Path ($Source + $File.FullName))) {
      $PerentFolder = Split-Path -Parent -Path ($Source + $File.FullName)
      Out-File -FilePath $Global:Logs -InputObject $PerentFolder -Append
    }

    $SourceFile = $SourceFilesList | Where-Object {$_.FullName -like $File.FullName}  
    $DestinationFile = $TargetFilesList | Where-Object {$_.FullName -eq $File.FullName}
    $CountTotalBytes += $SourceFile.Length

    If ($File.SideIndicator -eq "=="){

      Switch($SourceFile.LastWriteTime) {
        {$_ -lt $DestinationFile.LastWriteTime} { 
          $CountNewerFiles ++
          $CountNewerBytes += $SourceFile.Length
          $Output = " Newer File         "
          $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
          Out-File -FilePath $Global:Logs -InputObject "$($Output)" -Append
          Break
        }
        {$_ -like $DestinationFile.LastWriteTime} { 
          $CountSkipFiles ++
          $CountSkipBytes += $SourceFile.Length
          $Output = " Skipped File       "
          $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
          Out-File -FilePath $Global:Logs -InputObject "$($Output)" -Append
          Break
        } 
        {$_ -gt $DestinationFile.LastWriteTime} { 
          Try {
            $SourcePath = $Source + $SourceFile.FullName
            $DestinationPath = $Target + $DestinationFile.FullName
            Copy-Item -Path $SourcePath -Destination $DestinationPath
            $Output = " Copied File        "
            $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
            Out-File -FilePath $Global:Logs -InputObject "$($Output)" -Append
            $CountCopyFiles ++
            $CountCopyBytes += $SourceFile.Length
          }
          Catch {
            $Output = " FAILED             Unable to copy "
            $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
            Out-File -FilePath $Global:Logs -InputObject "$($Output)" -Append
            $CountFailFiles ++
            $CountFailBytes += $SourceFile.Length
          }
          Break
        }
      }
    }
    If (($File.SideIndicator -eq "<=")) {
        Try {
          $SourcePath = $Source + $SourceFile.FullName
          $DestinationPath = $Target + $SourceFile.FullName
          Copy-Item -Path $SourcePath -Destination $DestinationPath
          $Output = " Copied File        "
          $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
          Out-File -FilePath $Global:Logs -InputObject "$($Output)" -Append
          $CountCopyFiles ++
          $CountCopyBytes += $SourceFile.Length
        }
        Catch {
          $Output = " FAILED             Unable to copy "
          $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
          Out-File -FilePath $Global:Logs -InputObject "$($Output)" -Append
          $CountFailFiles ++
          $CountFailBytes += $SourceFile.Length
        }
      }
    If (($File.SideIndicator -eq "=>")) {
        Try {
          $DestinationPath = $Target + $DestinationFile.FullName
          Remove-Item $DestinationPath
          $Output = " Extra File         "
          $Output += $DestinationPath.Split("\") | Select-Object -Last 1
          Out-File -FilePath $Global:Logs -InputObject "$($Output)" -Append
          $CountExtraFiles ++
          $CountExtraBytes += $DestinationFile.Length
        }
        Catch {
          $Output = " FAILED             Unable to delete "
          $Output += $DestinationPath.Split("\") | Select-Object -Last 1
          Out-File -FilePath $Global:Logs -InputObject "$($Output)" -Append
          $CountFailFiles ++
          $CountFailBytes += $DestinationFile.Length
        }
      }
    }

    $Result = New-Object system.Data.DataTable

    $col1 = New-Object system.Data.DataColumn ' ',([String])
    $col2 = New-Object system.Data.DataColumn Total,([Int])
    $col3 = New-Object system.Data.DataColumn Copied,([Int])
    $col4 = New-Object system.Data.DataColumn Skipped,([Int])
    $col5 = New-Object system.Data.DataColumn Newer,([Int])
    $col6 = New-Object system.Data.DataColumn Failed,([Int])
    $col7 = New-Object system.Data.DataColumn Extras,([Int])

    $Result.columns.add($col1)
    $Result.columns.add($col2)
    $Result.columns.add($col3)
    $Result.columns.add($col4)
    $Result.columns.add($col5)
    $Result.columns.add($col6)
    $Result.columns.add($col7)

    $row = $Result.NewRow()
    $row.' ' = "Files"
    $row.Total = $CountTotalFiles
    $row.Copied = $CountCopyFiles
    $row.Skipped = $CountSkipFiles
    $row.Newer = $CountNewerFiles
    $row.Failed = $CountFailFiles
    $row.Extras = $CountExtraFiles
    $Result.Rows.Add($row)

    $row = $Result.NewRow()
    $row.' ' = "Bytes"
    $row.Total = $CountTotalBytes
    $row.Copied = $CountCopyBytes
    $row.Skipped = $CountSkipBytes
    $row.Newer = $CountNewerBytes
    $row.Failed = $CountFailBytes
    $row.Extras = $CountExtraBytes
    $Result.Rows.Add($row)

    $Temp.TotalFiles = $CountTotalFiles
    $Temp.TotalBytes = $CountTotalBytes
    $Temp.CopiedFiles = $CountCopyFiles
    $Temp.CopiedBytes = $CountCopyBytes
    $Temp.SkippedFiles = $CountSkipFiles
    $Temp.SkippedBytes = $CountSkipBytes
    $Temp.NewerFiles = $CountNewerFiles
    $Temp.NewerBytes = $CountNewerBytes
    $Temp.FailedFiles = $CountFailFiles
    $Temp.FailedBytes = $CountFailBytes
    $Temp.ExtrasFiles = $CountExtraFiles
    $Temp.ExtrasBytes = $CountExtraBytes

    Out-File -FilePath $Global:Logs -InputObject "" -Append
    Out-File -FilePath $Global:Logs -InputObject "--------------------------------------------------" -Append
    $Result | Format-Table -AutoSize | Out-File -FilePath $Logs -Append
    Out-File -FilePath $Global:Logs -InputObject "End time:       $(Get-Date)" -Append
    Out-File -FilePath $Global:Logs -InputObject "" -Append



    $Temp.State = "COMPLETED"
    $ExportCSV += $Temp 

  }

# *******************************************************************************

# Start script
Out-File -FilePath $Logs -InputObject "--------------------------------------------------" 
Out-File -FilePath $Logs -InputObject "SCRIPT BEGIN" -Append
Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
Out-File -FilePath $Logs -InputObject "" -Append

$ErrorActionPreference = "stop"

# Validate if CSV file exist.
If (Test-Path -Path $CSVPath) {
  Try {
    $CSV = Import-CSV -Path $CSVPath
    $TotalEntries = Import-CSV -Path $CSVPath | Measure-Object
    Out-File -FilePath $Logs -InputObject "Read input file: $($CSVPath)" -Append
    Out-File -FilePath $Logs -InputObject "" -Append
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

# Validate Windows Version.
# Get windows version
# If windows 10
# Get HKEY_CURRENT_USER\Software\Microsoft\OneDrive\Accounts\Business1\cid to find the user ID
# validate if C:\Users\bbla00326a\AppData\Local\Microsoft\OneDrive\settings\Business1\userid.ini exist
# Open the file and find line with https://cascades-my.sharepoint.com/personal/
#Find path C:\...
# Validate if path exist
# Start Mirro

# If windows 7


# Validate if drive letter is currently in use.
If(Test-Path $DriveLetter) {
  $Loop = 0
  Do {
    Try{$Del = NET USE $DriveLetter.SubString(0,2) /DELETE /Y 2>&1}Catch{$Null}
    $Loop ++
  } While ((Test-Path $DriveLetter) -and ($Loop -lt 5))
  If ($Loop -eq 5) {
    Out-File -FilePath $Logs -InputObject "ERROR : unable to unmap drive $($DriveLetter)" -Append
    Out-File -FilePath $Logs -InputObject "" -Append
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Out-File -FilePath $Logs -InputObject "SCRIPT END" -Append
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Exit
  }
}

  # Call OneDriveMapper to map the OneDrive.
  $URL = $line.ONEDRIVEURL
  $ScriptBlock = [ScriptBlock]::Create("$OneDriveScriptPathShort -O365 $O365CustomerName -URL $URL -account $UserName -password $Password")
  $Invoke = Invoke-Command -ScriptBlock $ScriptBlock

   If(Test-Path $DriveLetter) {
   #Call mirror
   }

       # Validate if drive letter is currently in use.
    If(Test-Path $DriveLetter) {
      $Loop = 0
      Do {
        Try{$Del = NET USE $DriveLetter.SubString(0,2) /DELETE /Y 2>&1}Catch{$Null}
        $Loop ++
      } While ((Test-Path $DriveLetter) -and ($Loop -lt 5))
      If ($Loop -eq 5) {
        Out-File -FilePath $Logs -InputObject "ERROR : unable to unmap drive $($DriveLetter)" -Append
        Out-File -FilePath $Logs -InputObject "" -Append
        Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
        Out-File -FilePath $Logs -InputObject "SCRIPT END" -Append
        Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
        $Temp.State = "ERROR"
        $ExportCSV += $Temp
        ExitScript
      }
    }



  


 



 
  
    

ExitScript