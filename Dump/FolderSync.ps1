# *******************************************************************************
# Script to mirror a local folder to OneDrive.
#
# This script need three things:
#
# 1. CSV file with the source folder and destination user in URL.
#    Example:
#    DIRECTORY,ONEDRIVEURL
#    F:\UserShares\bbla00326a,https://cascadest-my.sharepoint.com/personal/benoit_blais_cascades_com
#
# 2. OneDriveMapper.ps1 (*The path cannot contains space)
#    We use the version 3.20 of the script.
#    This file need to be modified to use a Sharepoint Administrator account and
#    accept a parameter for the URL.
#    
#    param(
#       [String]$O365,
#       [String]$URL,
#       [String]$account,
#       [String]$password
#    )
#    if($O365 -ne $null){
#        $O365CustomerName  = $O365                     #This should be the name of your tenant (example, ogd as in ogd.onmicrosoft.com) 
#    }else{
#        abort_OM
#    }
#    if (($URL -ne $null) -and ($account -ne $null) -and ($password -ne $null)){
#        $desiredMappings =  @(
#            @{"displayName"="Onedrive Cascades";"targetLocationType"="driveletter";"targetLocationPath"="V:";"sourceLocationPath"="$URL";"mapOnlyForSpecificGroup"=""}
#        )
#        $forceUserName     = $account                  #if anything is entered here, userLookupMode is ignored
#        $forcePassword     = $password                 #if anything is entered here, the user won't be prompted for a password. This function is not recommended, as your password could be stolen from this file 
#    }else{
#        abort_OM
#    }
#    $showProgressBar       = $False
#     
#    We also comment all log information to avoid having multiple text file and
#    screen output. 
#
# 3. Passowrd file and Encryption file for password.
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2019-11-14  Benoit Blais        Creation
# *******************************************************************************

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION
$CSVFile = "Mapping User.csv"                            # CSV file containing the source folder and the destination user URL.
$OneDriveScriptFile = "OneDriveMapper.ps1"               # OneDriveMapper script.
$UserName = "benoit_blais@cascadestest1.onmicrosoft.com" # Sharepoint tenant administrator.
$PasswordFile = "Password.txt"                           # Text file with 
$EncryptionKeyFile = "AES.key"                           # AES Key file to descript credentials.
$O365CustomerName = "Cascadestest1"                      # This should be the name of your tenant (example, ogd as in ogd.onmicrosoft.com) 
$DriveLetter = "V:\"                                     # The drive letter used by OneDriveScript.
$ExcludeFolder = @("V:\Documents\Forms")                 # Folder to exclude from the sync.

# *******************************************************************************

Function Get-PlainText()
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.Security.SecureString]$SecureString
	)
	BEGIN { }
	PROCESS
	{
		$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString);

		Try
		{
			Return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr);
		}
		Finally
		{
			[Runtime.InteropServices.Marshal]::FreeBSTR($bstr);
		}
	}
	END { }
}

Function ExitScript() 
{
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Out-File -FilePath $Logs -InputObject "SCRIPT END" -Append
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    $Global:ExportCSV | Export-CSV -Path $Global:Export -NoTypeInformation
    Exit
}

# *******************************************************************************

$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1
$TimeStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Logs = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).log"
$Export = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).csv"
$CSVPath = "$($ScriptPath)\$($CSVFile)"
$OneDriveScriptPath = "$($ScriptPath)\$($OneDriveScriptFile)"
$SFSO = New-Object -ComObject Scripting.FileSystemObject 
$OneDriveScriptPathShort = $SFSO.GetFile($($OneDriveScriptPath)).ShortPath 
$PasswordPath = "$($ScriptPath)\$($PasswordFile)"
$EncryptionKeyPath = "$($ScriptPath)\$($EncryptionKeyFile)"
$Password = Get-Content $PasswordPath | ConvertTo-SecureString -Key (Get-Content $EncryptionKeyPath)
$Password = Get-PlainText $Password 
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

