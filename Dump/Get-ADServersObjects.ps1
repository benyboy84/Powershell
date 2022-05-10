# *******************************************************************************
# Script to get a list of all objects on Active Directory with Microsoft Windows
# server edition.
# 
# This script will create a .txt file with the list of server name.
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2019-10-11  Benoit Blais        Creation
# *******************************************************************************

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION

# Configure the number of inactive days to exclude old object from the list.
$DaysInactive = 90

# Configure the output file destination.
$OutFile = ".\ServerList.txt"

# **********************************************************************************

$time = (Get-Date).Adddays(-($DaysInactive))

Get-ADComputer -Filter {(LastLogonTimeStamp -gt $time) -and (OperatingSystem -Like "*server*")} -ResultPageSize 2000 -resultSetSize $null | Select-Object Name  | Out-File -FilePath $OutFile