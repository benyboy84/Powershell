# *******************************************************************************
# Script to validate if files in folder are newer than a specific time.
# 
# This script can be use in WhatsUP Gold application to monitor if a folder
# contains file not treated by a software since a specefic time.
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2019-10-11  Benoit Blais        Creation
# *******************************************************************************

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION

# Configure the folder path where you want to monitor file.
$FolderPath = "\\ad.cascades.com\apps\CTX-Apps\396\Amtech\EDI\Outbound\Tencorr"

# Configure the file extension to monitor.
$EXT = "*.dat"

# Configure the delay in minutes since the file was create to allow software to treate it.
$TimeSinceCreation = 60  

# **********************************************************************************

$limit = (Get-Date).AddMinutes(-($TimeSinceCreation))

$Files = Get-ChildItem -Path $FolderPath -Filter $EXT | Where-Object { $_.CreationTime -lt $limit }

If (!($Files.Count)) {
    $Context.SetResult(0,$Files.Count)
    }
Else {
    $Context.SetResult(1,$Files.Count)
    }