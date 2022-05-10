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

$OneDriveFolder = "OneDrive - Cascades"

$SourceFolder = "C:\MyVaut"

$ErrorActionPreference = "stop"

# *******************************************************************************

Function Mirror() {

  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [String]$Source,
    [parameter(Mandatory = $true)]
    [String]$Destination
  )
  BEGIN { }
  PROCESS
  {

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
      $TargetFile.FullName = $tFile.FullName.Replace($Destination,"")
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
            Try {
              $SourcePath = $Source + $SourceFile.FullName
              Remove-Item $SourcePath
              $CountNewerFiles ++
              $CountNewerBytes += $SourceFile.Length
              $Output = " Newer File         "
              $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
              Out-File -FilePath $Global:Logs -InputObject "$($Output)" -Append
              Break
            }
            Catch {
              $Output = " FAILED             Unable to delete "
              $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
              Out-File -FilePath $Global:Logs -InputObject "$($Output)" -Append
              $CountFailFiles ++
              $CountFailBytes += $SourceFile.Length
            }
          }
          {$_ -like $DestinationFile.LastWriteTime} { 
            Try {
              $SourcePath = $Source + $SourceFile.FullName
              Remove-Item $SourcePath
              $CountSkipFiles ++
              $CountSkipBytes += $SourceFile.Length
              $Output = " Skipped File       "
              $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
              Out-File -FilePath $Global:Logs -InputObject "$($Output)" -Append
              Break
            }
            Catch {
              $Output = " FAILED             Unable to delete "
              $Output += $SourceFile.FullName.Split("\") | Select-Object -Last 1
              Out-File -FilePath $Global:Logs -InputObject "$($Output)" -Append
              $CountFailFiles ++
              $CountFailBytes += $SourceFile.Length
            }
          } 
          {$_ -gt $DestinationFile.LastWriteTime} { 
            Try {
              $SourcePath = $Source + $SourceFile.FullName
              $DestinationPath = $Destination + $DestinationFile.FullName
              Copy-Item -Path $SourcePath -Destination $DestinationPath
              Remove-Item $SourcePath
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
            $DestinationPath = $Destination + $SourceFile.FullName
            Copy-Item -Path $SourcePath -Destination $DestinationPath
            Remove-Item $SourcePath
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
            $DestinationPath = $Destination + $DestinationFile.FullName
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

      Out-File -FilePath $Global:Logs -InputObject "" -Append
      Out-File -FilePath $Global:Logs -InputObject "--------------------------------------------------" -Append
      $Result | Format-Table -AutoSize | Out-File -FilePath $Logs -Append
      Out-File -FilePath $Global:Logs -InputObject "End time:       $(Get-Date)" -Append
      Out-File -FilePath $Global:Logs -InputObject "" -Append
  	}
	END { }
  }

# *******************************************************************************

Function SendEmail([string]$From, [string]$To, [string]$Subject, [string]$User, [string]$Server, [string]$Port) {

  $body = "<head>"
  $body = $body + "<meta content=""text/html; charset=utf-8"" http-equiv=""Content-Type"" /></head><body style=""margin: 0; padding: 10px;"">"
  $body = $body + "<table cellspacing=""0"" align=""left"" width=""620"" style=""margin: 0px; background-color: #FFF; color: #000;"" >"
  $body = $body + "<tr height=""5"" Align=""top""><td style=""vertical-align: bottom;"">"
  $body = $body + "<p style=""font-family: Segoe UI; font-size:10.5pt; font-weight:bold; color:#000; background-color:#FFF; margin:0px;padding:0px; vertical-align:bottom;"">"
  $body = $body + "ENGLISH BELOW"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr height=""75"" style=""vertical-align: top;"" bgcolor=""#006C31""><td valign=""top"" style=""vertical-align: top;"" bgcolor=""#006C31""></td></tr>"
  $body = $body + "<tr height=""1"" style=""vertical-align: top;"" bgcolor=""#FFF""><td valign=""top"" style=""vertical-align: top;"" bgcolor=""#FFF""></td><tr>"
  $body = $body + "<tr height=""5"" style=""vertical-align: top;"" bgcolor=""#006C31""><td valign=""top"" style=""vertical-align: top;"" bgcolor=""#006C31""></td></tr>"
  $body = $body + "<tr height=""4"" style=""vertical-align: top;"" bgcolor=""#FFF""><td valign=""top"" style=""vertical-align: top;"" bgcolor=""#FFF""></td></tr>"
  $body = $body + "<tr height=""55"" style=""vertical-align: top;"" bgcolor=""#00B050"">"
  $body = $body + "<td valign=""top"" style=""vertical-align: middle"" bgcolor=""#00B050"">"
  $body = $body + "<p style=""font-family: Lucida Sans Unicode; font-size:13.5pt; font-weight:bold; color:#FFF; padding: 0px; background-color:00B050; vertical-align: middle; text-align:center"">"
  $body = $body + "IMPACT MINEUR"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr height=""1"" style=""vertical-align: top;"" bgcolor=""#FFF""><td valign=""top"" style=""vertical-align: top;"" bgcolor=""#FFF""></td></tr>"
  $body = $body + "<tr height=""4"" style=""vertical-align: top;"" bgcolor=""#00B050""><td valign=""top"" style=""vertical-align: top;"" bgcolor=""#00B050""></td></tr>"
  $body = $body + "<tr style=""vertical-align: top;"">"
  $body = $body + "<td valign=""top"" colspan=""2"" style=""vertical-align: top;"">"
  $body = $body + "<p style=""font-family: Segoe UI; font-size:10.5pt; margin: 5px 5px 5px; padding: 0px;color:#000;"">"
  $body = $body + "<B>Quoi : </B> <BR>"
  $body = $body + "D&eacute;placement des donn&eacute;es du r&eacute;pertoire C:\MyVault vers le dossier MyVault dans OneDrive.<BR><BR>"
  $body = $body + "<B>Quand :</B><BR>" 
  $body = $body + "$((Get-Date).ToString("yyyy-MM-dd"))<BR><BR>"
  $body = $body + "<B>Qui :</B><BR>"
  $body = $body + "$($User)<BR><BR>"
  $body = $body + "<B>Raison :</B><BR>" 
  $body = $body + "Cascades d&eacute;sir utilis&eacute; la solution OneDrive de Microsoft pour y stocker les fichiers puisqu’elle offre une solution de sauvegarde.<BR><BR>"
  $body = $body + "<B>Impact :</B><BR>"		  
  $body = $body + "Les donn&eacute;es pr&eacute;sentes dans le r&eacute;pertoire C:\MyVault ont &eacute;t&eacute; d&eacute;plac&eacute;es vers votre OneDrive.<BR><BR>"
  $body = $body + "<B>Veuillez aviser les utilisateurs concern&eacute;s. <BR>"
  $body = $body + "Nous vous remercions de votre compréhension.</B>"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr style=""vertical-align: top;"" bgcolor=""#3E3E3E"">"
  $body = $body + "<td valign=""top"" style=""vertical-align: top;"" bgcolor=""#3E3E3E"">"
  $body = $body + "<p style=""font-family: Lucida Sans Unicode; font-size:9pt; margin: 2px 2px 0px; padding: 0px;color:#CDCDCD; background-color:#3E3E3E"">"
  $body = $body + "Envoy&eacute; par : Cascades Centre des Technologies<BR>"
  $body = $body + "412, boul. Marie-Victorin Kingsey Falls, Qu&eacute;bec, Canada  J0A 1B0<BR>"
  $body = $body + "T&eacute;l&eacute;phone : 4500 / 54500 (Avaya) / 819 363-2607 / 855 437-2607<BR>"
  $body = $body + "Assistance : http://agora.cascades.com/fr#/technologie-de-linformation/assistance<BR>"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr height=""10"" style=""vertical-align: top;"" bgcolor=""#FFF""><td valign=""top"" style=""vertical-align: top;"" bgcolor=""#FFF""></td><tr>"
  $body = $body + "<tr height=""5"" Align=""top""><td style=""vertical-align: bottom;"">"
  $body = $body + "<p style=""font-family: Segoe UI; font-size:10.5pt; font-weight:bold; color:#000; background-color:#FFF; margin:0px;padding:0px; vertical-align:bottom;"">"
  $body = $body + "FRAN&Ccedil;AIS PLUS HAUT"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr height=""75"" style=""vertical-align: top;"" bgcolor=""#006C31""><td valign=""top"" style=""vertical-align: top;"" bgcolor=""#006C31""></td></tr>"
  $body = $body + "<tr height=""1"" style=""vertical-align: top;"" bgcolor=""#FFF""><td valign=""top"" style=""vertical-align: top;"" bgcolor=""#FFF""></td><tr>"
  $body = $body + "<tr height=""5"" style=""vertical-align: top;"" bgcolor=""#006C31""><td valign=""top"" style=""vertical-align: top;"" bgcolor=""#006C31""></td></tr>"
  $body = $body + "<tr height=""4"" style=""vertical-align: top;"" bgcolor=""#FFF""><td valign=""top"" style=""vertical-align: top;"" bgcolor=""#FFF""></td></tr>"
  $body = $body + "<tr height=""55"" style=""vertical-align: top;"" bgcolor=""#00B050"">"
  $body = $body + "<td valign=""top"" style=""vertical-align: middle"" bgcolor=""#00B050"">"
  $body = $body + "<p style=""font-family: Lucida Sans Unicode; font-size:13.5pt; font-weight:bold; color:#FFF; padding: 0px; background-color:00B050; vertical-align: middle; text-align:center"">"
  $body = $body + "MINOR IMPACT"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr height=""1"" style=""vertical-align: top;"" bgcolor=""#FFF""><td valign=""top"" style=""vertical-align: top;"" bgcolor=""#FFF""></td></tr>"
  $body = $body + "<tr height=""4"" style=""vertical-align: top;"" bgcolor=""#00B050""><td valign=""top"" style=""vertical-align: top;"" bgcolor=""#00B050""></td></tr>"
  $body = $body + "<tr style=""vertical-align: top;"">"
  $body = $body + "<td valign=""top"" colspan=""2"" style=""vertical-align: top;"">"
  $body = $body + "<p style=""font-family: Segoe UI; font-size:10.5pt; margin: 5px 5px 5px; padding: 0px;color:#000;"">"
  $body = $body + "<B>What: </B> <BR>" 
  $body = $body + "Moving files from C:\MyVault to MyVault folder in OneDrive.<BR><BR>"
  $body = $body + "<B>When:</B><BR>"
  $body = $body + "$((Get-Date).ToString("yyyy-MM-dd"))<BR><BR>"
  $body = $body + "<B>Who:</B><BR>"
  $body = $body + "$($User)<BR><BR>"
  $body = $body + "<B>Reason:</B><BR>"
  $body = $body + "Cascades want to use Microsoft OneDrive to save user file and this solution have a built-in backup solution.<BR><BR>"
  $body = $body + "<B>Impact:</B><BR>"		  
  $body = $body + "Files located in C:\MyVault has been move to MyVault OneDrive folder.<BR><BR>"
  $body = $body + "<B>Please notify affected users. <BR>"
  $body = $body + "We thank you for your understanding.</B>"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr style=""vertical-align: top;"" bgcolor=""#3E3E3E"">"
  $body = $body + "<td valign=""top"" style=""vertical-align: top;"" bgcolor=""#3E3E3E"">"
  $body = $body + "<p style=""font-family: Lucida Sans Unicode; font-size:9pt; margin: 2px 2px 0px; padding: 0px;color:#CDCDCD; background-color:#3E3E3E"">"
  $body = $body + "Sent by : Cascades Centre des Technologies<BR>"
  $body = $body + "412, boul. Marie-Victorin Kingsey Falls, Quebec, Canada J0A  1B0<BR>"
  $body = $body + "Phone : 4500 / 54500 (Avaya) / 819 363-2607 / 855 437-2607<BR>"
  $body = $body + "Support : http://agora.cascades.com/en#/technology/support<BR>"
  $body = $body + "</p></td></tr></table></body></html>"

  Send-MailMessage -To $To -Subject $Subject -Body $body -SmtpServer $Server -From $From -BodyAsHtml -Port $Port
}

# *******************************************************************************

# Validate if the computer can reach the Cascades network.
If (Test-Path $ScriptPath) {

  # Validate if the log folder exist, if not, create it.
  If(!(Test-Path "$($ScriptPath)\$($ScriptName)")) { New-Item -ItemType Directory -Path "$($ScriptPath)\$($ScriptName)" }
  
  Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
  Out-File -FilePath $Logs -InputObject "SCRIPT BEGIN" -Append
  Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
  Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | INFO  : Laptop User: $($env.Username)" -Append

  # Validate operating system version
  $WindowsVersion = [System.Environment]::OSVersion.Version
  If ($WindowsVersion.Major -eq 10) {

    Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | INFO  : Operating system : Windosw 10" -Append

    # Validate if the OneDrive is configure.
    If ($env:OneDriveCommercial -like "$($env:userprofile)\$($OneDriveFolder)") {

      Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | INFO  : OneDrive folder : $($env:OneDriveCommercial)" -Append
      
      $DestinationFolder = $env:OneDriveCommercial + "\MyVault"
      #test-path
      #si n'existe pas
      New-Item $DestinationFolder
      #log dnas fichier
      #sinon log dans fihcier already exist
      Mirror $SourceFolder $DestinationFolder

      If (( Get-ChildItem $SourceFolder | Measure-Object ).Count -eq 0) {

        Try {
          Remove-Item $SourceFolder
          Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | INFO  : $($SourceFolder) deleted" -Append
        }
        Catch {
          Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | INFO  : Unable to delete $($SourceFolder)" -Append
        }

      }
          
      #edit CSV file with Success in x colonne
      SendEmail "NoReply@Cascades.com" "Benoit_Blais@Cascades.com" "Migration des données MyVault vers OneDrive / Data migration from MyVault to OneDrive" "Benoit Blais" "smtp.cascades.com" "25"

    }
    Else {

    #do same things as Windows 7

    }

  }
  Else {
    
    Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | INFO  : Operating system : Windosw 7" -Append
    
    # Validate if the computer is connected to network from a VPN
    Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = 'True'" | ForEach-Object { if($_.Description -eq "Citrix Virtual Adapter") {$VPN = $True} Else { $VPN = $False } }
    
    # Because the OneDriveMapper script can't connect when the VPN is connected, we need to validate this
    If (!($VPN)) {

      Out-File -FilePath $Logs -InputObject "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | INFO  : Operating system : Windosw 7" -Append
      
      # Validate if drive letter is currently in use.
      If(Test-Path $DriveLetter) {
    
        # Validate if the drive is mapped to OneDrive
        $MappedDrive = Get-PSDrive $DriveLetter.SubString(0,1)
        If ($MappedDrive.DisplayRoot.Substring(0,28) -like $OneDrivePath) {
      
          Mirror $SourceFolder $DestinationFolder

        } 
        
        Else {
        
          # Try to find another drive letter
          #$Letter = [char[]](67..90) | Where {(get-wmiobject win32_logicaldisk | select -expand DeviceID) -notcontains "$($_):"} | Select -first 1
          # Run script
          # Start miror
        
        }
        Else 
        {
          # Map drive
          # run mirror
        }
      }
    }

  }

}















## Validate if drive letter is currently in use.
#If(Test-Path $DriveLetter) {
#  $Loop = 0
#  Do {
#    Try{$Del = NET USE $DriveLetter.SubString(0,2) /DELETE /Y 2>&1}Catch{$Null}
#    $Loop ++
#  } While ((Test-Path $DriveLetter) -and ($Loop -lt 5))
#  If ($Loop -eq 5) {
#    Out-File -FilePath $Logs -InputObject "ERROR : unable to unmap drive $($DriveLetter)" -Append
#    Out-File -FilePath $Logs -InputObject "" -Append
#    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
#    Out-File -FilePath $Logs -InputObject "SCRIPT END" -Append
#    Out-File -FilePath $Logs -InputObject "--------------------------------------------------" -Append
#    Exit
#  }
#}

#  # Call OneDriveMapper to map the OneDrive.
#  $URL = $line.ONEDRIVEURL
#  $ScriptBlock = [ScriptBlock]::Create("$OneDriveScriptPathShort -O365 $O365CustomerName -URL $URL -account $UserName -password $Password")
#  $Invoke = Invoke-Command -ScriptBlock $ScriptBlock#


