# **********************************************************************************
# Script to get computer inventory over network
#
# This script will loop throuht ActiveDirectory to find all computer object.
# It will test the connection and if the computer is on the network, it will 
# get all the inventory.
#
# IMPORTANT : Active Directory module for Windows Powershell is required.
# ==================================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2019-09-24  Benoit Blais        First iteration
# **********************************************************************************

# **********************************************************************************

<#
.SYNOPSIS

.DESCRIPTION

.EXAMPLE

.PARAMETER

#>

# **********************************************************************************

####MANDATORY MANUAL CONFIGURATION
$DaysInactive = 90      #This will limit the search in Active Directory by excluding computers that have not communicated for some time.

# **********************************************************************************

# Set the error prefer action
$ErrorActionPreference = "Stop"

# **********************************************************************************

# Import Active Directory Module to use Get-ADUser command
Try{
    Import-Module ActiveDirectory
    } 
  Catch{
    $ErrorMessage = 'Unable to import Active Directory Module'
    Write-Host "Error on loading Active Dorectory module" -ForegroundColor Red
    Exit
    }

# **********************************************************************************




$time = (Get-Date).Adddays(-($DaysInactive))

$Computer = Get-ADComputer -Filter {LastLogonTimeStamp -lt $time} -ResultPageSize 2000 -resultSetSize $null -Properties Name, OperatingSystem, SamAccountName, DistinguishedName


#$computers = Get-ADComputer -filter {(Name -like "PC*")} | 
#   Select-Object -ExpandProperty Name