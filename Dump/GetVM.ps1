# **********************************************************************************
# Script to get VM
# Ce script nécessite en argument le nom du vCenter.
# Ce script nécessite le PowerCLI de VMware.
# ==================================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2015-11-10  Benoit Blais        Cération initiale du script
# **********************************************************************************

# Environment Setup
$OutputFile = "C:\Windows\Temp\VM.txt"

If ($args[0] -is [string]) {
   cd "C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\"
   .\Initialize-PowerCLIEnvironment.ps1
   Connect-VIServer -Server $args[0]
   Get-vm | where { ($_.PowerState -eq "PoweredOn") -and ($_.Guest -like "*Microsoft*")} | select name | FT -Auto | Out-File $OutputFile
}