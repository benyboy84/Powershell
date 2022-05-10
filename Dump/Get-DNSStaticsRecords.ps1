# *******************************************************************************
# Script to get a list of statics DNS records for s specific zone.
# 
# This script will create a .txt file with the list of statics records.
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2019-10-11  Benoit Blais        Creation
# *******************************************************************************

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION

# Configure DNS zone where to search.
$Zone = "orchids.local"

# Configure the output file destination.
$OutFile = ".\DNS.txt"

# **********************************************************************************

Get-DnsServerResourceRecord -ZoneName $Zone | Where-Object Timestamp -like $null  | Out-File -FilePath $OutFile