# Loop through each line of the CSV file
ForEach ($Line in $CSV) { 
  
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
  $Count1++

  Write-Progress -Id $Id -Activity "Comparing folder..." -Status "Checking $($Count1) of $($TotalEntries.count): Source Folder - $($line.DIRECTORY)"  -PercentComplete ($Count1/$TotalEntries.count*100)
  Write-Progress -Id ($Id + 1) -Activity "Mapping Drive..." -Status "In progress..."  -PercentComplete 0

  # Call OneDriveMapper to map the OneDrive.
  $URL = $line.ONEDRIVEURL
  $ScriptBlock = [ScriptBlock]::Create("$OneDriveScriptPathShort -O365 $O365CustomerName -URL $URL -account $UserName -password $Password")
  $Invoke = Invoke-Command -ScriptBlock $ScriptBlock

  If(Test-Path $DriveLetter) {

    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Out-File -FilePath $Logs -InputObject "FILE SYNCHRONIZATION" -Append
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Out-File -FilePath $Logs -InputObject "" -Append

    $Temp = "" | Select-Object SourceDirectory,TotalFiles,CopiedFiles,SkippedFiles,NewerFiles,FailedFiles,ExtrasFiles,
                               TotalBytes,CopiedBytes,SkippedBytes,NewerBytes,FailedBytes,ExtrasBytes,State
    $PerentFolder = ""
    $Source = $line.DIRECTORY 
    $Temp.SourceDirectory = $line.DIRECTORY
    $Target = "$($DriveLetter)Documents" 
    $Count2 = 0

    Out-File -FilePath $Logs -InputObject "Start time:       $(Get-Date)" -Append
    Out-File -FilePath $Logs -InputObject "Source:           $($Source)" -Append
    Out-File -FilePath $Logs -InputObject "Destination:      $($DriveLetter) ($($line.ONEDRIVEURL))" -Append
    Out-File -FilePath $Logs -InputObject "" -Append
    Out-File -FilePath $Logs -InputObject "Files:            *.*" -Append
    Out-File -FilePath $Logs -InputObject "" -Append
    Out-File -FilePath $Logs -InputObject "Exclude folder:   $ExcludeFolder" -Append
    Out-File -FilePath $Logs -InputObject "" -Append
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Out-File -FilePath $Logs -InputObject "" -Append

    $SourceFiles = Get-ChildItem -Path $Source -Recurse
    $SourceFilesList = @()
    ForEach ($sFile in $SourceFiles) {
      If (($ExcludeFolder -NotContains (Split-Path -Parent -Path $sFile.FullName)) -and ($ExcludeFolder -NotContains $sFile.FullName)){
        $SourceFile = "" | Select-Object FullName,Length,LastWriteTime
        $SourceFile.FullName = $sFile.FullName.Replace($Source,"")
        $SourceFile.Length = $sFile.Length
        $SourceFile.LastWriteTime = $sFile.LastWriteTime
        $SourceFilesList += $SourceFile
      }
    }

    $TargetFiles = Get-ChildItem -Path $Target -Recurse
    $TargetFilesList = @()
    ForEach ($tFile in $TargetFiles) {
      If (($ExcludeFolder -NotContains (Split-Path -Parent -Path $tFile.FullName)) -and ($ExcludeFolder -NotContains $tFile.FullName)){
        $TargetFile = "" | Select-Object FullName,Length,LastWriteTime
        $TargetFile.FullName = $tFile.FullName.Replace($Target,"")
        $TargetFile.Length = $tFile.Length
        $TargetFile.LastWriteTime = $tFile.LastWriteTime
        $TargetFilesList += $TargetFile
      }
    } 

    Try{ $Diff = Compare-Object -ReferenceObject $SourceFilesList -DifferenceObject $TargetFilesList -Property FullName -IncludeEqual }
    Catch {  $Diff = $Null
             Out-File -FilePath $Logs -InputObject " ERROR: Unable to compare source and destination" -Append
             Out-File -FilePath $Logs -InputObject "" -Append
             }
    
    ForEach($File in $Diff) {  

      $Count2++
      Write-Progress -Id ($Id + 1) -Activity "Comparing files..." -Status "Checking $($Count2) of $($Diff.count): Source Files - $($File.FullName.SubString(1,$File.FullName.length - 1))"  -PercentComplete ($Count2/$Diff.count*100)

      $CountTotalFiles++ 

      If ($PerentFolder -ne (Split-Path -Parent -Path ($Source + $File.FullName))) {
        $PerentFolder = Split-Path -Parent -Path ($Source + $File.FullName)
        Out-File -FilePath $Logs -InputObject $PerentFolder -Append
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
            Out-File -FilePath $Logs -InputObject "$($Output)" -Append
            Break
            }
          {$_ -like $DestinationFile.LastWriteTime} { 
            $CountSkipFiles ++
            $CountSkipBytes += $SourceFile.Length
            $Output = " Skipped File       "
            $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
            Out-File -FilePath $Logs -InputObject "$($Output)" -Append
            Break
            } 
          {$_ -gt $DestinationFile.LastWriteTime} { 
            Try {
              $SourcePath = $Source + $SourceFile.FullName
              $DestinationPath = $Target + $DestinationFile.FullName
              Copy-Item -Path $SourcePath -Destination $DestinationPath
              $Output = " Copied File        "
              $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
              Out-File -FilePath $Logs -InputObject "$($Output)" -Append
              $CountCopyFiles ++
              $CountCopyBytes += $SourceFile.Length
            }
            Catch {
              $Output = " FAILED             Unable to copy "
              $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
              Out-File -FilePath $Logs -InputObject "$($Output)" -Append
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
          Out-File -FilePath $Logs -InputObject "$($Output)" -Append
          $CountCopyFiles ++
          $CountCopyBytes += $SourceFile.Length
        }
        Catch {
          $Output = " FAILED             Unable to copy "
          $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
          Out-File -FilePath $Logs -InputObject "$($Output)" -Append
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
          Out-File -FilePath $Logs -InputObject "$($Output)" -Append
          $CountExtraFiles ++
          $CountExtraBytes += $DestinationFile.Length
        }
        Catch {
          $Output = " FAILED             Unable to delete "
          $Output += $DestinationPath.Split("\") | Select-Object -Last 1
          Out-File -FilePath $Logs -InputObject "$($Output)" -Append
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

    Out-File -FilePath $Logs -InputObject "" -Append
    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    $Result | Format-Table -AutoSize | Out-File -FilePath $Logs -Append
    Out-File -FilePath $Logs -InputObject "End time:       $(Get-Date)" -Append
    Out-File -FilePath $Logs -InputObject "" -Append

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

    $Temp.State = "COMPLETED"
    $ExportCSV += $Temp 

  }
  Else {

    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
    Out-File -FilePath $Logs -InputObject "" -Append
    Out-File -FilePath $Logs -InputObject "ERROR: Unable to map the drive to $URL" -Append
    Out-File -FilePath $Logs -InputObject "" -Append
    $Temp = "" | Select-Object SourceDirectory,TotalFiles,CopiedFiles,SkippedFiles,NewerFiles,FailedFiles,ExtrasFiles,
                               TotalBytes,CopiedBytes,SkippedBytes,NewerBytes,FailedBytes,ExtrasBytes,State
    $Temp.SourceDirectory = $line.DIRECTORY
    $Temp.State = "ERROR"
    $ExportCSV += $Temp
  }
  
 }   

ExitScript