# **********************************************************************************
# Script to get information for KRBTGT Account.
#
# The KRBTGT account is a domain default account that acts as a service account for 
# the KDC service. In most cases, KRBTGT resets might be performed when Active 
# Directory is compromised. Still, Microsoft advises changing the password at 
# regular intervals to keep the environment more secure. The script checks and 
# highlights whether the account password has not changed within the last 180 days.
#
# If you need to troubleshoot the script, you can enable the Debug option in
# the parameter. This will generate display information on the screen.
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
        Try {
            #Trying to import Active Directory module.
            Log -Text "Trying to import Active Directory module"
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

#Get krbtgt account information
Try {
    Log -Text "Get krbtgt account information"
    $DomainKRBTGTAccount = Get-ADUser 'krbtgt' -Server $DCtoConnect -Properties 'msds-keyversionnumber',Created,PasswordLastSet
}
Catch {
    Log -Text "An error occured during getting krbtgt account information" -Error
    Break
}

$SelectedPros = @("DistinguishedName","Enabled","msds-keyversionnumber","PasswordLastSet","Created")
$Result = @()

#Create an array with the desired properties
$SelectedPros | % {
    $Object = "" | Select-Object Property,
                                Value 
    $Object.Property = $_
    $Object.Value = $DomainKRBTGTAccount.$PSItem
    $Result += $Object 
}

Write-Host "KRBTGT Account Information" -ForegroundColor Cyan
$Result | FT

 