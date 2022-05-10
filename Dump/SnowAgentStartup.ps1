# *******************************************************************************
#
# Script to deploy Snow Agent
#
# This script is used to install Snow Agent on Citrix servers.
#
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2021-07-08  Benoit Blais        Creation
# *******************************************************************************

Param(
    [Switch]$Debug = $False
)

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION
$SourcePath = "\\ad.cascades.com\NETLOGON\SNOW"    #Do not put \ at the end"
$ConfigFile = "snowagent.config"
$DisplayName = "Snow Inventory Agent"
$ScheduledTaskName = "SnowAgentScan"
$ScriptPath = "C:\Script"                          #Do not put \ at the end"

#If you need to edit the SystemSettings section in the ConfigFile, edit the folliwing line
$SystemSettings = @(
    New-Object PSObject -Property @{Key = "env.is_virtual_desktop_infrastructure"; Value = "true"}
)

# *******************************************************************************

#Default action when an error occured.
$ErrorActionPreference = "Stop"

# *******************************************************************************

#Here is the script to do a scan with the agent.
#We need to create a PS1 file on the server to be able to launch a scheduled task.
$Script = '
# *******************************************************************************
#
# Script to launch Snow Agent Scan
#
# This script is used by a scheduled task to launch the scan.
#
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2021-07-08  Benoit Blais        Creation
# *******************************************************************************

# *******************************************************************************

#Default action when an error occured.
$ErrorActionPreference = "Stop"

# *******************************************************************************

#Launch scan
$SnowAgentPath = "$env:programfiles\Snow Software\Inventory\Agent\snowagent.exe"
If (Test-Path -Path $SnowAgentPath) {    
    If ((Get-Service "SnowInventoryAgent5").Status -eq "Running") {
        Try {
            Stop-Service "SnowInventoryAgent5"
        }
        Catch {
            Exit 1
        }
    }
    $Arguments = "scan"    
    Try {
        $MyPID = Start-Process $SnowAgentPath $Arguments -PassThru -WindowStyle Hidden    
    }
    Catch {
        Exit 1
    }
    Wait-Process $MyPID.Id -Timeout 300    
    $Arguments = "send"    
    Try {
        $MyPID = Start-Process $SnowAgentPath $Arguments -PassThru -WindowStyle hidden    
    }
    Catch {
        Exit 1
    }
    Wait-Process $MyPID.Id -Timeout 300
    Start-Service "SnowInventoryAgent5"
}
'

# *******************************************************************************

#If debug is not $TRUE, we will hide the current PowerShell processus window.
If($Debug -eq $False) {
    $t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
    Try {
        Add-Type -name win -member $t -namespace native
        [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)
    } Catch {$Null}
}

# *******************************************************************************

#Log function will allow to display colored information in the PowerShell window
#if debug mode is $TRUE.
#Parameters:
#$Text : Text added to the text file.
#$Error and $Warning: These switch need to be use to specify something else then an information.
Function Log{
    Param (
        [Parameter(Mandatory=$true)][String]$Text,
        [Switch]$Error,
        [Switch]$Warning
    )
    If($Error){
        $Text = "ERROR | $Text"
    }
    ElseIf($Warning){
        $Text = "WARNING | $Text"
    }
    Else{
        $Text = "INFO | $Text"
    }
    If($Debug){
        If($Error){
            Write-Host $Text -ForegroundColor Red
        }ElseIf($Warning){
            Write-Host $Text -ForegroundColor Yellow
        }Else{
            Write-Host $Text -ForegroundColor Green
        }
    }
}


# *******************************************************************************

#Function to validate if a software is already installed
Function IsInstalled{
    Param (
        [Parameter(Mandatory=$true)][String]$DisplayName
    )
    $UninstallKey64Bits = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $UninstallKey32Bits += "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    If ((Get-ChildItem -Path $UninstallKey64Bits | Get-ItemProperty | Where DisplayName -match $DisplayName) -eq $Null -and (Get-ChildItem -Path $UninstallKey32Bits | Get-ItemProperty | Where DisplayName -match $DisplayName) -eq $Null) {
        return $false
    }
    Else {
        return $true
    }
}

# *******************************************************************************

Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Script begin"

