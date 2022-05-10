# *******************************************************************************
# Script to extract icon from Citrix Application.
#
# This script need Citrix module. To launch it, open Citrix Studio, in the left
# menu, click on Citrix Studio then, click on PowerShell tab. Click on Launch
# PowerShell button at the bottom of the screen.
#
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2020-07-20  Benoit Blais        Creation
# *******************************************************************************

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION
# You need to specify the application location in the tree.
$CitrixApplication = Get-BrokerApplication -Name "Path\ApplicationName"

# You need to specify the destionation where the icon will be save.
$Destination = "C:\Temp"

# *******************************************************************************
$Base64String = Get-BrokerIcon -Uid $CitrixApplication.IconUid | Select * -ExpandProperty EncodedIconData
$Image = "$($Destination)\$($CitrixApplication.ApplicationName).ico"
[byte[]]$Bytes = [convert]::FromBase64String($Base64String)
[System.IO.File]::WriteAllBytes($Image,$Bytes)