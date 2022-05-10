# *******************************************************************************
# Script to get installed feature of all computer listed in a text file.
# 
# This script will create a .csv file with the inventory.
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2019-10-11  Benoit Blais        Creation
# *******************************************************************************

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION

# Configure the input file with the server list. This file need to be a .txt file.
# The text file should only list the server name, no header.
$InFile = "ServersList.txt"

# Configure the output CSV file destination.
$OutFile = "ServersFeatures.csv"

# **********************************************************************************

$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1
$TimeStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Count = 0

# Define task log file name
$Logs = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).log"

# **********************************************************************************

$ErrorActionPreference = "stop"

# Start script
Out-File -FilePath $Logs -InputObject "$(Get-Date) - Script Begin" 

If (Test-Path ($ScriptPath + "\" + $InFile)) {
    $ServersList = Get-Content ($ScriptPath + "\" + $InFile)
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Read Input File"
}
Else {
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - $($ScriptPath) \ $($InFile) not found" -Append
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Script End" -Append
}

$Inventory = New-Object System.Collections.ArrayList

ForEach($ComputerName in $ServersList) {

    $Count++

    Write-Progress -Activity "Collecting server Features..." -Status "Checking $($Count) of $($ServersList.count): Server - $($ComputerName)"  -PercentComplete ($Count/$ServersList.count*100)

    $ComputerInfo = New-Object System.Object

    Try{
        $Features =  Get-WmiObject -Computer $ComputerName -query 'select * from Win32_ServerFeature where parentid=0' | foreach { $_.Name }
        $Features =  $Features -join "`r`n"
        if ($lastexitcode) {throw $er}
        Else { Out-File -FilePath $Logs -InputObject "$(Get-Date) - Features successfully collected on $($ComputerName)" -Append }
    } 
    Catch {
        $Features = "Features not collected on " + $ComputerName
        Out-File -FilePath $Logs -InputObject "$(Get-Date) - Features not collected on $($ComputerName)" -Append
    }

    $ComputerInfo | 
      Add-Member -MemberType NoteProperty -Name "Name" -Value "$ComputerName" -Force
    $ComputerInfo |
      Add-Member -MemberType NoteProperty -Name "Features" -Value "$Features" -Force 

    $Inventory.Add($ComputerInfo) | Out-Null

    $Features = ""
}

Try {
    $Inventory | Export-Csv ($ScriptPath + "\" + $OutFile) -NoTypeInformation
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Export CSV" -Append
}
Catch {
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to export CSV" -Append
}

Out-File -FilePath $Logs -InputObject "$(Get-Date) - Script End" -Append