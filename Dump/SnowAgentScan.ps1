# *******************************************************************************
#
# Script to launch Snow Agent Scan
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

# *******************************************************************************

#Default action when an error occured.
$ErrorActionPreference = "Stop"

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

#Launch scan
$SnowAgentPath = "$env:programfiles\Snow Software\Inventory\Agent\snowagent.exe"
If (Test-Path -Path $SnowAgentPath) {    
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
    $Arguments = "scan"    
    Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Starting scan"
    Try {
        $MyPID = Start-Process $SnowAgentPath $Arguments -PassThru -WindowStyle Hidden    
    }
    Catch {
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Error:$($PSItem.Exception.Message)" -Error
        Exit 1
    }
    Wait-Process $MyPID.Id -Timeout 300    
    $Arguments = "send"    
    Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Sending data"
    Try {
        $MyPID = Start-Process $SnowAgentPath $Arguments -PassThru -WindowStyle hidden    
    }
    Catch {
        Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Error:$($PSItem.Exception.Message)" -Error
        Exit 1
    }
    Wait-Process $MyPID.Id -Timeout 300
    Log -Text "$((Get-Date).ToString("yyyy-MM-dd HH:mm")) | Starting service"
    Start-Service 'SnowInventoryAgent5'
}