#If software is not install, we will install it
If (!(IsInstalled($DisplayName))) {
    Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | $($DisplayName) is not installed"
    If (Test-Path -Path $SourcePath) {
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Get source file"
        Switch ((Get-ChildItem -Path $SourcePath -Filter "*$((Get-WmiObject Win32_Processor).AddressWidth).msi" | Measure-Object).Count) {
            {$_ -eq 1}  {
                        $SourceFile = Get-ChildItem -Path $SourcePath -Filter "*$((Get-WmiObject Win32_Processor).AddressWidth).msi"
            }
            {$_ -gt 1}  {
                        $SourceFiles = Get-ChildItem -Path $SourcePath -Filter "*$((Get-WmiObject Win32_Processor).AddressWidth)*" | Sort LastWriteTime -Descending
                        $SourceFile = $SourceFiles[0]
            }
            {$_ -eq 0}  {
                        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | No source file" -Error
                        Exit 1
            }
        }
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Copy source file"
        Try {
            Copy-Item -Path $SourceFile.FullName -Destination "$($env:windir)\Temp\$($SourceFile.Name)" -Force
        }
        Catch {
            Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Error:$($PSItem.Exception.Message)" -Error
            Exit 1
        }
        If (Test-Path -Path "$($SourcePath)\$($ConfigFile)") {
            Try {
                Copy-Item -Path "$($SourcePath)\$($ConfigFile)" -Destination "$($env:windir)\Temp\$($ConfigFile)" -Force
            }
            Catch {
                Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Error:$($PSItem.Exception.Message)" -Error
                Exit 1
            }
        }
        Else {
            Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Source file $($ConfigFile) does not exist" -Error
            Exit 1
        }
    }
    Else {
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Source path does not exist" -Error
        Exit 1
    }

    #Edit ConfigFile SystemSettings section
    If ($SystemSettings.Count -gt 0) {
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Edit config file"
        ForEach($SystemSetting in $SystemSettings){
            Try {
                [XML]$FileContent = Get-Content "$($env:windir)\Temp\$($ConfigFile)"
            }
            Catch {
                Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Error:$($PSItem.Exception.Message)" -Error
                Exit 1
            }
            If (($FileContent.Configuration.SystemSettings.Setting | Select-Object key).key -notcontains $SystemSetting.Key) {
                Try {
                    $NewElemenent = $FileContent.Configuration.SystemSettings.AppendChild($FileContent.CreateElement("Setting"))
                    $NewElemenent.SetAttribute("key", $SystemSetting.Key)
                    $NewElemenent.SetAttribute("value", $SystemSetting.Value)
                    $FileContent.Save("$($env:windir)\Temp\$($ConfigFile)")
                }
                Catch {
                    Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Error:$($PSItem.Exception.Message)" -Error
                    Exit 1
                }
            }
            Else {
                If (($FileContent.Configuration.SystemSettings.Setting | Where Key -match $SystemSetting.Key).value -ne $SystemSetting.Value) {
                    Try {
                        ($FileContent.Configuration.SystemSettings.Setting | Where Key -match $SystemSetting.Key).SetAttribute("value", $SystemSetting.Value)
                        $FileContent.Save("$($env:windir)\Temp\$($ConfigFile)")
                    }
                    Catch {
                        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Error:$($PSItem.Exception.Message)" -Error
                        Exit 1
                    }
                }
            }
        }
    }

    #Install software
    Try {    
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Install $($DisplayName)"
        Start-Process "msiexec.exe" -ArgumentList "/i $($env:windir)\Temp\$($SourceFile.Name) /quiet" -NoNewWindow -Wait 
    }
    Catch {
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Error:$($PSItem.Exception.Message)" -Error
        Exit 1
    }

    #Copy config file
    If ((Get-Service 'SnowInventoryAgent5').Status -eq 'Running') {
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Stopping service"
        Try {
            Stop-Service 'SnowInventoryAgent5'     
        }
        Catch {
            Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Unable to stop service" -Error
            Exit 1
        }
    }
    Try {
        Copy-Item -Path "$($env:windir)\Temp\$($ConfigFile)" -Destination "C:\Program Files\Snow Software\Inventory\Agent\$($ConfigFile)" -Force
    }
    Catch {
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Unable to copy configuration file" -Error
        Exit 1
    }

    #Loop until the validation check for the installation pass
    $Count = 0
    While (!(IsInstalled($DisplayName)) -and $Count -lt 30) {
        Start-Sleep -Seconds 10
        $Count++
    }

    #Confirm installaiton status
    If (IsInstalled($DisplayName)) {
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | $($DisplayName) is install"
    }
    Else {
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | $($DisplayName) not install" -Error
        Exit 1
    }

}

#Create scheduled task
If (!(Get-ScheduledTask | Select-Object TaskName | Where-Object -Property TaskName -EQ $ScheduledTaskName)) {

    If (!(Test-Path -Path $ScriptPath)){
        Try {
            Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Create folder containing script"
            $Path = $ScriptPath.Split("\") | Select-Object -First ( $ScriptPath.Split("\").Count - 1)
            $Name = $ScriptPath.Split("\") | Select-Object -Last 1
            New-Item -Path "$($Path)\" -Name $Name -ItemType Directory -Force | Out-Null
        }
        Catch {
            Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Unable to create folder containing script" -Error
            Exit 1
        }
    }
    If (!(Test-Path -Path "$($ScriptPath)\SnowScan.ps1")){
        Try {
            Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Create script"
            $Script | Out-File -FilePath "$($ScriptPath)\SnowScan.ps1" 
        }
        Catch {
            Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Unable to create script" -Error
            Exit 1
        }
    }

    # Create scheduled task to run the Snow Agent scan
    Try {
        $command = "PowerShell -WindowStyle Hidden -ExecutionPolicy unrestricted $($ScriptPath)\SnowScan.ps1"
        @(SCHTASKS /CREATE /SC ONSTART /ru "SYSTEM" /TN "SnowAgentScan" /TR "$($command)" /F)
        @(SCHTASKS /Run /TN "SnowAgentScan")
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Scheduled task created"
    }
    Catch {
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Unable to create scheduled task" -Error
        Exit 1
    }
}