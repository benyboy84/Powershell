# *******************************************************************************
# Script to get a printer inventory of all computer listed in a text file.
# This script will get printer name, type, driver, port... informations. 
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
$InFile = "ServerList.txt"

# Configure the output CSV file destination.
$OutFile = "PrintersInventory.csv"

# **********************************************************************************

$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1
$TimeStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Count = 0

# Define task log file name
$Logs = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).log"

# **********************************************************************************

# Start script
Out-File -FilePath $Logs -InputObject "$(Get-Date) - Script Begin" 

$ErrorActionPreference = "stop"

If (Test-Path ($ScriptPath + "\" + $InFile)) {
    $ServersList = Get-Content ($ScriptPath + "\" + $InFile)
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Read Input File"
}
Else {
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - $($ScriptPath) \ $($InFile) not found" -Append
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Script End" -Append
}

$Inventory = @()

ForEach($ComputerName in Get-Content $InFile) {
    
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Collecting $($CompuerName) inventory" -Append

    $Count++

    Write-Progress -Activity "Collecting server inventory..." -Status "Checking $($Count) of $($ServersList.count): Server - $($ComputerName)"  -PercentComplete ($Count/$ServersList.count*100)

    $ComputerInfo = New-Object System.Object 

    Try{
        $ComputerPrinters = Get-Printer -ComputerName $ComputerName 
       }
    Catch{}

    If ($ComputerPrinters -ne $Null) {
        ForEach($Printer in $ComputerPrinters) {
        $obj = "" | 
        Select-Object Name,
                      ComputerName,
                      Type,
                      DriverName,
                      Port,
                      Shared,
                      Published
        $obj.Name = $Printer.Name
        $obj.ComputerName = $Printer.ComputerName
        $obj.Type = $Printer.Type
        $obj.DriverName = $Printer.DriverName
        $obj.Port = $Printer.Port
        $obj.Shared = $Printer.Shared
        $obj.Published = $Printer.Published
        $Inventory += $obj
        }
    }
    Else {
        $obj = "" | 
        Select-Object Name,
                      ComputerName,
                      Type,
                      DriverName,
                      Port,
                      Shared,
                      Published
        $obj.Name = "No Spooler"
        $obj.ComputerName = $Printer.ComputerName
        $obj.Type = "N/A"
        $obj.DriverName = "N/A"
        $obj.Port = "N/A"
        $obj.Shared = "N/A"
        $obj.Published = "N/A"
        $Inventory += $obj
    }
}

Try {
    $Inventory | Export-Csv ($ScriptPath + "\" + $OutFile) -NoTypeInformation
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Export CSV" -Append
}
Catch {
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to export CSV" -Append
}

Out-File -FilePath $Logs -InputObject "$(Get-Date) - Script End" -Append
