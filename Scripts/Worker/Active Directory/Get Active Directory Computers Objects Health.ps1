# **********************************************************************************
# Script to find all Active Directory Computers objects informations.
#
# If you need to troubleshoot the script, you can enable the Debug option in
# the parameter. This will generate display information on the screen.
#
# This script needs to be run directly on a Domain Controller.
#
# This script use Active Directory module
#
# ==================================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2022-02-01  Benoit Blais        Original version
# **********************************************************************************

Param(
    [Switch]$Debug = $False
)

#Default action when an error occured
$ErrorActionPreference = "Stop"

# **********************************************************************************

#Log function will allow to display colored information in the PowerShell window
#if debug mode is $TRUE.
#Parameters:
#$Text : Text added to the text file.
#$Error and $Warning: These switch need to be use to specify something else then an information.
Function Log {
    Param (
        [Parameter(Mandatory=$true)][String]$Text,
        [Switch]$Error,
        [Switch]$Warning
    )
    If ($Debug) {
        $Output = "$(Get-Date) |"
        If($Error) {
            $Output += " ERROR   | $Text"
            Write-Host $Output -ForegroundColor Red
        }
        ElseIf($Warning) {
            $Output += " WARNING | $Text"
            Write-Host $Output -ForegroundColor Yellow
        }
        Else {
            $Output += " INFO    | $Text"
            Write-Host $Output -ForegroundColor Green
        }
    }
}

# **********************************************************************************

Log -Text "Script Begin"

#Validate if Active Directory module is currently loaded in Powershell session.
Log -Text "Validating if Active Directory module is loaded in the currect Powershell session"
If (!(Get-Module | Where-Object {$_.Name -eq "ActiveDirectory"})){

    #Active Directory is not currently loaded in Powershell session.
    Log -Text "Active Directory is not currently loaded in Powershell session" -Warning
    If (Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"}) { 
        
        #Active Directory module installed on that computer.
        Log -Text "Active Directory module installed on that computer"
        #Trying to import Active Directory module.
        Log -Text "Trying to import Active Directory module"
        Try {
            Import-Module ActiveDirectory 
        }
        Catch {
            #Unable to import Active Directory module.
            Log -Text "Unable to import Active Directory module" -Error
            #Because this script can't be run without this module, the script execution is stop.
            Break
        }
    
    }
    Else {
        
        #Active Directory module is not installed on the current computer.
        Log -Text "ctive Directory module is not installed on the current computer" -Error
        #Because this script can't be run without this module, the script execution is stop.
        Break
    }
}
Else {

    #Active Directory module is loaded in the current Powershell session.
    Log -Text "Active Directory module is loaded in the current Powershell session"

}

#Get all Active Directory Computer objects.
Try {
   
    Log -Text "Getting Active Directory computers objects"
    $Computers = Get-ADComputer -Filter * -Properties Name,OperatingSystem,Lastlogondate
    
}
Catch {
    Log -Text "An error occured during getting Active Directory computers objects" -Error
}
Write-Host "Active Directory Computers Objects ($($Computers.Count))" -ForegroundColor Cyan


#Get computer's objects by operating system.
Log -Text "Get computer's objects by operating system"
$ComputersByOperatingSystem = @()
ForEach ($OperatingSystem in $OperatingSystems) {

        If ($OperatingSystem.OperatingSystem -ne $Null) {    
            [Array]$Count = $Computers | Where-Object {$_.OperatingSystem -eq $OperatingSystem.OperatingSystem}
            $Object = "" | Select-Object OperatingSystem,
                                        Count
            $Object.OperatingSystem = $OperatingSystem.OperatingSystem
            $Object.Count = $Count.Count
            $ComputersByOperatingSystem += $Object
        }
}
Write-Host "Active Directory Computers Objects by operating system" -ForegroundColor Cyan
$ComputersByOperatingSystem | Format-Table -AutoSize

#Get computers objects by last loggon date
Write-Host "Active Directory Computers Objects by operating system" -ForegroundColor Cyan
Log -Text "Get computer's objects by last loggon date"
[Array]$Count = $Computers | Where-Object {$_.Lastlogondate -gt (Get-Date).AddMonths(-6)}
Write-Host "Last 6 months                      : $($Count.Count)"
[Array]$Count = $Computers | Where-Object {($_.Lastlogondate -gt (Get-Date).AddMonths(-12)) -and($_.Lastlogondate -lt (Get-Date).AddMonths(-6))}
Write-Host "Between 6 months to 1 year         : $($Count.Count)"
[Array]$Count = $Computers | Where-Object {($_.Lastlogondate -gt (Get-Date).AddMonths(-24)) -and ($_.Lastlogondate -lt (Get-Date).AddMonths(-12))}
Write-Host "Between 1 to 2 years               : $($Count.Count)"
[Array]$Count = $Computers | Where-Object {$_.Lastlogondate -lt (Get-Date).AddMonths(-24) }
Write-Host "More then 2 years                  : $($Count.Count)"

Log -Text "Script ended"